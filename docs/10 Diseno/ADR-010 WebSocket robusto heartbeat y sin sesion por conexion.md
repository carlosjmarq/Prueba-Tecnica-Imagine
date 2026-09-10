---
tags: [adr, decision, realtime, websocket, base-de-datos, bugfix]
status: Propuesto
date: 2026-09-10
---

# ADR-010: WebSocket robusto — heartbeat y sin retención de sesión de BD

## Status

**Aceptado**

## Contexto

Durante un E2E real se detectaron dos fallos relacionados:

1. **Timeout en REST al ver el detalle de un pedido entregado** (`DioException receive timeout` a los 15 s).
2. **El realtime "no funcionaba"** de forma intermitente.

Diagnóstico con evidencia: `get_current_user_ws` (`app/api/deps.py`) dependía de `get_session`, reteniendo **una conexión asyncpg por cada WebSocket abierto durante toda la vida de la conexión**. El experimento lo confirmó: con 15 WS abiertos se agotaba el pool (5 + overflow 10) y `GET /orders/{id}` fallaba por timeout. Sin heartbeat, las conexiones de clientes muertos quedaban bloqueadas en `receive_text()` reteniendo la sesión, y las reconexiones del cliente acumulaban handlers hasta saturar el pool → también el propio WS dejaba de aceptar conexiones.

Se consideró migrar a **Socket.IO** para "arreglar" el realtime.

## Decisión

**Mantener WebSocket nativo** (ver [[ADR-005 Realtime WebSocket vs SSE]]) y corregir la causa raíz:

1. **Auth del WS sin retener sesión**: `get_current_user_ws` resuelve el usuario con una sesión de corta vida (abre, consulta, cierra antes de entrar al loop). Se respeta el override de dependencias (para tests) y no se toca el pool durante la conexión.
2. **Heartbeat servidor**: si el cliente no envía nada en 60 s, el servidor envía `ping`; si el envío falla (cliente muerto) la conexión se limpia en `finally`.
3. **Heartbeat cliente** (`OrderSocket`): envía `ping` cada 20 s y reconecta si no recibe `pong` en 10 s; responde `pong` a los `ping` del servidor.
4. **Pool de seguridad**: `pool_size=10, max_overflow=20`.

**Se descarta Socket.IO**: raw WS funciona (verificado desde host y emulador); el problema no era el transporte sino la gestión de sesiones y la falta de heartbeat. Migrar añadiría dependencias en ambos lados, un protocolo con fallback y cambiaría [[ADR-005 Realtime WebSocket vs SSE]], sin atacar la causa.

## Consecuencias

### Positivas

- El REST deja de sufrir timeouts por presión del pool; N conexiones WS no bloquean la API (test de regresión con 18 WS).
- Las conexiones muertas se detectan y limpian (servidor y cliente).
- Sin dependencias nuevas ni cambio de protocolo.

### Negativas / Trade-offs

- El WS hace una consulta corta a BD por handshake (igual que antes, pero liberada de inmediato).
- El pool sigue siendo finito: si se abren más conexiones que `pool_size + max_overflow` simultáneas, el handshake esperará; en producción se escalaría horizontalmente (Redis Pub/Sub, ver [[Realtime]]).

### Neutrales

- Se añadió `test_many_ws_does_not_block_rest` y `test_ws_heartbeat_ping` como regresión.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Afecta a:** [[Realtime]], [[API Implementada]], [[Testing y calidad]]
- **Relacionada con:** [[ADR-005 Realtime WebSocket vs SSE]]
- **Repo:** `backend` (`app/api/deps.py`, `app/api/ws/orders.py`, `app/core/database.py`), `mobile/packages/shared` (`order_socket.dart`)