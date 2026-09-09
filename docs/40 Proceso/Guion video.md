---
tags: [proceso, video, entrega]
status: borrador
date: 2026-09-08
---

# Guion video

> Guión opcional para el video de máx. 5 minutos de la prueba técnica.

## Estructura (5 min)

1. **Intro (0:30)** — Qué es la plataforma y el stack elegido.
2. **Demo Customer (1:30)** — Registro/login → crear pedido → ver estado en tiempo real.
3. **Demo Driver (1:30)** — Login → ver pedidos disponibles → aceptar → cambiar estado → realtime al customer.
4. **Arquitectura (1:00)** — Diagrama: EC2/ALB, RDS Multi-AZ, S3+CloudFront, CloudWatch, Lambda. 30 seg explicando por qué.
5. **Cierre (0:30)** — Puntos extra cubiertos (rate limiting, refresh, tests, CI/CD, logging) y repo(s) del entregable.

## Notas

- Grabar en ventana con resolución ≥ 1080p.
- Tener listas: 2 emuladores (customer/driver) + Postman/Swagger en `/docs`.
- Ensayar los flujos realtime (aceptar pedido en driver → ver el cambio en customer sin refrescar).

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Checklist de la prueba]], [[Fases del proyecto]]