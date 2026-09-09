---
description: Fase 3 - Implementa las apps Flutter (Customer y Driver) en mobile/: login, registro, pedidos, realtime. Usa el agente mobile.
agent: build
---

Ejecuta la Fase 3 — Apps móviles del proyecto aplicando el ciclo RPI (Research → Plan → Implement, ver `docs/40 Proceso/RPI Research Plan Implement`). Usa el agente `mobile`.

Instrucciones:

1. **Research**: carga la skill `flutter` y revisa [[ADR-004 Estado de las apps]] (resolver su estado), [[ADR-007 Monorepo de apps moviles]], [[Realtime]] y las notas de API.
2. **Plan**: define el alcance de cada pantalla y flujo; actualiza el ADR de estado y las notas de cada app ANTES de codificar.
3. **Implement**: codifica validando con `flutter analyze` + `flutter test`.

Las apps viven en `mobile/` (ver [[ADR-007 Monorepo de apps moviles]]) dentro del monorepo único ([[ADR-008 Monorepo unico]]):

```
mobile/
├── customer_app/          # Customer App (pubspec propio)
├── driver_app/            # Driver App (pubspec propio)
└── packages/shared/       # código común: client HTTP, modelos, WS, theme
```

Alcance:
1. **Customer App** (`mobile/customer_app`):
   - Login, Registro, Crear pedido, Lista y detalle de pedidos.
   - Estado en tiempo real (WebSocket) en la lista/detalle de pedidos.
2. **Driver App** (`mobile/driver_app`):
   - Login, Lista de pedidos disponibles, Aceptar pedido, Actualizar estado.
   - Realtime: nuevos pedidos y cambios de estado.
3. **Paquete compartido** (`mobile/packages/shared`): client HTTP, modelos, manejo de WebSocket, theme. Cada app lo referencia por path (`flutter pub add shared --path packages/shared`).
4. Convenciones: patrón feature-first; estado con Riverpod o Bloc según `ADR-004` (si no existe, créalo en esta fase antes de implementar).
5. Configuración: URLs y tokens vía configuración (dart-define/env), nunca hardcodeados. Cliente HTTP + WebSocket compartido.
6. Calidad: `flutter analyze` limpio y `flutter test` verde en cada app tocada (ambas si cambia `shared`), `dart format` aplicado.
7. Commits con scope de la app: `feat(customer)`, `feat(driver)`, `feat(shared)`.
8. Documentación: actualiza `docs/20 Tecnico` con las notas de cada app y el ADR de estado/arquitectura. Actualiza READMEs de ambas apps.
9. Cierra con: ambas apps compilan y pasan tests, vault actualizado.