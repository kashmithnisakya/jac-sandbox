"""REST basics: pub vs auth gating, graph writes, node-addressed spawn,
function endpoints."""

from helpers import check_golden, reports_of, result_of


def test_pub_walker_open(client):
    r = client.post("/walker/PingPub", json={})
    assert r.status_code == 200
    assert reports_of(r.json()) == [{"pong": True, "auth_required": False}]
    check_golden("ping_pub", r.json())


def test_auth_walker_rejects_anonymous(client):
    r = client.post("/walker/PingAuth", json={})
    assert r.status_code == 401


def test_auth_walker_accepts_token(client, alice_headers):
    r = client.post("/walker/PingAuth", json={}, headers=alice_headers)
    assert r.status_code == 200
    assert reports_of(r.json()) == [{"pong": True, "auth_required": True}]


def test_add_and_list_items(client, alice_headers):
    r = client.post(
        "/walker/AddItem", json={"label": "conformance-item"}, headers=alice_headers
    )
    assert r.status_code == 200
    created = reports_of(r.json())[0]
    assert created["label"] == "conformance-item"
    assert created["_jac_type"] == "Item"

    r = client.post("/walker/ListItems", json={}, headers=alice_headers)
    labels = [item["label"] for item in reports_of(r.json())[0]]
    assert "conformance-item" in labels


def test_node_addressed_spawn(client, alice_headers):
    r = client.post(
        "/walker/AddItem", json={"label": "spawn-target"}, headers=alice_headers
    )
    node_id = reports_of(r.json())[0]["_jac_id"]

    r = client.post(f"/walker/VisitItem/{node_id}", json={}, headers=alice_headers)
    assert r.status_code == 200
    assert reports_of(r.json()) == [{"visited": "spawn-target"}]


def test_pub_function(client):
    r = client.post("/function/sandbox_health", json={})
    assert r.status_code == 200
    assert result_of(r.json()) == {"ok": True, "service": "jac-sandbox"}
    check_golden("fn_sandbox_health", r.json())


def test_auth_function_rejects_anonymous(client):
    r = client.post("/function/add_two", json={"a": 2, "b": 3})
    assert r.status_code == 401


def test_auth_function_accepts_token(client, alice_headers):
    r = client.post("/function/add_two", json={"a": 2, "b": 3}, headers=alice_headers)
    assert r.status_code == 200
    assert result_of(r.json()) == 5
