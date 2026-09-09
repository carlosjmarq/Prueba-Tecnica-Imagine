---
tags: [adr, decision, repositorios, flutter, monorepo]
status: Aceptado
date: 2026-09-08
---

# ADR-007: Monorepo para las apps móviles

## Status

**Aceptado** (estructura interna de `mobile/` dentro del [[ADR-008 Monorepo unico]])

## Contexto

Las apps de Customer y Driver comparten gran parte del dominio: cliente HTTP, modelos de datos, manejo de WebSocket, tema visual y lógica de autenticación. Originalmente se planteó como un repo git separado de las apps; tras el ADR-008 (monorepo único) esta decisión se mantiene como **estructura interna de la carpeta `mobile/`** dentro del repo único.

## Decisión

Las dos apps Flutter viven juntas bajo `mobile/` con una app por carpeta y un paquete compartido opcional:

```
mobile/                       # dentro del monorepo imagine-delivery (ADR-008)
├── AGENTS.md
├── customer_app/             # Customer App (pubspec propio)
├── driver_app/               # Driver App (pubspec propio)
└── packages/
    └── shared/               # opcional: client HTTP, modelos, WS, theme
```

Reglas:

- Cada app tiene su propio `pubspec.yaml` y su propio `main.dart`; se ejecutan de forma independiente (`flutter run` desde su carpeta).
- El código común vive en `packages/shared` y se referencia por path (`flutter pub add shared --path packages/shared`).
- Un cambio que toque `packages/shared` debe verificar ambas apps (`flutter analyze` y `flutter test` en `customer_app` y `driver_app`).
- El CI del repo corre dos pipelines: uno por app (analizar + testear + build).

## Consecuencias

### Positivas

- Código compartido sin duplicación ni versionado cruzado entre repos.
- Commits atómicos que pueden tocar ambas apps y el paquete compartido a la vez.
- Un solo CI/CD para las apps, un solo PR por cambio.
- La prueba pide "Customer App y Driver App" como entregables: siguen siendo apps independientes dentro del monorepo.

### Negativas / Trade-offs

- El repo crece y el historial mezcla cambios de ambas apps (mitigado con Conventional Commits por scope: `feat(customer)`, `feat(driver)`, `feat(shared)`).
- Un cambio en `shared` rompe potencialmente ambas apps (mitigado con CI que valida las dos).

### Neutrales

- No afecta a backend, infra ni docs: el resto del sistema vive en el monorepo único ([[ADR-008 Monorepo unico]]).

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Complementa a:** [[ADR-008 Monorepo unico]]
- **Afecta a:** [[ADR-004 Estado de las apps]], [[Fases del proyecto]], [[Convenciones git y commits]]