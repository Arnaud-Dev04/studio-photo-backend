# Blueprint Auth — Authentification (login, register, profil)
from flask import Blueprint, request, jsonify
from app import db
from app.models.user import User
from app.utils.jwt_helpers import create_token, jwt_required, role_required

auth_bp = Blueprint('auth', __name__)


# ============================================================
# POST /auth/setup — Créer le premier admin (uniquement si aucun user n'existe)
# ============================================================
@auth_bp.route('/setup', methods=['POST'])
def setup():
    """Créer le premier administrateur (fonctionne une seule fois)
    ---
    tags:
      - Auth
    responses:
      201:
        description: Admin créé
      403:
        description: Des utilisateurs existent déjà
    """
    if User.query.count() > 0:
        return jsonify({'erreur': 'Des utilisateurs existent déjà. Utilisez /auth/register.'}), 403

    admin = User(
        email='admin@studio.com',
        nom='Administrateur',
        telephone='+257 79 000 000',
        role='admin',
    )
    admin.set_password('admin123')
    db.session.add(admin)
    db.session.commit()

    return jsonify({
        'message': 'Admin créé avec succès',
        'email': 'admin@studio.com',
        'password': 'admin123',
    }), 201


# ============================================================
# POST /auth/register — Inscription d'un nouveau membre (admin only)
# ============================================================
@auth_bp.route('/register', methods=['POST'])
@role_required('admin')
def register():
    """Inscrire un nouveau membre
    ---
    tags:
      - Auth
    security:
      - Bearer: []
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [email, password, nom]
          properties:
            email:
              type: string
              example: photo@studio.com
            password:
              type: string
              example: motdepasse123
            nom:
              type: string
              example: Jean Ndayishimiye
            telephone:
              type: string
              example: "+257 79 123 456"
            role:
              type: string
              enum: [admin, manager, photographe, assistant, retoucheur, commercial]
              example: photographe
    responses:
      201:
        description: Membre créé avec succès
      400:
        description: Données invalides
      409:
        description: Email déjà utilisé
    """
    data = request.get_json()

    if not data:
        return jsonify({'erreur': 'Données JSON requises'}), 400

    required_fields = ['email', 'password', 'nom']
    for field in required_fields:
        if not data.get(field):
            return jsonify({'erreur': f'Le champ "{field}" est requis'}), 400

    existing = User.query.filter_by(email=data['email']).first()
    if existing:
        return jsonify({'erreur': 'Cet email est déjà utilisé'}), 409

    valid_roles = ['admin', 'manager', 'photographe', 'assistant', 'retoucheur', 'commercial']
    role = data.get('role', 'photographe')
    if role not in valid_roles:
        return jsonify({'erreur': f'Rôle invalide. Valeurs acceptées : {", ".join(valid_roles)}'}), 400

    user = User(
        email=data['email'],
        nom=data['nom'],
        telephone=data.get('telephone'),
        role=role,
    )
    user.set_password(data['password'])

    db.session.add(user)
    db.session.commit()

    return jsonify({
        'message': f'Membre "{user.nom}" créé avec succès',
        'user': user.to_dict()
    }), 201


# ============================================================
# POST /auth/login — Connexion
# ============================================================
@auth_bp.route('/login', methods=['POST'])
def login():
    """Connexion — retourne un token JWT
    ---
    tags:
      - Auth
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [email, password]
          properties:
            email:
              type: string
              example: admin@studio.com
            password:
              type: string
              example: admin123
            fcm_token:
              type: string
              description: Token Firebase Cloud Messaging (optionnel)
    responses:
      200:
        description: Connexion réussie, retourne le token JWT
      401:
        description: Email ou mot de passe incorrect
    """
    data = request.get_json()

    if not data or not data.get('email') or not data.get('password'):
        return jsonify({'erreur': 'Email et mot de passe requis'}), 400

    user = User.query.filter_by(email=data['email']).first()
    if not user or not user.check_password(data['password']):
        return jsonify({'erreur': 'Email ou mot de passe incorrect'}), 401

    if not user.actif:
        return jsonify({'erreur': 'Ce compte est désactivé. Contactez l\'administrateur.'}), 403

    if data.get('fcm_token'):
        user.fcm_token = data['fcm_token']
        db.session.commit()

    token = create_token(user)

    return jsonify({
        'message': 'Connexion réussie',
        'token': token,
        'user': user.to_dict()
    }), 200


