from typing import Dict, Any, List, Optional
from psycopg2.extras import RealDictCursor
from app.database import get_connection


def _ensure_user_id_column(cur) -> None:
    """Self-healing: adds the user_id column to patients if it doesn't exist."""
    cur.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS user_id UUID UNIQUE;")


# ── Auth-linked operations ────────────────────────────────────────────────────

def create_with_user_id(data: Dict[str, Any], user_id: str) -> Dict[str, Any]:
    """
    Creates a new patient row linked to a Supabase Auth user.
    The user_id is the UUID from auth.users and becomes the FK bridge.
    """
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            _ensure_user_id_column(cur)
            cur.execute(
                """
                INSERT INTO patients (user_id, first_name, last_name, email, phone)
                VALUES (%(user_id)s, %(first_name)s, %(last_name)s, %(email)s, %(phone)s)
                RETURNING *;
                """,
                {**data, "user_id": user_id},
            )
            row = cur.fetchone()
            conn.commit()
            return dict(row) if row else {}


def get_by_user_id(user_id: str) -> Optional[Dict[str, Any]]:
    """
    Returns the patient row whose user_id matches a Supabase Auth UUID.
    Used by protected endpoints after JWT validation.
    """
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            _ensure_user_id_column(cur)
            cur.execute(
                "SELECT * FROM patients WHERE user_id = %s;",
                (user_id,),
            )
            row = cur.fetchone()
            return dict(row) if row else None


# ── Standard CRUD (admin / internal use) ──────────────────────────────────────

def create(data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Creates a new patient, supporting an optional custom UUID id.
    """
    if "id" in data:
        query = """
        INSERT INTO patients (id, first_name, last_name, email, phone)
        VALUES (%(id)s, %(first_name)s, %(last_name)s, %(email)s, %(phone)s)
        RETURNING *;
        """
    else:
        query = """
        INSERT INTO patients (first_name, last_name, email, phone)
        VALUES (%(first_name)s, %(last_name)s, %(email)s, %(phone)s)
        RETURNING *;
        """
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, data)
            row = cur.fetchone()
            conn.commit()
            return dict(row) if row else {}


def get(patient_id: str) -> Optional[Dict[str, Any]]:
    """Retrieves a single patient by their internal UUID."""
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT * FROM patients WHERE id = %s;", (patient_id,))
            row = cur.fetchone()
            return dict(row) if row else None


def list_all() -> List[Dict[str, Any]]:
    """Retrieves all patients."""
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT * FROM patients;")
            return [dict(row) for row in cur.fetchall()]


def update(patient_id: str, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """Updates an existing patient record by internal UUID."""
    if not data:
        return get(patient_id)
    fields = ", ".join([f"{k} = %({k})s" for k in data.keys()])
    query = f"UPDATE patients SET {fields} WHERE id = %(id)s RETURNING *;"
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, {**data, "id": patient_id})
            row = cur.fetchone()
            conn.commit()
            return dict(row) if row else None


def delete(patient_id: str) -> bool:
    """Deletes a patient by their internal UUID."""
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("DELETE FROM patients WHERE id = %s RETURNING id;", (patient_id,))
            row = cur.fetchone()
            conn.commit()
            return row is not None
