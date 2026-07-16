"""The SPA client page is served at / with the client bundle wired in."""


def test_client_page_served(client):
    r = client.get("/")
    assert r.status_code == 200
    assert "text/html" in r.headers.get("content-type", "")
    assert "<script" in r.text


def test_guestbook_walkers_exposed(client):
    r = client.post("/walker/ListMessages", json={})
    assert r.status_code == 200
    body = r.json()
    assert body["ok"] is True
    assert isinstance(body["data"]["reports"], list)
