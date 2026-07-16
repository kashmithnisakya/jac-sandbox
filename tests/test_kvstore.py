"""scale kvstore over redis. Without a redis backend (local default) the
call must fail with a clean EXECUTION_ERROR envelope; with KVSTORE_MODE=ok
(k8s / redis available) the round trip must work."""

import os
import uuid

from helpers import reports_of

MODE = os.environ.get("KVSTORE_MODE", "error")


def test_kvstore_behavior(client):
    key = f"conf-{uuid.uuid4().hex[:8]}"
    r = client.post("/walker/KvPut", json={"key": key, "value": "v1"})

    if MODE == "ok":
        assert r.status_code == 200
        assert reports_of(r.json()) == [{"stored": key}]
        r = client.post("/walker/KvGet", json={"key": key})
        assert reports_of(r.json())[0]["value"] == {"value": "v1"}
    else:
        body = r.json()
        assert body["ok"] is False
        assert body["error"]["code"] == "EXECUTION_ERROR"
        assert "Redis URL not found" in body["error"]["message"]
