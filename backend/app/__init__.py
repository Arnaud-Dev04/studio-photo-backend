# Factory pattern Flask — Point d'entrée de l'application
# Initialise toutes les extensions et enregistre les blueprints

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from flask_mail import Mail
from flask_migrate import Migrate
from flasgger import Swagger
import cloudinary

# Extensions globales
db = SQLAlchemy()
mail = Mail()
migrate = Migrate()


def create_app():
    """Crée et configure l'application Flask."""
    app = Flask(__name__)

    # Charger la configuration
    app.config.from_object('app.config.Config')

    # Initialiser les extensions
    db.init_app(app)
    mail.init_app(app)
    migrate.init_app(app, db)
    CORS(app, resources={r"/*": {"origins": "*"}})

    # Configuration Swagger / Flasgger
    swagger_config = {
        "headers": [],
        "specs": [
            {
                "endpoint": "apispec",
                "route": "/apispec.json",
                "rule_filter": lambda rule: True,
                "model_filter": lambda tag: True,
            }
        ],
        "static_url_path": "/flasgger_static",
        "swagger_ui": True,
        "specs_route": "/docs"
    }
    swagger_template = {
        "info": {
            "title": "Studio Photo API",
            "description": "API de gestion de studio photo — Locations, Galerie, Équipe, Finance",
            "version": "1.0.0",
            "contact": {"email": "admin@studio.com"},
        },
        "securityDefinitions": {
            "Bearer": {
                "type": "apiKey",
                "name": "Authorization",
                "in": "header",
                "description": "Token JWT. Format : Bearer <token>"
            }
        },
        "security": [{"Bearer": []}],
        "tags": [
            {"name": "Auth", "description": "Authentification et gestion des membres"},
            {"name": "Matériels", "description": "Catalogue de matériel photo"},
            {"name": "Locations", "description": "Contrats de location"},
            {"name": "Maintenances", "description": "Suivi des maintenances"},
        ]
    }
    Swagger(app, config=swagger_config, template=swagger_template)

    # Configurer Cloudinary
    cloudinary.config(
        cloud_name=app.config['CLOUDINARY_CLOUD_NAME'],
        api_key=app.config['CLOUDINARY_API_KEY'],
        api_secret=app.config['CLOUDINARY_API_SECRET'],
        secure=True
    )

    # Importer les modèles pour que SQLAlchemy les connaisse
    from app.models import user, material, rental, maintenance
    from app.models import album, photo, gallery_token
    from app.models import task, schedule, attendance
    from app.models import invoice, payment, expense, salary_config

    # Enregistrer les blueprints
    from app.blueprints.auth import auth_bp
    app.register_blueprint(auth_bp, url_prefix='/auth')

    from app.blueprints.rentals import rentals_bp
    app.register_blueprint(rentals_bp)

    from app.blueprints.tasks import tasks_bp
    app.register_blueprint(tasks_bp)

    from app.blueprints.attendance import attendance_bp
    app.register_blueprint(attendance_bp)

    from app.blueprints.schedules import schedules_bp
    app.register_blueprint(schedules_bp)

    from app.blueprints.finance import finance_bp
    app.register_blueprint(finance_bp)

    # Endpoint anti-veille pour Render / UptimeRobot
    @app.route('/ping')
    def ping():
        """Endpoint anti-veille
        ---
        tags:
          - Système
        responses:
          200:
            description: Serveur actif
        """
        return {'status': 'ok'}, 200

    # Créer les tables si elles n'existent pas (dev uniquement)
    with app.app_context():
        db.create_all()

    # Initialiser le scheduler pour les alertes automatiques
    from app.scheduler import init_scheduler
    init_scheduler(app)

    return app

