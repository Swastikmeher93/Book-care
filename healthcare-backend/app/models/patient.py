from pydantic import BaseModel
from typing import Optional, Any


class PatientBase(BaseModel):
    first_name: str
    last_name: str
    email: str
    phone: Optional[str] = None


class PatientCreate(PatientBase):
    pass


class PatientResponse(PatientBase):
    id: str
    created_at: Any = None

    class Config:
        from_attributes = True
