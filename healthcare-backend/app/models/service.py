from pydantic import BaseModel, field_validator
from typing import Optional, Any, List

class CaregiverBrief(BaseModel):
    id: str
    name: str

class ServiceBase(BaseModel):
    name: str
    description: Optional[str] = None
    duration_minutes: int
    price: float
    location: Optional[str] = None

class ServiceCreate(ServiceBase):
    @field_validator("duration_minutes")
    @classmethod
    def validate_duration(cls, v: int) -> int:
        if v <= 0 or v % 15 != 0:
            raise ValueError("Duration must be a positive number in 15-minute increments (e.g. 15, 30, 45, 60).")
        return v

class ServiceResponse(ServiceBase):
    id: str
    created_at: Any = None
    caregivers: List[CaregiverBrief] = []

    class Config:
        from_attributes = True
