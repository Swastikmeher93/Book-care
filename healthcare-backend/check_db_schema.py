import psycopg2
from psycopg2.extras import RealDictCursor

conn_uri = "postgresql://postgres.tntvebgyadjewfervpon:HealthCare123%40%23%24@aws-1-ap-northeast-1.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(conn_uri)
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        # Query column information for patients table
        cur.execute("""
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns
            WHERE table_name = 'patients';
        """)
        columns = cur.fetchall()
        print("Columns:")
        for col in columns:
            print(f"  {col['column_name']}: {col['data_type']} | Nullable: {col['is_nullable']} | Default: {col['column_default']}")
            
        # Also query table constraints
        cur.execute("""
            SELECT conname, pg_get_constraintdef(c.oid)
            FROM pg_constraint c
            JOIN pg_namespace n ON n.oid = c.connamespace
            WHERE conrelid = 'patients'::regclass;
        """)
        constraints = cur.fetchall()
        print("\nConstraints:")
        for cons in constraints:
            print(f"  {cons['conname']}: {cons['pg_get_constraintdef']}")
            
    conn.close()
except Exception as e:
    import traceback
    print("Error:", e)
    traceback.print_exc()
