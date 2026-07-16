"""Webhook pipeline: API key + HMAC signature + replay window. The exact
security properties the converted server must reproduce."""

import json
import time

import pytest

from helpers import reports_of, sign_webhook


@pytest.fixture(scope="module")
def api_key(client, alice_headers):
    r = client.post(
        "/api-key/create",
        json={"name": "conformance", "expiry_days": 30},
        headers=alice_headers,
    )
    assert r.status_code in (200, 201), f"api-key create failed: {r.text}"
    data = r.json()["data"]
    return {"key": data["api_key"], "secret": data["signing_secret"]}


def test_webhook_rejects_missing_api_key(client):
    r = client.post("/webhook/HookPing", json={})
    assert r.status_code in (401, 422)
    assert r.json().get("ok") is not True


def test_webhook_rejects_bad_signature(client, api_key):
    body = json.dumps({}).encode()
    headers = sign_webhook(body, "wrong-secret")
    headers["X-API-Key"] = api_key["key"]
    r = client.post("/webhook/HookPing", content=body, headers={
        **headers, "content-type": "application/json",
    })
    assert r.status_code == 401


def test_webhook_rejects_stale_timestamp(client, api_key):
    body = json.dumps({}).encode()
    headers = sign_webhook(body, api_key["secret"], ts=int(time.time()) - 3600)
    headers["X-API-Key"] = api_key["key"]
    r = client.post("/webhook/HookPing", content=body, headers={
        **headers, "content-type": "application/json",
    })
    assert r.status_code == 401


def test_webhook_accepts_signed_request(client, api_key):
    body = json.dumps({}).encode()
    headers = sign_webhook(body, api_key["secret"])
    headers["X-API-Key"] = api_key["key"]
    r = client.post("/webhook/HookPing", content=body, headers={
        **headers, "content-type": "application/json",
    })
    assert r.status_code == 200
    assert reports_of(r.json()) == [
        {"status": "received", "transport": "webhook"}
    ]


def test_webhook_with_fields(client, api_key):
    body = json.dumps(
        {"order_id": "ord-1", "amount": 12.5, "currency": "EUR"}
    ).encode()
    headers = sign_webhook(body, api_key["secret"])
    headers["X-API-Key"] = api_key["key"]
    r = client.post("/webhook/HookOrderPaid", content=body, headers={
        **headers, "content-type": "application/json",
    })
    assert r.status_code == 200
    assert reports_of(r.json()) == [{
        "status": "received", "order_id": "ord-1",
        "amount": 12.5, "currency": "EUR",
    }]


def test_webhook_walker_not_on_walker_path(client, alice_headers):
    r = client.post("/walker/HookPing", json={}, headers=alice_headers)
    assert r.status_code in (404, 405)
