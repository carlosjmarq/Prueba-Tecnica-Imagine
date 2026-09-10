import asyncio
import logging
from typing import Annotated

from fastapi import APIRouter, Depends, WebSocket

from app.api.deps import get_current_user_ws
from app.models import User, UserRole
from app.services.realtime import manager

router = APIRouter(tags=["realtime"])

logger = logging.getLogger(__name__)

WsUserDep = Annotated[User, Depends(get_current_user_ws)]

# Si el cliente no envia nada en este lapso, el servidor envia un "ping"
# de heartbeat. Si el cliente esta muerto, el send falla y se limpia la conexion.
HEARTBEAT_SECONDS = 60


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
            try:
                message = await asyncio.wait_for(
                    websocket.receive_text(), timeout=HEARTBEAT_SECONDS
                )
            except TimeoutError:
                await websocket.send_text("ping")
                continue
            if message == "ping":
                await websocket.send_text("pong")
    except Exception:
        # Conexion cerrada o cliente muerto: la limpieza ocurre en `finally`.
        logger.debug("WebSocket cerrado")
    finally:
        for room in rooms:
            manager.disconnect(room, websocket)
