from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import CurrentUser, SessionDep
from app.core.config import get_settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_refresh_token,
)
from app.models import RefreshToken, User
from app.schemas import LoginRequest, RefreshRequest, RegisterRequest, TokenPair, UserRead
from app.services.orders import DomainError, authenticate_user, register_user, store_refresh_token

router = APIRouter(prefix="/auth", tags=["auth"])


async def _issue_tokens(session: AsyncSession, user: User) -> TokenPair:
    settings = get_settings()
    access_token = create_access_token(user.id, user.role.value)
    raw_refresh, refresh_hash = create_refresh_token()
    expires = datetime.now(UTC) + timedelta(days=settings.refresh_token_expire_days)
    await store_refresh_token(session, user.id, refresh_hash, expires)
    return TokenPair(access_token=access_token, refresh_token=raw_refresh)


@router.post("/register", response_model=UserRead, status_code=201)
async def register(data: RegisterRequest, session: SessionDep) -> User:
    try:
        return await register_user(session, data)
    except DomainError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from None


@router.post("/login", response_model=TokenPair)
async def login(data: LoginRequest, session: SessionDep) -> TokenPair:
    try:
        user = await authenticate_user(session, data)
    except DomainError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from None
    return await _issue_tokens(session, user)


@router.post("/refresh", response_model=TokenPair)
async def refresh(data: RefreshRequest, session: SessionDep) -> TokenPair:
    refresh_hash = hash_refresh_token(data.refresh_token)
    result = await session.execute(
        select(RefreshToken).where(RefreshToken.token_hash == refresh_hash)
    )
    token = result.scalar_one_or_none()
    if not token or token.revoked or token.expires_at < datetime.now(UTC):
        raise HTTPException(status_code=401, detail="Refresh token invalido o expirado")
    user = await session.get(User, token.user_id)
    if user is None:
        raise HTTPException(status_code=401, detail="Usuario no encontrado")
    token.revoked = True
    await session.commit()
    return await _issue_tokens(session, user)


@router.post("/logout", status_code=204)
async def logout(data: RefreshRequest, session: SessionDep) -> None:
    refresh_hash = hash_refresh_token(data.refresh_token)
    result = await session.execute(
        select(RefreshToken).where(RefreshToken.token_hash == refresh_hash)
    )
    token = result.scalar_one_or_none()
    if token:
        token.revoked = True
        await session.commit()


@router.get("/me", response_model=UserRead)
async def me(user: CurrentUser) -> User:
    return user
