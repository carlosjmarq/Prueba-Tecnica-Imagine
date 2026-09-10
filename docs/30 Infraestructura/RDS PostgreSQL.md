---
tags: [infra, aws, rds, postgres]
status: vigente
date: 2026-09-08
---

# RDS PostgreSQL

> Cómo desplegar PostgreSQL en AWS RDS: instancia, backups y alta disponibilidad.

## Instancia

| Parámetro            | Valor recomendado (demo)     | Notas                                |
| -------------------- | ---------------------------- | ------------------------------------ |
| Engine               | PostgreSQL 16                | compatible con el dev local          |
| Clase                | `db.t3.small` (demo)         | en prod: según carga                 |
| Storage              | gp3, 20–100 GB               | autoescalado opcional                |
| Multi-AZ             | **Sí** (HA)                  | replicación síncrona standby         |
| Backup retention     | 7 días (mín. recomendado)    | automáticos diarios + PITR           |
| VPC                  | Subnets privadas (2 AZ)      | sin IP pública                       |
| Security Group       | Solo 5432 desde SG-API       | nunca exponer a internet             |
| Parameter group      | default (sin `force_ssl`)    | `pg8000` conecta con SSL; no se obliga |

## Alta disponibilidad (Multi-AZ)

- RDS aprovisiona una **standby en otra AZ** con replicación síncrona de almacenamiento.
- Fallover automático (~60–120s) sin intervención; el endpoint DNS es el mismo.
- Para la prueba: **Multi-AZ sí o sí** como decisión de diseño; en `db.t3.small` el coste es bajo y demuestra criterio.

## Backups

- **Automáticos**: diarios en ventana configurable (ej. 02:00–03:00 UTC), retención 7 días, con **Point-in-Time Recovery** (PITR) a cualquier segundo dentro de la retención.
- **Manuales/snapshots**: antes de migraciones grandes (snapshot pre-deploy).
- Restore: consola/CLI/Terraform → `aws rds restore-db-instance-to-point-in-time`.

## Migraciones con Alembic

```
alembic upgrade head   # apunta a DATABASE_URL de producción (solo en ventana de deploy)
```

Estrategia: migraciones **aditivas** y reversibles (`downgrade`); backup antes de cada deploy; ejecutar desde CI con permisos restringidos (ver [[Docker y despliegue]]).

## Terraform (resumen)

```hcl
resource "aws_db_instance" "delivery" {
  identifier              = "delivery-db"
  engine                  = "postgres"
  engine_version          = "16.4"
  instance_class          = "db.t3.small"
  allocated_storage       = 20
  storage_type            = "gp3"
  multi_az                = true
  backup_retention_period = 7
  backup_window           = "02:00-03:00"
  deletion_protection     = true
  skip_final_snapshot     = false
  db_subnet_group_name    = aws_db_subnet_group.private.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
}
```

> **Implementación (Fase 4, 2026-09-10):** módulo `infra/terraform/modules/rds/`.
> `aws_db_instance` PostgreSQL 16.4, `db.t3.small`, gp3 20 GB, `multi_az=true`,
> `backup_retention_period=7`, ventana `02:00-03:00`, `deletion_protection=true`,
> `skip_final_snapshot=false` y `storage_encrypted=true`, en subnets privadas.
> Publica la URL asyncpg en SSM SecureString `delivery/db/url` y el password en
> `delivery/db/password`, consumidos por el EC2 (rol IAM) y la Lambda (`pg8000`).
> El parameter group queda por defecto, con `rds.force_ssl` sin activar.

## Estado real (deploy 2026-09-10)

- RDS PostgreSQL **16.13** en `eu-west-1` (16.4 no estaba disponible en la región al desplegar), `db.t3.small`, gp3 20 GB, **Multi-AZ**, backups 7 días con PITR y deletion protection.
- Migraciones Alembic aplicadas sobre la instancia real: `initial schema` + `add delivery proof key`.
- Credenciales publicadas en SSM SecureString `/delivery/db/url` y `/delivery/db/password` (nombres jerárquicos con `/` inicial); SG-RDS 5432 solo desde SG-API y SG-Lambda.
- Corrección durante el deploy: el SG-API abría el puerto 8000 (no solo el de origen) para el health check del ALB.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Arquitectura AWS]], [[Modelo de datos]], [[Docker y despliegue]]
- **Repo:** `infra` (Terraform: `modules/rds/`)