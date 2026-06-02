from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from datetime import date

from app.crud import cart as crud_cart
from app.models.cart import CartAddRequest, BookingResponse, AvailableSlotResponse

router = APIRouter()

@router.get("/services/{service_id}/available_slots", response_model=List[AvailableSlotResponse])
async def get_service_available_slots(service_id: str, scheduled_date: date):
    """
    Retrieve available time slots for a specific service on a given date.
    """
    try:
        slots = crud_cart.get_available_slots(str(service_id), scheduled_date.isoformat())
        return slots
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.post("/cart/add", response_model=dict)
async def add_item_to_cart(cart_item: CartAddRequest):
    """
    Add a service with a selected time slot to the cart.
    """
    try:
        new_item = crud_cart.add_to_cart(cart_item.model_dump())
        return {"message": "Item added to cart successfully", "item": new_item}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.post("/cart/checkout/{patient_id}", response_model=BookingResponse)
async def checkout_current_cart(patient_id: str):
    """
    Checkout the current cart for a patient and create a booking.
    """
    try:
        cart_items = crud_cart.list_cart()
        if not cart_items:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cart is empty.")
        
        # Convert RealDictRow to dict for each item
        cart_items_dicts = [dict(item) for item in cart_items]

        booking = crud_cart.checkout_booking(patient_id, cart_items_dicts)
        return booking
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))