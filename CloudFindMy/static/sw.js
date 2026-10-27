'use strict';
self.addEventListener('push', event => {
  let message = {};
  try { message = event.data?.json() || {}; } catch (_) { /* Safe generic notification. */ }
  event.waitUntil(self.registration.showNotification('Elsepin · Nearby', {
    body: String(message.body || 'Open your helper to review an alert.').slice(0, 240),
    tag: String(message.id || 'shift-nearby').slice(0, 80),
    renotify: true,
    data: {url: '/nearby'}
  }));
});
self.addEventListener('notificationclick', event => {
  event.notification.close();
  // Opening or dismissing never acknowledges an event; Stop this alert is explicit.
  event.waitUntil(clients.openWindow('/nearby'));
});
// Deliberately no fetch handler: authenticated pages and locations are never cached offline.
