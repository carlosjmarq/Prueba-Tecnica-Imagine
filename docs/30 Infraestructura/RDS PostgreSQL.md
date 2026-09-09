---
tags: [infra, aws, rds, postgres]
status: borrador
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
| Parameter group      | `rds.force_ssl=1`            | TLS obligatorio                      |

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

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Arquitectura AWS]], [[Modelo de datos]], [[Docker y despliegue]]
- **Repo:** `infra` (Terraform: `modules/rds/`)