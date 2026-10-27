import asyncio
import json
from pathlib import Path
import sys
import tempfile
import time
import unittest
from unittest.mock import AsyncMock, Mock, patch

sys.path.insert(0, str(Path(__file__).parent))
from nearby import Nearby, PrivateState, distance
from nearby_web import RUNTIME
from web_push import Push, encode, subscription
from web_ui import nearby_page
import test_render
from render_server import Config, make_render_app


TARGET = {"provider": "findmy-device", "id": "device-one", "name": "Test phone"}
FIELDS = dict(name="Home", latitude="0", longitude="0", radius="500", event="enter", repeat="escalate", hours="1")


def push_subscription(endpoint="https://web.push.apple.com/Qtest"):
    from cryptography.hazmat.primitives.asymmetric import ec
    from cryptography.hazmat.primitives import serialization
    key = ec.generate_private_key(ec.SECP256R1()).public_key().public_bytes(serialization.Encoding.X962, serialization.PublicFormat.UncompressedPoint)
    return {"endpoint": endpoint, "keys": {"p256dh": encode(key), "auth": encode(b"a"*16)}}


class RuleTests(unittest.TestCase):
    def setUp(self):
        self.now = 1000
        self.state = PrivateState("test"*12)
        self.engine = Nearby(self.state, clock=lambda: self.now)
        self.rule = self.engine.add(FIELDS, TARGET)

    def report(self, lat, **changes):
        return dict(dict(provider="findmy-device", state="ok", latitude=lat, longitude=0,
                         accuracy=5, locatedAt=self.now, fetchedAt=self.now), **changes)

    def sample(self, lat, **changes):
        self.now += 10
        self.engine.observe(self.rule, self.report(lat, **changes))

    def trigger(self):
        self.sample(.01)
        self.sample(0)
        self.sample(0)

    def test_starting_inside_is_baseline_not_false_arrival(self):
        self.sample(0); self.sample(0); self.sample(0)
        self.assertIsNone(self.rule["alert"])

    def test_two_distinct_certain_reports_confirm_crossing(self):
        self.sample(.01); self.sample(0)
        self.assertIsNone(self.rule["alert"])
        self.engine.observe(self.rule, self.report(0))
        self.assertIsNone(self.rule["alert"])
        self.sample(0)
        self.assertEqual(self.engine.due(), [self.rule])

    def test_stale_revoked_invalid_future_reports_cannot_trigger(self):
        for change in (dict(state="old"), dict(state="unavailable"), dict(locatedAt=1),
                       dict(locatedAt=999999), dict(latitude=float("nan")), dict(accuracy=900),
                       dict(latitude=True), dict(provider="life360")):
            with self.subTest(change=change):
                self.engine.runtime.clear()
                self.sample(.01)
                self.sample(0, **change)
                self.sample(0)
                self.assertIsNone(self.rule["alert"])

    def test_old_out_of_order_report_is_ignored(self):
        self.sample(.01)
        at = self.now
        self.sample(0)
        self.engine.observe(self.rule, self.report(0, locatedAt=at))
        self.assertIsNone(self.rule["alert"])

    def test_uncertain_edge_resets_candidate_not_baseline(self):
        self.sample(.01); self.sample(0)
        self.sample(500/111195)
        self.sample(0)
        self.assertIsNone(self.rule["alert"])
        self.sample(0)
        self.assertIsNotNone(self.rule["alert"])

    def test_long_gap_requires_new_baseline(self):
        self.sample(.01)
        self.now += 200
        self.sample(0); self.sample(0)
        self.assertIsNone(self.rule["alert"])

    def test_leave_crossing(self):
        self.rule["event"] = "leave"
        self.sample(0); self.sample(.01); self.sample(.01)
        self.assertIsNotNone(self.rule["alert"])

    def test_ack_does_not_pause_rule_or_allow_duplicate_event(self):
        self.trigger()
        self.engine.change(self.rule["id"], "stop")
        self.assertEqual(self.engine.due(), [])
        self.assertTrue(self.engine.active(self.rule))
        self.sample(0); self.sample(0)
        self.assertTrue(self.rule["alert"]["acknowledged"])
        self.sample(.01); self.sample(.01); self.sample(0); self.sample(0)
        self.assertFalse(self.rule["alert"]["acknowledged"])

    def test_escalation_is_bounded_and_failures_back_off(self):
        self.trigger()
        for delay in (300, 120, 60, 60):
            self.engine.attempted(self.rule, True)
            self.assertEqual(self.rule["alert"]["next"]-self.now, delay)
            self.now += delay
        sent = self.rule["alert"]["sent"]
        self.engine.attempted(self.rule, False)
        self.assertEqual(self.rule["alert"]["next"]-self.now, 300)
        self.assertEqual(self.rule["alert"]["sent"], sent)

    def test_once_does_not_repeat_after_success(self):
        self.rule["repeat"] = "once"
        self.trigger(); self.engine.attempted(self.rule, True)
        self.now += 400
        self.assertEqual(self.engine.due(), [])

    def test_pause_all_and_expiry_stop_delivery(self):
        self.trigger(); self.engine.pause_all()
        self.assertEqual(self.engine.due(), [])
        self.engine.change(self.rule["id"], "resume")
        self.assertIsNone(self.rule["alert"])
        self.trigger(); self.now += 3601
        self.assertEqual(self.engine.due(), [])
        self.assertEqual(self.engine.status(self.rule), "Finished")

    def test_invalid_rule_values_never_persist(self):
        for change in (dict(latitude="nan"), dict(longitude=181), dict(radius=0),
                       dict(hours=25), dict(event="anything"), dict(repeat="0s"), dict(name="")):
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.engine.add(dict(FIELDS, **change), TARGET)
        self.assertEqual(len(self.engine.rules), 1)

    def test_globe_distance_and_antimeridian(self):
        self.assertAlmostEqual(distance(0, 0, 0, 0), 0)
        self.assertAlmostEqual(distance(0, 179.999, 0, -179.999), 222.39, delta=.1)

    def test_explicit_until_paused_does_not_expire(self):
        rule = self.engine.add(dict(FIELDS, hours="0"), TARGET)
        self.now += 90000
        self.assertTrue(self.engine.active(rule))
        self.engine.change(rule['id'], 'pause')
        self.assertFalse(self.engine.active(rule))

    def test_double_submission_does_not_duplicate_active_rule(self):
        same = self.engine.add(FIELDS, TARGET)
        self.assertIs(same, self.rule)
        self.assertEqual(len(self.engine.rules), 1)

    def test_encrypted_restart_preserves_ack_and_pauses_rule(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)/"private.enc"
            state = PrivateState("local-test-key", path)
            engine = Nearby(state, clock=lambda: 1000)
            rule = engine.add(FIELDS, TARGET)
            rule["alert"] = {"acknowledged": True, "id": "event", "at": 990, "sent": 1, "next": 1100}
            state.save()
            self.assertNotIn(b'Home', path.read_bytes())
            restored = Nearby(PrivateState("local-test-key", path))
            self.assertFalse(restored.rules[0]["enabled"])
            self.assertTrue(restored.rules[0]["alert"]["acknowledged"])
            with self.assertRaises(ValueError):
                PrivateState("wrong-key", path)

    def test_ui_escapes_names_and_keeps_unpublished_people_unavailable(self):
        self.rule["name"] = '<script>alert(1)</script>'
        source = nearby_page(self.engine, {}, "test-csrf")
        self.assertNotIn('<script>alert(1)</script>', source)
        self.assertIn('Find My People is not available yet', source)
        self.assertIn('Pause all alerts', source)


