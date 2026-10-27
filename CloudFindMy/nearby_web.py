"""Browser rules and independent polling, isolated from spoof-check leases."""
import asyncio
from contextlib import suppress
from datetime import datetime, timezone
import hashlib
import hmac
import json
from pathlib import Path

from aiohttp import web

from nearby import Nearby, PrivateState
from web_push import Push
from web_ui import nearby_page

RUNTIME = web.AppKey("nearby_runtime", object)


class NearbyRuntime:
    def __init__(self, config, apple, life, path=None):
        self.config, self.apple, self.life = config, apple, life
        self.engine = Nearby(PrivateState(config.admin_key, path))
        self.push = Push(self.engine.state, config.origin)
        self.lock = asyncio.Lock()
        self.stopped = False

    def targets(self):
        result = {}
        for owner in (self.apple, self.life):
            if owner.busy or owner.stage != "ready":
                continue
            connector = owner.connector
            if owner is self.apple:
                device = getattr(connector, "device_id", None)
                values = [(device, owner.target)] if device else []
            else:
                circle = getattr(connector, "circle_id", None)
                values = [(json.dumps([circle, identifier]), name) for identifier, name in connector.choices] if circle else []
            for identifier, name in values:
                token = hmac.new(self.config.admin_key.encode(), (owner.provider+identifier).encode(), hashlib.sha256).hexdigest()
                result[token] = {"provider": owner.provider, "id": identifier, "name": name}
        return result

    def known(self, rule):
        return any(t["provider"] == rule["provider"] and t["id"] == rule["target"] for t in self.targets().values())

    async def report(self, rule):
        owner = self.apple if rule["provider"] == "findmy-device" else self.life
        generation = owner.generation
        async with owner.lock:
            if self.stopped or owner.busy or not self.known(rule):
                return {"state": "unavailable"}
            try:
                if owner is self.apple:
                    report = (await owner.call("fetch")).json()
                else:
                    circle, member = json.loads(rule["target"])
                    report = (await owner.call("fetch_member", circle, member)).json()
            except Exception:
                return {"state": "unavailable"}
            if self.stopped or generation != owner.generation or not self.known(rule):
                return {"state": "unavailable"}
            return report

    async def send(self, body, identifier, endpoint=None):
        sent = False
        # Sequential, bounded delivery; state changes stay on the event loop.
        for entry in list(self.engine.state.data["subscriptions"]):
            if endpoint and entry["endpoint"] != endpoint:
                continue
            if self.stopped:
                break
            result = await asyncio.to_thread(self.push.send, entry, body, identifier)
            if result == "gone":
                self.push.remove(entry["endpoint"])
            sent = sent or result == "sent"
        return sent

    async def tick(self):
        if self.lock.locked():
            return
        async with self.lock:
            cache = {}
            for rule in list(self.engine.rules):
                if not self.engine.active(rule):
                    continue
                revision = rule.get("revision")
                key = (rule["provider"], rule["target"])
                if key not in cache:
                    cache[key] = await self.report(rule)
                # Rule can be paused/deleted while an HTTP request finishes.
                if self.engine.get(rule["id"]) is rule and rule.get("revision") == revision:
                    self.engine.observe(rule, cache[key])
            for rule in self.engine.due():
                if not self.known(rule) or self.engine.status(rule) == "Location unavailable":
                    continue
                event = rule["alert"]
                at = datetime.fromtimestamp(event["at"], timezone.utc).strftime("%H:%M UTC")
                body = f'{rule["targetName"]} {"entered" if rule["event"] == "enter" else "left"} {rule["name"]} at {at}. Open Nearby to stop reminders.'
                # Recheck acknowledgement before each device delivery. An already
                # accepted push cannot be recalled; payload TTL is just 60 seconds.
                sent = False
                for entry in list(self.engine.state.data["subscriptions"]):
                    if (self.stopped or self.engine.get(rule["id"]) is not rule
                            or not self.engine.active(rule) or event["acknowledged"]):
                        break
                    if not any(s["endpoint"] == entry["endpoint"] for s in self.engine.state.data["subscriptions"]):
                        continue
                    result = await asyncio.to_thread(self.push.send, entry, body, event["id"])
                    if result == "gone":
                        self.push.remove(entry["endpoint"])
                    sent = sent or result == "sent"
                if self.engine.get(rule["id"]) is rule and rule["alert"] is event:
                    self.engine.attempted(rule, sent)


