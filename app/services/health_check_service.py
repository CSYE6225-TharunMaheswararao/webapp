from app.models.model import HealthCheck
from app.models.database import db
from app import logger
from aws_embedded_metrics import metric_scope
import time

# DB insert method
def insert_health_check():
    # logger.info("Inserting health check record into DB")
    # start_time = time.time()

    try:
        new_check = HealthCheck()
        db.session.add(new_check)
        db.session.commit()

        # duration = (time.time() - start_time) * 1000
        # emit_health_metrics(success=True, duration=duration)
        # logger.info("Health check inserted successfully")
        return True
    except Exception as e:
        db.session.rollback()
        # duration = (time.time() - start_time) * 1000
        # emit_health_metrics(success=False, duration=duration)
        # logger.error(f"Error inserting health check: {str(e)}", exc_info=True)
        print(f"Error inserting health check: {e}")
        return False

# @metric_scope
# def emit_health_metrics(metrics, success: bool, duration: float):
#     metrics.set_namespace("WebAppMetrics")
#     metrics.put_metric("HealthCheck_DB_Duration", duration, "Milliseconds")
#     metrics.put_metric("HealthCheck_Status", 1 if success else 0, "None")