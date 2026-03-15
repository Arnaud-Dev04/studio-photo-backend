# Fichier de configuration Flask
# Charge les variables d'environnement depuis .env ou depuis l'hôte Render

import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Configuration de base pour l'application Flask."""

    # --- Flask ---
    SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'dev-secret-key-a-changer')
    DEBUG = os.getenv('FLASK_DEBUG', '0') == '1'

    # --- Base de données PostgreSQL (Supabase) ---
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'sqlite:///dev.db')
    # Render utilise parfois 'postgres://' au lieu de 'postgresql://'
    if SQLALCHEMY_DATABASE_URI.startswith('postgres://'):
        SQLALCHEMY_DATABASE_URI = SQLALCHEMY_DATABASE_URI.replace('postgres://', 'postgresql://', 1)
    # Ajouter sslmode et timeout pour Supabase si c'est PostgreSQL
    if 'postgresql' in SQLALCHEMY_DATABASE_URI and 'sslmode' not in SQLALCHEMY_DATABASE_URI:
        separator = '&' if '?' in SQLALCHEMY_DATABASE_URI else '?'
        SQLALCHEMY_DATABASE_URI += f'{separator}sslmode=require&connect_timeout=10'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_recycle': 300,
        'pool_pre_ping': True,
        'pool_size': 5,
        'max_overflow': 10,
    }

    # --- JWT ---
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'dev-secret-key-a-changer')
    JWT_ACCESS_TOKEN_EXPIRES = 86400  # 24 heures en secondes

    # --- Cloudinary ---
    CLOUDINARY_CLOUD_NAME = os.getenv('CLOUDINARY_CLOUD_NAME', '')
    CLOUDINARY_API_KEY = os.getenv('CLOUDINARY_API_KEY', '')
    CLOUDINARY_API_SECRET = os.getenv('CLOUDINARY_API_SECRET', '')

    # --- Flask-Mail ---
    MAIL_SERVER = os.getenv('MAIL_SERVER', 'smtp.gmail.com')
    MAIL_PORT = int(os.getenv('MAIL_PORT', 587))
    MAIL_USE_TLS = os.getenv('MAIL_USE_TLS', 'true').lower() == 'true'
    MAIL_USERNAME = os.getenv('MAIL_USERNAME', '')
    MAIL_PASSWORD = os.getenv('MAIL_PASSWORD', '')
    MAIL_DEFAULT_SENDER = os.getenv('MAIL_DEFAULT_SENDER', os.getenv('MAIL_USERNAME', ''))

    # --- Redis (pour Celery) ---
    REDIS_URL = os.getenv('REDIS_URL', 'redis://localhost:6379/0')

    # --- Firebase ---
    FIREBASE_CREDENTIALS_JSON = os.getenv('FIREBASE_CREDENTIALS_JSON', '{}')

    # --- Upload ---
    MAX_CONTENT_LENGTH = 50 * 1024 * 1024  # 50 Mo max par requête
