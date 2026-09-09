---
tags: [adr, decision, stack]
status: Aceptado
date: 2026-09-08
---

# ADR-001: Elección de stack

## Status

**Aceptado**

## Contexto

La prueba técnica exige: Python/FastAPI + PostgreSQL + SQLAlchemy + Alembic + JWT en backend, Flutter en móvil, y AWS (RDS, S3, EC2/Lambda, CloudFront, CloudWatch) en infraestructura. El stack es **impuesto por la prueba**, no libre.

## Decisión

Adoptar el stack de la prueba sin desviaciones:

- **Backend:** Python 3.12, FastAPI, SQLAlchemy 2.0 (async), Alembic, Pydantic v2, PostgreSQL 16.
- **Auth:** JWT (access + refresh) con `python-jose` o `pyjwt` + bcrypt/passlib para hash.
- **Realtime:** WebSocket (ver [[ADR-005 Realtime WebSocket vs SSE]]).
- **Mobile:** Flutter (Customer App + Driver App), patrón feature-first.
- **Infra:** AWS RDS, S3, EC2/ALB, CloudFront, CloudWatch; Terraform como IaC.
- **Herramientas:** uv para gestión de Python, Docker para contenerización, ruff + mypy + pytest para calidad, GitHub Actions para CI/CD.

## Consecuencias

### Positivas

- Cumple los requisitos de la prueba al 100%.
- SQLAlchemy 2.0 async + FastAPI = stack moderno y escalable.
- Terraform + Docker permiten reproducibilidad y demo de buenas prácticas.

### Negativas / Trade-offs

- Más complejidad que una solución mínima (async ORM, WS, IaC).
- Tiempo de setup mayor (ver [[Setup y herramientas]]).

### Neutrales

- Se documenta toda decisión en el vault ([[ADR-003 Vault Obsidian como fuente de verdad]]).

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Afecta a:** [[Modelo de datos]], [[API Autenticacion]], [[Arquitectura AWS]]