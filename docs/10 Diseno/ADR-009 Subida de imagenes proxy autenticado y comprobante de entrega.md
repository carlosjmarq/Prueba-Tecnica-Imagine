---
tags: [adr, decision, imagenes, storage, s3, entrega]
status: Propuesto
date: 2026-09-10
---

# ADR-009: Subida de imágenes — proxy autenticado + comprobante de entrega

## Status

**Aceptado**

## Contexto

El backend ya exponía `POST /api/v1/uploads/images` (S3/MinIO vía [[StorageService]]) y el modelo guardaba `order_items.image_key`, pero **ninguna app móvil subía imágenes**: no había `uploadImage` en el cliente HTTP, ni UI de selección, ni se enviaba `image_key` al crear pedidos.

Además, al servir las imágenes se detectaron dos problemas:

1. `public_url()` devuelve `http://localhost:9000/...` (MinIO en dev), inalcanzable desde el emulador (que resuelve el host como `10.0.2.2`). Las URLs directas rompen en desarrollo.
2. El bucket es privado; en producción las imágenes se sirven por CloudFront, pero en dev no existe ese CDN.

El Driver también necesita adjuntar un **comprobante de entrega** al marcar `DELIVERED`, que hoy no existe en el modelo.

## Decisión

1. **Proxy de lectura autenticado**: `GET /api/v1/uploads/images/{key:path}` con `CurrentUser`. El cliente construye la URL a partir de `API_BASE_URL` (funciona en emulador) y `Image.network` envía el Bearer vía `headers`. En producción el bucket sigue privado y se puede servir por CloudFront con OAC.
2. **Subida en el envío del formulario** (Customer): la foto se selecciona localmente (preview con `Image.memory`) y se sube al confirmar el pedido. Evita imágenes huérfanas por abandono del formulario.
3. **Comprobante de entrega**: columna `orders.delivery_proof_key` (nullable), enviado como `delivery_proof_key` opcional en `POST /orders/{id}/status` al pasar a `DELIVERED`. **Obligatorio en la app** (no se deja avanzar sin foto) pero **opcional en la API** (flexible para integraciones y tests).
4. Selección de imagen con `image_picker` (galería). Android no requiere permisos; iOS añade `NSPhotoLibraryUsageDescription`.

## Consecuencias

### Positivas

- Las imágenes se cargan desde el emulador y el bucket permanece privado.
- `image_key` ya existente en el dominio se usa de verdad (foto por ítem).
- Comprobante de entrega con costo mínimo: una columna nullable, sin cambios en la máquina de estados.
- El proxy es la implementación "real" del endpoint que [[StorageService]] ya documentaba.

### Negativas / Trade-offs

- Cualquier usuario autenticado puede leer cualquier key por el proxy (las keys son `users/{uuid}/images/...`, no adivinables). Aceptado para el alcance de la prueba; en prod se puede validar que la key pertenezca a un pedido visible por el usuario.
- Si `createOrder` falla después de subir las fotos, quedan objetos huérfanos en el bucket (aceptable; limpieza programada como mejora).
- Subida al enviar hace esperar el `multipart` antes de crear el pedido (N items → N uploads).

### Neutrales

- Se reutiliza `S3StorageService` con un nuevo método `get()`; la ruta de lectura y la de escritura viven en `app/api/routes/uploads.py`.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Afecta a:** [[StorageService]], [[API Pedidos y estados]], [[Modelo de datos]], [[Apps moviles implementadas]], [[API Implementada]]
- **Repo:** `backend`, `mobile/packages/shared`, `mobile/customer_app`, `mobile/driver_app`