"""publish -> @subscribe delivery through the events broker."""

import time
import uuid

from helpers import reports_of, result_of


def test_publish_reaches_subscriber(client):
    marker = f"evt-{uuid.uuid4().hex[:8]}"
    r = client.post("/walker/EmitEvent", json={"payload": marker})
    assert r.status_code == 200
    assert reports_of(r.json()) == [{"published": True}]

    deadline = time.time() + 5.0
    received = []
    while time.time() < deadline:
        r = client.post("/function/read_events", json={})
        received = result_of(r.json())["received"]
        if any(entry.get("msg") == marker for entry in received):
            return
        time.sleep(0.25)
    raise AssertionError(f"event {marker} never delivered; got: {received}")
