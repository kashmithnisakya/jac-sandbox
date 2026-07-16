"""Multipart UploadFile walkers, pub and auth."""

from helpers import reports_of


def test_public_upload(client):
    r = client.post(
        "/walker/UploadPublic",
        files={"attachment": ("hello.txt", b"hello-upload!", "text/plain")},
    )
    assert r.status_code == 200
    assert reports_of(r.json()) == [
        {"filename": "hello.txt", "size": 13, "public": True}
    ]


def test_auth_upload_rejects_anonymous(client):
    r = client.post(
        "/walker/UploadDoc",
        files={"document": ("doc.txt", b"body", "text/plain")},
    )
    assert r.status_code == 401


def test_auth_upload_accepts_token(client, alice_headers):
    r = client.post(
        "/walker/UploadDoc",
        files={"document": ("doc.txt", b"body", "text/plain")},
        data={"notes": "conformance"},
        headers=alice_headers,
    )
    assert r.status_code == 200
    report = reports_of(r.json())[0]
    assert report["filename"] == "doc.txt"
    assert report["notes"] == "conformance"
    assert report["authenticated"] is True
