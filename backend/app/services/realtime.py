import asyncio
from typing import Any

from fastapi import WebSocket


class ConnectionManager:
    """Gestiona conexiones WebSocket por room.

    Rooms:
      - order:{id}          -> customer + driver asignado de un pedido
      - orders:available    -> drivers (reciben pedidos PENDING)
    """

    def __init__(self) -> None:
        self._rooms: dict[str, set[WebSocket]] = {}

    def connect(self, room: str, websocket: WebSocket) -> None:
        self._rooms.setdefault(room, set()).add(websocket)

    def disconnect(self, room: str, websocket: WebSocket) -> None:
        self._rooms.get(room, set()).discard(websocket)

    async def send_to_room(self, room: str, message: dict[str, Any]) -> None:
        dead: list[WebSocket] = []
        for ws in self._rooms.get(room, set()):
            try:
                await ws.send_json(message)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self._rooms.get(room, set()).discard(ws)

    async def broadcast(self, message: dict[str, Any], rooms: list[str]) -> None:
        await asyncio.gather(*(self.send_to_room(r, message) for r in rooms))


manager = ConnectionManager()
