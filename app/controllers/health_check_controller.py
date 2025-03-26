from flask import request, make_response
from app.services.health_check_service import insert_health_check
from aws_embedded_metrics import metric_scope
import time
from app import logger

def health_checking(bp):
    @metric_scope
    def record_health_metrics(metrics, status_code, duration):
        metrics.set_namespace("WebAppMetrics")
        metrics.put_metric("HealthCheck_Call_Count", 1, "Count")
        metrics.put_metric("HealthCheck_Response_Time", duration, "Milliseconds")
        metrics.put_metric("HealthCheck_Status", status_code, "None")

    @bp.route('/healthz', methods=['GET'])
    def health_check():
        # Disallow payloads in GET requests
        logger.info("GET /healthz called")
        start_time = time.time()

        # Check if there are query parameters or body data
        if request.args or (request.data and request.data.strip()):  # Handles cases like /healthz?param=value
            logger.warning("Invalid payload/query on GET /healthz")
            response = make_response('', 400)  # Bad Request
            response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
            response.headers['Pragma'] = 'no-cache'
            response.headers['X-Content-Type-Options'] = 'nosniff'
            return response
         
        # Attempt to insert a health check record
        if insert_health_check():  # Call from the service module
            logger.info("Health check passed")
            response = make_response('', 200)  # OK
        else:
            logger.error("Health check failed - service unavailable")
            response = make_response('', 503)  # Service Unavailable

        duration = (time.time() - start_time) * 1000
        record_health_metrics(response.status_code, duration)

        # Add necessary headers
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['X-Content-Type-Options'] = 'nosniff'
        return response

    @bp.route('/healthz', methods=['POST', 'PUT', 'DELETE', 'PATCH'])
    def method_not_allowed():
        logger.warning(f"Method {request.method} not allowed on /healthz")
        response = make_response('', 405)  # Method Not Allowed
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['X-Content-Type-Options'] = 'nosniff'
        return response
