---
description: Fase 4 - Implementa la infraestructura AWS (Terraform, RDS, S3, EC2/ALB, CloudFront, CloudWatch, Lambda, GitHub Actions) y el diagrama de arquitectura.
agent: build
---

Ejecuta la Fase 4 — Infraestructura del proyecto aplicando el ciclo RPI (Research → Plan → Implement, ver `docs/40 Proceso/RPI Research Plan Implement`). Usa el agente `infra`.

Instrucciones:

1. **Research**: carga las skills (`localstack-deploy`) y revisa [[Arquitectura AWS]], [[RDS PostgreSQL]], [[S3 y CloudFront]], [[CloudWatch y logging]], [[Lambda]] y [[Docker y despliegue]].
2. **Plan**: decide el proceso Lambda (crear `ADR-006 Lambda order-timeout-canceller`) y cualquier desviación del plan antes de codificar Terraform.
3. **Implement**: codifica validando con `tofu validate` (OpenTofu, ver nota de bloqueo regional).
2. Entregables en `infra/`:
   - Diagrama de arquitectura (Mermaid o draw.io) en `docs/assets/diagrams/` con: EC2, RDS, S3, CloudFront, Load Balancer, WebSocket, Security Groups.
   - Terraform: VPC, Security Groups, RDS PostgreSQL (multi-AZ, backups, alta disponibilidad), S3 + CloudFront, ALB + EC2/ECS para la API (con soporte WebSocket), CloudWatch (logs, métricas, alarmas), IAM.
   - Un proceso Lambda identificado y justificado (en ADR).
   - GitHub Actions: CI (lint + tests) y CD (build imagen + deploy).
3. Documentación en el vault (`docs/30 Infraestructura`):
   - Cómo desplegar PostgreSQL en AWS RDS (instancia, backups, HA).
   - Uso de CloudFront (CDN, S3 origin).
   - Monitoreo con CloudWatch y logging estructurado.
   - ADR del proceso Lambda.
4. El proyecto debe estar dockerizado: Dockerfile del backend + docker-compose para prod-like (imagen de la API, Postgres, MinIO/S3).
5. Validación: `terraform validate` (y `plan` si hay credenciales), `docker build` OK, docs actualizadas.
6. Cierra con: infra/ con todo versionado, vault completo, README de infra actualizado.