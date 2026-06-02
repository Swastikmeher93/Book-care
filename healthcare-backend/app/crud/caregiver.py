from typing import Dict, Any, List, Optional
from psycopg2.extras import RealDictCursor
from app.database import get_connection

def create(data: Dict[str, Any]) -> Dict[str, Any]:
    query = """
    INSERT INTO caregivers (first_name, last_name, email, phone, specialty, hourly_rate)
    VALUES (%(first_name)s, %(last_name)s, %(email)s, %(phone)s, %(specialty)s, %(hourly_rate)s)
    RETURNING *;
    """
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, data)
            row = cur.fetchone()
            conn.commit()
            return dict(row) if row else {}

def get(caregiver_id: str) -> Optional[Dict[str, Any]]:
    query = "SELECT * FROM caregivers WHERE id = %s;"
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, (caregiver_id,))
            row = cur.fetchone()
            return dict(row) if row else None

def list_all() -> List[Dict[str, Any]]:
    query = "SELECT * FROM caregivers;"
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query)
            rows = cur.fetchall()
            return [dict(row) for row in rows]

def update(caregiver_id: str, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    if not data:
        return get(caregiver_id)
    fields = ", ".join([f"{k} = %({k})s" for k in data.keys()])
    query = f"UPDATE caregivers SET {fields} WHERE id = %(id)s RETURNING *;"
    params = {**data, "id": caregiver_id}
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, params)
            row = cur.fetchone()
            conn.commit()
            return dict(row) if row else None

def delete(caregiver_id: str) -> bool:
    query = "DELETE FROM caregivers WHERE id = %s RETURNING id;"
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, (caregiver_id,))
            row = cur.fetchone()
            conn.commit()
            return row is not None

def add_availability(caregiver_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Adds a schedule block (availability shift) for a caregiver.
    """
    create_table_query = """
    CREATE TABLE IF NOT EXISTS caregiver_availability (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        caregiver_id UUID REFERENCES caregivers(id) ON DELETE CASCADE,
        scheduled_date DATE NOT NULL,
        start_time TIME NOT NULL,
        end_time TIME NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """
    query = """
    INSERT INTO caregiver_availability (caregiver_id, scheduled_date, start_time, end_time)
    VALUES (%(caregiver_id)s, %(scheduled_date)s, %(start_time)s, %(end_time)s)
    RETURNING *;
    """
    params = {**data, "caregiver_id": caregiver_id}
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(create_table_query)
            cur.execute(query, params)
            row = cur.fetchone()
            conn.commit()
            return dict(row) if row else {}

def list_availability(caregiver_id: str) -> List[Dict[str, Any]]:
    """
    Lists all availability schedule blocks for a caregiver.
    """
    create_table_query = """
    CREATE TABLE IF NOT EXISTS caregiver_availability (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        caregiver_id UUID REFERENCES caregivers(id) ON DELETE CASCADE,
        scheduled_date DATE NOT NULL,
        start_time TIME NOT NULL,
        end_time TIME NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """
    query = """
    SELECT * FROM caregiver_availability 
    WHERE caregiver_id = %s
    ORDER BY scheduled_date ASC, start_time ASC;
    """
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(create_table_query)
            cur.execute(query, (caregiver_id,))
            rows = cur.fetchall()
            return [dict(row) for row in rows]

def remove_availability(availability_id: str) -> bool:
    """
    Deletes an availability schedule block.
    """
    query = "DELETE FROM caregiver_availability WHERE id = %s RETURNING id;"
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, (availability_id,))
            row = cur.fetchone()
            conn.commit()
            return row is not None
