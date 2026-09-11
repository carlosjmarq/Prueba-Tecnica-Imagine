# customer_app — App del cliente

Aplicación Flutter del **cliente** de la plataforma de delivery. Permite registrarse, crear pedidos con foto por ítem, seguir su estado en tiempo real y ver el historial.

Parte del monorepo `imagine-delivery` (ver `../AGENTS.md` y el vault `docs/`). Código común en `../packages/shared` (referenciado por path, ver `../AGENTS.md`).

## Funcionalidades

- Login / Registro (JWT + refresh, ver `docs/20 Tecnico/API Autenticacion`)
- Crear pedido: ítems con nombre/precio/cantidad y **foto por ítem** (subida directa con presigned URL, compresión WebP, ver `docs/10 Diseno/ADR-011`)
- Lista y detalle de pedidos, con **filtro de activos/completados**
- Estado en **tiempo real** por WebSocket (heartbeat, ver `docs/20 Tecnico/Realtime`)
- Perfil con nombre

## Requisitos

- Flutter **3.22.1** (el proyecto usa APIs de Dart 3.4; el stable más nuevo rompe `CardTheme`/`google_fonts`, ver `docs/40 Proceso/Setup y herramientas`)
- Backend corriendo (local: `scripts/dev.ps1`; o URL de la API desplegada)

## Ejecutar

```bash
flutter pub get
flutter run
```

La URL de la API se configura con `--dart-define` (default `http://127.0.0.1:8000`):

```bash
# Emulador Android (el host del PC es 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=WS_URL=ws://10.0.2.2:8000
```

O lanzarla junto con la app de driver con `scripts/apps.ps1` desde la raíz del monorepo.

## Calidad

```bash
flutter analyze
flutter test
dart format .
```

## Estructura

```
lib/
  core/         # providers globales (sesión, red)
  features/
    auth/       # login, registro
    home/       # home + perfil
    orders/     # crear, listar, detalle (realtime)
  app.dart
main.dart
```

## Documentación

- `docs/20 Tecnico/Apps moviles implementadas`
- `docs/10 Diseno/ADR-004 Estado de las apps` (Riverpod)
- `docs/10 Diseno/ADR-007 Monorepo de apps moviles`