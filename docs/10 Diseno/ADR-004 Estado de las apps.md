---
tags: [adr, decision, flutter, estado]
status: Propuesto
date: 2026-09-08
---

# ADR-004: Estado de las apps (Riverpod vs Bloc)

## Status

**Aceptado**

## Contexto

Las apps Flutter (Customer y Driver) necesitan manejo de estado: sesión, listas de pedidos, estado en tiempo real vía WebSocket, navegación. Se evaluaron las opciones más populares de la comunidad Flutter.

## Decisión

Usar **Riverpod** (flutter_riverpod) con patrón feature-first.

Justificación:

- Menos boilerplate que Bloc; state simple con `Notifier`/`AsyncNotifier`.
- Perfecto para realtime: un `StreamProvider`/`Notifier` consume el WebSocket y las vistas reaccionan.
- Testing simple (sobrescribir providers con fake repos).
- Comunidad activa y soporte de código-gen (`riverpod_generator`).

Alternativas descartadas: Bloc (más rígido y verboso para este alcance), Provider (obsoleto), setState puro (no escala con realtime).

## Consecuencias

### Positivas

- Menos código, pruebas fáciles, integración natural con streams (WebSocket).
- Mismo patrón en ambas apps → menor curva de mantenimiento.

### Negativas / Trade-offs

- Riverpod tiene curva de aprendizaje en generadores/refs.
- Cambiar a Bloc después sería costoso (por eso se fija ahora).

### Neutrales

- Dependencias: `flutter_riverpod`, `dio` (HTTP), `web_socket_channel` o similar.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Afecta a:** [[API Pedidos y estados]], [[Realtime]], apps en `mobile/customer_app` y `mobile/driver_app` ([[ADR-007 Monorepo de apps moviles]])