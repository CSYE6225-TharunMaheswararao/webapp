from app.controllers.health_check_controller import health_check_bp

def register_routes(app):
    app.register_blueprint(health_check_bp)
