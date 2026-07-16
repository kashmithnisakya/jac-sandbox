"""grant(ReadPerm) + cross-user read by node id."""

from helpers import reports_of


def test_cross_user_shared_read(client, alice_headers, bob_headers):
    r = client.post(
        "/walker/ShareNote", json={"text": "shared-secret"}, headers=alice_headers
    )
    assert r.status_code == 200
    doc_id = reports_of(r.json())[0]["id"]
    assert doc_id

    r = client.post(
        "/walker/ReadShared", json={"doc_id": doc_id}, headers=bob_headers
    )
    assert r.status_code == 200
    assert reports_of(r.json()) == [{"content": "shared-secret"}]
