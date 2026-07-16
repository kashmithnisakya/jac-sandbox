"""Fixtures: base URL parameterization and per-run users.

BASE_URL selects the server under test (default http://localhost:8000).
Users are unique per run so persisted state from earlier runs never
bleeds into assertions.
"""

import os
import uuid

import httpx
import pytest

BASE_URL = os.environ.get("BASE_URL", "http://localhost:8000").rstrip("/")
RUN_ID = uuid.uuid4().hex[:8]


@pytest.fixture(scope="session")
def base_url() -> str:
    return BASE_URL


@pytest.fixture(scope="session")
def ws_url() -> str:
    scheme = "wss" if BASE_URL.startswith("https") else "ws"
    return scheme + BASE_URL[BASE_URL.index("://"):]


@pytest.fixture(scope="session")
def client(base_url):
    with httpx.Client(base_url=base_url, timeout=30.0) as c:
        yield c


def _register_and_login(client: httpx.Client, username: str) -> str:
    password = "conformance-pw-1"
    r = client.post(
        "/user/register",
        json={
            "identities": [{"type": "username", "value": username}],
            "credential": {"type": "password", "password": password},
        },
    )
    assert r.status_code in (200, 201), f"register failed: {r.text}"
    r = client.post(
        "/user/login",
        json={
            "identity": {"type": "username", "value": username},
            "credential": {"type": "password", "password": password},
        },
    )
    assert r.status_code == 200, f"login failed: {r.text}"
    return r.json()["data"]["token"]


@pytest.fixture(scope="session")
def alice_token(client) -> str:
    return _register_and_login(client, f"alice_{RUN_ID}")


@pytest.fixture(scope="session")
def bob_token(client) -> str:
    return _register_and_login(client, f"bob_{RUN_ID}")


@pytest.fixture(scope="session")
def alice_headers(alice_token) -> dict:
    return {"authorization": f"Bearer {alice_token}"}


@pytest.fixture(scope="session")
def bob_headers(bob_token) -> dict:
    return {"authorization": f"Bearer {bob_token}"}
