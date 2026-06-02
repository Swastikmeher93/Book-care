from fastapi import APIRouter, HTTPException, status
from typing import List
from app.models.patient import PatientCreate, PatientResponse
import app.crud.patient as patient_crud

router = APIRouter(prefix="/patients", tags=["Patients"])


@router.post("", response_model=PatientResponse, status_code=status.HTTP_201_CREATED)
def create_patient(patient: PatientCreate):
    try:
        return patient_crud.create(patient.model_dump())
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Failed to create patient: {str(e)}")


@router.get("", response_model=List[PatientResponse])
def list_patients():
    try:
        return patient_crud.list_all()
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to retrieve patients: {str(e)}")


@router.get("/{patient_id}", response_model=PatientResponse)
def get_patient(patient_id: str):
    try:
        patient = patient_crud.get(patient_id)
        if not patient:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Patient {patient_id} not found.")
        return patient
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to retrieve patient: {str(e)}")


@router.put("/{patient_id}", response_model=PatientResponse)
def update_patient(patient_id: str, patient_update: PatientCreate):
    try:
        updated = patient_crud.update(patient_id, patient_update.model_dump())
        if not updated:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Patient {patient_id} not found.")
        return updated
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Failed to update patient: {str(e)}")


@router.delete("/{patient_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_patient(patient_id: str):
    try:
        if not patient_crud.delete(patient_id):
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Patient {patient_id} not found.")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Failed to delete patient: {str(e)}")
