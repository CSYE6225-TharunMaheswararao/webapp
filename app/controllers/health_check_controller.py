from flask import request, make_response
from app.services.health_check_service import insert_health_check

def health_checking(bp):
    @bp.route('/healthz', methods=['GET'])
    def health_check():
        # Disallow payloads in GET requests
        if request.data:
            response = make_response('', 400)  # Bad Request
            response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
            response.headers['Pragma'] = 'no-cache'
            response.headers['X-Content-Type-Options'] = 'nosniff'
            return response
        
        # Attempt to insert a health check record
        if insert_health_check():
            response = make_response('', 200)  # OK
        else:
            response = make_response('', 503)  # Service Unavailable

        # Add necessary headers
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['X-Content-Type-Options'] = 'nosniff'
        return response

    @bp.route('/healthz', methods=['POST', 'PUT', 'DELETE', 'PATCH'])
    def method_not_allowed():
        response = make_response('', 405)  # Method Not Allowed
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['X-Content-Type-Options'] = 'nosniff'
        return response
