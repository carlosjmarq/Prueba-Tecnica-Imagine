---
tags: [tecnico, storage, s3, minio]
status: borrador
date: 2026-09-08
---

# StorageService

> Servicio de almacenamiento de imágenes de ítems de pedido y comprobantes de entrega. **Siempre apunta a S3** (misma implementación en todos los entornos); en desarrollo el endpoint S3 lo emula MinIO/LocalStack.

## Contrato

```python
class StorageService(Protocol):
    async def upload(self, key: str, data: bytes, content_type: str) -> str: ...
    async def get(self, key: str) -> tuple[bytes, str]: ...
    async def delete(self, key: str) -> None: ...
    def public_url(self, key: str) -> str: ...
```

## Implementación única: S3

No existe `LocalStorageService` ni filesystem: **todos los entornos usan `S3StorageService`** (cliente S3 de `boto3`). Lo único que cambia es el endpoint al que apunta:

| Entorno      | Endpoint S3                               | Bucket                          |
| ------------ | ----------------------------------------- | ------------------------------- |
| Desarrollo   | MinIO `http://localhost:9000` (S3-compatible) | `delivery-media` (local)     |
| CI/Tests     | MinIO en el runner (service container)    | `delivery-media` (test)         |
| Producción   | AWS S3 (`AWS_REGION`, IAM role)           | `delivery-media-<env>` (privado)|

Configuración por entorno (nunca cambia la implementación):

```
STORAGE_BACKEND=s3               # único valor soportado
S3_ENDPOINT_URL=http://localhost:9000   # solo dev/CI; vacío en prod (usa S3 real)
S3_BUCKET=delivery-media
S3_REGION=us-east-1
```

El `endpoint_url` se omite en producción para usar el endpoint real de AWS S3. En dev con MinIO se usa el cliente S3 apuntando a `http://localhost:9000` (skill `localstack-deploy` para el setup local).

## Endpoints relacionados

| Método | Ruta                      | Uso                          |
| ------ | ------------------------- | ---------------------------- |
| POST   | `/api/v1/uploads/images`  | Subir imagen → devuelve `key` + URL |
| GET    | `/api/v1/uploads/images/{key}` | **Proxy de lectura autenticado** (implementado) |

La lectura **en la app** se hace siempre por el proxy autenticado `GET /uploads/images/{key}` (requiere Bearer): funciona desde el emulador (`10.0.2.2`) y mantiene el bucket privado. En producción las imágenes se sirven por **CloudFront** con origen S3 y OAC (ver [[S3 y CloudFront]]); el `public_url` devuelve la URL de CloudFront en todos los entornos (en dev, la URL de MinIO).

> Decisión completa en [[ADR-009 Subida de imagenes proxy autenticado y comprobante de entrega]].

## Buenas prácticas

- Keys con prefijo por entidad: `orders/{order_id}/items/{item_id}.jpg`.
- Validar tipo MIME y tamaño máximo (ej. 5 MB) antes de subir.
- Presigned URLs para escritura directa cliente→S3 (opcional).
- No exponer el bucket: solo CloudFront público o acceso firmado (OAC).
- Bucket versionado + lifecycle rules para costes.
- Al ser la misma implementación S3 en todos los entornos, "carga real a AWS S3" solo exige cambiar `S3_ENDPOINT_URL` y credenciales: el código es idéntico en dev y prod.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Modelo de datos]], [[S3 y CloudFront]]
- **Repo:** `backend` (`app/services/storage/`)