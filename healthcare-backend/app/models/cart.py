from pydantic import BaseModel, field_validator
from typing import List, Optional, Any
from datetime import date, time


# ──────────────────────────────────────────────────────────────────────────────
# CART MODELS
# ──────────────────────────────────────────────────────────────────────────────

class CartAddRequest(BaseModel):
    """Payload to add a single service slot to the cart."""
    service_id: str
    scheduled_date: str
    start_time: str

    @field_validator("scheduled_date")
    @classmethod
    def validate_date(cls, v: str) -> str:
        try:
            date.fromisoformat(v)
        except ValueError:
            raise ValueError("scheduled_date must be in YYYY-MM-DD format.")
        return v

    @field_validator("start_time")
    @classmethod
    def validate_time(cls, v: str) -> str:
        try:
            time.fromisoformat(v)
        except ValueError:
            raise ValueError("start_time must be in HH:MM format (e.g. 14:30).")
        return v


class CartItemResponse(BaseModel):
    id: str
    service_id: str
    scheduled_date: Any
    start_time: Any
    created_at: Optional[Any] = None
    service_name: Optional[str] = None
    service_duration_minutes: Optional[int] = None
    service_price: Optional[float] = None

    class Config:
        from_attributes = True


# ──────────────────────────────────────────────────────────────────────────────
# CHECKOUT MODELS
# ──────────────────────────────────────────────────────────────────────────────

class CheckoutItem(BaseModel):
    """A single service slot in a checkout request."""
    service_id: str
    scheduled_date: str
    start_time: str

    @field_validator("scheduled_date")
    @classmethod
    def validate_date(cls, v: str) -> str:
        try:
            date.fromisoformat(v)
        except ValueError:
            raise ValueError("scheduled_date must be in YYYY-MM-DD format.")
        return v

    @field_validator("start_time")
    @classmethod
    def validate_time(cls, v: str) -> str:
        try:
            time.fromisoformat(v)
        except ValueError:
            raise ValueError("start_time must be in HH:MM format (e.g. 14:30).")
        return v


class CheckoutRequest(BaseModel):
    """Request body for the checkout endpoint."""
    patient_id: str
    items: List[CheckoutItem]


class BookingItemResponse(BaseModel):
    id: str
    booking_id: str
    service_id: str
    caregiver_id: str
    scheduled_date: Any
    start_time: Any
    price: float
    status: str
    created_at: Optional[Any] = None
    service_name: Optional[str] = None
    service_duration_minutes: Optional[int] = None
    caregiver_first_name: Optional[str] = None
    caregiver_last_name: Optional[str] = None

    class Config:
        from_attributes = True


class BookingResponse(BaseModel):
    id: str
    patient_id: str
    total_price: float
    status: str
    payment_status: str
    created_at: Optional[Any] = None
    items: List[BookingItemResponse] = []

    class Config:
        from_attributes = True


# ──────────────────────────────────────────────────────────────────────────────
# SLOT MODELS
# ──────────────────────────────────────────────────────────────────────────────

class CaregiverSlotBrief(BaseModel):
    id: str
    name: str


class AvailableSlotResponse(BaseModel):
    time: str
    caregiver: CaregiverSlotBrief
