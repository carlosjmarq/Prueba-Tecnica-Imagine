# shared

Paquete Flutter compartido de las apps de delivery (cliente y repartidor). Contiene el código común para no duplicar lógica entre `customer_app` y `driver_app`.

Parte del monorepo `imagine-delivery` (ver `../../AGENTS.md` y el vault `docs/`). Se referencia por path: `flutter pub add shared --path ../packages/shared`.

## Contenido

```
lib/
  network/     # ApiClient (dio + auth), ApiConfig (baseUrl/wsUrl via dart-define), refresh dedup
  realtime/    # OrderSocket: WebSocket con heartbeat, rooms y backoff
  models/      # Modelos de dominio (Order, OrderItem, User, estados...)
  image/       # Compresión WebP antes de subir (image_compress)
  theme/       # Design system de las apps (AppColors, AppTheme, Google Fonts)
  shared.dart  # Exports
```

## Notas

- La URL de la API/WS se lee de `API_BASE_URL` y `WS_URL` (`--dart-define`), con defaults `http://127.0.0.1:8000` / `ws://127.0.0.1:8000`.
- Un cambio en `shared` obliga a validar AMBAS apps (`flutter analyze` + `flutter test` en `customer_app` y `driver_app`).

## Calidad

```bash
flutter analyze
flutter test
dart format .
```

## Documentación

- `docs/20 Tecnico/Apps moviles implementadas`, `docs/20 Tecnico/Design System de las apps`, `docs/20 Tecnico/Realtime`
- `docs/10 Diseno/ADR-004 Estado de las apps`, `ADR-007 Monorepo de apps moviles`, `ADR-011 Subida directa con presigned URLs`