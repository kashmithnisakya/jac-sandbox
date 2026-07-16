"""WebSocket walkers: echo, auth-required, broadcast."""

import asyncio
import json

import pytest
import websockets

from helpers import check_golden


async def _roundtrip(url: str, payload: dict, timeout: float = 10.0) -> dict:
    async with websockets.connect(url) as ws:
        await ws.send(json.dumps(payload))
        return json.loads(await asyncio.wait_for(ws.recv(), timeout))


def test_ws_echo(ws_url):
    frame = asyncio.run(
        _roundtrip(f"{ws_url}/ws/WsEcho", {"message": "hi-ws", "client_id": "conf"})
    )
    assert frame["ok"] is True
    assert frame["data"]["reports"] == [
        {"echo": "hi-ws", "client_id": "conf", "protocol": "websocket"}
    ]
    check_golden("ws_echo_frame", frame)


def test_ws_private_requires_token(ws_url):
    async def attempt():
        async with websockets.connect(f"{ws_url}/ws/WsPrivate") as ws:
            await ws.send(json.dumps({"message": "sneak"}))
            return json.loads(await asyncio.wait_for(ws.recv(), 10.0))

    try:
        frame = asyncio.run(attempt())
    except (websockets.exceptions.WebSocketException, OSError):
        return
    assert frame.get("ok") is not True, f"unauthenticated WS succeeded: {frame}"


def test_ws_private_with_token(ws_url, alice_token):
    frame = asyncio.run(
        _roundtrip(
            f"{ws_url}/ws/WsPrivate?token={alice_token}", {"message": "authed"}
        )
    )
    assert frame["ok"] is True
    assert frame["data"]["reports"] == [{"message": "authed", "authenticated": True}]


def test_ws_broadcast_reaches_all_clients(ws_url):
    async def scenario():
        url = f"{ws_url}/ws/WsBroadcast"
        async with websockets.connect(url) as a, websockets.connect(url) as b:
            await a.send(json.dumps({"message": "to-everyone", "sender": "a"}))
            frame_a = json.loads(await asyncio.wait_for(a.recv(), 10.0))
            frame_b = json.loads(await asyncio.wait_for(b.recv(), 10.0))
            return frame_a, frame_b

    frame_a, frame_b = asyncio.run(scenario())
    for frame in (frame_a, frame_b):
        assert frame["ok"] is True
        assert frame["data"]["reports"][0]["content"] == "to-everyone"
