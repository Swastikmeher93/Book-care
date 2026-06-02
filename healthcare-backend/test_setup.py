import sys
import os

# Add workspace directory to path
sys.path.append("/Users/swastik/Projects/healthcare-backend")

from app.database import get_connection
import app.crud.service as service_crud
import app.crud.caregiver as caregiver_crud
import app.crud.patient as patient_crud
import app.crud.cart as cart_crud

def setup_db():
    print("Setting up database tables...")
    with get_connection() as conn:
        with conn.cursor() as cur:
            # Create caregiver_services pool table
            cur.execute("""
            CREATE TABLE IF NOT EXISTS caregiver_services (
                caregiver_id UUID REFERENCES caregivers(id) ON DELETE CASCADE,
                service_id UUID REFERENCES services(id) ON DELETE CASCADE,
                PRIMARY KEY (caregiver_id, service_id)
            );
            """)
            # Create global cart_items table
            cur.execute("""
            CREATE TABLE IF NOT EXISTS cart_items (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                service_id UUID REFERENCES services(id) ON DELETE CASCADE,
                scheduled_date DATE NOT NULL,
                start_time TIME NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """)
            # Create caregiver_availability table
            cur.execute("""
            CREATE TABLE IF NOT EXISTS caregiver_availability (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                caregiver_id UUID REFERENCES caregivers(id) ON DELETE CASCADE,
                scheduled_date DATE NOT NULL,
                start_time TIME NOT NULL,
                end_time TIME NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """)
            conn.commit()
    print("Database tables initialized successfully.")

def seed_mockup_data():
    print("\n--- Seeding mockup data matching UI screenshot ---")
    with get_connection() as conn:
        with conn.cursor() as cur:
            # 1. Clean existing records for a fresh test run
            print("Cleaning up old test bookings, availabilities, and pools...")
            cur.execute("DELETE FROM booking_items;")
            cur.execute("DELETE FROM bookings;")
            cur.execute("DELETE FROM cart_items;")
            cur.execute("DELETE FROM caregiver_availability;")
            cur.execute("DELETE FROM caregiver_services;")
            cur.execute("DELETE FROM services;")
            cur.execute("DELETE FROM caregivers;")
            cur.execute("DELETE FROM patients;")
            conn.commit()

    # 2. Create "Physiotherapy Session" Service ($80, 45 minutes, Room 3, Floor 2)
    print("Seeding Physiotherapy Session service...")
    physio_svc = service_crud.create({
        "name": "Physiotherapy Session",
        "description": "Personalized rehabilitation and mobility therapy with certified specialists.",
        "duration_minutes": 45,
        "price": 80.00,
        "location": "Room 3, Floor 2"
    })

    # 3. Create caregiver "Dr. Sarah Lee"
    print("Seeding caregiver Dr. Sarah Lee...")
    sarah = caregiver_crud.create({
        "first_name": "Dr. Sarah",
        "last_name": "Lee",
        "email": "sarah.lee@example.com",
        "phone": "555-0101",
        "specialty": "Physiotherapy",
        "hourly_rate": 60.0
    })

    # 4. Map Dr. Sarah Lee to Physiotherapy pool
    print("Assigning Dr. Sarah Lee to pool...")
    service_crud.assign_caregiver_to_service(physio_svc["id"], sarah["id"])

    # 5. Seed Dr. Sarah Lee availability shift on Wednesday 2026-06-14 (08:00 to 18:00)
    print("Seeding Dr. Sarah Lee shift availability (08:00 - 18:00)...")
    caregiver_crud.add_availability(sarah["id"], {
        "scheduled_date": "2026-06-14",
        "start_time": "08:00",
        "end_time": "18:00"
    })

    # 6. Create a test patient
    print("Seeding patient...")
    patient = patient_crud.create({
        "first_name": "John",
        "last_name": "Smith",
        "email": "john.smith@example.com",
        "phone": "555-0123"
    })

    # 7. Seed an existing booking for Dr. Sarah Lee at 12:00 to 12:45 to block the 12:00 PM slot
    print("Seeding existing booking at 12:00 PM to block it...")
    with get_connection() as conn:
        with conn.cursor() as cur:
            # Create a booking
            cur.execute("""
            INSERT INTO bookings (patient_id, total_price, status, payment_status)
            VALUES (%s, %s, 'pending', 'unpaid')
            RETURNING id;
            """, (patient["id"], 80.00))
            booking_id = cur.fetchone()[0]

            # Create the booking item for Dr. Sarah Lee at 12:00
            cur.execute("""
            INSERT INTO booking_items (booking_id, service_id, caregiver_id, scheduled_date, start_time, price, status)
            VALUES (%s, %s, %s, '2026-06-14', '12:00', 80.00, 'scheduled');
            """, (booking_id, physio_svc["id"], sarah["id"]))
            conn.commit()

    return physio_svc, sarah, patient

def run_tests():
    setup_db()
    physio_svc, sarah, patient = seed_mockup_data()

    print("\n--- Listing Available Slots for Wednesday 2026-06-14 ---")
    slots = cart_crud.get_available_slots(physio_svc["id"], "2026-06-14")
    print(f"Available slots ({len(slots)} total):")
    
    # We will print out the status of key mockup slots to verify
    target_slots = ["09:00", "10:30", "12:00", "14:00", "16:00", "17:30"]
    available_times = {s["time"]: s for s in slots}
    
    print("\nMockup UI Slot Status:")
    for ts in target_slots:
        if ts in available_times:
            cg = available_times[ts]["caregiver"]
            print(f"  [AVAILABLE]   {ts} -> caregiver: {cg['name']} (ID: {cg['id']})")
        else:
            print(f"  [UNAVAILABLE] {ts} -> (Caregiver busy or off-shift)")

if __name__ == "__main__":
    run_tests()
