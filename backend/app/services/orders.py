from datetime import datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.security import hash_password, verify_password
from app.models import (
    VALID_TRANSITIONS,
    Order,
    OrderItem,
    OrderStatus,
    OrderStatusHistory,
    RefreshToken,
    User,
    UserRole,
)
from app.schemas import LoginRequest, OrderCreate, RegisterRequest
from app.services.realtime import manager


class DomainError(Exception):
    def __init__(self, message: str, status_code: int = 400) -> None:
        self.message = message
        self.status_code = status_code
        super().__init__(message)


async def get_user_by_email(session: AsyncSession, email: str) -> User | None:
    result = await session.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()


async def register_user(session: AsyncSession, data: RegisterRequest) -> User:
    existing = await get_user_by_email(session, data.email)
    if existing:
        raise DomainError("El email ya esta registrado", 409)
    user = User(
        email=data.email,
        full_name=data.full_name,
        password_hash=hash_password(data.password),
        role=data.role,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


async def authenticate_user(session: AsyncSession, data: LoginRequest) -> User:
    user = await get_user_by_email(session, data.email)
    if not user or not verify_password(data.password, user.password_hash):
        raise DomainError("Credenciales invalidas", 401)
    return user


async def store_refresh_token(
    session: AsyncSession, user_id: UUID, token_hash: str, expires_at: datetime
) -> RefreshToken:
    token = RefreshToken(user_id=user_id, token_hash=token_hash, expires_at=expires_at)
    session.add(token)
    await session.commit()
    await session.refresh(token)
    return token


async def consume_refresh_token(session: AsyncSession, token_hash: str) -> RefreshToken:
    result = await session.execute(
        select(RefreshToken).where(RefreshToken.token_hash == token_hash)
    )
    token = result.scalar_one_or_none()
    if (
        not token
        or token.revoked
        or token.expires_at.tzinfo
        and token.expires_at < token.created_at.replace()
    ):
        raise DomainError("Refresh token invalido o expirado", 401)
    token.revoked = True
    await session.commit()
    return token


async def create_order(session: AsyncSession, customer: User, data: OrderCreate) -> Order:
    total = sum(item.price * item.quantity for item in data.items)
    order = Order(
        customer_id=customer.id,
        pickup_address=data.pickup_address,
        delivery_address=data.delivery_address,
        notes=data.notes,
        total_amount=total,
    )
    for item in data.items:
        order.items.append(
            OrderItem(
                name=item.name, price=item.price, quantity=item.quantity, image_key=item.image_key
            )
        )
    order.history.append(OrderStatusHistory(to_status=OrderStatus.PENDING, actor_id=customer.id))
    session.add(order)
    await session.commit()
    await session.refresh(order)
    await manager.broadcast(
        {"type": "order.created", "order_id": str(order.id), "status": order.status.value},
        ["orders:available", f"user:{customer.id}"],
    )
    return order


async def get_order(session: AsyncSession, order_id: UUID) -> Order | None:
    result = await session.execute(
        select(Order)
        .options(selectinload(Order.items), selectinload(Order.history))
        .where(Order.id == order_id)
    )
    return result.scalar_one_or_none()


async def list_orders(
    session: AsyncSession, user: User, available_only: bool = False
) -> list[Order]:
    stmt = (
        select(Order)
        .options(selectinload(Order.items), selectinload(Order.history))
        .order_by(Order.created_at.desc())
    )
    if available_only:
        stmt = stmt.where(Order.status == OrderStatus.PENDING)
    elif user.role == UserRole.CUSTOMER:
        stmt = stmt.where(Order.customer_id == user.id)
    elif user.role == UserRole.DRIVER:
        stmt = stmt.where(Order.driver_id == user.id)
    result = await session.execute(stmt)
    return list(result.scalars().all())


async def _transition(
    session: AsyncSession, order: Order, to_status: OrderStatus, actor: User
) -> Order:
    if order.status not in VALID_TRANSITIONS:
        raise DomainError(f"No se puede transicionar desde {order.status.value}", 409)
    if to_status not in VALID_TRANSITIONS[order.status]:
        raise DomainError(f"Transicion {order.status.value} -> {to_status.value} invalida", 409)
    from_status = order.status
    order.status = to_status
    order.history.append(
        OrderStatusHistory(from_status=from_status, to_status=to_status, actor_id=actor.id)
    )
    if to_status == OrderStatus.ACCEPTED and order.driver_id is None:
        order.driver_id = actor.id
    await session.commit()
    await session.refresh(order)
    rooms = [f"order:{order.id}", f"user:{order.customer_id}"]
    if order.driver_id:
        rooms.append(f"user:{order.driver_id}")
    await manager.broadcast(
        {"type": "order.updated", "order_id": str(order.id), "status": to_status.value},
        rooms,
    )
    return order


async def accept_order(session: AsyncSession, order: Order, driver: User) -> Order:
    if order.status != OrderStatus.PENDING:
        raise DomainError("El pedido ya no esta disponible", 409)
    return await _transition(session, order, OrderStatus.ACCEPTED, driver)


async def update_order_status(
    session: AsyncSession, order: Order, to_status: OrderStatus, actor: User
) -> Order:
    if order.driver_id != actor.id:
        raise DomainError("Solo el driver asignado puede actualizar este pedido", 403)
    return await _transition(session, order, to_status, actor)


async def cancel_order(session: AsyncSession, order: Order, actor: User) -> Order:
    if order.customer_id != actor.id:
        raise DomainError("Solo el customer puede cancelar su pedido", 403)
    if order.status != OrderStatus.PENDING:
        raise DomainError("Solo se puede cancelar un pedido PENDING", 409)
    return await _transition(session, order, OrderStatus.CANCELLED, actor)
