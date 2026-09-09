from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "delivery-api"
    environment: str = "development"
    debug: bool = True

    database_url: str = (
        "postgresql+asyncpg://imagine_delivery:imagine_delivery_dev@localhost:5434/imagine_delivery"
    )

    secret_key: str = "change-me"
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 7

    storage_backend: str = "s3"
    s3_endpoint_url: str | None = "http://localhost:9000"
    s3_bucket: str = "delivery-media"
    s3_region: str = "us-east-1"
    s3_access_key: str = "minioadmin"
    s3_secret_key: str = "minioadmin"

    rate_limit_per_minute: int = 60

    cors_origins: list[str] = ["*"]


@lru_cache
def get_settings() -> Settings:
    return Settings()
