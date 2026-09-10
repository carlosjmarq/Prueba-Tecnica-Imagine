---
tags: [infra, aws, lambda, serverless]
status: vigente
date: 2026-09-08
---

# Lambda

> Proceso identificado para AWS Lambda y justificación.

## Proceso elegido: `order-timeout-canceller`

**Función:** cancelar automáticamente pedidos `PENDING` que ningún driver aceptó dentro de `ORDER_TIMEOUT_MINUTES` (ej. 15 min).

### Justificación

| Criterio              | ¿Por qué encaja Lambda?                                   |
| --------------------- | --------------------------------------------------------- |
| Evento discreto       | Timer programado (EventBridge `cron` cada 1–5 min)        |
| Baja duración         | Query batch + updates atómicos, segundos de ejecución     |
| Baja frecuencia       | No es tráfico de usuarios; no merece servidor dedicado    |
| Independiente del API | No comparte estado con el servicio web                     |
| Coste                 | ~0 si no hay pedidos pendientes (pago por invocación)     |
| Operación sencilla    | No requiere autoscaling ni deploy de la API                |

Alternativas descartadas: tarea Celery/worker (agrega infraestructura persistente y colas); cron en EC2 (instancia extra 24/7).

## Comportamiento

1. EventBridge invoca la Lambda cada N minutos.
2. La Lambda consulta pedidos `PENDING` con `created_at < now - timeout`.
3. Transiciona a `CANCELLED` con guard en el `UPDATE` y registra el cambio en `order_status_history`.
4. Registra en `order_status_history` (mismo dominio que el API).

## Código (resumen)

```python
def handler(event, context):
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=ORDER_TIMEOUT_MINUTES)
    ids = query_pending_older_than(cutoff)      # SELECT id FROM orders WHERE status='PENDING' AND created_at < cutoff
    for order_id in ids:
        transition(order_id, "CANCELLED", reason="timeout")
    return {"cancelled": len(ids)}
```

- Runtime: Python 3.12 (mismo lenguaje del proyecto).
- VPC: subnets privadas + `sg_lambda` (autorizado en el SG de RDS); el egress sale por NAT para leer SSM.
- IAM: `AWSLambdaVPCAccessExecutionRole` + `AWSLambdaBasicExecutionRole` + `ssm:GetParameter`/`kms:Decrypt`.
- Terraform: `aws_lambda_function` + `aws_cloudwatch_event_rule` (`cron(0/5 * * * ? *)`) + `aws_cloudwatch_event_target`.

> **Implementación (Fase 4, 2026-09-10):** módulo `infra/terraform/modules/lambda/` y
> código en `infra/functions/order_timeout_canceller/` (`lambda_function.py` + `build.ps1`
> que empaqueta `pg8000` pure-python en `package/`). Lee `delivery/db/url` y
> `delivery/db/password` de SSM en runtime con boto3, conecta con `pg8000` (SSL) y
> cancela los `PENDING` con `created_at` anterior al cutoff, devolviendo `{"cancelled": n}`
> y un log JSON. Ver [[ADR-006 Lambda order-timeout-canceller]].

## Estado real (deploy 2026-09-10)

- Función **`delivery-order-timeout-canceller`** desplegada (python3.12, pg8000, VPC, cron cada 5 min) y **verificada en real**: devuelve `{"cancelled": 0}`.
- Conecta a RDS con `pg8000` en modo autocommit nativo: se eliminó el `commit()` explícito que fallaba en runtime.
- Empaquetado de `pg8000` (pure-python) vía `build.ps1`; lee `/delivery/db/url` y `/delivery/db/password` de SSM.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[API Pedidos y estados]], [[Arquitectura AWS]]
- **ADR:** [[ADR-006 Lambda order-timeout-canceller]] (Aceptado)
- **Repo:** `infra` (Terraform: `modules/lambda/`, código en `functions/`)