class PushTests(unittest.TestCase):
    def test_reject_untrusted_endpoints_and_bad_key_lengths(self):
        good = push_subscription()
        self.assertEqual(subscription(good), good)
        for endpoint in ('http://web.push.apple.com/Qtest', 'https://127.0.0.1/push/x',
                         'https://evil.test/push/x', 'https://web.push.apple.com.evil.test/Qx',
                         'https://web.push.apple.com:443/Qx', 'https://x@web.push.apple.com/Qx'):
            with self.subTest(endpoint=endpoint), self.assertRaises(ValueError):
                subscription(dict(good, endpoint=endpoint))
        with self.assertRaises(ValueError):
            subscription(dict(good, keys={"p256dh": "a"*65, "auth": "b"*16}))

    def test_vapid_key_is_stable_and_roundtrips_real_encryption_without_network(self):
        import requests
        state = PrivateState("a"*40)
        push = Push(state, "https://test.onrender.com")
        self.assertEqual(push.public_key(), push.public_key())
        response = requests.Response(); response.status_code = 201; response._content = b''
        with patch('requests.Session.request', return_value=response) as post:
            self.assertEqual(push.send(push_subscription(), "Test", "id"), "sent")
        self.assertEqual(post.call_args.kwargs['timeout'], 10)
        self.assertFalse(post.call_args.kwargs['allow_redirects'])
        self.assertNotIn(b'Test', post.call_args.kwargs['data'])

    def test_subscription_is_deduplicated_and_can_be_removed(self):
        push = Push(PrivateState("a"*40), "https://test.onrender.com")
        value = push_subscription()
        push.subscribe(value); push.subscribe(value)
        self.assertEqual(len(push.state.data['subscriptions']), 1)
        push.remove(value['endpoint'])
        self.assertEqual(push.state.data['subscriptions'], [])