# ============================================================
# GET /auth/me — Profil de l'utilisateur connecté
# ============================================================
@auth_bp.route('/me', methods=['GET'])
@jwt_required
def me():
    """Profil de l'utilisateur connecté
    ---
    tags:
      - Auth
    security:
      - Bearer: []
    responses:
      200:
        description: Profil utilisateur
      401:
        description: Token manquant ou invalide
    """
    user_id = request.current_user['user_id']
    user = User.query.get(user_id)

    if not user:
        return jsonify({'erreur': 'Utilisateur non trouvé'}), 404

    return jsonify({'user': user.to_dict()}), 200


# ============================================================
# PATCH /auth/password — Changer le mot de passe
# ============================================================
@auth_bp.route('/password', methods=['PATCH'])
@jwt_required
def change_password():
    """Changer le mot de passe
    ---
    tags:
      - Auth
    security:
      - Bearer: []
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [ancien_mot_de_passe, nouveau_mot_de_passe]
          properties:
            ancien_mot_de_passe:
              type: string
            nouveau_mot_de_passe:
              type: string
    responses:
      200:
        description: Mot de passe modifié
      401:
        description: Ancien mot de passe incorrect
    """
    data = request.get_json()

    if not data or not data.get('ancien_mot_de_passe') or not data.get('nouveau_mot_de_passe'):
        return jsonify({'erreur': 'Ancien et nouveau mot de passe requis'}), 400

    user = User.query.get(request.current_user['user_id'])
    if not user:
        return jsonify({'erreur': 'Utilisateur non trouvé'}), 404

    if not user.check_password(data['ancien_mot_de_passe']):
        return jsonify({'erreur': 'Ancien mot de passe incorrect'}), 401

    if len(data['nouveau_mot_de_passe']) < 6:
        return jsonify({'erreur': 'Le nouveau mot de passe doit contenir au moins 6 caractères'}), 400

    user.set_password(data['nouveau_mot_de_passe'])
    db.session.commit()

    return jsonify({'message': 'Mot de passe modifié avec succès'}), 200


# ============================================================
# GET /auth/users — Liste des membres (admin/manager)
# ============================================================
@auth_bp.route('/users', methods=['GET'])
@role_required('admin', 'manager')
def list_users():
    """Liste des membres de l'équipe
    ---
    tags:
      - Auth
    security:
      - Bearer: []
    responses:
      200:
        description: Liste des membres
      403:
        description: Accès refusé
    """
    users = User.query.order_by(User.nom).all()
    return jsonify({
        'users': [u.to_dict() for u in users],
        'total': len(users)
    }), 200


# ============================================================
# PATCH /auth/users/<user_id> — Modifier un membre (admin only)
# ============================================================
@auth_bp.route('/users/<user_id>', methods=['PATCH'])
@role_required('admin')
def update_user(user_id):
    """Modifier un membre
    ---
    tags:
      - Auth
    security:
      - Bearer: []
    parameters:
      - in: path
        name: user_id
        type: string
        required: true
      - in: body
        name: body
        schema:
          type: object
          properties:
            nom:
              type: string
            telephone:
              type: string
            role:
              type: string
              enum: [admin, manager, photographe, assistant, retoucheur, commercial]
            actif:
              type: boolean
    responses:
      200:
        description: Membre modifié
      404:
        description: Membre non trouvé
    """
    user = User.query.get(user_id)
    if not user:
        return jsonify({'erreur': 'Membre non trouvé'}), 404

    data = request.get_json()

    if data.get('nom'):
        user.nom = data['nom']
    if data.get('telephone'):
        user.telephone = data['telephone']
    if data.get('role'):
        valid_roles = ['admin', 'manager', 'photographe', 'assistant', 'retoucheur', 'commercial']
        if data['role'] not in valid_roles:
            return jsonify({'erreur': f'Rôle invalide'}), 400
        user.role = data['role']
    if 'actif' in data:
        user.actif = data['actif']

    db.session.commit()
    return jsonify({
        'message': f'Membre "{user.nom}" modifié avec succès',
        'user': user.to_dict()
    }), 200
