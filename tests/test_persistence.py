"""Graph persistence across requests and per-user root isolation."""

from helpers import reports_of


def test_notes_persist_across_requests(client, alice_headers):
    r = client.post("/walker/CountNotes", json={}, headers=alice_headers)
    before = reports_of(r.json())[0]["count"]

    client.post("/walker/AddNote", json={"text": "note-1"}, headers=alice_headers)
    client.post("/walker/AddNote", json={"text": "note-2"}, headers=alice_headers)

    r = client.post("/walker/CountNotes", json={}, headers=alice_headers)
    assert reports_of(r.json())[0]["count"] == before + 2


def test_per_user_root_isolation(client, alice_headers, bob_headers):
    client.post("/walker/AddNote", json={"text": "alice-only"}, headers=alice_headers)

    r = client.post("/walker/CountNotes", json={}, headers=bob_headers)
    assert reports_of(r.json())[0]["count"] == 0
