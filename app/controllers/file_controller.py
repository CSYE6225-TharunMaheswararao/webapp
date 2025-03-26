from flask import request, jsonify, make_response
from app.services.file_service import upload_file_to_s3, get_file_metadata, delete_file_from_s3
from app import logger, statsd  # ✅ import StatsD
import time

def file_routes(bp):
    def record_api_metrics(api_name: str, duration: float):
        statsd.incr(f"{api_name}.called")
        statsd.timing(f"{api_name}.duration", duration)

    @bp.route('/v1/file', methods=['POST'])
    def upload_file():
        logger.info("POST /v1/file called")
        start_time = time.time()

        """Uploads a file to S3 and stores metadata in DB."""
        if "file" not in request.files:
            logger.warning("No file part in request")
            return make_response(jsonify({"error": "No file part"}), 400)

        file = request.files["file"]
        if file.filename == "":
            logger.warning("Empty filename in upload")
            return make_response(jsonify({"error": "No selected file"}), 400)

        file_data, error = upload_file_to_s3(file)
        duration = (time.time() - start_time) * 1000
        record_api_metrics("UploadFile", duration)
        if error:
            logger.error(f"File upload failed: {error}")
            return make_response(jsonify({"error": error}), 500)

        logger.info(f"File uploaded successfully: {file_data['id']}")
        return make_response(jsonify(file_data), 201)
    
    @bp.route('/v1/file', methods=['GET', 'DELETE', 'HEAD', 'OPTIONS', 'PATCH', 'PUT'])
    def method_not_allowed():
        logger.warning(f"Method {request.method} not allowed on /v1/file")
        response = make_response('', 405)  # Method Not Allowed
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['X-Content-Type-Options'] = 'nosniff'
        return response

    @bp.route('/v1/file/<file_id>', methods=['GET'])
    def get_file(file_id):
        """Fetches file metadata from the database."""
        logger.info(f"GET /v1/file/{file_id} called")
        start_time = time.time()

        file_data, error = get_file_metadata(file_id)
        duration = (time.time() - start_time) * 1000
        record_api_metrics("GetFile", duration)
        if error:
            logger.warning(f"File not found: {file_id}")
            return make_response(jsonify({"error": error}), 404)

        logger.info(f"File metadata retrieved: {file_id}")
        return make_response(jsonify(file_data), 200)

    @bp.route('/v1/file/<file_id>', methods=['DELETE'])
    def delete_file(file_id):
        """Deletes a file from S3 and removes metadata from the database."""
        logger.info(f"DELETE /v1/file/{file_id} called")
        start_time = time.time()

        result, error = delete_file_from_s3(file_id)
        duration = (time.time() - start_time) * 1000
        record_api_metrics("DeleteFile", duration)
        if error:
            logger.warning(f"File delete failed: {error}")
            return make_response(jsonify({"error": error}), 404)

        logger.info(f"File deleted: {file_id}")
        return make_response(jsonify(result), 200)
    
    @bp.route('/v1/file/<file_id>', methods=['POST', 'HEAD', 'OPTIONS', 'PATCH', 'PUT'])
    def fileid_method_not_allowed(file_id):
        logger.warning(f"Method {request.method} not allowed on /v1/file/{file_id}")
        response = make_response('', 405)  # Method Not Allowed
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['X-Content-Type-Options'] = 'nosniff'
        return response