class NearbyWebTests(unittest.IsolatedAsyncioTestCase):
    get = test_render.RenderWebTests.get
    post = test_render.RenderWebTests.post
    unlock = test_render.RenderWebTests.unlock
    action = test_render.RenderWebTests.action

    async def asyncSetUp(self):
        from aiohttp.test_utils import TestClient, TestServer
        self.config = Config('https://test.onrender.com', 'a'*48)
        self.fake = test_render.FakeApple()
        self.app = make_render_app(self.config, self.fake)
        self.runtime = self.app[RUNTIME]
        self.client = TestClient(TestServer(self.app))
        await self.client.start_server()
        self.headers = {'Host': 'test.onrender.com', 'Origin': self.config.origin}
        self.csrf = None

    async def asyncTearDown(self):
        await self.client.close()

    def ready(self):
        self.fake.device_id = 'device-one'
        self.fake.target = 'Test phone'
        self.runtime.apple.target = self.fake.target
        self.runtime.apple.stage = 'ready'
        return next(iter(self.runtime.targets()))

    async def json_post(self, path, data, headers=None):
        return await self.client.post(path, json=data,
            headers=headers or dict(self.headers, **{'X-Shift-CSRF': self.csrf or ''}), allow_redirects=False)

    async def test_no_provider_fetch_on_page_or_health_request(self):
        await self.unlock(); self.ready()
        await self.get('/nearby'); await self.get('/healthz')
        self.assertEqual(self.fake.fetches, 0)

    async def test_create_stop_pause_and_delete_are_explicit(self):
        await self.unlock(); token = self.ready()
        response = await self.action('/nearby/create', **FIELDS, target=token, consent='yes')
        self.assertEqual(response.status, 303)
        rule = self.runtime.engine.rules[0]
        rule['alert'] = {'id':'e', 'at':time.time(), 'acknowledged':False, 'sent':0, 'next':0}
        await self.get('/nearby')
        self.assertFalse(rule['alert']['acknowledged'])
        await self.action('/nearby/stop', id=rule['id'])
        self.assertTrue(rule['alert']['acknowledged'])
        self.assertTrue(rule['enabled'])
        await self.action('/nearby/pause-all')
        self.assertFalse(rule['enabled'])
        await self.action('/nearby/delete', id=rule['id'])
        self.assertEqual(self.runtime.engine.rules, [])

    async def test_unsupported_people_and_arbitrary_target_cannot_start(self):
        await self.unlock(); self.ready()
        response = await self.action('/nearby/create', **FIELDS, target='findmy-people', consent='yes')
        self.assertEqual(response.status, 400)
        self.assertEqual(self.runtime.engine.rules, [])

    async def test_auth_csrf_origin_required_for_push_and_rules(self):
        response = await self.json_post('/nearby/subscribe', push_subscription())
        self.assertEqual(response.status, 401)
        await self.unlock()
        for headers in (self.headers, dict(self.headers, **{'X-Shift-CSRF':'wrong'}),
                        dict(self.headers, Origin='https://evil.test', **{'X-Shift-CSRF':self.csrf})):
            response = await self.json_post('/nearby/subscribe', push_subscription(), headers)
            self.assertEqual(response.status, 403)

    async def test_push_config_subscribe_test_and_unsubscribe(self):
        await self.unlock()
        response = await self.get('/nearby/push-config')
        self.assertEqual(response.status, 200)
        value = push_subscription()
        self.assertEqual((await self.json_post('/nearby/subscribe', value)).status, 200)
        with patch.object(self.runtime.push, 'send', return_value='sent') as send:
            response = await self.json_post('/nearby/test-push', {'endpoint':value['endpoint']})
            self.assertTrue((await response.json())['sent'])
            send.assert_called_once()
            self.assertEqual((await self.json_post('/nearby/test-push', {'endpoint':value['endpoint']})).status, 429)
        await self.json_post('/nearby/unsubscribe', {'endpoint':value['endpoint']})
        self.assertEqual(self.runtime.engine.state.data['subscriptions'], [])

    async def test_rules_poll_independently_of_phone_lease_and_pause_stops(self):
        self.ready()
        rule = self.runtime.engine.add(FIELDS, TARGET)
        await self.runtime.tick()
        self.assertEqual(self.fake.fetches, 1)
        self.assertIsNone(self.runtime.apple.store.session)
        self.runtime.engine.pause_all()
        await self.runtime.tick()
        self.assertEqual(self.fake.fetches, 1)

    async def test_disconnecting_during_fetch_discards_late_report(self):
        self.ready(); rule = self.runtime.engine.add(FIELDS, TARGET)
        started, release = asyncio.Event(), asyncio.Event()
        async def fetch(*args):
            started.set(); await release.wait()
            return self.fake.fetch()
        with patch.object(self.runtime.apple, 'call', side_effect=fetch):
            task = asyncio.create_task(self.runtime.tick())
            await started.wait()
            self.runtime.apple.generation += 1
            release.set(); await task
        self.assertEqual(self.runtime.engine.status(rule), 'Location unavailable')

    async def test_pause_while_request_in_flight_cannot_create_event(self):
        self.ready(); rule = self.runtime.engine.add(FIELDS, TARGET)
        started, release = asyncio.Event(), asyncio.Event()
        async def report(*args):
            started.set(); await release.wait()
            return self.fake.fetch().json()
        with patch.object(self.runtime, 'report', side_effect=report):
            task = asyncio.create_task(self.runtime.tick()); await started.wait()
            self.runtime.engine.pause_all(); release.set(); await task
        self.assertIsNone(rule['alert'])
        self.assertEqual(self.runtime.engine.status(rule), 'Paused')

    async def test_rapid_pause_resume_rejects_previous_request(self):
        self.ready(); rule = self.runtime.engine.add(FIELDS, TARGET)
        started, release = asyncio.Event(), asyncio.Event()
        async def report(*args):
            started.set(); await release.wait()
            return self.fake.fetch().json()
        with patch.object(self.runtime, 'report', side_effect=report):
            task = asyncio.create_task(self.runtime.tick()); await started.wait()
            self.runtime.engine.change(rule['id'], 'pause')
            self.runtime.engine.change(rule['id'], 'resume')
            release.set(); await task
        self.assertEqual(self.runtime.engine.status(rule), 'Waiting for location')

    async def test_static_assets_do_not_cache_private_pages(self):
        for path in ('/nearby.js','/sw.js','/manifest.webmanifest','/icon.svg'):
            response = await self.get(path)
            self.assertEqual(response.status, 200)
            self.assertEqual(response.headers['Cache-Control'], 'no-store')
        response = await self.get('/sw.js')
        self.assertNotIn("addEventListener('fetch'", await response.text())

    async def test_editor_is_separate_and_failed_save_preserves_draft(self):
        await self.unlock(); token = self.ready()
        main = await (await self.get('/nearby')).text()
        self.assertNotIn('name="latitude"', main)
        source = await (await self.get('/nearby/new')).text()
        self.assertIn('name="latitude"', source)
        response = await self.action('/nearby/create', **dict(FIELDS, name='My draft', radius='bad'), target=token, consent='yes')
        self.assertEqual(response.status, 400)
        self.assertIn('value="My draft"', await response.text())
        self.assertEqual(self.runtime.engine.rules, [])

    async def test_source_unavailable_suspends_existing_reminders(self):
        self.ready(); rule = self.runtime.engine.add(FIELDS, TARGET)
        rule['alert'] = {'id':'e', 'at':time.time(), 'acknowledged':False, 'sent':0, 'next':0}
        self.runtime.push.subscribe(push_subscription())
        with patch.object(self.runtime, 'report', new=AsyncMock(return_value={'state':'unavailable'})), patch.object(self.runtime.push, 'send') as send:
            await self.runtime.tick()
            send.assert_not_called()

    async def test_acknowledgement_during_send_stops_remaining_devices(self):
        import threading
        self.ready(); rule = self.runtime.engine.add(FIELDS, TARGET)
        rule['alert'] = {'id':'e', 'at':time.time(), 'acknowledged':False, 'sent':0, 'next':0}
        self.runtime.push.subscribe(push_subscription())
        self.runtime.push.subscribe(push_subscription('https://web.push.apple.com/Qtwo'))
        started, release = threading.Event(), threading.Event()
        def send(*args):
            started.set(); release.wait(3); return 'sent'
        with patch.object(self.runtime.push, 'send', side_effect=send) as sender:
            task = asyncio.create_task(self.runtime.tick())
            try:
                self.assertTrue(await asyncio.to_thread(started.wait, 1))
                self.runtime.engine.change(rule['id'], 'stop')
            finally:
                release.set()
            await task
            self.assertEqual(sender.call_count, 1)
        self.assertEqual(self.runtime.engine.due(), [])


