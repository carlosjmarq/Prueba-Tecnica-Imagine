from uuid import UUID

from fastapi import APIRouter, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import CurrentUser, CustomerDep, DriverDep, SessionDep
from app.models import Order, OrderStatus, UserRole
from app.schemas import OrderCreate, OrderRead, OrderUpdateStatus
from app.services.orders import (
    DomainError,
    accept_order,
    cancel_order,
    create_order,
    get_order,
    list_orders,
    update_order_status,
)

router = APIRouter(prefix="/orders", tags=["orders"])


def _to_read(order: Order) -> OrderRead:
    return OrderRead.model_validate(order)


async def _reload(session: AsyncSession, order: Order) -> OrderRead:
    fresh = await get_order(session, order.id)
    assert fresh is not None
    return _to_read(fresh)


@router.post("", response_model=OrderRead, status_code=201)
async def create(order_in: OrderCreate, user: CustomerDep, session: SessionDep) -> OrderRead:
    try:
        order = await create_order(session, user, order_in)
    except DomainError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from None
    return await _reload(session, order)


@router.get("", response_model=list[OrderRead])
async def list_mine(user: CurrentUser, session: SessionDep) -> list[OrderRead]:
    orders = await list_orders(session, user)
    return [_to_read(o) for o in orders]


@router.get("/available", response_model=list[OrderRead])
async def list_available(user: DriverDep, session: SessionDep) -> list[OrderRead]:
    orders = await list_orders(session, user, available_only=True)
    return [_to_read(o) for o in orders]


@router.get("/mine", response_model=list[OrderRead])
async def list_assigned(user: DriverDep, session: SessionDep) -> list[OrderRead]:
    orders = await list_orders(session, user)
    return [_to_read(o) for o in orders]


@router.get("/{order_id}", response_model=OrderRead)
async def detail(order_id: UUID, user: CurrentUser, session: SessionDep) -> OrderRead:
    order = await get_order(session, order_id)
    if order is None:
        raise HTTPException(404, "Pedido no encontrado")
    if user.role == UserRole.CUSTOMER and order.customer_id != user.id:
        raise HTTPException(403, "No puedes ver pedidos de otros usuarios")
    if user.role == UserRole.DRIVER:
        # El driver puede ver un pedido PENDING (disponible para aceptar)
        # o uno que le fue asignado. Cualquier otro pedido ajeno -> 403.
        es_disponible = order.status == OrderStatus.PENDING
        es_asignado = order.driver_id == user.id
        if not (es_disponible or es_asignado):
            raise HTTPException(403, "No puedes ver pedidos de otros usuarios")
    return _to_read(order)


@router.post("/{order_id}/cancel", response_model=OrderRead)
async def cancel(order_id: UUID, user: CustomerDep, session: SessionDep) -> OrderRead:
    order = await get_order(session, order_id)
    if order is None:
        raise HTTPException(404, "Pedido no encontrado")
    try:
        order = await cancel_order(session, order, user)
    except DomainError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from None
    return await _reload(session, order)


@router.post("/{order_id}/accept", response_model=OrderRead)
async def accept(order_id: UUID, user: DriverDep, session: SessionDep) -> OrderRead:
    order = await get_order(session, order_id)
    if order is None:
        raise HTTPException(404, "Pedido no encontrado")
    try:
        order = await accept_order(session, order, user)
    except DomainError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from None
    return await _reload(session, order)


@router.post("/{order_id}/status", response_model=OrderRead)
async def update_status(
    order_id: UUID, payload: OrderUpdateStatus, user: DriverDep, session: SessionDep
) -> OrderRead:
    order = await get_order(session, order_id)
    if order is None:
        raise HTTPException(404, "Pedido no encontrado")
    try:
        order = await update_order_status(
            session, order, payload.status, user, payload.delivery_proof_key
        )
    except DomainError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from None
    return await _reload(session, order)
