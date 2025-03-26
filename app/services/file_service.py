import os
import boto3
from werkzeug.utils import secure_filename
from datetime import datetime
import uuid
import time
from app.models.model import File
from app.models.database import db
from app.config import S3_BUCKET_NAME
from app import logger
from aws_embedded_metrics import metric_scope

# Initialize S3 Client
s3 = boto3.client("s3")
S3_BUCKET = S3_BUCKET_NAME

@metric_scope
def record_metric(metrics, action, duration, metric_type):
    metrics.set_namespace("WebAppMetrics")
    metrics.put_metric(f"{action}_{metric_type}_Duration", duration, "Milliseconds")

def upload_file_to_s3(file):
    """Uploads a file to S3 and stores metadata in DB."""
    file_name = secure_filename(file.filename)
    file_id = str(uuid.uuid4())
    s3_key = f"{file_id}/{file_name}"

    try:
        logger.info(f"Uploading file {file_name} to S3 with key {s3_key}")
        s3_start = time.time()
        # Upload file to S3
        s3.upload_fileobj(file, S3_BUCKET, s3_key)
        s3_duration = (time.time() - s3_start) * 1000
        record_metric("UploadFile", s3_duration, "S3")

        logger.info("Storing file metadata in DB")
        db_start = time.time()
        # Store metadata in database
        new_file = File(
            id=file_id,
            file_name=file_name,
            url=f"{S3_BUCKET}/{s3_key}",
            upload_date=datetime.utcnow()
        )
        db.session.add(new_file)
        db.session.commit()
        db_duration = (time.time() - db_start) * 1000
        record_metric("UploadFile", db_duration, "DB")

        logger.info(f"File uploaded and saved successfully with ID {file_id}")
        return new_file.to_dict(), None

    except Exception as e:
        db.session.rollback()
        logger.error(f"Error during upload_file_to_s3: {str(e)}", exc_info=True)
        return None, str(e)


def get_file_metadata(file_id):
    """Fetches file metadata from the database."""
    logger.info(f"Fetching file metadata for ID {file_id}")
    file = File.query.get(file_id)
    try:
        db_start = time.time()
        file = File.query.get(file_id)
        db_duration = (time.time() - db_start) * 1000
        record_metric("GetFile", db_duration, "DB")

        if not file:
            logger.warning(f"File not found for ID: {file_id}")
            return None, "File not found"
        logger.info(f"File metadata found for ID: {file_id}")
        return file.to_dict(), None
    except Exception as e:
        logger.error(f"Error fetching file metadata: {str(e)}", exc_info=True)
        return None, str(e)

def delete_file_from_s3(file_id):
    """Deletes a file from S3 and removes metadata from the database."""
    logger.info(f"Deleting file with ID {file_id}")
    file = File.query.get(file_id)
    if not file:
        logger.warning(f"File not found for deletion: {file_id}")
        return None, "File not found"

    try:
        s3_key = file.url.split(f"{S3_BUCKET}/")[-1]
        logger.info(f"Deleting from S3 key: {s3_key}")
        s3_start = time.time()
        s3.delete_object(Bucket=S3_BUCKET, Key=s3_key)
        s3_duration = (time.time() - s3_start) * 1000
        record_metric("DeleteFile", s3_duration, "S3")

        logger.info("Deleting metadata from DB")
        db_start = time.time()
        db.session.delete(file)
        db.session.commit()
        db_duration = (time.time() - db_start) * 1000
        record_metric("DeleteFile", db_duration, "DB")

        logger.info(f"File deleted successfully: {file_id}")
        return {"message": "File deleted"}, None

    except Exception as e:
        db.session.rollback()
        logger.error(f"Error deleting file: {str(e)}", exc_info=True)
        return None, str(e)
