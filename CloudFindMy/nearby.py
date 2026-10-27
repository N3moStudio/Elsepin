"""Private, opt-in place alerts. No provider credentials or automatic spoofing."""
from __future__ import annotations

import hashlib
import json
import math
import os
from pathlib import Path
import time
import uuid

from cryptography.hazmat.primitives.ciphers.aead import AESGCM


def number(value, low, high):
    if isinstance(value, bool):
        raise ValueError("Enter a valid number.")
    value = float(value)
    if not math.isfinite(value) or not low <= value <= high:
        raise ValueError("Number is outside the allowed range.")
    return value


def distance(lat, lon, other_lat, other_lon):
    r = math.pi / 180
    a = math.sin((other_lat-lat)*r/2)**2
    a += math.cos(lat*r)*math.cos(other_lat*r)*math.sin((other_lon-lon)*r/2)**2
    return 6371000 * 2 * math.asin(math.sqrt(min(1, max(0, a))))


class PrivateState:
    """Atomic authenticated storage; an unavailable/corrupt store fails closed.

    Render Free may erase the filesystem. No disk means no restart durability.
    Tests inject path=None. Accounts/passwords never enter this store.
    """
    def __init__(self, key, path=None):
        self.path = Path(path) if path else None
        self.cipher = AESGCM(hashlib.sha256(b"shift-nearby-storage-v1\0" + key.encode()).digest())
        self.data = {"version": 1, "rules": [], "subscriptions": [], "vapid": None}
        if self.path and self.path.exists():
            try:
                raw = self.path.read_bytes()
                if len(raw) > 512_000:
                    raise ValueError()
                self.data = json.loads(self.cipher.decrypt(raw[:12], raw[12:], b"shift-nearby-v1"))
                if self.data["version"] != 1 or len(self.data["rules"]) > 20 or len(self.data["subscriptions"]) > 5:
                    raise ValueError()
            except Exception:
                raise ValueError("Nearby storage could not be opened. Restore its key or private backup.") from None

    def save(self):
        if not self.path:
            return
        self.path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        nonce = os.urandom(12)
        raw = nonce + self.cipher.encrypt(nonce, json.dumps(self.data, allow_nan=False).encode(), b"shift-nearby-v1")
        temporary = self.path.with_suffix(".tmp")
        try:
            with open(temporary, "wb") as stream:
                os.chmod(temporary, 0o600)
                stream.write(raw)
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(temporary, self.path)
        finally:
            temporary.unlink(missing_ok=True)


