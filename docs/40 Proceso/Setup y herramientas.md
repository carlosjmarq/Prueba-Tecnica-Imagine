---
tags: [proceso, setup, herramientas]
status: borrador
date: 2026-09-08
---

# Setup y herramientas

> Fase 0 — Toolchain completo para el proyecto. Ejecutar `scripts/setup.ps1` (idempotente).

## Herramientas requeridas

| Herramienta         | Versión mínima | Uso                              | Instalación (Windows)           |
| ------------------- | -------------- | -------------------------------- | ------------------------------- |
| Python              | 3.12+          | Backend FastAPI                  | winget Python.Python.3.12       |
| uv                  | 0.5+           | Gestor de dependencias Python    | `pip install uv` o winget       |
| Flutter SDK         | 3.24+ (stable) | Apps móviles                     | git clone o winget (ver nota)   |
| Dart                | 3.5+           | Con Flutter                       | incluido en Flutter SDK         |
| Docker Desktop      | 24+            | PostgreSQL, MinIO, builds        | winget Docker.DockerDesktop     |
| AWS CLI v2         | 2.x            | Interacción con AWS              | winget Amazon.AWSCLI            |
| Session Manager     | plugin         | Acceso a instancias EC2          | MSI de AWS                      |
| Terraform           | 1.8+           | IaC                               | winget Hashicorp.Terraform      |
| GitHub CLI (gh)    | 2.x            | Repos, PRs, releases             | winget GitHub.cli               |
| Node.js            | 20+            | npx skills, tooling              | winget OpenJS.NodeJS            |
| Git                | 2.40+          | Control de versiones             | winget Git.Git                  |
| MinIO (Docker)     | latest         | S3 local (dev)                   | imagen docker minio/minio       |

## Verificación

Después de instalar, ejecutar `scripts/verify.ps1` o revisar:

```powershell
python --version        # 3.12.x
uv --version            # 0.5.x
flutter --version       # stable 3.x
docker version          # client+server OK
aws --version           # aws-cli/2.x
terraform version       # v1.8.x
gh --version            # gh version 2.x
```

## Infraestructura local

Levantar servicios base con Docker Compose (PostgreSQL 16 + MinIO):

```powershell
docker compose -f infra/docker-compose.base.yml up -d
```

O **levantar todo el proyecto de una vez** (infra + migraciones + API en `:8000`):

```powershell
powershell -ExecutionPolicy Bypass -File scripts/dev.ps1     # -Reload para hot reload
powershell -ExecutionPolicy Bypass -File scripts/dev.ps1 -Stop   # detiene todo
```

Lanzar las apps Flutter (customer y driver, cada una en su ventana):

```powershell
powershell -ExecutionPolicy Bypass -File scripts/apps.ps1            # ambas
powershell -ExecutionPolicy Bypass -File scripts/apps.ps1 -App customer
powershell -ExecutionPolicy Bypass -File scripts/apps.ps1 -ApiUrl http://10.0.2.2:8000  # emulador Android
```

Probar S3 local con MinIO: `http://localhost:9001` (consola, minioadmin/minioadmin).

Colección de Insomnia para probar la API: importar `scripts/insomnia/delivery-api-insomnia.json`
(login alimenta el token de las requests de pedidos automáticamente).

## Estado actual

| Herramienta | Versión instalada | Estado |
| ----------- | ----------------- | ------ |
| Python      | 3.12.3            | ✅     |
| uv          | 0.12.10 (winget)  | ✅ (reiniciar terminal) |
| Flutter     | SDK en `%LOCALAPPDATA%\flutter` | ✅ |
| Docker      | 29.4.2            | ✅ daemon activo |
| AWS CLI     | 2.35.5            | ✅ |
| SSM plugin  | 1.2.835.0         | ✅ (PATH añadido) |
| Terraform   | OpenTofu 1.12.6   | ✅ (ver nota bloqueo) |
| gh          | instalado         | ✅ (PATH añadido) |
| Node        | v24.14.1          | ✅ |
| Git         | 2.45.1            | ✅ |

> **Nota Terraform/OpenTofu**: `releases.hashicorp.com` está bloqueado por controles de exportación en esta región (404 desde winget y descargas directas). Se instaló **OpenTofu 1.12.6** (fork open source de Terraform, HCL 100% compatible) desde GitHub releases en `C:\Users\carlo\opentofu`. El código HCL de Terraform funciona igual; documentar el estado en infra.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Fases del proyecto]], [[Testing y calidad]], [[Docker y despliegue]]
- **Scripts:** `scripts/setup.ps1`, `scripts/verify.ps1`