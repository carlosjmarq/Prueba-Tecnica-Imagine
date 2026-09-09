# Prueba Técnica Imagine — Workflow de IA

Plataforma de delivery (Full Stack): FastAPI + PostgreSQL + Flutter (Customer/Driver) + AWS.

## Objetivo del workflow

Este harness estandariza cómo la IA (y el equipo) ejecutan la prueba técnica:
misma estructura, misma documentación, mismo orden de fases, calidad reproducible.
Toda decisión, funcionalidad e infraestructura se documenta en el vault Obsidian
(`docs/`, ver `[[00 Inbox/MOC]]`).

## Arquitectura: monorepo único

El proyecto es **un único repo git** `imagine-delivery` con todo dentro (ver
`[[ADR-008 Monorepo unico]]`). No hay repos git independientes por artefacto.

| Ruta          | Contenido                                        |
| ------------- | ------------------------------------------------ |
| `backend/`    | API FastAPI (auth JWT, pedidos, WS/SSE, Alembic) |
| `mobile/`     | Apps Flutter: `customer_app/` + `driver_app/` + `packages/shared` ([[ADR-007 Monorepo de apps moviles]]) |
| `infra/`      | Terraform/OpenTofu, diagramas, CI/CD, docker-compose |
| `docs/`       | Vault Obsidian (documentación y decisiones)      |
| `.github/`    | GitHub Actions con filtros por path              |
| `scripts/`    | Setup y verificación del toolchain               |

Reglas:
- Commits atómicos: un cambio de feature toca API + app + docs en un mismo commit.
- Scopes por artefacto en los commits: `feat(backend)`, `feat(customer)`, `feat(driver)`, `feat(shared)`, `feat(infra)`, `docs(vault)`.
- CI: un pipeline con filtros por path (`backend/**`, `mobile/**`, `infra/**`).
- Cada carpeta tiene su `AGENTS.md` con sus convenciones y comandos.

## Fases del proyecto

Ejecutar SIEMPRE en orden. Cada fase termina con documentación actualizada y tests verdes.
Cada fase y cada feature aplica el ciclo **RPI (Research → Plan → Implement)**:
investigar opciones y cargar skills → documentar la decisión (ADR/nota) → implementar y validar.
Ver `[[40 Proceso/RPI Research Plan Implement]]`.

1. **Fase 0 — Setup** (`/setup`): instalar y verificar toolchain (Python 3.12+, uv, Flutter SDK, Docker, AWS CLI, Terraform, PostgreSQL/MinIO en Docker). Ver `docs/40 Proceso/Setup y herramientas`.
2. **Fase 1 — Fundaciones** (`/foundations`): esqueleto del monorepo, CI vacío, docker-compose base, vault con ADRs iniciales.
3. **Fase 2 — Backend** (`/backend`): dominio delivery completo (auth JWT + refresh, pedidos, estados, WS/SSE, StorageService S3-ready, rate limiting, logging, Alembic, tests, Swagger).
4. **Fase 3 — Apps móviles** (`/apps`): Customer App y Driver App (login, registro, crear/listar pedidos, aceptar, actualizar estado, realtime).
5. **Fase 4 — Infraestructura** (`/infra`): diagrama de arquitectura, Terraform AWS (RDS, S3, EC2/ALB, CloudFront, CloudWatch, Lambda), GitHub Actions, deploy.
6. **Fase 5 — Entrega** (`/deliver`): README final, checklist de la prueba, video opcional.

## Reglas de documentación (vault Obsidian)

- Cada tarea de código toca el vault: **antes** de implementar, verificar la nota relacionada; **después**, actualizarla.
- Toda decisión de diseño significativa crea un **ADR** en `docs/10 Diseno/` con wikilinks a las notas afectadas.
- Notas nuevas: usar plantilla `[[90 Recursos/Templates/Nota]]`; ADRs: `[[90 Recursos/Templates/ADR]]`.
- Los wikilinks usan el nombre del archivo sin extensión, ej. `[[10 Diseno/ADR-001 Eleccion de stack]]` → se puede acortar a `[[ADR-001 Eleccion de stack]]`.
- Documentar siempre: decisiones de diseño, funcionalidades técnicas, infraestructura y el proceso (qué se hizo y por qué).

## Convenciones de código

- Backend: FastAPI + SQLAlchemy 2.0 async + Alembic + Pydantic v2. Proyecto en `backend/app/`, tests con pytest + httpx. Usar las skills `fastapi`, `fastapi-python`, `fastapi-templates`, `sqlalchemy-alembic-expert-best-practices-code-review`, `pytest-skill`.
- Apps: Flutter con patrón feature-first y estado Riverpod/Bloc (elegir y ADR). Usar skill `flutter`.
- Realtime: WebSocket con gestión de conexiones; si se usa SSE, documentar el porqué (ver ADR). Usar skill `websocket-realtime-builder`.
- AWS local: LocalStack/MinIO para S3 en dev. Usar skill `localstack-deploy` cuando se toque infra local.
- Logging estructurado (JSON) en backend; monitoreo vía CloudWatch (ver `docs/30 Infraestructura`).
- No exponer secretos: todo va en `.env` (gitignored) o Secrets Manager/SSM.

## Calidad (Definition of Done)

- Tests pasan: `pytest` (backend) y `flutter test` (apps).
- Lint/format: ruff + mypy (backend); dart format + flutter analyze (apps).
- Migración Alembic aplicada y revisada.
- Swagger accesible en `/docs`.
- Vault actualizado con la funcionalidad y/o decisión.
- README actualizado si cambió el uso.

## Skills del proyecto

Instaladas a nivel proyecto en `.agents/skills/` (gestionadas con `npx skills update`):
`fastapi`, `fastapi-templates`, `fastapi-python`, `flutter`, `sqlalchemy-alembic-expert-best-practices-code-review`, `websocket-realtime-builder`, `pytest-skill`, `localstack-deploy`, `obsidian`.

Cargar la skill correspondiente ANTES de escribir código del dominio (usa la herramienta `skill`).

## Stack objetivo (resumen de la prueba)

- Backend: Python, FastAPI, PostgreSQL, SQLAlchemy, Alembic, JWT (+ refresh, rate limiting).
- Mobile: Flutter (Customer App y Driver App).
- Infra: AWS RDS, S3, EC2/Lambda, CloudFront, CloudWatch, Load Balancer, WebSocket, Security Groups, Docker, GitHub Actions.
- Estados de pedido: `Pending → Accepted → Picked Up → Delivered`, con `Cancelled`.