class Nearby:
    def __init__(self, state, clock=time.time):
        self.state, self.clock = state, clock
        self.runtime = {}
        self.delivery = "Enable notifications on this device."
        # A restart never silently resumes polling or repeats a previous event.
        for rule in self.rules:
            rule["enabled"] = False
        self.state.save()

    @property
    def rules(self):
        return self.state.data["rules"]

    def get(self, identifier):
        return next((r for r in self.rules if r["id"] == identifier), None)

    def add(self, fields, target):
        if len(self.rules) >= 20:
            raise ValueError("Keep up to 20 alert rules.")
        name = str(fields.get("name", "")).strip()
        if not 1 <= len(name) <= 60:
            raise ValueError("Give this place a short name.")
        mode, repeat = fields.get("event"), fields.get("repeat")
        if mode not in ("enter", "leave") or repeat not in ("once", "5m", "2m", "1m", "escalate"):
            raise ValueError("Choose an alert and reminder option.")
        hours = number(fields.get("hours", 1), 0, 24)
        rule = dict(id=str(uuid.uuid4()), revision=str(uuid.uuid4()), name=name, provider=target["provider"],
                    target=target["id"], targetName=target["name"],
                    latitude=number(fields.get("latitude"), -90, 90),
                    longitude=number(fields.get("longitude"), -180, 180),
                    radius=number(fields.get("radius"), 100, 50000),
                    event=mode, repeat=repeat, hours=hours, enabled=True,
                    until=self.clock()+hours*3600 if hours else None, alert=None)
        fields = ("name", "provider", "target", "latitude", "longitude", "radius", "event", "repeat", "hours")
        for existing in self.rules:
            if self.active(existing) and all(existing[k] == rule[k] for k in fields):
                return existing  # Repeated submissions must not double the alerts.
        self.rules.append(rule)
        self.state.save()
        return rule

    def change(self, identifier, action):
        rule = self.get(identifier)
        if not rule:
            raise ValueError("This rule no longer exists.")
        if action == "stop":
            if rule["alert"]:
                rule["alert"]["acknowledged"] = True
        elif action == "pause":
            rule["revision"] = str(uuid.uuid4())
            rule["enabled"] = False
            if rule["alert"]:
                rule["alert"]["acknowledged"] = True
            self.runtime.pop(identifier, None)
        elif action == "resume":
            rule["revision"] = str(uuid.uuid4())
            rule["enabled"] = True
            rule["until"] = self.clock() + rule["hours"]*3600 if rule["hours"] else None
            rule["alert"] = None
            self.runtime.pop(identifier, None)
        elif action == "delete":
            self.rules.remove(rule)
            self.runtime.pop(identifier, None)
        else:
            raise ValueError("Choose a valid action.")
        self.state.save()

    def pause_all(self):
        for rule in list(self.rules):
            self.change(rule["id"], "pause")

    def active(self, rule):
        return rule["enabled"] and (rule["until"] is None or self.clock() < rule["until"])

    def observe(self, rule, report):
        """Two distinct certain samples confirm a crossing, after a baseline.

        Duplicate, stale, future, inaccurate and out-of-order reports cannot
        trigger an arrival. Uncertainty at the edge never changes the baseline.
        """
        if not self.active(rule):
            self.runtime.pop(rule["id"], None)
            return
        runtime = self.runtime.setdefault(rule["id"], {})
        try:
            if report.get("state") != "ok" or report.get("provider") != rule["provider"]:
                raise ValueError()
            at = number(report["locatedAt"], self.clock()-90, self.clock())
            accuracy = number(report["accuracy"], 0, min(500, rule["radius"]/2))
            lat, lon = number(report["latitude"], -90, 90), number(report["longitude"], -180, 180)
        except (ValueError, KeyError, TypeError):
            self.runtime[rule["id"]] = {"status": "Location unavailable"}
            return
        if at <= runtime.get("at", 0):
            return
        gap = runtime.get("at") is not None and at - runtime["at"] > 90
        if gap:
            runtime.clear()
        runtime["at"] = at
        metres = distance(rule["latitude"], rule["longitude"], lat, lon)
        margin = accuracy + 10
        side = "inside" if metres < rule["radius"]-margin else "outside" if metres > rule["radius"]+margin else None
        runtime["status"] = "Inside" if side == "inside" else "Outside" if side else "Near boundary"
        if side is None:
            runtime["candidate"] = None
            runtime["count"] = 0
            return
        if not runtime.get("stable"):
            runtime["stable"] = side
            return
        if side == runtime["stable"]:
            runtime["candidate"], runtime["count"] = None, 0
            return
        runtime["count"] = runtime.get("count", 0)+1 if runtime.get("candidate") == side else 1
        runtime["candidate"] = side
        if runtime["count"] < 2:
            return
        runtime["stable"], runtime["count"] = side, 0
        wanted = "inside" if rule["event"] == "enter" else "outside"
        previous = rule["alert"]
        if side == wanted and (not previous or previous["acknowledged"]):
            rule["alert"] = dict(id=str(uuid.uuid4()), at=at, acknowledged=False, sent=0, next=self.clock())
            self.state.save()

    def due(self):
        return [r for r in self.rules if self.active(r) and r["alert"]
                and not r["alert"]["acknowledged"] and self.clock() >= r["alert"]["next"]
                and (r["repeat"] != "once" or r["alert"]["sent"] == 0)]

    def attempted(self, rule, delivered):
        event = rule["alert"]
        if delivered:
            event["sent"] += 1
        interval = {"once": 300, "5m": 300, "2m": 120, "1m": 60}.get(rule["repeat"])
        if interval is None:
            interval = (300, 120, 60)[min(max(event["sent"]-1, 0), 2)]
        # Failures never produce a tight retry loop or escalate urgency.
        event["next"] = self.clock() + (interval if delivered else max(300, interval))
        self.state.save()

    def status(self, rule):
        if not rule["enabled"]:
            return "Paused"
        if rule["until"] is not None and self.clock() >= rule["until"]:
            return "Finished"
        return self.runtime.get(rule["id"], {}).get("status", "Waiting for location")
