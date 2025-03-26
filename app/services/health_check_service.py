from app.models.model import HealthCheck
from app.models.database import db
from app import logger
from aws_embedded_metrics import metric_scope, MetricsLogger
import time

# DB insert method
@metric_scope
def insert_health_check(metrics: MetricsLogger) -> bool:
    logger.info("Inserting health check record into DB")
    start_time = time.time()

    try:
        new_check = HealthCheck()
        db.session.add(new_check)
        db.session.commit()

        duration = (time.time() - start_time) * 1000
        metrics.set_namespace("WebAppMetrics")
        metrics.put_metric("HealthCheck_DB_Duration", duration, "Milliseconds")
        metrics.put_metric("HealthCheck_Status", 1)
        logger.info("Health check inserted successfully")
        return True
    except Exception as e:
        db.session.rollback()
        duration = (time.time() - start_time) * 1000
        metrics.set_namespace("WebAppMetrics")
        metrics.put_metric("HealthCheck_DB_Duration", duration, "Milliseconds")
        metrics.put_metric("HealthCheck_Status", 0)
        logger.error(f"Error inserting health check: {str(e)}", exc_info=True)
        print(f"Error inserting health check: {e}")
        return False
