from app.models.database import db
from datetime import datetime

class HealthCheck(db.Model):
    __tablename__ = 'health_check'
    id = db.Column(db.Integer, primary_key=True, auto_increment=True)
    datetime = db.Column(db.DateTime, default=datetime.utcnow)

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