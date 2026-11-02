"""Account-free checks for shared Nearby/session reads and provider recovery."""
import asyncio
import time
import unittest
import uuid

from render_server import Config, Owner
from core import Store
from nearby_web import NearbyRuntime
from reports import Report


class Connector:
    def __init__(self, provider):
        self.provider = provider
        self.device_id = "device"
        self.circle_id, self.member_id = "circle", "me"
        self.target = "Own phone"
        self.choices = [("me", self.target), ("friend", "Shared phone")]
        self.calls, self.closes = [], 0
        self.error = None
        self.started = self.release = None
        self.at = time.time()

    async def fetch(self):
        return await self.fetch_member(self.circle_id, self.member_id)

    async def fetch_member(self, circle, member):
        self.calls.append((circle, member))
        if self.started:
            self.started.set()
            await self.release.wait()
        if self.error:
            raise self.error
        return Report(self.provider, dict(self.choices)[member], "ok", 37, -122,
                      self.at, 5, self.at)

    async def close(self):
        self.closes += 1


class SharedPollingTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.now = [0]
        self.apple = Connector("findmy-device")
        self.life = Connector("life360")
        self.owners = [Owner(connector, Store(), connector.provider, clock=lambda: self.now[0])
                       for connector in (self.apple, self.life)]
        for owner in self.owners:
            owner.stage, owner.store.auth_state = "ready", None
            owner.target = owner.connector.target
        self.runtime = NearbyRuntime(Config("https://example.onrender.com", "x"*40), *self.owners)

    def rule(self, provider="findmy-device", name="Own phone"):
        target = next(t for t in self.runtime.targets().values()
                      if t["provider"] == provider and t["name"] == name)
        return self.runtime.engine.add(dict(name="Test place", latitude=37, longitude=-122,
            radius=500, event="enter", repeat="once", hours=1), target)

    def lease(self, owner):
        now, sid = time.time(), str(uuid.uuid4())
        owner.store.update(dict(version=1, sessionID=sid, startedAt=now-1,
            sequence=1, sentAt=now, active=True, samples=[]))
        return sid

    async def test_session_then_nearby_share_cooldown_without_redating_report(self):
        owner = self.owners[0]
        rule = self.rule()
        await owner.fetch(self.lease(owner))
        await self.runtime.tick()
        self.assertEqual(len(self.apple.calls), 1)
        self.now[0] = 59
        report = await self.runtime.report(rule)
        self.assertEqual((report["locatedAt"], report["fetchedAt"]), (self.apple.at, self.apple.at))
        self.assertEqual(len(self.apple.calls), 1)
        self.now[0] = 60
        await self.runtime.tick()
        self.assertEqual(len(self.apple.calls), 2)

    async def test_nearby_then_session_uses_same_report_and_needs_no_phone_lease(self):
        owner = self.owners[0]
        self.rule()
        await self.runtime.tick()
        self.assertIsNone(owner.store.session)
        await owner.fetch(self.lease(owner))
        self.assertEqual(len(self.apple.calls), 1)
        self.assertEqual(owner.store.report["locatedAt"], self.apple.at)

    async def test_overlapping_consumers_wait_for_one_provider_request(self):
        owner = self.owners[0]
        self.rule()
        self.apple.started, self.apple.release = asyncio.Event(), asyncio.Event()
        first = asyncio.create_task(owner.fetch(self.lease(owner)))
        await self.apple.started.wait()
        second = asyncio.create_task(self.runtime.tick())
        await asyncio.sleep(0)
        self.apple.release.set()
        await asyncio.gather(first, second)
        self.assertEqual(len(self.apple.calls), 1)

    async def test_life360_shares_own_report_but_keeps_other_member_separate(self):
        owner = self.owners[1]
        self.rule("life360")
        self.rule("life360", "Shared phone")
        await self.runtime.tick()
        await owner.fetch(self.lease(owner))
        self.assertEqual(self.life.calls, [("circle", "me"), ("circle", "friend")])
        self.assertEqual(owner.store.report["target"], "Own phone")
        self.assertEqual((self.life.circle_id, self.life.member_id), ("circle", "me"))
        self.assertEqual(self.apple.calls, [])

    async def test_nearby_auth_errors_stop_only_failed_provider_and_update_readiness(self):
        class ProviderError(Exception):
            def __init__(self, status):
                self.status = status
        for status, expected in ((401, "sign-in"), (403, "blocked"), (429, "blocked")):
            with self.subTest(status=status):
                self.setUp()
                owner = self.owners[0]
                self.rule()
                self.apple.error = ProviderError(status)
                await self.runtime.tick()
                self.assertEqual(owner.stage, "sign-in")
                self.assertEqual(owner.store.auth_state, expected)
                self.assertEqual(owner.reports, {})
                self.assertEqual(self.apple.closes, 1)
                self.assertEqual(self.owners[1].stage, "ready")
                self.assertNotIn("findmy-device", {t["provider"] for t in self.runtime.targets().values()})
                self.now[0] = 120
                await self.runtime.tick()
                self.assertEqual(len(self.apple.calls), 1)

    async def test_transient_timeout_keeps_login_and_recovers_after_cooldown(self):
        owner = self.owners[0]
        rule = self.rule()
        self.apple.error = TimeoutError()
        await self.runtime.tick()
        self.assertEqual(self.runtime.engine.status(rule), "Location unavailable")
        self.assertEqual(owner.stage, "ready")
        self.assertIsNone(owner.store.auth_state)
        self.assertEqual(self.apple.closes, 0)
        self.apple.error = None
        self.now[0] = 59
        await owner.fetch(self.lease(owner))
        self.assertEqual(len(self.apple.calls), 1)
        self.assertEqual(owner.store.report["state"], "unavailable")
        self.now[0] = 60
        await self.runtime.tick()
        await owner.fetch(owner.store.session.id)
        self.assertEqual(len(self.apple.calls), 2)
        self.assertEqual(owner.store.report["state"], "ok")
        self.assertEqual(self.runtime.engine.status(rule), "Inside")

    async def test_disconnecting_discards_a_cached_report_immediately(self):
        owner = self.owners[0]
        await owner.read_report()
        self.assertTrue(owner.reports)
        owner.start("close")
        self.assertEqual(owner.reports, {})
        await owner.job
        self.assertIsNone(await owner.read_report())

    async def test_idle_report_cache_expires_without_another_location_read(self):
        owner = self.owners[0]
        await owner.read_report()
        self.now[0] = 60
        owner.expire_reports()
        self.assertEqual(owner.reports, {})
        self.assertEqual(len(self.apple.calls), 1)


if __name__ == "__main__":
    unittest.main()
