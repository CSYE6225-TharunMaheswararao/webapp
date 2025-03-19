import os
import boto3
from werkzeug.utils import secure_filename
from datetime import datetime
import uuid
from app.models.model import File
from app.models.database import db

# Initialize S3 Client
s3 = boto3.client("s3")
S3_BUCKET = os.getenv("S3_BUCKET")

def upload_file_to_s3(file):
    """Uploads a file to S3 and stores metadata in DB."""
    file_name = secure_filename(file.filename)
    file_id = str(uuid.uuid4())
    s3_key = f"{file_id}/{file_name}"

    try:
        # Upload file to S3
        s3.upload_fileobj(file, S3_BUCKET, s3_key)

        # Store metadata in database
        new_file = File(
            id=file_id,
            file_name=file_name,
            url=f"{S3_BUCKET}/{s3_key}",
            upload_date=datetime.utcnow()
        )
        db.session.add(new_file)
        db.session.commit()

        return new_file.to_dict(), None

    except Exception as e:
        db.session.rollback()
        return None, str(e)


def get_file_metadata(file_id):
    """Fetches file metadata from the database."""
    file = File.query.get(file_id)
    if not file:
        return None, "File not found"
    return file.to_dict(), None


def delete_file_from_s3(file_id):
    """Deletes a file from S3 and removes metadata from the database."""
    file = File.query.get(file_id)
    if not file:
        return None, "File not found"

    try:
        s3_key = file.url.split(f"{S3_BUCKET}/")[-1]
        s3.delete_object(Bucket=S3_BUCKET, Key=s3_key)

        db.session.delete(file)
        db.session.commit()

        return {"message": "File deleted"}, None

    except Exception as e:
        db.session.rollback()
        return None, str(e)
