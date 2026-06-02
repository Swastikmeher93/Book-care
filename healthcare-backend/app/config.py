import os
from dotenv import load_dotenv

load_dotenv()

# ── PostgreSQL direct connection ──────────────────────────────────────────────
CONNECTION_URI = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres.tntvebgyadjewfervpon:HealthCare123%40%23%24@aws-1-ap-northeast-1.pooler.supabase.com:6543/postgres",
)

# ── Supabase project credentials ──────────────────────────────────────────────
# SUPABASE_KEY must be the SERVICE ROLE key so the backend can create/validate
# auth users server-side without hitting Row Level Security restrictions.
SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")   # service-role key
