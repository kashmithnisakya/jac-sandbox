"""Shared helpers for the conformance suite.

The suite runs unchanged against any server that claims to serve this
project: `jac start` locally, the k8s deployment, or the converted
FastAPI output. Golden files pin the normalized wire envelopes.
"""

import hashlib
import hmac
import json
import os
import time
from pathlib import Path

GOLDEN_DIR = Path(__file__).parent / "goldens"

VOLATILE_KEYS = {
    "_jac_id",
    "token",
    "trace_id",
    "user_id",
    "root_id",
    "id",
    "doc_id",
    "key_id",
    "api_key",
    "api_key_id",
    "signing_secret",
    "details",
    "created_at",
    "expires_at",
}


def normalize(obj):
    """Replace run-varying values (ids, tokens, tracebacks) with markers."""
    if isinstance(obj, dict):
        return {
            k: "<VOLATILE>" if k in VOLATILE_KEYS else normalize(v)
            for k, v in obj.items()
        }
    if isinstance(obj, list):
        return [normalize(v) for v in obj]
    return obj


def check_golden(name: str, obj):
    """Compare `obj` against the recorded golden, or record it when
    RECORD_GOLDENS=1. Golden files are the parity contract."""
    normalized = normalize(obj)
    path = GOLDEN_DIR / f"{name}.json"
    if os.environ.get("RECORD_GOLDENS") == "1":
        GOLDEN_DIR.mkdir(exist_ok=True)
        path.write_text(json.dumps(normalized, indent=2, sort_keys=True) + "\n")
        return
    assert path.exists(), (
        f"No golden '{name}'. Record baselines first: make baseline"
    )
    expected = json.loads(path.read_text())
    assert normalized == expected, (
        f"Envelope drift for '{name}':\n"
        f"expected: {json.dumps(expected, indent=2, sort_keys=True)}\n"
        f"actual:   {json.dumps(normalized, indent=2, sort_keys=True)}"
    )


def sign_webhook(body: bytes, secret: str, ts: int | None = None) -> dict:
    """Build the X-Webhook-* headers the scale webhook pipeline verifies:
    HMAC-SHA256 hexdigest over b\"{timestamp}.\" + raw_body."""
    ts = ts if ts is not None else int(time.time())
    signed_payload = f"{ts}.".encode() + body
    sig = hmac.new(secret.encode(), signed_payload, hashlib.sha256).hexdigest()
    return {
        "X-Webhook-Signature": sig,
        "X-Webhook-Timestamp": str(ts),
    }


def parse_sse(text: str) -> list:
    """Parse an SSE body into a list of {'event': ..., 'data': ...} dicts."""
    frames = []
    event = None
    for line in text.splitlines():
        if line.startswith("event:"):
            event = line[len("event:"):].strip()
        elif line.startswith("data:"):
            payload = line[len("data:"):].strip()
            try:
                payload = json.loads(payload)
            except (ValueError, TypeError):
                pass
            frames.append({"event": event or "message", "data": payload})
            event = None
    return frames


def reports_of(envelope: dict) -> list:
    assert envelope.get("ok") is True, f"expected ok envelope, got: {envelope}"
    return envelope["data"]["reports"]


def result_of(envelope: dict):
    assert envelope.get("ok") is True, f"expected ok envelope, got: {envelope}"
    return envelope["data"]["result"]
