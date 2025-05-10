from flask import Flask
from flask_cors import CORS
from config import Config
from extensions import db,jwt



def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    # Initialize extensions with app
    db.init_app(app)
    jwt.init_app(app)
    # Enable CORS for all routes
    CORS(app)

    # Import and register blueprints
    from routes.auth import auth_bp
    from routes.box import box_bp
    from routes.item import item_bp
    from routes.history import history_bp
    from routes.box_access import box_access_bp
    from routes.search import search_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(box_bp)
    app.register_blueprint(item_bp)
    app.register_blueprint(history_bp)
    app.register_blueprint(box_access_bp)
    app.register_blueprint(search_bp)

    # Create database tables if they don't exist
    with app.app_context():
        db.create_all()

    return app

# Create the app instance
app = create_app()

if __name__ == '__main__':
    app.run(debug=True,host='0.0.0.0', port=5000)