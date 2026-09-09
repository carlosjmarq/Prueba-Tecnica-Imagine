from typing import Annotated, cast
from uuid import UUID

import jwt
from fastapi import Depends, HTTPException, WebSocket, WebSocketException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.core.security import TokenType, decode_token
from app.models import User

bearer_scheme = HTTPBearer(auto_error=False)

SessionDep = Annotated[AsyncSession, Depends(get_session)]


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
    session: SessionDep,
) -> User:
    if credentials is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Autenticacion requerida")
    try:
        payload = decode_token(credentials.credentials)
        if payload.get("type") != TokenType.ACCESS:
            raise jwt.InvalidTokenError
    except jwt.PyJWTError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token invalido o expirado") from None
    user = await session.get(User, UUID(cast(str, payload["sub"])))
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Usuario no encontrado")
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]


async def require_customer(user: CurrentUser) -> User:
    if user.role != "CUSTOMER":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Se requiere rol CUSTOMER")
    return user


async def require_driver(user: CurrentUser) -> User:
    if user.role != "DRIVER":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Se requiere rol DRIVER")
    return user


CustomerDep = Annotated[User, Depends(require_customer)]
DriverDep = Annotated[User, Depends(require_driver)]


async def get_current_user_ws(
    websocket: WebSocket,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> User:
    token = websocket.query_params.get("token")
    if not token:
        raise WebSocketException(code=status.WS_1008_POLICY_VIOLATION, reason="Token requerido")
    try:
        payload = decode_token(token)
        if payload.get("type") != TokenType.ACCESS:
            raise jwt.InvalidTokenError
    except jwt.PyJWTError:
        raise WebSocketException(
            code=status.WS_1008_POLICY_VIOLATION, reason="Token invalido"
        ) from None
    user = await session.get(User, UUID(cast(str, payload["sub"])))
    if user is None:
        raise WebSocketException(
            code=status.WS_1008_POLICY_VIOLATION, reason="Usuario no encontrado"
        )
    return user
