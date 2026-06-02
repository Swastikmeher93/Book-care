class MockUser:
    def __init__(self):
        # A static mock UUID that maps to a local patient
        self.id = "4403d2d2-d4d2-4b2f-a47b-833412027346"
        self.email = "john.smith@example.com"
        self.user_metadata = {
            "given_name": "John",
            "family_name": "Smith",
            "full_name": "John Smith"
        }

def get_current_user():
    """
    Mock get_current_user dependency that returns a MockUser.
    Bypasses token verification so the frontend can sync the patient profile locally.
    """
    return MockUser()

def get_supabase_client():
    return None
