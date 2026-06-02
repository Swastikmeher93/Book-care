from fastapi import APIRouter, HTTPException, status
from typing import List
from app.models.service import ServiceCreate, ServiceResponse
import app.crud.service as service_crud

router = APIRouter(prefix="/services", tags=["Services"])

@router.post("", response_model=ServiceResponse, status_code=status.HTTP_201_CREATED)
def create_service(service: ServiceCreate):
    try:
        return service_crud.create(service.model_dump())
    except ValueError as val_err:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(val_err)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create service: {str(e)}"
        )

@router.get("", response_model=List[ServiceResponse])
def list_services():
    try:
        return service_crud.list_all()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve services: {str(e)}"
        )

@router.get("/{service_id}", response_model=ServiceResponse)
def get_service(service_id: str):
    try:
        service = service_crud.get(service_id)
        if not service:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Service with ID {service_id} not found."
            )
        return service
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve service: {str(e)}"
        )

@router.put("/{service_id}", response_model=ServiceResponse)
def update_service(service_id: str, service_update: ServiceCreate):
    try:
        updated_service = service_crud.update(service_id, service_update.model_dump())
        if not updated_service:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Service with ID {service_id} not found."
            )
        return updated_service
    except ValueError as val_err:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(val_err)
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to update service: {str(e)}"
        )

@router.delete("/{service_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_service(service_id: str):
    try:
        success = service_crud.delete(service_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Service with ID {service_id} not found."
            )
        return None
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to delete service: {str(e)}"
        )

@router.post("/{service_id}/caregivers/{caregiver_id}", status_code=status.HTTP_200_OK)
def assign_caregiver_to_service(service_id: str, caregiver_id: str):
    """
    Assigns a caregiver to a service's pool.
    """
    try:
        # Check if service exists
        service = service_crud.get(service_id)
        if not service:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Service with ID {service_id} not found."
            )
        # Check if caregiver exists
        import app.crud.caregiver as caregiver_crud
        caregiver = caregiver_crud.get(caregiver_id)
        if not caregiver:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Caregiver with ID {caregiver_id} not found."
            )
        service_crud.assign_caregiver_to_service(service_id, caregiver_id)
        return {"detail": "Caregiver successfully assigned to service pool."}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to assign caregiver to service pool: {str(e)}"
        )

@router.delete("/{service_id}/caregivers/{caregiver_id}", status_code=status.HTTP_200_OK)
def remove_caregiver_from_service(service_id: str, caregiver_id: str):
    """
    Removes a caregiver from a service's pool.
    """
    try:
        # Check if service exists
        service = service_crud.get(service_id)
        if not service:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Service with ID {service_id} not found."
            )
        # Check if caregiver exists
        import app.crud.caregiver as caregiver_crud
        caregiver = caregiver_crud.get(caregiver_id)
        if not caregiver:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Caregiver with ID {caregiver_id} not found."
            )
        success = service_crud.remove_caregiver_from_service(service_id, caregiver_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Caregiver was not assigned to this service pool."
            )
        return {"detail": "Caregiver successfully removed from service pool."}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to remove caregiver from service pool: {str(e)}"
        )
