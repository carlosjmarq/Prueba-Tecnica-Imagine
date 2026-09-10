---
tags: [infra, aws, cloudwatch, logging]
status: vigente
date: 2026-09-08
---

# CloudWatch y logging

> Logging estructurado en el backend y monitoreo con CloudWatch.

## Logging estructurado (JSON)

- Librería `structlog` (o logging estándar con formatter JSON).
- Cada línea de log es JSON con campos consistentes:

```json
{
  "timestamp": "2026-09-08T12:00:00Z",
  "level": "INFO",
  "event": "order.accepted",
  "logger": "app.services.orders",
  "request_id": "550e8400-...",
  "order_id": "7b4a...",
  "driver_id": "c9d1...",
  "duration_ms": 42
}
```

- `request_id` se genera por petición (middleware) y se propaga a WS y logs de dominio.
- Niveles: DEBUG (dev), INFO (negocio), WARNING/ERROR (fallos), siempre con contexto.

## CloudWatch

| Recurso             | Qué recoge                                              |
| ------------------- | ------------------------------------------------------- |
| **Log Groups**      | `/aws/ec2/delivery-api`, `/aws/alb/delivery`, `/aws/lambda/delivery-order-timeout` |
| **Log Streams**     | por instancia/contenedor                                 |
| **Métricas**        | custom: `orders.created`, `orders.accepted`, `ws.connections`, latencias, errores 4xx/5xx |
| **Alarmas**         | 5xx > X% (5 min), latencia p95 > umbral, RDS CPU > 80%, free storage < 20% → SNS |
| **Dashboards**      | panel delivery: API + RDS + ALB + Lambda                  |

El agente en EC2 (CloudWatch Agent) envía logs del contenedor/uvicorn y métricas de disco/CPU; RDS y ALB envían métricas nativas.

## Alertas (ejemplo)

```hcl
resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "delivery-api-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

> **Implementación (Fase 4, 2026-09-10):** módulo `infra/terraform/modules/observability/`.
> Crea los 3 log groups (retención 14 días), el topico SNS `delivery-alerts` con
> suscripción email, las alarmas ALB 5XX > 10 (2×300 s), RDS CPU > 80% y RDS
> `FreeStorageSpace` < 20% del almacenamiento asignado (todas con acción al SNS),
> y un dashboard `delivery-dev` con widgets de ALB y RDS. Los logs del contenedor
> llegan con el driver Docker `awslogs` (rol de instancia con `CloudWatchAgentServerPolicy`).

## Estado real (deploy 2026-09-10)

- Log groups creados y recibiendo logs: `/aws/ec2/delivery-api`, `/aws/alb/delivery`, `/aws/lambda/delivery-order-timeout` (retención 14 días).
- SNS `delivery-alerts` con suscripción email (`carlosjwriter01@gmail.com`) y alarmas activas: ALB 5xx, RDS CPU y RDS free storage.
- Dashboard `delivery-dev` desplegado con widgets de ALB y RDS; los logs del contenedor llegan vía driver Docker `awslogs`.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Arquitectura AWS]], [[Testing y calidad]]
- **Repo:** `backend` (middleware logging) y `infra` (Terraform: `modules/observability/`)