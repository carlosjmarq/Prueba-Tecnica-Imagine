---
tags: [proceso, checklist, entrega]
status: entregado
date: 2026-09-11
---

# Checklist de la prueba

> Checklist oficial contra el enunciado de la prueba técnica. **Completado el 2026-09-11** (Fase 5, [[Fases del proyecto]]). Todos los requerimientos verificados: tests verdes (backend pytest + flutter analyze/test), CI/CD operativos y deploy real en AWS.

## Requerimientos funcionales

- [x] Autenticación JWT para Customer y Driver ([[API Autenticacion]])
- [x] Customer: crear pedidos, consultar pedidos y ver estado ([[API Pedidos y estados]])
- [x] Driver: listar pedidos disponibles, aceptar pedidos y actualizar estado
- [x] Estados: Pending, Accepted, Picked Up, Delivered y Cancelled ([[Modelo de datos]])
- [x] Notificación realtime de cambios de estado (WS/SSE) ([[Realtime]])

## Apps Flutter

- [x] Customer App: Login, Registro, Crear pedido, Lista y detalle de pedidos ([[Apps moviles implementadas]])
- [x] Driver App: Login, Lista de pedidos, Aceptar pedido y actualizar estado ([[Apps moviles implementadas]])

## Base de datos

- [x] Modelo relacional PostgreSQL con migraciones Alembic ([[Modelo de datos]])

## Infraestructura cloud (obligatorio)

- [x] README explica cómo desplegar PostgreSQL en AWS RDS (instancia, backups, HA) ([[RDS PostgreSQL]])
- [x] StorageService para imágenes: siempre S3 (MinIO en dev, AWS S3 en prod) ([[StorageService]])
- [x] Subida de imágenes en las apps: foto por ítem (customer) y comprobante de entrega (driver) ([[ADR-009 Subida de imagenes proxy autenticado y comprobante de entrega]])
- [x] Diagrama de arquitectura: EC2, RDS, S3, CloudFront, Load Balancer, WebSocket, Security Groups ([[Arquitectura AWS]])
- [x] Proyecto dockerizado ([[Docker y despliegue]])

## Puntos extra

- [x] Rate Limiting ([[API Autenticacion]])
- [x] Refresh Tokens ([[API Autenticacion]])
- [x] Tests automatizados ([[Testing y calidad]])
- [x] Swagger documentado (`/docs`)
- [x] GitHub Actions ([[Docker y despliegue]])
- [x] Deploy
- [x] Carga real a AWS S3 ([[S3 y CloudFront]])
- [x] Proceso Lambda identificado y justificado ([[Lambda]])
- [x] Uso de CloudFront explicado ([[S3 y CloudFront]])
- [x] Logging estructurado + monitoreo CloudWatch ([[CloudWatch y logging]])

## Entregables

- [x] Repositorio(s) Git ([[ADR-008 Monorepo unico]]; ver también [[ADR-002 Estructura multi-repositorio]])
- [x] README con instrucciones (cada repo)
- [x] Migraciones
- [x] Mock data sembrable dev/prod ([[Seed de datos]])
- [x] Diagrama de arquitectura
- [ ] Video opcional ≤ 5 min ([[Guion video]]) — **no incluido** (opcional)

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Fases del proyecto]], [[Guion video]]