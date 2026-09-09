---
description: Fase 2 - Implementa el backend FastAPI completo (auth JWT+refresh, pedidos, estados, WS/SSE, S3-ready, rate limiting, logging, Alembic, tests, Swagger).
agent: build
---

Ejecuta la Fase 2 — Backend del proyecto aplicando el ciclo RPI (Research → Plan → Implement, ver `docs/40 Proceso/RPI Research Plan Implement`). Usa el agente `backend` para el desarrollo del dominio.

Instrucciones:

1. **Research**: carga las skills (`fastapi`, `fastapi-python`, `fastapi-templates`, `sqlalchemy-alembic...`, `pytest-skill`) y revisa las notas del vault ([[Modelo de datos]], [[API Autenticacion]], [[API Pedidos y estados]], [[Realtime]], [[StorageService]]).
2. **Plan**: antes de codificar cada feature, define el alcance (archivos, endpoints, tests) y crea/actualiza los ADRs y notas necesarios ([[ADR-004 Estado de las apps]] y [[ADR-005 Realtime WebSocket vs SSE]] quedaron Propuestos: resolver su estado aquí).
3. **Implement**: codifica validando con la Definition of Done.
2. Alcance funcional obligatorio:
   - Auth JWT para Customer y Driver (access + refresh tokens, roles).
   - Customer: crear pedidos, consultar pedidos, ver estado.
   - Driver: listar pedidos disponibles, aceptar pedidos, actualizar estado.
   - Estados: `Pending → Accepted → Picked Up → Delivered` + `Cancelled` (validar transiciones).
   - Realtime de cambios de estado: WebSocket (o SSE justificado en ADR).
   - StorageService S3-ready para imágenes (local/MinIO en dev, S3 en prod).
3. Puntos extra a incluir: rate limiting, refresh tokens, tests automatizados, Swagger `/docs`, logging JSON.
4. Calidad: SQLAlchemy 2.0 async, Alembic con migración inicial, Pydantic v2, ruff + mypy sin errores, `pytest` verde.
5. Documentación: antes de cada feature revisa el vault; después actualiza `docs/20 Tecnico` (API, auth, pedidos, realtime, storage) y crea ADR si hay decisión (ej. WebSocket vs SSE, esquema JWT, StorageService).
6. Cierra con: tests verdes, migración aplicada, Swagger accesible, vault actualizado, README de `backend/` actualizado.