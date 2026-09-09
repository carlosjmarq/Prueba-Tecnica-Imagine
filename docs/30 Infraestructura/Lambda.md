---
tags: [infra, aws, lambda, serverless]
status: borrador
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
3. Transiciona a `CANCELLED` (con `reason=timeout`) y emite evento por el canal realtime (si aplica, vía API/WebSocket o se omite en esta simplificación).
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
- VPC: conectada a la DB privada vía security group + `rds-proxy` si se requiere (o endpoint de red).
- IAM: `lambda:InvokeFunction` desde EventBridge, `s3:PutObject` (logs) / CloudWatch Logs.
- Terrasform: `aws_lambda_function` + `aws_cloudwatch_event_rule` + `aws_cloudwatch_event_target`.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[API Pedidos y estados]], [[Arquitectura AWS]]
- **ADR:** crea `ADR-006 Lambda order-timeout-canceller` al implementar
- **Repo:** `infra` (Terraform: `modules/lambda/`, código en `functions/`)