"""@restspec custom method/path routes."""

from helpers import check_golden, reports_of


def test_restspec_get_route(client):
    r = client.get("/api/v1/status")
    assert r.status_code == 200
    assert reports_of(r.json()) == [{"status": "up", "via": "restspec-get"}]
    check_golden("restspec_status", r.json())


def test_restspec_post_route(client):
    r = client.post("/api/v1/echo", json={"payload": "hi-restspec"})
    assert r.status_code == 200
    assert reports_of(r.json()) == [{"echo": "hi-restspec", "via": "restspec-post"}]


def test_restspec_walker_not_on_default_path(client):
    r = client.post("/walker/ApiStatus", json={})
    assert r.status_code in (404, 405)
