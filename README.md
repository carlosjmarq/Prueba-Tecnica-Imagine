# Prueba Técnica Imagine — Plataforma de delivery

Monorepo único `imagine-delivery` (ver [[ADR-008 Monorepo unico]] en el vault):
backend FastAPI, apps Flutter, infraestructura AWS y documentación en vault Obsidian.

## Estructura

```
imagine-delivery/
├── AGENTS.md              # Workflow de IA (fases, convenciones, calidad)
├── opencode.json          # Config de opencode: skills, agentes, permisos
├── .opencode/
│   ├── agent/             # Agentes: backend, mobile, infra, docs
│   └── command/           # Comandos de fase: /setup /backend /apps /infra ...
├── .agents/skills/        # Skills del proyecto (npx skills)
├── backend/               # API FastAPI (app/, alembic/, tests/)
├── mobile/                # Apps Flutter
│   ├── customer_app/      #   App del cliente
│   ├── driver_app/        #   App del repartidor
│   └── packages/shared/   #   Código compartido
├── infra/                 # OpenTofu, CI/CD, docker-compose
├── docs/                  # Vault Obsidian (ADRs, notas técnicas, infra)
├── scripts/
│   ├── setup.ps1          # Fase 0: instala el toolchain completo
│   ├── dev.ps1            # Levanta todo el proyecto (infra + migraciones + API)
│   ├── apps.ps1           # Lanza las apps Flutter (customer y/o driver)
│   ├── seed.ps1           # Mock data bajo demanda (dev/prod)
│   ├── verify.ps1         # Verifica el toolchain
│   └── insomnia/          # Colección de Insomnia para probar la API
└── .github/workflows/     # CI con filtros por path
```

## Fases del proyecto

| # | Fase          | Comando          | Contenido |
| - | ------------- | ---------------- | --------- |
| 0 | Setup         | `/setup`         | Toolchain completo (verificado) |
| 1 | Fundaciones   | `/foundations`   | Esqueleto del monorepo + ADRs iniciales |
| 2 | Backend       | `/backend`       | Auth JWT, pedidos, estados, WS, S3-ready, tests |
| 3 | Apps móviles  | `/apps`          | Customer App + Driver App |
| 4 | Infraestructura | `/infra`       | Terraform AWS, diagrama, GitHub Actions |
| 5 | Entrega       | `/deliver`       | READMEs, checklist, video |

Estado en `docs/40 Proceso/Fases del proyecto`.

> **CI/CD**: el CI (backend + mobile + infra) y el CD (ECR + `tofu apply` vía OIDC)
> están verificados en verde. Requisitos de GitHub: secrets `TF_DB_PASSWORD`/`TF_SNS_EMAIL`,
> variable `AWS_DEPLOY_ROLE_ARN` y el rol IAM `github-actions-deploy` (ver `docs/40 Proceso/Deploy AWS automatizado`).

## Primeros pasos

```powershell
# 1. Verificar/instalar el toolchain (Python, uv, Flutter, Docker, AWS CLI, OpenTofu...)
powershell -ExecutionPolicy Bypass -File scripts\setup.ps1

# 2. Levantar TODO el proyecto (Postgres + MinIO + migraciones + API)
powershell -ExecutionPolicy Bypass -File scripts\dev.ps1          # con hot reload: -Reload
#   Detener todo: powershell -ExecutionPolicy Bypass -File scripts\dev.ps1 -Stop

# 3. Lanzar las apps Flutter (customer y driver, cada una en su ventana)
powershell -ExecutionPolicy Bypass -File scripts\apps.ps1
#   Solo una app: -App customer | -App driver
#   Emulador Android: apuntar al host con -ApiUrl http://10.0.2.2:8000

# 4. Ejecutar las fases con los comandos de opencode: /backend, /apps, ...
```

La API queda en `http://127.0.0.1:8000` (Swagger en `/docs`). Para probar los endpoints con Insomnia, importar `scripts/insomnia/delivery-api-insomnia.json` (colección con request chaining: el login alimenta el token de los pedidos).

## Datos de prueba (mock data)

`dev.ps1` aplica migraciones (incluye el seed). Si no, sembrar bajo demanda:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\seed.ps1 -Env dev   # BD local
powershell -ExecutionPolicy Bypass -File scripts\seed.ps1 -Env prod  # entorno AWS (pide confirmación)
powershell -ExecutionPolicy Bypass -File scripts\seed.ps1 -Env prod -Reseed -Force   # reponer datos
```

Usuarios demo (password `password123`): `customer1@`, `customer2@`, `driver1@`, `driver2@example.com`. El deploy (`deploy-aws.ps1`) incluye la etapa `seed`; usar `-NoSeed` para deshabilitarla. Más detalle en `docs/20 Tecnico/Seed de datos`.

## Documentación (vault Obsidian)

Toda decisión, funcionalidad e infraestructura se documenta en `docs/` con wikilinks.
Empezar por `docs/00 Inbox/MOC.md`. ADRs en `docs/10 Diseno/`.

## Skills del proyecto

Instaladas en `.agents/skills/` (gestionadas con `npx skills`): fastapi, fastapi-python,
fastapi-templates, flutter, sqlalchemy-alembic, websocket-realtime-builder, pytest-skill,
localstack-deploy, obsidian.

## Prueba técnica

Enunciado y checklist: `docs/40 Proceso/Checklist de la prueba`.