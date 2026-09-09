from typing import Annotated

from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect

from app.api.deps import get_current_user_ws
from app.models import User, UserRole
from app.services.realtime import manager

router = APIRouter(tags=["realtime"])

WsUserDep = Annotated[User, Depends(get_current_user_ws)]


@router.websocket("/ws/orders")
async def orders_ws(websocket: WebSocket, user: WsUserDep) -> None:
    rooms: list[str] = [f"user:{user.id}"]
    if user.role == UserRole.DRIVER:
        rooms.append("orders:available")
    await websocket.accept()
    for room in rooms:
        manager.connect(room, websocket)
    try:
        await websocket.send_json({"type": "connected", "rooms": rooms})
        while True:
            message = await websocket.receive_text()
            if message == "ping":
                await websocket.send_text("pong")
    except WebSocketDisconnect:
        for room in rooms:
            manager.disconnect(room, websocket)
