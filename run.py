from flask import Blueprint, Flask
from flask_cors import CORS
from app.controllers.health_check_controller import health_checking
from app.models.database import db
from app.models import model
from app.config import get_db_uri

app = Flask(__name__)
cors = CORS(app, resources={r"/*": {"origins": "*"}})

# DATABASE CONFIGURATIONS
db_uri = get_db_uri()

# FLASK APP CONFIGURATIONS
app.config['SQLALCHEMY_DATABASE_URI'] = db_uri
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['CORS_HEADERS'] = 'Content-Type'

# INITIATE DB OBJECT
db.init_app(app)
with app.app_context():
    model.create_all_tables()

# API Blueprint
health_api_blueprint = Blueprint('health_api', __name__)    
health_checking(health_api_blueprint)

app.register_blueprint(health_api_blueprint)

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8080, debug=True)