from typing import Dict, Any, List, Optional
from psycopg2.extras import RealDictCursor
from app.database import get_connection


def _get_caregiver_pool(cur, service_id: str) -> List[Dict[str, str]]:
    """Returns the list of caregivers assigned to a service's pool."""
    cur.execute("""
        SELECT c.id, CONCAT(c.first_name, ' ', c.last_name) AS name
        FROM caregiver_services cs
        JOIN caregivers c ON cs.caregiver_id = c.id
        WHERE cs.service_id = %s;
    """, (service_id,))
    return [dict(row) for row in cur.fetchall()]


def create(data: Dict[str, Any]) -> Dict[str, Any]:
    if data.get("duration_minutes", 0) % 15 != 0:
        raise ValueError("duration_minutes must be in 15-minute increments (e.g. 15, 30, 45, 60).")

    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                INSERT INTO services (name, description, duration_minutes, price, location)
                VALUES (%(name)s, %(description)s, %(duration_minutes)s, %(price)s, %(location)s)
                RETURNING *;
            """, data)
            row = cur.fetchone()
            conn.commit()
            result = dict(row) if row else {}
            if result:
                result["caregivers"] = []
            return result


def get(service_id: str) -> Optional[Dict[str, Any]]:
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT * FROM services WHERE id = %s;", (service_id,))
            row = cur.fetchone()
            if not row:
                return None
            result = dict(row)
            result["caregivers"] = _get_caregiver_pool(cur, service_id)
            return result


def list_all() -> List[Dict[str, Any]]:
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT * FROM services;")
            rows = cur.fetchall()
            results = []
            for row in rows:
                r = dict(row)
                r["caregivers"] = _get_caregiver_pool(cur, r["id"])
                results.append(r)
            return results


def update(service_id: str, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    if not data:
        return get(service_id)

    if "duration_minutes" in data and data["duration_minutes"] % 15 != 0:
        raise ValueError("duration_minutes must be in 15-minute increments (e.g. 15, 30, 45, 60).")

    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            fields = ", ".join(f"{k} = %({k})s" for k in data)
            cur.execute(
                f"UPDATE services SET {fields} WHERE id = %(id)s RETURNING *;",
                {**data, "id": service_id}
            )
            row = cur.fetchone()
            conn.commit()
            if not row:
                return None
            result = dict(row)
            result["caregivers"] = _get_caregiver_pool(cur, service_id)
            return result


def delete(service_id: str) -> bool:
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("DELETE FROM services WHERE id = %s RETURNING id;", (service_id,))
            row = cur.fetchone()
            conn.commit()
            return row is not None


def assign_caregiver_to_service(service_id: str, caregiver_id: str) -> bool:
    """Assigns a caregiver to a service's pool (idempotent)."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO caregiver_services (caregiver_id, service_id)
                VALUES (%s, %s)
                ON CONFLICT DO NOTHING;
            """, (caregiver_id, service_id))
            conn.commit()
            return True


def remove_caregiver_from_service(service_id: str, caregiver_id: str) -> bool:
    """Removes a caregiver from a service's pool. Returns False if they weren't assigned."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                DELETE FROM caregiver_services
                WHERE caregiver_id = %s AND service_id = %s;
            """, (caregiver_id, service_id))
            deleted = cur.rowcount
            conn.commit()
            return deleted > 0
