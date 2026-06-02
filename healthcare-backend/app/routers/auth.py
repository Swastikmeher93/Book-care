"""
app/routers/auth.py — Google OAuth sync endpoints.

With Supabase Google OAuth, sign-in/sign-up happens entirely on the CLIENT side:
  1. Client opens the Supabase Google OAuth URL
  2. User authenticates with Google
  3. Supabase redirects back to the client with a session (access_token + refresh_token)
  4. Client calls POST /auth/sync with Authorization: Bearer <access_token>
  5. Backend validates the JWT, auto-creates the patients row if it's the first login,
     and returns the patient profile.

POST /auth/sync-all  — admin endpoint to seed patients from ALL existing Supabase Auth users.
"""
from fastapi import APIRouter, HTTPException, status, Depends
from typing import Any, List, Dict
from app.models.patient import PatientResponse
from app.auth import get_current_user, get_supabase_client
import app.crud.patient as patient_crud

router = APIRouter(prefix="/auth", tags=["Auth"])


def _provision_patient_from_user(user: Any) -> Dict:
    """
    Given a Supabase User object, create a patients row if one doesn't exist yet.
    Returns { "user_id", "email", "status": "created" | "exists" }.
    """
    user_id = str(user.id)
    existing = patient_crud.get_by_user_id(user_id)
    if existing:
        return {"user_id": user_id, "email": user.email, "status": "exists"}

    meta: dict = getattr(user, "user_metadata", {}) or {}
    email      = user.email or meta.get("email", "")

    # Self-healing: If a patient record with this email already exists but is not linked, link it.
    if email:
        from app.database import get_connection
        from psycopg2.extras import RealDictCursor
        with get_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("SELECT * FROM patients WHERE email = %s;", (email,))
                existing_email = cur.fetchone()
                if existing_email:
                    cur.execute(
                        "UPDATE patients SET user_id = %s WHERE id = %s RETURNING *;",
                        (user_id, existing_email["id"])
                    )
                    conn.commit()
                    return {"user_id": user_id, "email": email, "status": "exists"}

    first_name = (
        meta.get("given_name")
        or (meta.get("full_name", "").split(" ")[0] if meta.get("full_name") else "")
        or "Unknown"
    )
    last_name  = (
        meta.get("family_name")
        or (" ".join(meta.get("full_name", "").split(" ")[1:]) if meta.get("full_name") else "")
        or ""
    )

    patient_crud.create_with_user_id(
        {"first_name": first_name, "last_name": last_name, "email": email, "phone": None},
        user_id=user_id,
    )
    return {"user_id": user_id, "email": email, "status": "created"}


@router.post(
    "/sync",
    response_model=PatientResponse,
    summary="Sync Google OAuth user → patient profile  🔒",
    description=(
        "Call this **once after Google sign-in** from the client app.\n\n"
        "- If this is the first login, a `patients` row is automatically created "
        "using the name and email from the Google account.\n"
        "- Subsequent calls just return the existing patient profile.\n\n"
        "Requires `Authorization: Bearer <access_token>` "
        "(the token returned by Supabase after Google OAuth)."
    ),
)
def sync_google_patient(user: Any = Depends(get_current_user)):
    """
    Auto-provisions the patients row on first Google login.

    Google provides the following in user.user_metadata:
      - full_name    e.g. "Jane Doe"
      - given_name   e.g. "Jane"
      - family_name  e.g. "Doe"
      - email        (also available as user.email)
      - avatar_url   profile picture
    """
    try:
        result = _provision_patient_from_user(user)
        # Return the full patient row
        return patient_crud.get_by_user_id(str(user.id))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to sync patient profile: {str(e)}",
        )


@router.post(
    "/sync-all",
    summary="Seed patients table from all Supabase Auth users (admin)",
    description=(
        "Reads **all users** from Supabase Auth and creates a `patients` row for "
        "any user that doesn't already have one.\n\n"
        "Safe to call multiple times — existing rows are never overwritten.\n\n"
        "> ⚠️ This is an admin utility endpoint. Protect it with network-level "
        "restrictions in production."
    ),
)
def sync_all_patients():
    """
    Iterates every user in auth.users via the Supabase Admin API and provisions
    a patients row for each one that doesn't already have a linked profile.
    """
    try:
        supabase = get_supabase_client()
        users_response = supabase.auth.admin.list_users()

        # supabase-py v2 returns a list directly
        users = users_response if isinstance(users_response, list) else []

        results = []
        for user in users:
            try:
                result = _provision_patient_from_user(user)
                results.append(result)
            except Exception as e:
                results.append({
                    "user_id": str(user.id),
                    "email":   user.email,
                    "status":  f"error: {str(e)}",
                })

        created = sum(1 for r in results if r["status"] == "created")
        skipped = sum(1 for r in results if r["status"] == "exists")

        return {
            "total_auth_users": len(users),
            "created": created,
            "already_existed": skipped,
            "details": results,
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"sync-all failed: {str(e)}",
        )
