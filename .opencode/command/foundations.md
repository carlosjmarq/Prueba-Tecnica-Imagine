---
description: Fase 1 - Crea el esqueleto del monorepo (backend, mobile, infra, docs) con CI vacío, docker-compose base y ADRs iniciales.
agent: build
---

Ejecuta la Fase 1 — Fundaciones del proyecto aplicando el ciclo RPI (Research → Plan → Implement, ver `docs/40 Proceso/RPI Research Plan Implement`). Instrucciones:

1. **Research**: revisa el vault ([[00 Inbox/MOC]]) y el README raíz; verifica las skills instaladas. Planifica qué archivos y ADRs vas a crear.

1. Verifica que el monorepo (raíz, ver [[ADR-008 Monorepo unico]]) tenga la estructura base ya inicializada con `git init`:
   - `backend/` (API FastAPI)
   - `mobile/` (`customer_app` + `driver_app` + `packages/shared`, ver [[ADR-007 Monorepo de apps moviles]])
   - `infra/` (infraestructura)
   - `docs/` (vault Obsidian)
2. Cada carpeta tiene su `AGENTS.md` con sus convenciones y comandos (guíate del AGENTS.md raíz).
3. Backend: esqueleto mínimo `pyproject.toml` con uv, estructura `backend/app/` vacía, `backend/tests/`, CI de GitHub Actions vacío (solo lint/test).
4. Apps: `flutter create` para cada app dentro de `mobile/` (org `com.imagine`): `customer_app`, `driver_app`, paquete `packages/shared` inicial, estructura feature-first, `AGENTS.md` por app.
5. Infra: `docker-compose.base.yml` con PostgreSQL 16 + MinIO, README.
6. Verifica los ADRs iniciales en el vault usando `docs/90 Recursos/Templates/ADR`:
   - `ADR-001 Eleccion de stack` (Aceptado)
   - `ADR-002 Estructura multi-repositorio` (Superseded por ADR-008)
   - `ADR-003 Vault Obsidian como fuente de verdad` (Aceptado)
   - `ADR-007 Monorepo de apps moviles` (Aceptado)
   - `ADR-008 Monorepo unico` (Aceptado)
7. Actualiza el `[[00 Inbox/MOC]]` y el README raíz con el estado del proyecto.
8. Cierra con: monorepo con commit inicial, docker-compose base validado (`docker compose config`), vault actualizado.