class NearbyLife360Tests(unittest.IsolatedAsyncioTestCase):
    async def test_other_authorized_member_does_not_replace_own_checker_profile(self):
        from web_life360 import WebLife360
        adapter = WebLife360()
        adapter.circle_id, adapter.member_id, adapter.target = 'circle', 'me', 'Own profile'
        adapter.choices = [('me','Own profile'), ('friend','Shared profile')]
        member = {'id':'friend', 'features':{'shareLocation':1}, 'location':{'latitude':0,'longitude':0,'timestamp':time.time(),'accuracy':10}}
        adapter.api = Mock(get_circle_member=AsyncMock(return_value=member))
        report = await adapter.fetch_member('circle','friend')
        self.assertEqual(report.state,'ok')
        self.assertEqual(report.target,'Shared profile')
        self.assertEqual(adapter.member_id,'me')
        self.assertEqual(adapter.target,'Own profile')
        member['features']['shareLocation'] = 0
        self.assertEqual((await adapter.fetch_member('circle','friend')).state,'unavailable')
        member['features']['shareLocation'] = 1
        member['id'] = 'someone-else'
        self.assertEqual((await adapter.fetch_member('circle','friend')).state,'unavailable')
        adapter.api.get_circle_member.reset_mock()
        self.assertEqual((await adapter.fetch_member('wrong-circle','friend')).state,'unavailable')
        self.assertEqual((await adapter.fetch_member('circle','unlisted')).state,'unavailable')
        adapter.api.get_circle_member.assert_not_called()


if __name__ == '__main__':
    unittest.main()
