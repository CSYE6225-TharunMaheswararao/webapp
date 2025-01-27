from app.models.model import HealthCheck
from app.models.database import db

class HealthCheckService:
    @staticmethod
    def insert_health_check():
        try:
            new_check = HealthCheck()
            db.session.add(new_check)
            db.session.commit()
            return True
        except Exception as e:
            db.session.rollback()
            print(f"Error inserting health check: {e}")
            return False
