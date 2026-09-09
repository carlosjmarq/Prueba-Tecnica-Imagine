---
description: Fase 0 - Instala y verifica el toolchain completo (Python, uv, Flutter, Docker, AWS CLI, Terraform, PostgreSQL/MinIO).
agent: build
---

Ejecuta la Fase 0 — Setup del proyecto. Instrucciones:

1. Ejecuta `scripts/setup.ps1` para instalar y verificar todo el toolchain:
   - Python 3.12+, uv, pip
   - Flutter SDK + Dart
   - Docker + Docker Compose
   - AWS CLI v2 + Session Manager plugin
   - Terraform
   - GitHub CLI (gh)
   - Node.js (ya debería estar)
2. Si algún componente falta o falla, instálalo manualmente siguiendo `docs/40 Proceso/Setup y herramientas` y vuelve a verificar.
3. Levanta la infraestructura local base: PostgreSQL y MinIO vía Docker Compose (usa `infra/docker-compose.base.yml`).
4. Documenta en el vault: actualiza `docs/40 Proceso/Setup y herramientas` con la versión instalada de cada herramienta y cualquier problema encontrado (marca la fase como completada en la nota de fases).
5. Reporta al usuario una tabla resumen: herramienta → versión → estado (OK/FALTA).

NO empieces ninguna otra fase. Solo setup.