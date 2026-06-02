from typing import Dict, Any, List, Optional
from psycopg2.extras import RealDictCursor
from app.database import get_connection
import app.crud.service as service_crud


# ──────────────────────────────────────────────────────────────────────────────
# TIME HELPERS
# ──────────────────────────────────────────────────────────────────────────────

def time_to_minutes(t) -> int:
    """Converts HH:MM / HH:MM:SS string or datetime.time to minutes since midnight."""
    if isinstance(t, str):
        parts = t.split(":")
        return int(parts[0]) * 60 + int(parts[1])
    return t.hour * 60 + t.minute


def minutes_to_time_str(minutes: int) -> str:
    """Converts minutes since midnight to HH:MM string."""
    return f"{minutes // 60:02d}:{minutes % 60:02d}"


# ──────────────────────────────────────────────────────────────────────────────
# SLOT AVAILABILITY ENGINE
# ──────────────────────────────────────────────────────────────────────────────

def get_available_slots(service_id: str, date_str: str, patient_id: Optional[str] = None) -> List[dict]:
    """
    Returns all open 15-minute-aligned slots (08:00–20:00) for a service on a given date.

    A slot is included only when at least one pool caregiver is:
      1. On shift for the full service duration.
      2. Not already booked (confirmed or cart-reserved) during that window.

    If patient_id is supplied, slots that overlap the patient's existing bookings
    on that day are also excluded.

    Response shape per slot:
        { "time": "HH:MM", "caregiver": { "id": "...", "name": "..." } }
    """
    service = service_crud.get(service_id)
    if not service:
        raise ValueError(f"Service with ID {service_id} not found.")
    duration = int(service["duration_minutes"])

    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:

            # Pool caregivers for this service
            cur.execute("""
                SELECT c.id, CONCAT(c.first_name, ' ', c.last_name) AS name
                FROM caregiver_services cs
                JOIN caregivers c ON cs.caregiver_id = c.id
                WHERE cs.service_id = %s;
            """, (service_id,))
            pool = [{"id": str(r["id"]), "name": r["name"]} for r in cur.fetchall()]
            if not pool:
                return []

            pool_ids = [cg["id"] for cg in pool]

            # Caregiver shifts on this date
            cur.execute("""
                SELECT caregiver_id, start_time, end_time
                FROM caregiver_availability
                WHERE scheduled_date = %s;
            """, (date_str,))
            shifts: dict[str, list] = {cg_id: [] for cg_id in pool_ids}
            for row in cur.fetchall():
                cid = str(row["caregiver_id"])
                if cid in shifts:
                    shifts[cid].append((
                        time_to_minutes(row["start_time"]),
                        time_to_minutes(row["end_time"]),
                    ))

            # Confirmed bookings on this date
            cur.execute("""
                SELECT bi.caregiver_id, bi.start_time, s.duration_minutes
                FROM booking_items bi
                JOIN bookings b ON bi.booking_id = b.id
                JOIN services s ON bi.service_id = s.id
                WHERE bi.scheduled_date = %s
                  AND bi.status != 'cancelled'
                  AND b.status  != 'cancelled';
            """, (date_str,))
            busy: dict[str, list] = {cg_id: [] for cg_id in pool_ids}
            for row in cur.fetchall():
                cid = str(row["caregiver_id"])
                if cid in busy:
                    s = time_to_minutes(row["start_time"])
                    busy[cid].append((s, s + int(row["duration_minutes"])))

            # Cart reservations on this date (simulate caregiver assignment)
            cur.execute("""
                SELECT ci.service_id, ci.start_time, s.duration_minutes
                FROM cart_items ci
                JOIN services s ON ci.service_id = s.id
                WHERE ci.scheduled_date = %s
                ORDER BY ci.start_time;
            """, (date_str,))
            for cart_row in cur.fetchall():
                c_start = time_to_minutes(cart_row["start_time"])
                c_end = c_start + int(cart_row["duration_minutes"])
                cur.execute(
                    "SELECT caregiver_id FROM caregiver_services WHERE service_id = %s;",
                    (cart_row["service_id"],)
                )
                svc_pool = [str(r["caregiver_id"]) for r in cur.fetchall()]
                for cid in svc_pool:
                    if cid not in busy:
                        busy[cid] = []
                    if not any(c_start < e and c_end > s for s, e in busy[cid]):
                        busy[cid].append((c_start, c_end))
                        break

            # Patient's existing bookings on this date
            patient_busy: list = []
            if patient_id:
                cur.execute("""
                    SELECT bi.start_time, s.duration_minutes
                    FROM booking_items bi
                    JOIN bookings b ON bi.booking_id = b.id
                    JOIN services s ON bi.service_id = s.id
                    WHERE b.patient_id     = %s
                      AND bi.scheduled_date = %s
                      AND bi.status != 'cancelled'
                      AND b.status  != 'cancelled';
                """, (patient_id, date_str))
                for row in cur.fetchall():
                    s = time_to_minutes(row["start_time"])
                    patient_busy.append((s, s + int(row["duration_minutes"])))

    # Generate slots 08:00–20:00 in 15-minute steps
    available_slots = []
    for slot_start in range(8 * 60, 20 * 60 - duration + 1, 15):
        slot_end = slot_start + duration

        if any(slot_start < p_end and slot_end > p_start for p_start, p_end in patient_busy):
            continue

        assigned = None
        for cg in pool:
            cid = cg["id"]
            on_shift = any(
                s <= slot_start and e >= slot_end
                for s, e in shifts.get(cid, [])
            )
            if not on_shift:
                continue
            if any(slot_start < e and slot_end > s for s, e in busy.get(cid, [])):
                continue
            assigned = cg
            break

        if assigned:
            available_slots.append({
                "time": minutes_to_time_str(slot_start),
                "caregiver": {"id": assigned["id"], "name": assigned["name"]},
            })

    return available_slots


