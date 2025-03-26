from app.models.model import HealthCheck
from app.models.database import db
from app import logger, statsd  # 👈 Import statsd from __init__.py
import time

# DB insert method
def insert_health_check():
    logger.info("Inserting health check record into DB")
    start_time = time.time()

    try:
        new_check = HealthCheck()
        db.session.add(new_check)
        db.session.commit()

        duration = (time.time() - start_time) * 1000  # milliseconds
        statsd.timing("health_check.db_duration", duration)  # ✅ Metric: DB insert time
        statsd.gauge("health_check.db_status", 1)  # ✅ Metric: 1 for success

        logger.info("Health check inserted successfully")
        return True
    except Exception as e:
        db.session.rollback()
        duration = (time.time() - start_time) * 1000
        statsd.timing("health_check.db_duration", duration)
        statsd.gauge("health_check.db_status", 0)  # 0 for failure

        logger.error(f"Error inserting health check: {str(e)}", exc_info=True)
        print(f"Error inserting health check: {e}")
        return False

# @metric_scope
# def emit_health_metrics(metrics, success: bool, duration: float):
#     metrics.set_namespace("WebAppMetrics")
#     metrics.put_metric("HealthCheck_DB_Duration", duration, "Milliseconds")
#     metrics.put_metric("HealthCheck_Status", 1 if success else 0, "None")