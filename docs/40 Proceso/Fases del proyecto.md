---
tags: [proceso, fases, workflow]
status: permanente
date: 2026-09-08
---

# Fases del proyecto

> Orden de ejecución del workflow de IA. Cada fase termina con tests verdes y vault actualizado.

## Estado de fases

| Fase | Nombre          | Comando opencode      | Estado |
| ---- | --------------- | --------------------- | ------ |
| 0    | Setup           | `/setup`              | ✅     |
| 1    | Fundaciones     | `/foundations`        | ⬜     |
| 2    | Backend         | `/backend`            | ⬜     |
| 3    | Apps móviles    | `/apps`               | ⬜     |
| 4    | Infraestructura | `/infra`              | ⬜     |
| 5    | Entrega         | `/deliver`            | ⬜     |

## Fase 0 — Setup

Instalar y verificar el toolchain ([[Setup y herramientas]]). Salida: tabla de herramientas OK + servicios locales (Postgres/MinIO) levantados.

## Fase 1 — Fundaciones

- `git init` en los 4 repos ([[ADR-002 Estructura multi-repositorio]]).
- `AGENTS.md` por repo, CI vacío, docker-compose base.
- ADRs iniciales en el vault ([[ADR-001 Eleccion de stack]], [[ADR-002 Estructura multi-repositorio]], [[ADR-003 Vault Obsidian como fuente de verdad]]).

## Fase 2 — Backend

- Auth JWT + refresh ([[API Autenticacion]]).
- Pedidos y máquina de estados ([[API Pedidos y estados]], [[Modelo de datos]]).
- Realtime WebSocket ([[Realtime]], [[ADR-005 Realtime WebSocket vs SSE]]).
- StorageService S3-ready ([[StorageService]]).
- Rate limiting, logging JSON, Alembic, Swagger, tests ([[Testing y calidad]]).

## Fase 3 — Apps móviles

- Customer App y Driver App (login, registro, pedidos, realtime), en `mobile/` ([[ADR-007 Monorepo de apps moviles]]) dentro del monorepo único ([[ADR-008 Monorepo unico]]).
- Estado Riverpod ([[ADR-004 Estado de las apps]]).

## Fase 4 — Infraestructura

- Diagrama de arquitectura ([[Arquitectura AWS]]).
- Terraform: RDS ([[RDS PostgreSQL]]), S3+CloudFront ([[S3 y CloudFront]]), EC2/ALB, CloudWatch ([[CloudWatch y logging]]), Lambda ([[Lambda]]).
- GitHub Actions + dockerizado ([[Docker y despliegue]]).

## Fase 5 — Entrega

- READMEs finales, checklist ([[Checklist de la prueba]]), guion de video ([[Guion video]]).

## Reglas

- No saltar fases: la Fase N+1 asume la N completada.
- Cada fase y cada feature aplica el ciclo **RPI (Research → Plan → Implement)** — ver [[RPI Research Plan Implement]].
- Cada fase actualiza su estado en esta tabla y el [[00 Inbox/MOC]].
- Si una fase descubre un cambio de diseño → nuevo ADR.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Setup y herramientas]], [[ADR-002 Estructura multi-repositorio]]