# ──────────────────────────────────────────────────────────────────────────────
# CART OPERATIONS
# ──────────────────────────────────────────────────────────────────────────────

def add_to_cart(data: Dict[str, Any]) -> Dict[str, Any]:
    """Adds a service slot to the global database-backed cart."""
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT id FROM services WHERE id = %s;", (data["service_id"],))
            if not cur.fetchone():
                raise ValueError(f"Service with ID {data['service_id']} does not exist.")

            cur.execute("""
                INSERT INTO cart_items (service_id, scheduled_date, start_time)
                VALUES (%(service_id)s, %(scheduled_date)s, %(start_time)s)
                RETURNING *;
            """, data)
            row = cur.fetchone()
            conn.commit()
            return dict(row) if row else {}


def list_cart() -> List[Dict[str, Any]]:
    """Retrieves all items currently in the global cart, enriched with service info."""
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                SELECT
                    ci.id,
                    ci.service_id,
                    ci.scheduled_date,
                    ci.start_time,
                    ci.created_at,
                    s.name            AS service_name,
                    s.duration_minutes AS service_duration_minutes,
                    s.price           AS service_price
                FROM cart_items ci
                JOIN services s ON ci.service_id = s.id
                ORDER BY ci.created_at DESC;
            """)
            return [dict(row) for row in cur.fetchall()]


def remove_from_cart_by_service(service_id: str) -> int:
    """Removes all cart items for the given service_id. Returns number of rows deleted."""
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("DELETE FROM cart_items WHERE service_id = %s RETURNING id;", (service_id,))
            deleted = cur.fetchall()
            conn.commit()
            return len(deleted)


# ──────────────────────────────────────────────────────────────────────────────
# CHECKOUT / BOOKING ENGINE
# ──────────────────────────────────────────────────────────────────────────────

def checkout_booking(patient_id: str, cart_items: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Atomic checkout transaction.

    Enforces two hard rules before inserting any booking:
      Rule 1 – Patient overlap: a patient cannot have two services whose time
               windows overlap on the same calendar day (checked against both
               the current checkout batch AND existing DB bookings).
      Rule 2 – Caregiver overlap: a caregiver cannot be double-booked.
               Auto-assigns the first available, non-overlapping pool caregiver.

    Clears the global cart on success.
    """
    if not cart_items:
        raise ValueError("Cannot checkout with an empty cart.")

    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            total_price = 0.0
            enriched_items = []

            # patient_busy[date_str]        = [(start, end, service_name), ...]
            # caregiver_busy[(cg_id, date)] = [(start, end), ...]
            patient_busy: Dict[str, list] = {}
            caregiver_busy: Dict[tuple, list] = {}

            for item in cart_items:
                service_id = item["service_id"]
                date_str   = str(item["scheduled_date"])
                start_str  = str(item["start_time"])

                # Fetch service details
                cur.execute(
                    "SELECT price, duration_minutes, name FROM services WHERE id = %s;",
                    (service_id,)
                )
                svc = cur.fetchone()
                if not svc:
                    raise ValueError(f"Service {service_id} not found.")

                duration     = int(svc["duration_minutes"])
                price        = float(svc["price"])
                service_name = svc["name"]
                start_mins   = time_to_minutes(start_str)
                end_mins     = start_mins + duration
                end_str      = minutes_to_time_str(end_mins)

                # ── Rule 1: Patient overlap ───────────────────────────────────
                # 1a. Intra-batch
                for p_start, p_end, p_name in patient_busy.get(date_str, []):
                    if start_mins < p_end and end_mins > p_start:
                        raise ValueError(
                            f"Patient schedule conflict on {date_str}: "
                            f"'{service_name}' ({start_str}–{end_str}) overlaps with "
                            f"'{p_name}' ({minutes_to_time_str(p_start)}–{minutes_to_time_str(p_end)})."
                        )

                # 1b. Existing DB bookings
                cur.execute("""
                    SELECT bi.start_time, s.duration_minutes, s.name AS service_name
                    FROM booking_items bi
                    JOIN bookings b ON bi.booking_id = b.id
                    JOIN services s ON bi.service_id  = s.id
                    WHERE b.patient_id     = %s
                      AND bi.scheduled_date = %s
                      AND bi.status != 'cancelled'
                      AND b.status  != 'cancelled';
                """, (patient_id, date_str))
                for row in cur.fetchall():
                    ex_start = time_to_minutes(row["start_time"])
                    ex_end   = ex_start + int(row["duration_minutes"])
                    if start_mins < ex_end and end_mins > ex_start:
                        raise ValueError(
                            f"Patient schedule conflict on {date_str}: "
                            f"'{service_name}' ({start_str}–{end_str}) overlaps with "
                            f"existing booking '{row['service_name']}' "
                            f"({row['start_time']}–{minutes_to_time_str(ex_end)})."
                        )

                # ── Rule 2: Caregiver auto-assign (no double-booking) ─────────
                cur.execute("""
                    SELECT cs.caregiver_id, CONCAT(c.first_name, ' ', c.last_name) AS name
                    FROM caregiver_services cs
                    JOIN caregivers c ON cs.caregiver_id = c.id
                    WHERE cs.service_id = %s;
                """, (service_id,))
                pool = cur.fetchall()
                if not pool:
                    raise ValueError(
                        f"No caregivers are assigned to the pool for service '{service_name}'."
                    )

                # Pre-fetch all active bookings on this date (reused for all caregivers)
                cur.execute("""
                    SELECT bi.caregiver_id, bi.start_time, s.duration_minutes
                    FROM booking_items bi
                    JOIN bookings b ON bi.booking_id = b.id
                    JOIN services s ON bi.service_id  = s.id
                    WHERE bi.scheduled_date = %s
                      AND bi.status != 'cancelled'
                      AND b.status  != 'cancelled';
                """, (date_str,))
                date_bookings = cur.fetchall()

                assigned_id   = None
                assigned_name = None

                for cg in pool:
                    cg_id   = str(cg["caregiver_id"])
                    cg_name = cg["name"]

                    # Must be on shift for the full slot
                    cur.execute("""
                        SELECT start_time, end_time
                        FROM caregiver_availability
                        WHERE caregiver_id = %s AND scheduled_date = %s;
                    """, (cg_id, date_str))
                    on_shift = any(
                        time_to_minutes(sh["start_time"]) <= start_mins
                        and time_to_minutes(sh["end_time"]) >= end_mins
                        for sh in cur.fetchall()
                    )
                    if not on_shift:
                        continue

                    # Intra-batch conflict
                    if any(
                        start_mins < c_end and end_mins > c_start
                        for c_start, c_end in caregiver_busy.get((cg_id, date_str), [])
                    ):
                        continue

                    # DB conflict
                    if any(
                        str(row["caregiver_id"]) == cg_id
                        and start_mins < (time_to_minutes(row["start_time"]) + int(row["duration_minutes"]))
                        and end_mins   >  time_to_minutes(row["start_time"])
                        for row in date_bookings
                    ):
                        continue

                    assigned_id   = cg_id
                    assigned_name = cg_name
                    break

                if not assigned_id:
                    raise ValueError(
                        f"No available caregiver for '{service_name}' on {date_str} "
                        f"at {start_str}–{end_str}. "
                        f"All pool caregivers are either off-shift or already booked."
                    )

                patient_busy.setdefault(date_str, []).append((start_mins, end_mins, service_name))
                caregiver_busy.setdefault((assigned_id, date_str), []).append((start_mins, end_mins))

                total_price += price
                enriched_items.append({
                    "service_id":     service_id,
                    "caregiver_id":   assigned_id,
                    "scheduled_date": date_str,
                    "start_time":     start_str,
                    "price":          price,
                })

            # Insert booking header
            cur.execute("""
                INSERT INTO bookings (patient_id, total_price, status, payment_status)
                VALUES (%s, %s, 'pending', 'unpaid')
                RETURNING *;
            """, (patient_id, total_price))
            booking_row = cur.fetchone()
            if not booking_row:
                raise RuntimeError("Failed to create booking record.")
            booking_id = booking_row["id"]

            # Insert booking items
            inserted_items = []
            for ei in enriched_items:
                cur.execute("""
                    INSERT INTO booking_items
                        (booking_id, service_id, caregiver_id, scheduled_date, start_time, price, status)
                    VALUES
                        (%(booking_id)s, %(service_id)s, %(caregiver_id)s,
                         %(scheduled_date)s, %(start_time)s, %(price)s, 'scheduled')
                    RETURNING *;
                """, {**ei, "booking_id": booking_id})
                inserted_items.append(dict(cur.fetchone()))

            # Clear cart
            cur.execute("DELETE FROM cart_items;")
            conn.commit()

            result = dict(booking_row)
            result["items"] = inserted_items
            return result

    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
