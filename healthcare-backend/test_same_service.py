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
    print("Initializing database tables...")
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

def test_same_service_multi_booking():
    setup_db()
    
    print("\n--- Cleaning up old data for fresh test run ---")
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM booking_items;")
            cur.execute("DELETE FROM bookings;")
            cur.execute("DELETE FROM cart_items;")
            cur.execute("DELETE FROM caregiver_availability;")
            cur.execute("DELETE FROM caregiver_services;")
            cur.execute("DELETE FROM services;")
            cur.execute("DELETE FROM caregivers;")
            cur.execute("DELETE FROM patients;")
            conn.commit()

    print("Seeding service 'Physiotherapy Session'...")
    physio_svc = service_crud.create({
        "name": "Physiotherapy Session",
        "description": "Personalized rehabilitation and mobility therapy.",
        "duration_minutes": 45,
        "price": 80.00,
        "location": "Room 3, Floor 2"
    })

    print("Seeding caregiver 'Dr. Sarah Lee'...")
    sarah = caregiver_crud.create({
        "first_name": "Dr. Sarah",
        "last_name": "Lee",
        "email": "sarah.lee@example.com",
        "phone": "555-0101",
        "specialty": "Physiotherapy",
        "hourly_rate": 60.0
    })

    print("Assigning Dr. Sarah Lee to Physiotherapy pool...")
    service_crud.assign_caregiver_to_service(physio_svc["id"], sarah["id"])

    print("Seeding Dr. Sarah Lee shift availability on 2026-06-14 and 2026-06-15 (08:00 - 18:00)...")
    caregiver_crud.add_availability(sarah["id"], {
        "scheduled_date": "2026-06-14",
        "start_time": "08:00",
        "end_time": "18:00"
    })
    caregiver_crud.add_availability(sarah["id"], {
        "scheduled_date": "2026-06-15",
        "start_time": "08:00",
        "end_time": "18:00"
    })

    print("Seeding patient 'John Smith'...")
    patient = patient_crud.create({
        "first_name": "John",
        "last_name": "Smith",
        "email": "john.smith@example.com",
        "phone": "555-0123"
    })

    print("\n--- Adding same service for different dates & times to the cart ---")
    item1 = cart_crud.add_to_cart({
        "service_id": physio_svc["id"],
        "scheduled_date": "2026-06-14",
        "start_time": "09:00"
    })
    print(f"Added Item 1: Service {item1['service_id']} on {item1['scheduled_date']} at {item1['start_time']}")

    item2 = cart_crud.add_to_cart({
        "service_id": physio_svc["id"],
        "scheduled_date": "2026-06-15",
        "start_time": "14:30"
    })
    print(f"Added Item 2: Service {item2['service_id']} on {item2['scheduled_date']} at {item2['start_time']}")

    print("\n--- Listing Cart Items ---")
    cart_list = cart_crud.list_cart()
    for item in cart_list:
        print(f"  Cart Item ID: {item['id']} | Service: {item['service_name']} | Date: {item['scheduled_date']} | Time: {item['start_time']}")

    print("\n--- Performing Checkout for patient ---")
    try:
        checkout_items = [
            {
                "service_id": physio_svc["id"],
                "scheduled_date": "2026-06-14",
                "start_time": "09:00"
            },
            {
                "service_id": physio_svc["id"],
                "scheduled_date": "2026-06-15",
                "start_time": "14:30"
            }
        ]
        booking = cart_crud.checkout_booking(patient["id"], checkout_items)
        print("Checkout SUCCESSFUL!")
        print(f"Booking ID: {booking['id']}")
        print(f"Patient ID: {booking['patient_id']}")
        print(f"Total Price: ${booking['total_price']}")
        print("Booking Items:")
        for item in booking["items"]:
            print(f"  - Item ID: {item['id']} | Caregiver: {item['caregiver_id']} | Date: {item['scheduled_date']} | Time: {item['start_time']} | Price: ${item['price']}")
        
        # Verify cart was cleared
        remaining_cart = cart_crud.list_cart()
        print(f"Remaining items in cart after checkout: {len(remaining_cart)}")
        if len(remaining_cart) == 0:
            print("Cart successfully cleared after checkout.")
    except Exception as e:
        print(f"Checkout FAILED with error: {str(e)}")

if __name__ == "__main__":
    test_same_service_multi_booking()
