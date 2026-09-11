import asyncio
from functools import lru_cache
from typing import Any
from uuid import UUID

import boto3
from botocore.exceptions import ClientError

from app.core.config import get_settings


@lru_cache
def _s3_client() -> Any:
    """Cliente S3 compartido (se crea una sola vez por proceso)."""
    settings = get_settings()
    kwargs: dict[str, Any] = {
        "region_name": settings.s3_region,
    }
    if settings.s3_access_key and settings.s3_secret_key:
        kwargs["aws_access_key_id"] = settings.s3_access_key
        kwargs["aws_secret_access_key"] = settings.s3_secret_key
    if settings.s3_endpoint_url:
        kwargs["endpoint_url"] = settings.s3_endpoint_url
    return boto3.client("s3", **kwargs)


class S3StorageService:
    """StorageService que siempre apunta a S3 (MinIO en dev, AWS S3 en prod).

    La unica diferencia entre entornos es el endpoint y las credenciales;
    la implementacion es identica (ver docs/20 Tecnico/StorageService).
    Las llamadas boto3 son bloqueantes y se ejecutan en un thread para no
    bloquear el event loop de la API.
    """

    def __init__(self) -> None:
        self._client = _s3_client()
        self._bucket = get_settings().s3_bucket

    async def upload(self, key: str, data: bytes, content_type: str) -> str:
        await asyncio.to_thread(
            self._client.put_object,
            Bucket=self._bucket,
            Key=key,
            Body=data,
            ContentType=content_type,
        )
        return key

    async def get(self, key: str) -> tuple[bytes, str]:
        obj = await asyncio.to_thread(self._client.get_object, Bucket=self._bucket, Key=key)
        data = await asyncio.to_thread(obj["Body"].read)
        content_type: str = obj.get("ContentType", "application/octet-stream")
        return data, content_type

    async def delete(self, key: str) -> None:
        await asyncio.to_thread(self._client.delete_object, Bucket=self._bucket, Key=key)

    def presign_put(self, key: str, content_type: str, expires: int = 300) -> str:
        """URL firmada para que el cliente suba directo a S3/MinIO (escritura)."""
        url: str = self._client.generate_presigned_url(
            "put_object",
            Params={"Bucket": self._bucket, "Key": key, "ContentType": content_type},
            ExpiresIn=expires,
        )
        return url

    def public_url(self, key: str) -> str:
        settings = get_settings()
        if settings.s3_endpoint_url:
            return f"{settings.s3_endpoint_url}/{self._bucket}/{key}"
        return f"https://{self._bucket}.s3.{settings.s3_region}.amazonaws.com/{key}"

    def ensure_bucket(self) -> None:
        try:
            self._client.create_bucket(Bucket=self._bucket)
        except ClientError as exc:
            code = exc.response.get("Error", {}).get("Code")
            if code not in {"BucketAlreadyOwnedByYou", "BucketAlreadyExists"}:
                raise
        try:
            self._client.put_public_access_block(
                Bucket=self._bucket,
                PublicAccessBlockConfiguration={
                    "BlockPublicAcls": True,
                    "IgnorePublicAcls": True,
                    "BlockPublicPolicy": True,
                    "RestrictPublicBuckets": True,
                },
            )
        except ClientError:
            # MinIO no implementa PutPublicAccessBlock (bucket privado por defecto);
            # en AWS S3 el bloqueo de acceso publico lo aplica Terraform.
            pass


def get_storage() -> S3StorageService:
    return S3StorageService()


def build_key(prefix: str, order_id: UUID | None = None) -> str:
    base = prefix if order_id is None else f"{prefix}/{order_id}"
    return base
