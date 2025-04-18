from flask import request, make_response
from app.services.health_check_service import insert_health_check
from app import logger, statsd
import time

def health_checking(bp):
    def record_health_metrics(status_code: int, duration: float):
        statsd.incr("healthz.called")
        statsd.timing("healthz.response_time", duration)
        statsd.incr(f"healthz.status.{status_code}")

    @bp.route('/cicd', methods=['GET'])
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
        else:
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

    @bp.route('/cicd', methods=['POST', 'PUT', 'DELETE', 'PATCH'])
    def method_not_allowed():
        logger.warning(f"Method {request.method} not allowed on /cicd")
        response = make_response('', 405)  # Method Not Allowed
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['X-Content-Type-Options'] = 'nosniff'
        return response
