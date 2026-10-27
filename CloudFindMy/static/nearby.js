'use strict';
const statusLine = document.getElementById('push-status');
const csrf = document.querySelector('meta[name="csrf"]').content;
const buttons = [...document.querySelectorAll('#enable-push, #test-push, #disable-push')];
async function request(path, body = {}) {
  const response = await fetch(path, {method: 'POST', headers: {'Content-Type': 'application/json', 'X-Shift-CSRF': csrf}, body: JSON.stringify(body)});
  if (!response.ok) throw new Error(response.status === 401 ? 'Unlock your helper again, then retry.' : 'Could not finish. Check your connection and try again.');
  return response.json();
}
function bytes(value) {
  return Uint8Array.from(atob(value.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(value.length/4)*4, '=')), c => c.charCodeAt(0));
}
function connected(value) {
  document.getElementById('enable-push').hidden = value;
  document.getElementById('test-push').hidden = !value;
  document.getElementById('disable-push').hidden = !value;
}
async function run(action) {
  buttons.forEach(b => b.disabled = true);
  try { await action(); } catch (error) { statusLine.textContent = error.message; }
  finally { buttons.forEach(b => b.disabled = false); }
}
document.getElementById('enable-push').addEventListener('click', () => run(async () => {
  if (!('serviceWorker' in navigator) || !('PushManager' in window) || !('Notification' in window)) throw new Error('On iPhone, add this website to your Home Screen, then open it there.');
  // Permission is requested directly from the deliberate tap, before network work.
  if (await Notification.requestPermission() !== 'granted') throw new Error('Notifications are off. You can allow them in your device settings.');
  await navigator.serviceWorker.register('/sw.js');
  const registration = await navigator.serviceWorker.ready;
  const configResponse = await fetch('/nearby/push-config');
  if (!configResponse.ok) throw new Error('Unlock your helper again, then retry.');
  const config = await configResponse.json();
  let subscription = await registration.pushManager.getSubscription();
  const expected = bytes(config.key);
  if (subscription && Array.from(new Uint8Array(subscription.options.applicationServerKey || [])).join() !== Array.from(expected).join()) {
    await subscription.unsubscribe(); subscription = null;
  }
  subscription ||= await registration.pushManager.subscribe({userVisibleOnly: true, applicationServerKey: expected});
  await request('/nearby/subscribe', subscription.toJSON());
  connected(true);
  statusLine.textContent = 'Notifications enabled here. Send a test to check delivery.';
}));
document.getElementById('test-push').addEventListener('click', () => run(async () => {
  const registration = await navigator.serviceWorker?.getRegistration('/');
  const subscription = await registration?.pushManager.getSubscription();
  if (!subscription) throw new Error('Enable notifications on this device first.');
  const result = await request('/nearby/test-push', {endpoint: subscription.endpoint});
  statusLine.textContent = result.sent ? 'Test sent. Check your notifications.' : 'Test could not be sent. Enable notifications again or try later.';
}));
document.getElementById('disable-push').addEventListener('click', () => run(async () => {
  const registration = await navigator.serviceWorker?.getRegistration('/');
  const subscription = await registration?.pushManager.getSubscription();
  if (subscription) { await request('/nearby/unsubscribe', {endpoint: subscription.endpoint}); await subscription.unsubscribe(); }
  connected(false);
  statusLine.textContent = 'Notifications are off on this device.';
}));
// No heartbeat, background location request, animation loop, or automatic permission prompt.

(async () => {
  try {
    const registration = await navigator.serviceWorker?.getRegistration('/');
    const subscription = await registration?.pushManager.getSubscription();
    if (subscription) {
      const result = await request('/nearby/subscription-state', {endpoint: subscription.endpoint});
      connected(result.connected);
      if (result.connected) statusLine.textContent = 'Notifications enabled on this device.';
    }
  } catch (_) { /* No automatic permission prompt or background retry. */ }
})();
