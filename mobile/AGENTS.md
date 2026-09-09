# mobile — Apps Flutter

Carpeta de apps móviles de la plataforma de delivery. Parte del monorepo `imagine-delivery` (ADR-008); el agrupamiento de las dos apps con paquete compartido sigue [[ADR-007 Monorepo de apps moviles]].

> Gestionado por el harness: ver `AGENTS.md` raíz y `docs/` (vault Obsidian).

## Estructura

```
mobile/
├── customer_app/          # Customer App (pubspec propio, entry point propio)
├── driver_app/            # Driver App (pubspec propio, entry point propio)
└── packages/
    └── shared/            # código común: client HTTP, modelos, WS, theme
```

- Cada app se ejecuta de forma independiente: `flutter run` desde su carpeta.
- Código común en `packages/shared`, referenciado por path: `flutter pub add shared --path packages/shared`.
- Un cambio en `shared` obliga a validar AMBAS apps (`flutter analyze` + `flutter test` en `customer_app` y `driver_app`).

## Stack

- Flutter (stable), Dart
- Riverpod para estado (ver ADR-004)
- dio para HTTP, web_socket_channel para realtime
- Patrón feature-first

## Funcionalidad

| App           | Features                                        |
| ------------- | ----------------------------------------------- |
| customer_app  | Login, Registro, Crear pedido, Lista/detalle de pedidos, estado realtime |
| driver_app    | Login, Pedidos disponibles, Aceptar, Actualizar estado, realtime |

## Comandos (dev)

```powershell
cd customer_app; flutter pub get; flutter run; flutter analyze; flutter test
cd driver_app;   flutter pub get; flutter run; flutter analyze; flutter test
```

## Convenciones

- Commits con scope de la app: `feat(customer)`, `feat(driver)`, `feat(shared)`.
- URLs/tokens por configuración (dart-define), nunca hardcodeados.
- Todo cambio toca el vault: revisar `docs/` antes, actualizar después.