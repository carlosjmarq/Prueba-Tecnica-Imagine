---
tags: [tecnico, realtime, websocket]
status: borrador
date: 2026-09-08
---

# Realtime

> Notificación en tiempo real de cambios de estado de pedidos vía WebSocket. Ver [[ADR-005 Realtime WebSocket vs SSE]].

## Endpoint

```
WS /ws/orders?token=<access_jwt>
```

- Autenticación en el handshake (token JWT como query param o header). El servidor valida antes de aceptar la conexión. La auth **no retiene** una conexión de BD durante la vida del socket (ver [[ADR-010 WebSocket robusto heartbeat y sin sesion por conexion]]).
- Roles:
  - **Customer**: room `user:{id}` (recibe eventos de sus pedidos).
  - **Driver**: rooms `user:{id}` y `orders:available` (nuevos pedidos disponibles + sus pedidos asignados).

## Protocolo de mensajes

Eventos del servidor:

```json
{ "type": "order.created",   "order_id": "...", "status": "PENDING",   "ts": "..." }
{ "type": "order.updated",   "order_id": "...", "status": "ACCEPTED",  "ts": "..." }
{ "type": "order.available", "order_id": "...", "payload": { ... } }
```

El cliente envía `ping` periódicamente (20 s) y el servidor responde `pong`; además, si el servidor no recibe nada en 60 s envía su propio `ping`. Ver [[ADR-010 WebSocket robusto heartbeat y sin sesion por conexion]].

## Arquitectura en el backend

- **ConnectionManager** (patrón del dominio): mapa `room → set[WebSocket]`; `connect`, `disconnect`, `send_to_room`, `broadcast`.
- Emisión acoplada al servicio de pedidos: cada transición de estado válida (ver [[API Pedidos y estados]]) dispara `manager.send_to_room(...)`.
- Reconexión: el cliente reconecta con backoff; al reconectarse re-suscribe a rooms; el estado verdadero siempre llega por REST (el WS es un delta).
- Heartbeat bidireccional: cliente `ping` cada 20 s (reconecta si no llega `pong` en 10 s); servidor `ping` tras 60 s de silencio. La conexión muerta se limpia en `finally` (rooms + sesión de BD ya liberada).

## En producción (AWS)

- ALB con target group de WebSocket (protocolo `HTTP/2` o `WS`), idle timeout ≥ 3600s, o API Gateway WebSocket + Lambda (ver [[Arquitectura AWS]] y [[Lambda]]).
- Si se escala horizontal, los events se enrutan por room vía Redis Pub/Sub (en esta prueba se documenta como mejora; el ConnectionManager en memoria basta para una instancia).

## Alternativa: SSE

Descartada por ser unidireccional: el driver necesita enviar acciones (aceptar, cambiar estado) por el mismo canal. Ver justificación completa en [[ADR-005 Realtime WebSocket vs SSE]].

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[API Pedidos y estados]], [[Arquitectura AWS]]
- **ADR:** [[ADR-005 Realtime WebSocket vs SSE]], [[ADR-010 WebSocket robusto heartbeat y sin sesion por conexion]]
- **Repo:** `backend` (`app/api/ws/orders.py`, `app/services/realtime.py`)