def install(app, config, apple, life, admin, path=None):
    runtime = NearbyRuntime(config, apple, life, path)
    app[RUNTIME] = runtime
    engine = runtime.engine
    static = Path(__file__).parent / "static"
    last_test = 0

    async def index(request):
        try:
            state = admin(request)
        except web.HTTPUnauthorized:
            raise web.HTTPSeeOther("/")
        return web.Response(text=nearby_page(engine, runtime.targets(), state["csrf"], new=request.path.endswith("/new")), content_type="text/html")

    async def action(request):
        state = admin(request)
        data = await request.post()
        action = request.match_info["action"]
        try:
            if action == "create":
                target = runtime.targets().get(data.get("target"))
                if not target or data.get("consent") != "yes":
                    raise ValueError("Choose an available shared location and confirm permission.")
                distinct = {(r["provider"], r["target"]) for r in engine.rules}
                if (target["provider"], target["id"]) not in distinct and len(distinct) >= 5:
                    raise ValueError("Use up to five shared locations per helper.")
                engine.add(data, target)
            elif action == "pause-all":
                engine.pause_all()
            else:
                if action == "resume":
                    rule = engine.get(data.get("id"))
                    if not rule or not runtime.known(rule):
                        raise ValueError("Connect this location's service before resuming.")
                engine.change(data.get("id"), action)
        except (ValueError, TypeError):
            # Keep the form draft after validation, never echo provider exceptions.
            message = "Check the place details, selected service, and sharing permission. Use up to 20 rules and five locations."
            return web.Response(status=400, text=nearby_page(engine, runtime.targets(), state["csrf"], message, data, new=True), content_type="text/html")
        raise web.HTTPSeeOther("/nearby")

    async def push_config(request):
        admin(request)
        return web.json_response({"key": runtime.push.public_key()})

    async def push_action(request):
        nonlocal last_test
        admin(request)
        try:
            async with asyncio.timeout(5):
                data = await request.json()
            action = request.match_info["action"]
            if not isinstance(data, dict):
                raise ValueError()
            if action == "subscription-state":
                return web.json_response({"connected": any(s["endpoint"] == data.get("endpoint") for s in engine.state.data["subscriptions"])})
            elif action == "subscribe":
                runtime.push.subscribe(data)
            elif action == "unsubscribe":
                runtime.push.remove(data.get("endpoint"))
            elif action == "test-push":
                now = engine.clock()
                if now-last_test < 60:
                    raise web.HTTPTooManyRequests(text="Wait a minute before another test.")
                endpoint = data.get("endpoint")
                if not any(s["endpoint"] == endpoint for s in engine.state.data["subscriptions"]):
                    raise ValueError()
                last_test = now
                sent = await runtime.send("Notifications are connected. This is only a test.", "shift-test", endpoint)
                return web.json_response({"sent": sent})
            else:
                raise web.HTTPNotFound()
        except (ValueError, TypeError, TimeoutError):
            raise web.HTTPBadRequest(text="Enable notifications on this device again.")
        return web.json_response({"ok": True})

    async def asset(request):
        name = request.match_info["name"]
        if name == "manifest.webmanifest":
            return web.json_response({"id": "/", "name": "Elsepin Nearby", "short_name": "Elsepin",
                "start_url": "/nearby", "scope": "/", "display": "standalone",
                "background_color": "#f5f3f8", "theme_color": "#6336c5",
                "icons": [{"src": "/icon.svg", "sizes": "any", "type": "image/svg+xml"}]})
        if name == "icon.svg":
            return web.Response(text='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 192 192"><rect width="192" height="192" rx="42" fill="#6336c5"/><path d="M58 62h76L58 130h76" fill="none" stroke="white" stroke-width="16" stroke-linecap="round" stroke-linejoin="round"/></svg>', content_type="image/svg+xml")
        if name in ("nearby.js", "sw.js"):
            return web.Response(text=(static/name).read_text(encoding="utf-8"), content_type="application/javascript",
                                headers={"Service-Worker-Allowed": "/"})
        raise web.HTTPNotFound()

    async def lifespan(_):
        async def poll():
            while not runtime.stopped:
                try:
                    await runtime.tick()
                except Exception:
                    # Do not log coordinates, push tokens, or account responses.
                    engine.delivery = "Monitoring needs attention."
                await asyncio.sleep(60)
        task = asyncio.create_task(poll())
        yield
        runtime.stopped = True
        # Avoid canceling a thread-backed Apple call while it owns the account lock.
        if runtime.lock.locked():
            async with runtime.lock:
                pass
        task.cancel()
        with suppress(asyncio.CancelledError):
            await task

    app.cleanup_ctx.append(lifespan)
    app.router.add_get("/nearby", index)
    app.router.add_get("/nearby/new", index)
    app.router.add_get("/nearby/push-config", push_config)
    for name in ("subscribe", "unsubscribe", "test-push", "subscription-state"):
        app.router.add_post("/nearby/{action:"+name+"}", push_action)
    app.router.add_post("/nearby/{action}", action)
    app.router.add_get("/{name:nearby.js|sw.js|manifest.webmanifest|icon.svg}", asset)
    return runtime
