# customer_app — Flutter (Cliente)

App Flutter del cliente de la plataforma de delivery. Parte del monorepo `imagine-delivery` (ADR-008); vive en `mobile/customer_app/` con código común en `mobile/packages/shared` (ver [[ADR-007 Monorepo de apps moviles]] y `mobile/AGENTS.md`).

> Repo gestionado por el harness: ver `AGENTS.md` raíz y `docs/` (vault Obsidian).

## Stack

- Flutter (stable), Dart
- Riverpod para estado (ver ADR-004)
- dio para HTTP, web_socket_channel para realtime
- Patrón feature-first
- Código común en `../packages/shared` (referencia por path)

## Funcionalidad

- Login / Registro
- Crear pedido (items, direcciones)
- Lista y detalle de pedidos
- Estado en tiempo real (WebSocket)

## Estructura

```
lib/
  core/         # red, config, theme, widgets compartidos
  features/
    auth/       # login, registro
    orders/     # crear, listar, detalle
  app.dart
main.dart
```

## Comandos (dev)

```powershell
flutter pub get
flutter run
flutter analyze
flutter test
dart format .
```

## Convenciones

- URLs/tokens por configuración (dart-define), nunca hardcodeados.
- Todo cambio toca el vault: revisar `docs/` antes, actualizar después.
- Commits Conventional Commits.