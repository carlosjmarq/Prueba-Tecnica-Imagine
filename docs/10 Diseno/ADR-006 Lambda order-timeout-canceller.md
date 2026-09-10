---
tags: [adr, decision, infra, lambda, serverless]
status: Aceptado
date: 2026-09-10
---

# ADR-006: Lambda `order-timeout-canceller`

## Status

**Aceptado**

## Contexto

Los pedidos que entran en estado `PENDING` deben ser aceptados por un driver en un
tiempo razonable (`ORDER_TIMEOUT_MINUTES`, ej. 15 min). Si ningún driver los acepta,
quedan huérfanos: ocupan lugar en las listas, ensucian métricas y el customer nunca
recibe una respuesta. Se necesita un proceso automático que los cancele.

Opciones evaluadas:

1. **Tarea Celery / worker dedicado**: agrega infraestructura persistente (broker,
   worker, scheduler) solo para ejecutar una query cada pocos minutos. Sobredimensionado
   para la prueba.
2. **Cron en EC2**: una instancia extra encendida 24/7 que corre un script. Coste fijo y
   un servidor más que operar, sin beneficio frente a serverless.
3. **Lambda invocada por EventBridge**: serverless, sin servidor que mantener, coste casi
   nulo y desacoplada del ciclo de vida del API.

## Decisión

Implementar el proceso como una **función AWS Lambda** (`order-timeout-canceller`)
invocada por una **regla de EventBridge** con programación `cron` **cada 5 minutos**.

Comportamiento:

1. EventBridge dispara la Lambda cada 5 minutos.
2. La Lambda se conecta a **RDS PostgreSQL** usando su propio **security group** (SG de
   la Lambda autorizado en el SG de RDS, puerto 5432).
3. Selecciona los pedidos `PENDING` cuyo `created_at` supera el timeout.
4. Transiciona a `CANCELLED` con **guard en el `UPDATE`**:
   `UPDATE orders SET status='CANCELLED' WHERE id=:id AND status='PENDING'`. Esto evita
   pisar una aceptación concurrente de un driver (misma máquina de estados del dominio).
5. Inserta la transición en `order_status_history` (mismo dominio que el API, ver
   [[Modelo de datos]]).
6. Emite **logs estructurados JSON** a CloudWatch (ver [[CloudWatch y logging]]).

Detalles técnicos:

- **Runtime:** Python 3.12 (mismo lenguaje del proyecto).
- **Driver de DB:** `pg8000` (pure Python) para evitar dependencias binarias en el
  paquete de despliegue de Lambda.
- **Configuración:** timeout, credenciales y `ORDER_TIMEOUT_MINUTES` se inyectan por
  variables de entorno; los secretos viven en **SSM Parameter Store** (la Lambda necesita
  VPC + permisos SSM, ver [[Docker y despliegue]]).
- **Infraestructura:** `aws_lambda_function` + `aws_cloudwatch_event_rule` +
  `aws_cloudwatch_event_target` en `infra/terraform/modules/lambda/`; código en
  `infra/functions/order_timeout_canceller/`.

Alternativas descartadas: Celery/worker (infra persistente extra) y cron en EC2
(instancia 24/7).

## Consecuencias

### Positivas

- **Coste ~0**: se paga por invocación y, si no hay pedidos pendientes, el gasto es
  prácticamente nulo.
- **Sin servidor**: no hay instancia que mantener, parchear ni escalar.
- **Independiente del API**: el ciclo de vida del proceso no compite con el servicio web.

### Negativas / Trade-offs

- **Latencia de hasta 5 min**: un pedido puede tardar hasta un ciclo de cron en
  cancelarse; es aceptable para el timeout de negocio.
- **No emite realtime** en esta simplificación: el cambio de estado no se propaga por
  WebSocket de inmediato (ver [[Realtime]]); se refleja al siguiente fetch del cliente.
- **Requiere VPC + SSM**: la Lambda debe correr dentro de la VPC para alcanzar RDS y
  leer sus secretos, lo que añade configuración de red e IAM.

### Neutrales

- Usa la **misma máquina de estados del dominio** (`PENDING → CANCELLED`) y el mismo
  registro en `order_status_history`, así que no introduce un modelo paralelo.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Afecta a:** [[Lambda]], [[API Pedidos y estados]], [[Arquitectura AWS]]
- **Relacionada con:** [[Modelo de datos]], [[CloudWatch y logging]], [[Docker y despliegue]]
- **Repo:** `infra` (Terraform: `infra/terraform/modules/lambda/`, código en `infra/functions/order_timeout_canceller/`)
