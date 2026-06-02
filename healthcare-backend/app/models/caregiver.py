from pydantic import BaseModel, field_validator
from typing import Optional, Any
from datetime import date, time

class CaregiverBase(BaseModel):
    first_name: str
    last_name: str
    email: str
    phone: Optional[str] = None
    specialty: Optional[str] = None
    hourly_rate: float

class CaregiverCreate(CaregiverBase):
    pass

class CaregiverResponse(CaregiverBase):
    id: str
    created_at: Any = None

    class Config:
        from_attributes = True

class CaregiverAvailabilityBase(BaseModel):
    scheduled_date: str
    start_time: str
    end_time: str

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
    def validate_start_time(cls, v: str) -> str:
        try:
            time.fromisoformat(v)
        except ValueError:
            raise ValueError("start_time must be in HH:MM format.")
        return v

    @field_validator("end_time")
    @classmethod
    def validate_end_time(cls, v: str) -> str:
        try:
            time.fromisoformat(v)
        except ValueError:
            raise ValueError("end_time must be in HH:MM format.")
        return v

class CaregiverAvailabilityCreate(CaregiverAvailabilityBase):
    pass

class CaregiverAvailabilityResponse(CaregiverAvailabilityBase):
    id: str
    caregiver_id: str
    created_at: Any = None

    class Config:
        from_attributes = True
