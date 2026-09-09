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
