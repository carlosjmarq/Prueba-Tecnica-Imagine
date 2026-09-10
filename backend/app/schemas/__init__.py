from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models.enums import OrderStatus, UserRole


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    email: EmailStr
    full_name: str
    role: UserRole
    created_at: datetime


class RegisterRequest(BaseModel):
    email: EmailStr
    full_name: str = Field(min_length=2, max_length=120)
    password: str = Field(min_length=8, max_length=128)
    role: UserRole


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class OrderItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    price: float
    quantity: int
    image_key: str | None = None


class StatusHistoryRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    from_status: OrderStatus | None
    to_status: OrderStatus
    changed_at: datetime


class OrderRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    status: OrderStatus
    customer_id: UUID
    driver_id: UUID | None
    pickup_address: str
    delivery_address: str
    total_amount: float
    notes: str | None
    delivery_proof_key: str | None = None
    created_at: datetime
    updated_at: datetime
    items: list[OrderItemRead]
    history: list[StatusHistoryRead] = []


class OrderItemCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    price: float = Field(gt=0)
    quantity: int = Field(gt=0, le=100)
    image_key: str | None = None


class OrderCreate(BaseModel):
    pickup_address: str = Field(min_length=3, max_length=500)
    delivery_address: str = Field(min_length=3, max_length=500)
    notes: str | None = Field(default=None, max_length=1000)
    items: list[OrderItemCreate] = Field(min_length=1)


class OrderUpdateStatus(BaseModel):
    status: OrderStatus
    delivery_proof_key: str | None = Field(default=None, max_length=255)


class UploadResponse(BaseModel):
    key: str
    url: str


class PresignRequest(BaseModel):
    content_type: str = Field(min_length=1, max_length=100)


class PresignResponse(BaseModel):
    key: str
    url: str
