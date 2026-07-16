"""Static @schedule interval job: beats must accumulate while the server
runs. This is the test the converted server fails until the scheduler is
wired into its lifespan (Phase 3 workstream)."""

import time

from helpers import reports_of


def _beats(client) -> int:
    r = client.post("/walker/ReadHeartbeat", json={})
    assert r.status_code == 200
    return reports_of(r.json())[0]["beats"]


def test_interval_job_fires(client):
    first = _beats(client)
    time.sleep(2.5)
    second = _beats(client)
    assert second > first, (
        f"scheduler is not running: beats stayed at {first}. "
        "On a converted server this means the @schedule job was dropped."
    )
