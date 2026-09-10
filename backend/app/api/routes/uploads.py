from fastapi import APIRouter, HTTPException, Response, UploadFile

from app.api.deps import CurrentUser, SessionDep
from app.schemas import UploadResponse
from app.services.storage import build_key, get_storage

router = APIRouter(prefix="/uploads", tags=["uploads"])

MAX_SIZE = 5 * 1024 * 1024
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}


@router.post("/images", response_model=UploadResponse, status_code=201)
async def upload_image(user: CurrentUser, session: SessionDep, file: UploadFile) -> UploadResponse:
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(415, f"Tipo no permitido. Usa: {', '.join(sorted(ALLOWED_TYPES))}")
    data = await file.read()
    if len(data) > MAX_SIZE:
        raise HTTPException(413, "Imagen demasiado grande (max 5 MB)")
    storage = get_storage()
    key = build_key(f"users/{user.id}/images/{file.filename}")
    try:
        await storage.upload(key, data, file.content_type)
    except Exception as exc:  # boto3 errors
        raise HTTPException(500, f"Error subiendo a S3: {exc}") from None
    return UploadResponse(key=key, url=storage.public_url(key))


@router.get("/images/{key:path}")
async def get_image(key: str, user: CurrentUser) -> Response:
    """Proxy de lectura autenticado. En prod las imagenes se sirven por CloudFront."""
    storage = get_storage()
    try:
        data, content_type = await storage.get(key)
    except Exception:  # boto3: NoSuchKey / accesos
        raise HTTPException(404, "Imagen no encontrada") from None
    return Response(content=data, media_type=content_type)
