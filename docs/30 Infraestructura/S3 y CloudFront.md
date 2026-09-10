---
tags: [infra, aws, s3, cloudfront]
status: vigente
date: 2026-09-08
---

# S3 y CloudFront

> Almacenamiento de imágenes (StorageService) y distribución por CDN.

## S3

- Bucket privado `delivery-media-<env>` con:
  - `block_public_access = true` (el acceso público sale solo por CloudFront).
  - Versionado activado y lifecycle (transición a IA/Glacier después de 30/90 días).
  - Cifrado SSE-S3 por defecto.
- Acceso desde EC2 vía **IAM role** (`s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`), nunca credenciales estáticas.
- Keys por entidad: `orders/{order_id}/items/{item_id}.{ext}`.

## CloudFront

¿Por qué CloudFront?

1. **CDN global**: las imágenes (y el frontend si aplica) se sirven desde edge locations → latencia baja para customers/drivers.
2. **Coste**: las descargas salen por el edge (tarifa más barata que S3 directo + se reduce transferencia del bucket).
3. **Seguridad**: OAI/OAC — CloudFront firma las peticiones al bucket; S3 nunca se expone.
4. **HTTPS** en edge con certificado ACM (sin gestionar certs por app).

Configuración:

| Origen           | Behavior                       |
| ---------------- | ------------------------------ |
| `S3` (bucket)    | `/images/*` → cache 1 día, `Cache-Policy` con query strings |
| API (ALB)        | opcional para assets dinámicos (no necesario en la prueba) |

En `StorageService` ([[StorageService]]), `public_url()` devuelve `https://<distribution>.cloudfront.net/images/{key}`.

## CORS (subidas directas con presigned URLs)

Para que un navegador (build web) haga `PUT` directo al bucket con una presigned URL, S3 debe tener CORS. Reglas a aplicar en terraform:

```hcl
resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  cors_rule {
    allowed_origins = ["*"]
    allowed_methods = ["GET", "PUT", "HEAD"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
```

> Nota dev: MinIO (este build) **no implementa** bucket CORS (`PutBucketCors` → NotImplemented). Solo afecta a web; Android/emulador no requiere CORS. Script best-effort en `scripts/minio-cors.ps1` (avisa si MinIO no lo soporta).

## Contenido privado: signed URLs vs proxy

Las imágenes del proyecto son **por usuario** (fotos de ítems y comprobante de entrega). CloudFront con OAC sirve el bucket privado pero con **URLs públicas** (cualquiera con el enlace). Para contenido privado hay dos vías:

- **Proxy autenticado** `GET /uploads/images/{key}` (actual): el navegador/app envía el Bearer; S3 nunca se expone. Es la opción usada hoy.
- **CloudFront Signed URLs**: el backend firma URLs con expiración; CloudFront sirve directo (menor bandwidth del API) pero exige gestionar firmas. Documentado como opción de prod.

## Terraform (resumen)

```hcl
resource "aws_cloudfront_distribution" "media" {
  origin {
    domain_name = aws_s3_bucket.media.bucket_regional_domain_name
    origin_id   = "media"
    origin_access_control_id = aws_cloudfront_origin_access_control.media.id
  }
  default_cache_behavior {
    target_origin_id       = "media"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
  }
  viewer_certificate {
    cloudfront_default_certificate = true   # o ACM custom domain
  }
  restrictions { geo_restriction { restriction_type = "none" } }
}
```

> **Implementación (Fase 4, 2026-09-10):** módulo `infra/terraform/modules/s3_cloudfront/`.
> Bucket `delivery-media-<env>` privado (block public access total, versionado,
> SSE-S3 AES256, CORS para presigned PUT con `expose_headers=["ETag"]`, lifecycle
> STANDARD_IA 30d / GLACIER 90d), OAC y distribucion CloudFront con
> `CachingOptimized` (`658327ea-...`) y `redirect-to-https`. Exporta la policy IAM
> `delivery-media-rw` (Get/Put/Delete) que se adjunta al rol del EC2; el bucket
> policy solo permite `s3:GetObject` a CloudFront via OAC.

## Estado real (deploy 2026-09-10)

- Bucket real **`delivery-media-dev`** privado (block public access total, versioning, SSE-S3 AES256, CORS para presigned `PUT` con `expose_headers=["ETag"]`, lifecycle STANDARD_IA 30d / GLACIER 90d).
- Distribución CloudFront con **OAC**: `https://d3b1xgzyfgomor.cloudfront.net`.
- La **carga real a S3** se hizo por presigned URLs (subida directa desde las apps), verificada end-to-end; el bucket policy solo permite `s3:GetObject` a CloudFront vía OAC.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[StorageService]], [[Arquitectura AWS]]
- **Repo:** `infra` (Terraform: `modules/s3_cloudfront/`)