# Diagrama de arquitectura — Plataforma de delivery

> Entregable de la prueba técnica. Ver nota completa en [[30 Infraestructura/Arquitectura AWS]].

```mermaid
flowchart TB
    subgraph Clientes
        C[Customer App\nFlutter] --> CF[CloudFront]
        D[Driver App\nFlutter] --> CF
    end

    subgraph AWS
        CF --> ALB[Application Load Balancer\nTLS + HTTP/WS routing]
        ALB --> API1[EC2 - FastAPI\nREST + WebSocket]
        ALB --> API2[EC2 - FastAPI\n(autoscaling)]

        API1 --> RDS[(RDS PostgreSQL\nMulti-AZ, backups 7d)]
        API1 --> S3[(S3 Bucket\nimagenes, privado)]
        S3 --> CF

        LAMBDA[Lambda\norder-timeout-canceller] --> RDS
        EB[EventBridge\ncron 5 min] --> LAMBDA

        API1 --> CW[CloudWatch\nlogs JSON + metricas + alarmas]
        API2 --> CW
        ALB --> CW
        RDS --> CW

        subgraph VPC - Security Groups
            SG_ALB[SG-ALB\n443 desde internet]
            SG_API[SG-API\nsolo desde SG-ALB]
            SG_RDS[SG-RDS\n5432 solo desde SG-API]
            SG_LAMBDA[SG-Lambda\n5432]
        end
    end
```

## Componentes

| Componente    | Servicio       | Función                                    |
| ------------- | -------------- | ------------------------------------------ |
| CDN           | CloudFront     | HTTPS + cache de imágenes desde S3 (OAC)   |
| Routing       | ALB            | REST + WebSocket, TLS termination          |
| API           | EC2            | FastAPI (2+ instancias, autoscaling)       |
| DB            | RDS PostgreSQL | Multi-AZ, PITR, deletion protection        |
| Storage       | S3 + CloudFront| Imágenes de ítems (StorageService)         |
| Serverless    | Lambda         | Cancelar pedidos PENDING por timeout       |
| Observability | CloudWatch     | Logs JSON, métricas custom, alarmas → SNS  |

Ver también: [[30 Infraestructura/RDS PostgreSQL]], [[30 Infraestructura/S3 y CloudFront]],
[[30 Infraestructura/CloudWatch y logging]], [[30 Infraestructura/Lambda]], [[30 Infraestructura/Docker y despliegue]].