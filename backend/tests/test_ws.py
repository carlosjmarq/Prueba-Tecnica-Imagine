import time

import pytest
from fastapi.testclient import TestClient
from starlette.websockets import WebSocketDisconnect


def test_ws_rejects_no_token(client: TestClient) -> None:
    with pytest.raises(WebSocketDisconnect):
        with client.websocket_connect("/ws/orders"):
            pass


def test_ws_connect_and_ping(client: TestClient, auth_headers: dict) -> None:
    token = auth_headers["customer"]["Authorization"].replace("Bearer ", "")
    with client.websocket_connect(f"/ws/orders?token={token}") as ws:
        connected = ws.receive_json()
        assert connected["type"] == "connected"
        assert "user:" in connected["rooms"][0]
        ws.send_text("ping")
        assert ws.receive_text() == "pong"


def test_ws_driver_gets_available_room(client: TestClient, auth_headers: dict) -> None:
    token = auth_headers["driver"]["Authorization"].replace("Bearer ", "")
    with client.websocket_connect(f"/ws/orders?token={token}") as ws:
        connected = ws.receive_json()
        assert "orders:available" in connected["rooms"]


def test_ws_rejects_bad_token(client: TestClient) -> None:
    with pytest.raises(WebSocketDisconnect):
        with client.websocket_connect("/ws/orders?token=invalid-token"):
            pass


def test_ws_heartbeat_ping(
    client: TestClient, auth_headers: dict, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Si el cliente no envia nada, el servidor envia un ping de heartbeat."""
    from app.api.ws import orders as ws_orders

    monkeypatch.setattr(ws_orders, "HEARTBEAT_SECONDS", 1)
    token = auth_headers["customer"]["Authorization"].replace("Bearer ", "")
    with client.websocket_connect(f"/ws/orders?token={token}") as ws:
        assert ws.receive_json()["type"] == "connected"
        assert ws.receive_text() == "ping"
        ws.send_text("pong")
        ws.send_text("ping")
        assert ws.receive_text() == "pong"


def test_many_ws_does_not_block_rest(client: TestClient, auth_headers: dict) -> None:
    """Muchas conexiones WS no deben agotar el pool de BD ni bloquear el REST."""
    token = auth_headers["customer"]["Authorization"].replace("Bearer ", "")
    sockets = []
    for _ in range(18):
        ws = client.websocket_connect(f"/ws/orders?token={token}")
        ws.__enter__()
        sockets.append(ws)
    try:
        t0 = time.monotonic()
        resp = client.get("/api/v1/orders", headers=auth_headers["customer"])
        assert resp.status_code == 200, resp.text
        assert time.monotonic() - t0 < 5
    finally:
        for ws in sockets:
            ws.__exit__(None, None, None)
