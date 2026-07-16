"""Generator-reporting walker streams as SSE."""

from helpers import check_golden, parse_sse


def test_sse_stream_frames(client):
    r = client.post("/walker/SseTicker", json={"count": 3})
    assert r.status_code == 200
    assert "text/event-stream" in r.headers.get("content-type", "")
    frames = parse_sse(r.text)
    ticks = [f["data"] for f in frames if f["event"] == "message"]
    assert ticks == ["tick-0", "tick-1", "tick-2"]
    assert frames[-1]["event"] == "end"
    check_golden("sse_frames", frames)
