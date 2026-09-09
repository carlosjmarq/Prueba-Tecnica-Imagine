---
tags: [adr, decision, repositorios, monorepo]
status: Aceptado
date: 2026-09-08
---

# ADR-008: Monorepo único

## Status

**Aceptado**

## Contexto

El ADR-002 ([[ADR-002 Estructura multi-repositorio]]) planteaba un repo git por artefacto (backend, mobile, infra, docs) con un meta-repo de coordinación. Para una **prueba técnica ejecutada en solitario y con plazo acotado**, el multi-repo compra cosas que no se necesitan (independencia de equipos, versionado y release por separado, control de acceso distinto) y paga costes que sí se sufren:

- Un cambio de feature (endpoint + app + contrato) toca 3 repos → 3 commits/PRs.
- El evaluador debe abrir 4 repos + el vault para revisar la solución.
- CI/CD: un pipeline por repo con coordinación manual.
- Código compartido entre backend y apps (contrato API) difícil de versionar.

Además, el enunciado pide "**Repositorio Git**" (singular) como entregable.

## Decisión

El proyecto es **un único repo git** `imagine-delivery` con todo dentro:

```
imagine-delivery/
├── backend/     # FastAPI (app/, alembic/, tests/)
├── mobile/      # customer_app/ + driver_app/ + packages/shared ([[ADR-007 Monorepo de apps moviles]])
├── infra/       # OpenTofu, CI/CD, docker-compose
├── docs/        # vault Obsidian
├── .github/     # GitHub Actions con filtros por path
└── scripts/     # setup y verificación
```

Reglas:

- Commits atómicos: un cambio de feature toca API + app + docs en un mismo commit.
- Scopes por artefacto: `feat(backend)`, `feat(customer)`, `feat(driver)`, `feat(shared)`, `feat(infra)`, `docs(vault)`.
- CI: un pipeline con filtros por path (`backend/**`, `mobile/**`, `infra/**`).
- Cada carpeta conserva su `AGENTS.md` con sus convenciones.

El agrupamiento interno de las apps móviles (customer + driver + shared) se mantiene según [[ADR-007 Monorepo de apps moviles]], ahora como subcarpetas dentro del monorepo único.

## Consecuencias

### Positivas

- Commits atómicos y revisión en un solo lugar (mejor para la prueba).
- CI/CD único con path filters; contratos compartidos versionados juntos.
- Coherente con el entregable "Repositorio Git" del enunciado.

### Negativas / Trade-offs

- Se pierde el versionado independiente por artefacto (irrelevante para la prueba).
- El repo mezcla lenguajes/toolchains distintos (Python, Dart, HCL) — mitigado por CI por path y scopes de commit.

### Neutrales

- El vault Obsidian sigue siendo la fuente de verdad ([[ADR-003 Vault Obsidian como fuente de verdad]]).
- Supersede al ADR-002; el ADR-007 se mantiene vigente a nivel de estructura interna de `mobile/`.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Supersede a:** [[ADR-002 Estructura multi-repositorio]]
- **Modifica a:** [[ADR-007 Monorepo de apps moviles]]
- **Afecta a:** [[Fases del proyecto]], [[Convenciones git y commits]]