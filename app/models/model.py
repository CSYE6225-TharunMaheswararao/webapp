import uuid
from app.models.database import db
from datetime import datetime

class HealthCheck(db.Model):
    __tablename__ = 'health_check'
    id = db.Column(db.Integer, primary_key=True, auto_increment=True)
    datetime = db.Column(db.DateTime(timezone=True), default=datetime.utcnow)

class File(db.Model):
    __tablename__ = "files"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    file_name = db.Column(db.String(255), nullable=False)
    url = db.Column(db.String(512), nullable=False, unique=True)
    upload_date = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "file_name": self.file_name,
            "url": self.url,
            "upload_date": self.upload_date.strftime("%Y-%m-%d")
        }

##### HELPER METHODS ######
def create_all_tables():
    db.create_all()

def insert_row(row):
    db.session.add(row)
    db.session.flush()


def insert_multiple_row(rows):
    db.session.add_all(rows)
    db.session.flush()


def commit_session():
    db.session.commit()


def rollback_session():
    db.session.rollback()
    db.session.commit()


def delete_row(rows):
    db.session.delete(rows)
    db.session.flush()