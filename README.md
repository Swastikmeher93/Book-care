# FamCARE Healthcare System

A modern healthcare management application featuring a Flutter mobile client and a FastAPI local server backed by PostgreSQL/Supabase.

---

## Repository Structure

- `froentend/` — Flutter application for scheduling, booking, and managing healthcare services.
- `healthcare-backend/` — FastAPI REST API handling user synchronization, availability grids, and atomic booking transactions.

---

## 🚀 Getting Started

### 1. Backend Setup (FastAPI)

#### Prerequisites
* Python 3.9 or higher
* PostgreSQL database (e.g. Supabase instance)

#### Setup Steps
1. Navigate to the backend directory:
   ```bash
   cd healthcare-backend
   ```
2. Create and activate a Python virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Create a `.env` file in the `healthcare-backend/` root directory (refer to `.env.example`):
   ```ini
   DATABASE_URL=postgresql://<user>:<password>@<host>:<port>/<dbname>
   SUPABASE_URL=https://<your-project>.supabase.co
   SUPABASE_KEY=<your-service-role-key>
   ```
5. Launch the FastAPI server:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```
6. (Optional) Populate database with initial mock services, caregivers, and shifts:
   ```bash
   python test_setup.py
   ```

---

### 2. Frontend Setup (Flutter)

#### Prerequisites
* Flutter SDK (Stable channel)
* Android Studio / Xcode (for running on emulators/devices)

#### Setup Steps
1. Navigate to the frontend directory:
   ```bash
   cd froentend
   ```
2. Fetch package dependencies:
   ```bash
   flutter pub get
   ```
3. Configure the backend API endpoint in [api_config.dart](file:///Users/swastik/Projects/health_care/froentend/lib/auth/api_config.dart):
   ```dart
   class ApiConfig {
     static const String baseUrl = 'http://localhost:8000'; // Or your machine's LAN IP
   }
   ```
4. Launch the application:
   ```bash
   flutter run
   ```

---

## 🗄️ Database Schema

The system connects directly to a PostgreSQL database. Below are the key tables and relationships:

```mermaid
erDiagram
    users {
        uuid id PK
        string email
    }
    patients {
        uuid id PK
        uuid user_id FK "refers users(id)"
        string first_name
        string last_name
        string email
        string phone
        timestamp created_at
    }
    services {
        uuid id PK
        string name
        text description
        integer duration_minutes
        numeric price
        string location
        timestamp created_at
    }
    caregivers {
        uuid id PK
        string first_name
        string last_name
        string email
        string phone
        string specialty
        numeric hourly_rate
        timestamp created_at
    }
    caregiver_services {
        uuid caregiver_id PK, FK "refers caregivers(id)"
        uuid service_id PK, FK "refers services(id)"
    }
    caregiver_availability {
        uuid id PK
        uuid caregiver_id FK "refers caregivers(id)"
        date scheduled_date
        time start_time
        time end_time
        timestamp created_at
    }
    cart_items {
        uuid id PK
        uuid service_id FK "refers services(id)"
        date scheduled_date
        time start_time
        timestamp created_at
    }
    bookings {
        uuid id PK
        uuid patient_id FK "refers patients(id)"
        numeric total_price
        string status
        string payment_status
        timestamp created_at
    }
    booking_items {
        uuid id PK
        uuid booking_id FK "refers bookings(id)"
        uuid service_id FK "refers services(id)"
        uuid caregiver_id FK "refers caregivers(id)"
        date scheduled_date
        time start_time
        numeric price
        string status
        timestamp created_at
    }

    users ||--o| patients : "links profile"
    patients ||--o{ bookings : "makes"
    bookings ||--|{ booking_items : "contains"
    services ||--o{ booking_items : "booked under"
    caregivers ||--o{ booking_items : "assigned to"
    caregivers ||--|{ caregiver_services : "belongs to"
    services ||--|{ caregiver_services : "contains"
    caregivers ||--o{ caregiver_availability : "declares shift"
    services ||--o{ cart_items : "saved in cart"
```

### Table Definitions

1. **`patients`**
   * Links a registered person to their Supabase user ID (`user_id` referencing `auth.users`).
   * Supports local profile auto-seeding if no profile is active.

2. **`services`**
   * Lists available healthcare offerings (e.g. Physiotherapy Session, Wound Care) including pricing and clinic rooms.

3. **`caregivers`**
   * Stores healthcare professionals, specialties, and hourly rates.

4. **`caregiver_services`**
   * Association pool table mapping which caregivers are certified to perform which services.

5. **`caregiver_availability`**
   * Defines caregiver shifts (e.g., `08:00` to `18:00`) for specific calendar dates.
   * If no explicit shifts are configured in this table, the backend falls back to a default `08:00 - 20:00` schedule.

6. **`bookings` & `booking_items`**
   * Transactions representing finalized bookings, referencing patient orders, caregivers assigned, and appointment times.
