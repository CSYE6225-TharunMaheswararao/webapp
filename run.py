from flask import Flask
from flask_cors import CORS
from app.models.database import db
from app.models import model
import app.config as config

app = Flask(__name__)
cors = CORS(app, resources={r"/*": {"origins": "*"}})

# DATABASE CONFIGURATIONS
db_uri = config.get_db_uri()

# FLASK APP CONFIGURATIONS
app.config['SQLALCHEMY_DATABASE_URI'] = db_uri
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['CORS_HEADERS'] = 'Content-Type'

# INITIATE DB OBJECT
db.init_app(app)
with app.app_context():
    model.create_all_tables()

if __name__ == '__main__':
    app.run(host="127.0.0.1", port=8000, debug=True)