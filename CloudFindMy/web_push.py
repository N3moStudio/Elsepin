"""Opt-in Web Push with bounded requests and a strict push-service allowlist."""
import base64
import json
import re
from urllib.parse import urlsplit

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec


def encode(raw):
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def decode(value):
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9_-]{16,200}", value):
        raise ValueError("Invalid push subscription.")
    return base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))


def subscription(value):
    try:
        endpoint = value["endpoint"]
        if not isinstance(endpoint, str) or len(endpoint) > 2048:
            raise ValueError()
        url = urlsplit(endpoint)
        # Browser-owned delivery services only. No user-supplied webhooks, ports,
        # userinfo, IPs, redirects, or private network destinations.
        if (url.scheme != "https" or url.username or url.password or url.port or url.fragment
                or url.hostname not in ("web.push.apple.com", "fcm.googleapis.com", "updates.push.services.mozilla.com")
                or not url.path.startswith(("/Q", "/fcm/send/", "/wp/", "/wpush/", "/push/"))):
            raise ValueError()
        key = decode(value["keys"]["p256dh"])
        auth = decode(value["keys"]["auth"])
        if len(key) != 65 or len(auth) != 16:
            raise ValueError()
        ec.EllipticCurvePublicKey.from_encoded_point(ec.SECP256R1(), key)
        return {"endpoint": endpoint, "keys": {"p256dh": encode(key), "auth": encode(auth)}}
    except (ValueError, KeyError, TypeError, AttributeError):
        raise ValueError("This browser's push subscription is not supported.") from None


class Push:
    def __init__(self, state, origin):
        self.state, self.origin = state, origin

    def key(self):
        if not self.state.data["vapid"]:
            key = ec.generate_private_key(ec.SECP256R1())
            self.state.data["vapid"] = encode(key.private_bytes(serialization.Encoding.DER,
                serialization.PrivateFormat.PKCS8, serialization.NoEncryption()))
            self.state.save()
        raw = self.state.data["vapid"]
        return serialization.load_der_private_key(base64.urlsafe_b64decode(raw+"="*(-len(raw)%4)), None)

    def public_key(self):
        return encode(self.key().public_key().public_bytes(serialization.Encoding.X962, serialization.PublicFormat.UncompressedPoint))

    def subscribe(self, value):
        value = subscription(value)
        entries = self.state.data["subscriptions"]
        if any(s["endpoint"] == value["endpoint"] for s in entries):
            entries[:] = [s for s in entries if s["endpoint"] != value["endpoint"]]
        elif len(entries) >= 5:
            raise ValueError("Up to five devices can receive alerts. Turn one off first.")
        entries.append(value)
        self.state.save()

    def remove(self, endpoint):
        entries = self.state.data["subscriptions"]
        entries[:] = [s for s in entries if s["endpoint"] != endpoint]
        self.state.save()

    def send(self, entry, body, identifier):
        """Run off the event loop. Never log endpoints, payloads or exceptions."""
        from pywebpush import webpush, WebPushException
        from py_vapid import Vapid
        from requests import Session

        class NoRedirectSession(Session):
            def request(self, method, url, **kwargs):
                kwargs["allow_redirects"] = False
                return super().request(method, url, **kwargs)

        try:
            entry = subscription(entry)
            with NoRedirectSession() as session:
                session.trust_env = False
                response = webpush(entry, json.dumps({"body": body, "id": identifier}),
                    vapid_private_key=Vapid.from_string(self.state.data["vapid"]),
                    vapid_claims={"sub": self.origin}, ttl=60, timeout=10,
                    headers={"Urgency": "normal"}, requests_session=session)
                return "sent" if 200 <= response.status_code < 300 else "failed"
        except WebPushException as error:
            code = error.response.status_code if error.response is not None else None
            return "gone" if code in (404, 410) else "failed"
        except Exception:
            return "failed"
