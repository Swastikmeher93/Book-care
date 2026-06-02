from fastapi import APIRouter, HTTPException, status
from typing import List
from app.models.caregiver import (
    CaregiverCreate, 
    CaregiverResponse, 
    CaregiverAvailabilityCreate, 
    CaregiverAvailabilityResponse
)
import app.crud.caregiver as caregiver_crud

router = APIRouter(prefix="/caregivers", tags=["Caregivers"])

@router.post("", response_model=CaregiverResponse, status_code=status.HTTP_201_CREATED)
def create_caregiver(caregiver: CaregiverCreate):
    try:
        return caregiver_crud.create(caregiver.model_dump())
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create caregiver: {str(e)}"
        )

@router.get("", response_model=List[CaregiverResponse])
def list_caregivers():
    try:
        return caregiver_crud.list_all()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve caregivers: {str(e)}"
        )

@router.get("/{caregiver_id}", response_model=CaregiverResponse)
def get_caregiver(caregiver_id: str):
    try:
        caregiver = caregiver_crud.get(caregiver_id)
        if not caregiver:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Caregiver with ID {caregiver_id} not found."
            )
        return caregiver
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve caregiver: {str(e)}"
        )

@router.put("/{caregiver_id}", response_model=CaregiverResponse)
def update_caregiver(caregiver_id: str, caregiver_update: CaregiverCreate):
    try:
        updated_caregiver = caregiver_crud.update(caregiver_id, caregiver_update.model_dump())
        if not updated_caregiver:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Caregiver with ID {caregiver_id} not found."
            )
        return updated_caregiver
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to update caregiver: {str(e)}"
        )

@router.delete("/{caregiver_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_caregiver(caregiver_id: str):
    try:
        success = caregiver_crud.delete(caregiver_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Caregiver with ID {caregiver_id} not found."
            )
        return None
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to delete caregiver: {str(e)}"
        )

@router.post("/{caregiver_id}/availability", response_model=CaregiverAvailabilityResponse, status_code=status.HTTP_201_CREATED)
def add_caregiver_availability(caregiver_id: str, availability: CaregiverAvailabilityCreate):
    """
    Adds a schedule block (availability shift) for a caregiver.
    """
    try:
        caregiver = caregiver_crud.get(caregiver_id)
        if not caregiver:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Caregiver with ID {caregiver_id} not found."
            )
        return caregiver_crud.add_availability(caregiver_id, availability.model_dump())
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to add availability: {str(e)}"
        )

@router.get("/{caregiver_id}/availability", response_model=List[CaregiverAvailabilityResponse])
def list_caregiver_availability(caregiver_id: str):
    """
    Lists all availability schedule blocks for a caregiver.
    """
    try:
        caregiver = caregiver_crud.get(caregiver_id)
        if not caregiver:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Caregiver with ID {caregiver_id} not found."
            )
        return caregiver_crud.list_availability(caregiver_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve availability blocks: {str(e)}"
        )

@router.delete("/availability/{availability_id}", status_code=status.HTTP_200_OK)
def remove_caregiver_availability(availability_id: str):
    """
    Deletes an availability schedule block.
    """
    try:
        success = caregiver_crud.remove_availability(availability_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Availability block with ID {availability_id} not found."
            )
        return {"detail": "Availability schedule block successfully deleted."}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to delete availability block: {str(e)}"
        )
