---
tags: [proceso, deploy, aws, automatizacion]
status: vigente
date: 2026-09-10
---

# Deploy AWS automatizado

> Herramienta CLI única para desplegar toda la infraestructura AWS con las herramientas ya instaladas (AWS CLI, OpenTofu, Docker, Python). Cross-platform: PowerShell 7 (Windows y Linux).

## Script

`scripts/deploy-aws.ps1` — automatiza el ciclo completo de la Fase 4 ([[Fases del proyecto]]):

| Etapa      | Qué hace                                                        | Requiere   |
| ---------- | --------------------------------------------------------------- | ---------- |
| `verify`   | Toolchain + identidad AWS (`sts get-caller-identity`)           | AWS CLI    |
| `bootstrap`| State bucket S3 + tabla DynamoDB de lock (idempotente)          | AWS CLI    |
| `lambda`   | Empaqueta el zip de `order-timeout-canceller` (pg8000)          | Python     |
| `apply`    | `tofu init` + `plan` + `apply` (crea VPC/RDS/S3/EC2/Lambda...)  | OpenTofu   |
| `image`    | `docker login` ECR + build + push de la API                     | **Docker** |
| `refresh`  | Instance refresh del ASG para que tome la imagen nueva          | AWS CLI    |
| `migrate`  | `alembic upgrade head` vía SSM Run Command en la instancia      | AWS CLI    |
| `check`    | Compara AWS actual contra el baseline                            | AWS CLI    |

## Uso

```powershell
# Pipeline completo (recomendado). Pide db_password/email SNS si no estan en tfvars.
pwsh -File scripts/deploy-aws.ps1 deploy

# Etapas individuales
pwsh -File scripts/deploy-aws.ps1 verify     # pre-check del toolchain
pwsh -File scripts/deploy-aws.ps1 state      # captura baseline del estado esperado
pwsh -File scripts/deploy-aws.ps1 check      # compara AWS actual vs baseline
pwsh -File scripts/deploy-aws.ps1 migrate    # solo migraciones
pwsh -File scripts/deploy-aws.ps1 apply      # solo terraform apply

# Flags utiles
pwsh -File scripts/deploy-aws.ps1 deploy -AutoApprove   # sin confirmar
pwsh -File scripts/deploy-aws.ps1 deploy -Skip image    # si Docker no esta disponible
pwsh -File scripts/deploy-aws.ps1 refresh -Only refresh # una sola etapa
```

## Requisitos

- Cuenta AWS configurada en el CLI (`aws configure`), con permisos para crear los recursos.
- `aws`, `tofu` (OpenTofu), `docker`, `python`, `uv` en el PATH.
- **Docker solo es necesario en la etapa `image`** (la API corre como contenedor en EC2). Si no hay Docker, usar `deploy -Skip image` y subir la imagen por CI.
- `terraform.tfvars` (gitignored) con `db_password` y `sns_email`; el script los genera/pide si faltan.

## Baseline (estado esperado)

- `infra/terraform/envs/dev/baseline.json` (gitignored) captura el estado de referencia:
  - **Hard assertions** (deben coincidir tras re-deploy): config RDS, ASG, S3, Lambda, SSM params, log groups, SNS, tablas de BD, versiones Alembic, health `/health`.
  - **Volátiles (info)**: ALB DNS, CloudFront domain, RDS endpoint (cambian si se pierde el state).
- Flujo de validación: `state` antes del re-deploy → `deploy` → `check` sin drift.

## GitHub Actions (CD) — configurado y verificado (2026-09-11)

El CD (`deploy.yml`) asume un rol IAM vía **OIDC** de GitHub. Requisitos ya creados en la cuenta `646364595364`:

| Recurso                     | Valor |
| --------------------------- | ----- |
| OIDC provider               | `arn:aws:iam::646364595364:oidc-provider/token.actions.githubusercontent.com` (client-id `sts.amazonaws.com`) |
| IAM role                   | `github-actions-deploy` (trust OIDC restringido al repo `carlosjmarq/Prueba-Tecnica-Imagine`, policy `AdministratorAccess`) |
| Secret `TF_DB_PASSWORD`     | password de RDS (mismo valor que `terraform.tfvars`) |
| Secret `TF_SNS_EMAIL`       | email de alertas SNS |
| Variable `AWS_DEPLOY_ROLE_ARN` | `arn:aws:iam::646364595364:role/github-actions-deploy` |

> **Nota sobre el `sub` OIDC**: GitHub usa el formato nuevo con IDs
> (`repo:{owner}@{owner_id}/{repo}@{repo_id}:ref:...`). El trust policy acepta ese
> formato y el legacy (`repo:carlosjmarq/Prueba-Tecnica-Imagine:*`). Si se renombra
> el repo o la org, actualizar el trust.
>
> **Nota de seguridad**: el rol lleva `AdministratorAccess` por simplicidad en esta
> prueba; para producción conviene un policy scoped a los recursos del módulo.

Verificación: CI verde (backend tests con Postgres+MinIO, mobile analyze+test con
Flutter **3.22.1** pinned, infra `tofu validate`) y CD completo verde
(build/push ECR + `tofu apply` sin drift, 2 cambios in-place: AMI y Lambda).

## Notas

- El state vive en S3 (`imagine-delivery-tfstate-<account>`), así que un re-deploy sobre el mismo state **preserva** los IDs de recursos.
- Migraciones Alembic idempotentes: `alembic upgrade head` solo aplica lo pendiente.
- CI/CD: `deploy.yml` (GitHub Actions) hace build→ECR y `tofu apply` con OIDC; la herramienta local es la vía manual equivalente.
- **Arreglos de CI detectados en 2026-09-11**:
  - Job backend ahora levanta Postgres + MinIO con `docker-compose.base.yml` en el runner (los tests requieren `localhost:5434` y `:9000`).
  - Job mobile pinea **Flutter 3.22.1** (el código usa APIs de Dart 3.4; el stable 3.47 rompía con `CardTheme`/`google_fonts`).
  - Job infra corregido: `tofu validate` con `working-directory: infra/terraform/envs/dev`.
  - `ensure_bucket` en `StorageService` tolera que MinIO no implemente `PutPublicAccessBlock` (best-effort).

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Fases del proyecto]], [[Docker y despliegue]], [[Checklist de la prueba]]
- **Repo:** `scripts/deploy-aws.ps1`