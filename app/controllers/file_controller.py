from flask import request, jsonify, make_response
from app.services.file_service import upload_file_to_s3, get_file_metadata, delete_file_from_s3

def file_routes(bp):
    @bp.route('/v1/file', methods=['POST'])
    def upload_file():
        """Uploads a file to S3 and stores metadata in DB."""
        if "file" not in request.files:
            return make_response(jsonify({"error": "No file part"}), 400)

        file = request.files["file"]
        if file.filename == "":
            return make_response(jsonify({"error": "No selected file"}), 400)

        file_data, error = upload_file_to_s3(file)
        if error:
            return make_response(jsonify({"error": error}), 500)

        return make_response(jsonify(file_data), 201)
    
    @bp.route('/v1/file', methods=['GET', 'DELETE', 'HEAD', 'OPTIONS', 'PATCH', 'PUT'])
    def method_not_allowed():
        response = make_response('', 405)  # Method Not Allowed
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['X-Content-Type-Options'] = 'nosniff'
        return response

    @bp.route('/v1/file/<file_id>', methods=['GET'])
    def get_file(file_id):
        """Fetches file metadata from the database."""
        file_data, error = get_file_metadata(file_id)
        if error:
            return make_response(jsonify({"error": error}), 404)

        return make_response(jsonify(file_data), 200)

    @bp.route('/v1/file/<file_id>', methods=['DELETE'])
    def delete_file(file_id):
        """Deletes a file from S3 and removes metadata from the database."""
        result, error = delete_file_from_s3(file_id)
        if error:
            return make_response(jsonify({"error": error}), 404)

        return make_response(jsonify(result), 200)
    
    @bp.route('/v1/file/<file_id>', methods=['POST', 'HEAD', 'OPTIONS', 'PATCH', 'PUT'])
    def method_not_allowed():
        response = make_response('', 405)  # Method Not Allowed
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['X-Content-Type-Options'] = 'nosniff'
        return response
