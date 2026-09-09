---
tags: [tecnico, flutter, apps, implementacion]
status: implementado
date: 2026-09-09
---

# Apps moviles implementadas (Fase 3)

> Estado real de las apps tras la Fase 3. Se apoya en [[ADR-004 Estado de las apps]] (Riverpod), [[ADR-007 Monorepo de apps moviles]] (estructura `mobile/`) y el [[Design System de las apps]].

## Paquete compartido (`mobile/packages/shared`)

| Módulo | Contenido |
| ------ | --------- |
| `theme/app_theme.dart` | `buildAppTheme()` con tokens del design system; `orderStatusColor()` y `orderStatusLabel()` por estado |
| `models/models.dart` | `User`, `TokenPair`, `Order`, `OrderItem`, `StatusHistory`, `RealtimeEvent` (fromJson) |
| `network/api_client.dart` | `ApiClient` (dio) con interceptor Bearer + refresh automático; `ApiConfig` vía dart-define (`API_BASE_URL`, `WS_URL`); `ApiException` |
| `network/dio_factory.dart` | `DioClientFactory` para refresh/pruebas |
| `realtime/order_socket.dart` | `OrderSocket` con reconexión backoff (1s→5s) y parsing de eventos |
| `shared.dart` | Barrel + `formatMoney()` |

## Customer App (`mobile/customer_app`)

- **Auth**: Login/Registro con validación y estados de carga/error (login_screen + auth_providers).
- **Home**: bottom nav (Pedidos / Crear / Perfil) con `IndexedStack`.
- **Pedidos**: lista (pull-to-refresh, chips de estado), detalle (items, historial, cancelar si PENDING), crear (items dinámicos).
- **Realtime**: `realtimeEventsProvider` escucha el socket e invalida lista/detalle al recibir `order.updated`.

## Driver App (`mobile/driver_app`)

- **Auth**: Login (solo login, rol DRIVER).
- **Home**: bottom nav (Disponibles / Mis pedidos).
- **Disponibles**: lista de PENDING con botón "Aceptar".
- **Mis pedidos**: estado + botón para avanzar (ACCEPTED→PICKED_UP→DELIVERED).
- **Realtime**: invalida ambas listas al recibir eventos `order.created`/`order.updated`.

## Configuración

URLs por dart-define (nunca hardcodeadas): `--dart-define=API_BASE_URL=http://... --dart-define=WS_URL=ws://...`
Defaults: `http://127.0.0.1:8000` / `ws://127.0.0.1:8000`.

## Calidad

- `flutter analyze`: limpio en shared, customer_app y driver_app.
- `flutter test`: 1 test de smoke por app (login render).
- `dart format`: aplicado en las tres.
- Flujo E2E verificado contra la API real: register → login → crear → aceptar → PICKED_UP → DELIVERED (historial completo).

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Design System de las apps]], [[API Implementada]], [[Realtime]], [[ADR-004 Estado de las apps]], [[ADR-007 Monorepo de apps moviles]]
- **Repo:** `mobile/`