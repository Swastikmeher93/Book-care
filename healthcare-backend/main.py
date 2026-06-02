from fastapi import FastAPI
from app.routers.service import router as service_router
from app.routers.cart import router as cart_router
from app.routers.auth import router as auth_router
from app.routers.patient import router as patient_router
from app.routers.caregiver import router as caregiver_router

app = FastAPI(
    title="FamCARE Healthcare API",
    description=(
        "FastAPI backend for FamCARE — services and cart/booking flow.\n\n"
        "**Booking flow:**\n"
        "1. `GET /services` — browse available services\n"
        "2. `GET /slots/available?service_id=...&date=...` — pick an open slot\n"
        "3. `POST /cart/add` — save slot to cart\n"
        "4. `POST /cart/checkout` — confirm booking (auto-assigns caregiver, validates overlaps)"
    ),
    version="5.0.1",
)

app.include_router(service_router)
app.include_router(cart_router)
app.include_router(auth_router)
app.include_router(patient_router)
app.include_router(caregiver_router)


@app.get("/", tags=["Root"])
def read_root():
    return {
        "message": "FamCARE Healthcare API",
        "docs": "/docs",
        "version": "5.0.1",
        "status": "active",
    }
