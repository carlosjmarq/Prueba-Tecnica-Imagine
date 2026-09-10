---
tags: [adr, decision, imagenes, s3, presigned, storage, uploads]
status: Propuesto
date: 2026-09-10
---

# ADR-011: Subida directa con Presigned URLs (escritura) + proxy autenticado (lectura)

## Status

**Aceptado**

## Contexto

Las subidas de imágenes pasaban por la API como proxy multipart (`POST /uploads/images`): el servidor leía el body completo en memoria (`file.read()`, hasta 5 MB), validaba y re-subía a S3/MinIO con boto3 en un hilo. Esto coloca al backend en el **camino caliente** de los datos:

- Consume memoria (hasta 5 MB por request) y doble ancho de banda (cliente→API→S3).
- La concurrencia de subidas queda limitada por el ThreadPoolExecutor.
- No había progreso en tiempo real ni compresión previa.

Se evaluaron las mejores prácticas estándar: **Presigned URLs** (el backend firma una URL temporal de escritura y el cliente sube directo a S3), PUT sin `FormData`, `onSendProgress`, reintentos con backoff, compresión local (WebP) y CORS en el bucket.

## Decisión

1. **Escritura con Presigned URLs**: `POST /uploads/presign` valida la sesión, genera la key (`users/{uid}/images/{uuid}.{ext}`) y devuelve una **URL firmada de PUT** (boto3 `generate_presigned_url`, expira en 5 min, `Content-Type` firmado). El cliente sube directo con un dio **sin interceptor de auth** (la firma va en la URL; un header `Authorization` rompería la firma), con `Content-Type` exacto.
2. **Se mantiene `POST /uploads/images`** (proxy multipart) como fallback y `GET /uploads/images/{key}` como **proxy de lectura autenticado**.
3. **Lectura por proxy autenticado** (no CloudFront público): las imágenes son por usuario (ítems y comprobante). CloudFront con OAC haría las URLs públicas; para privacidad se necesitarían **signed URLs**. Se documenta como opción de prod.
4. **Progreso en tiempo real**: `onSendProgress` de dio, con **barra por imagen** en customer y driver.
5. **Compresión local**: `flutter_image_compress` → **WebP** (quality 70) antes de subir; `image_picker` con `maxWidth`/`maxHeight`/`imageQuality`.
6. **Reintentos con exponential backoff** (0.5s→1s→2s) para el PUT directo (idempotente).
7. **CORS**: reglas documentadas (GET/PUT/HEAD + headers) para entornos web. MinIO (este build) no implementa bucket CORS → se aplican en AWS S3 vía terraform.

## Consecuencias

### Positivas

- El backend deja de ser el "middle-man" de los bytes: menos RAM y bandwidth, subidas concurrentes casi ilimitadas.
- Progreso real por imagen (UX) y payload reducido con WebP.
- La lectura sigue siendo privada por usuario vía el proxy autenticado.

### Negativas / Trade-offs

- El servidor ya no valida el tamaño en la escritura (la firma no lo cubre); mitigado con compresión local (~300 KB). Opcional: `HEAD` post-subida o Lambda.
- `Content-Type` queda firmado: el cliente debe enviarlo exacto.
- Más piezas móviles: endpoint de presign, dio sin interceptor, CORS (solo web).
- Keys las genera el servidor (UUID), no el cliente.

### Neutrales

- El proxy `POST /uploads/images` se conserva como fallback y para tests.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Afecta a:** [[StorageService]], [[S3 y CloudFront]], [[API Implementada]], [[Apps moviles implementadas]], [[Testing y calidad]]
- **Relacionada con:** [[ADR-009 Subida de imagenes proxy autenticado y comprobante de entrega]], [[ADR-010 WebSocket robusto heartbeat y sin sesion por conexion]]
- **Repo:** `backend` (`app/api/routes/uploads.py`, `app/services/storage.py`), `mobile/packages/shared`, apps