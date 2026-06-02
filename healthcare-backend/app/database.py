import psycopg2
from urllib.parse import urlparse, unquote
from app.config import CONNECTION_URI

def get_connection():
    """
    Establishes and returns a new PostgreSQL database connection.
    """
    parsed = urlparse(CONNECTION_URI)
    return psycopg2.connect(
        database=parsed.path[1:] if parsed.path else None,
        user=parsed.username,
        password=unquote(parsed.password) if parsed.password else None,
        host=parsed.hostname,
        port=parsed.port
    )
