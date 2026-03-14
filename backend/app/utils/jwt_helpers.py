# Utilitaire JWT — Authentification par token
# Décorateurs pour protéger les endpoints par rôle

import jwt
import functools
from datetime import datetime, timedelta, timezone
from flask import request, jsonify, current_app


def create_token(user):
    """Créer un token JWT pour l'utilisateur connecté."""
    payload = {
        'user_id': user.id,
        'email': user.email,
        'nom': user.nom,
        'role': user.role,
        'exp': datetime.now(timezone.utc) + timedelta(
            seconds=current_app.config['JWT_ACCESS_TOKEN_EXPIRES']
        ),
        'iat': datetime.now(timezone.utc),
    }
    token = jwt.encode(
        payload,
        current_app.config['JWT_SECRET_KEY'],
        algorithm='HS256'
    )
    return token


def decode_token(token):
    """Décoder et valider un token JWT."""
    try:
        payload = jwt.decode(
            token,
            current_app.config['JWT_SECRET_KEY'],
            algorithms=['HS256']
        )
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None


def jwt_required(f):
    """Décorateur : endpoint nécessite un token JWT valide."""
    @functools.wraps(f)
    def decorated(*args, **kwargs):
        token = None

        # Récupérer le token depuis le header Authorization
        auth_header = request.headers.get('Authorization', '')
        if auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]

        if not token:
            return jsonify({'erreur': 'Token d\'authentification manquant'}), 401

        payload = decode_token(token)
        if not payload:
            return jsonify({'erreur': 'Token invalide ou expiré'}), 401

        # Ajouter les infos utilisateur à la requête
        request.current_user = payload
        return f(*args, **kwargs)

    return decorated


def role_required(*roles):
    """Décorateur : endpoint nécessite un rôle spécifique.

    Usage : @role_required('admin', 'manager')
    """
    def decorator(f):
        @functools.wraps(f)
        @jwt_required
        def decorated(*args, **kwargs):
            user_role = request.current_user.get('role', '')
            if user_role not in roles:
                return jsonify({
                    'erreur': f'Accès refusé. Rôle requis : {", ".join(roles)}'
                }), 403
            return f(*args, **kwargs)
        return decorated
    return decorator
