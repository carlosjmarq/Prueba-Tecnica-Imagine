---
tags: [adr, decision, realtime, websocket]
status: Propuesto
date: 2026-09-08
---

# ADR-005: Realtime — WebSocket vs SSE

## Status

**Aceptado**

## Contexto

La prueba exige "notificación en tiempo real de cambios de estado mediante WebSocket o SSE". Hay que elegir el mecanismo y justificarlo.

## Decisión

Usar **WebSocket** (`/ws/orders`), con autenticación vía token JWT en el handshake.

Justificación:

- **Bidireccional**: el Driver no solo recibe eventos, también emite acciones (aceptar, actualizar estado). SSE es unidireccional (servidor→cliente) y forzaría un canal HTTP paralelo para las acciones.
- **Baja latencia** para broadcast de cambios de estado a múltiples clientes (Customer y Driver conectados).
- FastAPI tiene soporte nativo de WebSocket (`WebSocketEndpoint`), trivial de implementar.
- En AWS funciona con ALB (target group de WebSocket) o API Gateway WebSocket; se documenta en [[Arquitectura AWS]].

SSE quedaría como alternativa si el alcance fuera solo "ver estado" (unidireccional), pero no cubre las acciones del repartidor.

## Consecuencias

### Positivas

- Canal único para eventos y acciones del driver.
- Latencia mínima y soporte nativo en FastAPI.

### Negativas / Trade-offs

- Requiere gestionar conexiones (connection manager, heartbeat, reconexión).
- ALB/WebSocket requiere configuración específica de idle timeout y stickiness.

### Neutrales

- Se implementa un `ConnectionManager` con rooms por pedido/usuario.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Afecta a:** [[Realtime]], [[API Pedidos y estados]], [[Arquitectura AWS]]