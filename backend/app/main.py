from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from slowapi.util import get_remote_address

from app.api.routes import auth, orders, uploads
from app.api.ws import orders as ws_orders
from app.core.config import get_settings
from app.core.logging import setup_logging

settings = get_settings()

limiter = Limiter(
    key_func=get_remote_address, default_limits=[f"{settings.rate_limit_per_minute}/minute"]
)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    setup_logging(settings.debug)
    yield


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description="API de la plataforma de delivery: auth JWT, pedidos, realtime WebSocket.",
    lifespan=lifespan,
)

app.state.limiter = limiter


async def _rate_limit_handler(request: Request, exc: Exception) -> JSONResponse:
    return JSONResponse(
        status_code=429,
        content={"detail": "Rate limit excedido. Intenta de nuevo mas tarde."},
    )


app.add_exception_handler(RateLimitExceeded, _rate_limit_handler)
app.add_middleware(SlowAPIMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1")
app.include_router(orders.router, prefix="/api/v1")
app.include_router(uploads.router, prefix="/api/v1")
app.include_router(ws_orders.router)


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
