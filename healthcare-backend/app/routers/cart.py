from fastapi import APIRouter, HTTPException, status
from typing import List, Optional
import app.crud.cart as cart_crud
from app.models.cart import (
    CheckoutRequest,
    BookingResponse,
    CartAddRequest,
    CartItemResponse,
    AvailableSlotResponse,
)

router = APIRouter(tags=["Booking"])


# ──────────────────────────────────────────────────────────────────────────────
# SLOT AVAILABILITY
# ──────────────────────────────────────────────────────────────────────────────

@router.get("/slots/available", response_model=List[AvailableSlotResponse])
def list_available_slots(
    service_id: str,
    date: str,
    patient_id: Optional[str] = None,
):
    """
    Returns all open 15-minute-aligned time slots for a service on a given date.

    Query params:
    - **service_id** *(required)*: UUID of the service
    - **date** *(required)*: `YYYY-MM-DD`
    - **patient_id** *(optional)*: when supplied, slots that overlap the
      patient's existing bookings on that day are excluded

    Each slot includes:
    ```json
    { "time": "09:00", "caregiver": { "id": "...", "name": "Dr. Sarah Lee" } }
    ```
    """
    from datetime import date as _date
    try:
        _date.fromisoformat(date)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="date must be in YYYY-MM-DD format.",
        )
    try:
        return cart_crud.get_available_slots(service_id, date, patient_id)
    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch available slots: {str(e)}",
        )


# ──────────────────────────────────────────────────────────────────────────────
# CART MANAGEMENT
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/cart/add", response_model=CartItemResponse, status_code=status.HTTP_201_CREATED)
def add_to_cart(request: CartAddRequest):
    """
    Saves a service slot to the cart.

    - **service_id**: UUID of the service
    - **scheduled_date**: `YYYY-MM-DD`
    - **start_time**: `HH:MM`
    """
    try:
        return cart_crud.add_to_cart(request.model_dump())
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to add to cart: {str(e)}",
        )


@router.get("/cart/list", response_model=List[CartItemResponse])
def list_cart():
    """Returns all services currently saved in the cart."""
    try:
        return cart_crud.list_cart()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve cart: {str(e)}",
        )


@router.delete("/cart/remove/{service_id}", status_code=status.HTTP_200_OK)
def remove_from_cart(service_id: str):
    """Removes all cart entries for the given service_id."""
    try:
        removed = cart_crud.remove_from_cart_by_service(service_id)
        if removed == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"No cart items found for service {service_id}.",
            )
        return {"detail": f"Removed {removed} item(s) from cart."}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to remove from cart: {str(e)}",
        )


# ──────────────────────────────────────────────────────────────────────────────
# CHECKOUT
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/cart/checkout", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
def checkout(request: CheckoutRequest):
    """
    Atomic checkout — books all requested services in a single transaction.

    **Enforced rules:**
    - A patient cannot have two services whose windows overlap on the same day.
    - A caregiver cannot be double-booked (full service duration is accounted for).

    Request body:
    ```json
    {
      "patient_id": "uuid",
      "items": [
        { "service_id": "uuid", "scheduled_date": "2026-06-14", "start_time": "09:00" }
      ]
    }
    ```

    On success caregivers are auto-assigned from each service's pool and the cart is cleared.
    """
    try:
        items_list = [item.model_dump() for item in request.items]
        return cart_crud.checkout_booking(request.patient_id, items_list)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Checkout failed: {str(e)}",
        )
