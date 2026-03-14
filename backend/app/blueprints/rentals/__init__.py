# Blueprint Rentals — Gestion des locations de matériel (MODULE 1)
from flask import Blueprint, request, jsonify, send_file
from datetime import datetime, date
import io

from app import db
from app.models.material import Material
from app.models.rental import Rental
from app.models.maintenance import Maintenance
from app.utils.jwt_helpers import jwt_required, role_required
from app.utils.cloudinary_helper import upload_image, delete_image
from app.utils.qr_generator import generate_qr_code

rentals_bp = Blueprint('rentals', __name__)


# ================================================================
# MATÉRIELS
# ================================================================

@rentals_bp.route('/materials', methods=['GET'])
@jwt_required
def list_materials():
    """Liste des matériels avec filtres
    ---
    tags:
      - Matériels
    security:
      - Bearer: []
    parameters:
      - in: query
        name: etat
        type: string
        enum: [disponible, loue, maintenance, hors_service]
      - in: query
        name: categorie
        type: string
        enum: [appareil, objectif, eclairage, trepied, drone, studio, accessoire, autre]
      - in: query
        name: search
        type: string
        description: Recherche par nom, marque, modèle
      - in: query
        name: page
        type: integer
        default: 1
      - in: query
        name: per_page
        type: integer
        default: 20
    responses:
      200:
        description: Liste paginée des matériels avec compteurs
    """
    query = Material.query

    etat = request.args.get('etat')
    if etat and etat in Material.ETATS:
        query = query.filter(Material.etat == etat)

    categorie = request.args.get('categorie')
    if categorie and categorie in Material.CATEGORIES:
        query = query.filter(Material.categorie == categorie)

    search = request.args.get('search', '').strip()
    if search:
        search_filter = f'%{search}%'
        query = query.filter(
            db.or_(
                Material.nom.ilike(search_filter),
                Material.marque.ilike(search_filter),
                Material.modele.ilike(search_filter),
                Material.numero_serie.ilike(search_filter),
            )
        )

    page = request.args.get('page', 1, type=int)
    per_page = min(request.args.get('per_page', 20, type=int), 100)

    pagination = query.order_by(Material.nom).paginate(
        page=page, per_page=per_page, error_out=False
    )

    counts = {
        'disponible': Material.query.filter_by(etat='disponible').count(),
        'loue': Material.query.filter_by(etat='loue').count(),
        'maintenance': Material.query.filter_by(etat='maintenance').count(),
        'hors_service': Material.query.filter_by(etat='hors_service').count(),
    }

    return jsonify({
        'materials': [m.to_dict() for m in pagination.items],
        'total': pagination.total,
        'page': page,
        'pages': pagination.pages,
        'compteurs': counts,
    }), 200


@rentals_bp.route('/materials', methods=['POST'])
@role_required('admin', 'manager')
def create_material():
    """Ajouter un matériel
    ---
    tags:
      - Matériels
    security:
      - Bearer: []
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [nom]
          properties:
            nom:
              type: string
              example: Canon EOS R5
            marque:
              type: string
              example: Canon
            modele:
              type: string
              example: EOS R5
            numero_serie:
              type: string
              example: CN-2024-001
            categorie:
              type: string
              enum: [appareil, objectif, eclairage, trepied, drone, studio, accessoire, autre]
              example: appareil
            tarif_journalier:
              type: number
              example: 50000
            tarif_hebdomadaire:
              type: number
              example: 300000
            tarif_mensuel:
              type: number
              example: 1000000
            description:
              type: string
            date_acquisition:
              type: string
              format: date
              example: "2024-01-15"
    responses:
      201:
        description: Matériel ajouté
      400:
        description: Données invalides
      409:
        description: Numéro de série existant
    """
    data = request.get_json()

    if not data:
        return jsonify({'erreur': 'Données JSON requises'}), 400
    if not data.get('nom'):
        return jsonify({'erreur': 'Le nom du matériel est requis'}), 400

    categorie = data.get('categorie', 'appareil')
    if categorie not in Material.CATEGORIES:
        return jsonify({'erreur': f'Catégorie invalide. Valeurs : {", ".join(Material.CATEGORIES)}'}), 400

    if data.get('numero_serie'):
        existing = Material.query.filter_by(numero_serie=data['numero_serie']).first()
        if existing:
            return jsonify({'erreur': 'Ce numéro de série existe déjà'}), 409

    material = Material(
        nom=data['nom'],
        marque=data.get('marque'),
        modele=data.get('modele'),
        numero_serie=data.get('numero_serie'),
        categorie=categorie,
        etat='disponible',
        tarif_journalier=data.get('tarif_journalier', 0),
        tarif_hebdomadaire=data.get('tarif_hebdomadaire', 0),
        tarif_mensuel=data.get('tarif_mensuel', 0),
        description=data.get('description'),
        date_acquisition=datetime.strptime(data['date_acquisition'], '%Y-%m-%d').date()
            if data.get('date_acquisition') else None,
    )
    material.qr_code_data = material.id

    db.session.add(material)
    db.session.commit()

    return jsonify({
        'message': f'Matériel "{material.nom}" ajouté avec succès',
        'material': material.to_dict()
    }), 201


@rentals_bp.route('/materials/<material_id>', methods=['GET'])
@jwt_required
def get_material(material_id):
    """Détail d'un matériel avec historique
    ---
    tags:
      - Matériels
    security:
      - Bearer: []
    parameters:
      - in: path
        name: material_id
        type: string
        required: true
    responses:
      200:
        description: Détail du matériel
      404:
        description: Matériel non trouvé
    """
    material = Material.query.get(material_id)
    if not material:
        return jsonify({'erreur': 'Matériel non trouvé'}), 404

    return jsonify({'material': material.to_dict(include_history=True)}), 200


@rentals_bp.route('/materials/<material_id>', methods=['PATCH'])
@role_required('admin', 'manager')
def update_material(material_id):
    """Modifier un matériel
    ---
    tags:
      - Matériels
    security:
      - Bearer: []
    parameters:
      - in: path
        name: material_id
        type: string
        required: true
      - in: body
        name: body
        schema:
          type: object
          properties:
            nom:
              type: string
            marque:
              type: string
            modele:
              type: string
            categorie:
              type: string
              enum: [appareil, objectif, eclairage, trepied, drone, studio, accessoire, autre]
            etat:
              type: string
              enum: [disponible, loue, maintenance, hors_service]
            tarif_journalier:
              type: number
            tarif_hebdomadaire:
              type: number
            tarif_mensuel:
              type: number
    responses:
      200:
        description: Matériel modifié
      404:
        description: Matériel non trouvé
    """
    material = Material.query.get(material_id)
    if not material:
        return jsonify({'erreur': 'Matériel non trouvé'}), 404

    data = request.get_json()
    if not data:
        return jsonify({'erreur': 'Données JSON requises'}), 400

    updatable_fields = [
        'nom', 'marque', 'modele', 'numero_serie', 'description',
        'tarif_journalier', 'tarif_hebdomadaire', 'tarif_mensuel'
    ]
    for field in updatable_fields:
        if field in data:
            setattr(material, field, data[field])

    if 'categorie' in data:
        if data['categorie'] not in Material.CATEGORIES:
            return jsonify({'erreur': 'Catégorie invalide'}), 400
        material.categorie = data['categorie']

    if 'etat' in data:
        if data['etat'] not in Material.ETATS:
            return jsonify({'erreur': 'État invalide'}), 400
        material.etat = data['etat']

    if 'date_acquisition' in data and data['date_acquisition']:
        try:
            material.date_acquisition = datetime.strptime(data['date_acquisition'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'erreur': 'Format de date invalide (YYYY-MM-DD attendu)'}), 400

    db.session.commit()
    return jsonify({
        'message': f'Matériel "{material.nom}" modifié avec succès',
        'material': material.to_dict()
    }), 200


@rentals_bp.route('/materials/<material_id>', methods=['DELETE'])
@role_required('admin')
def delete_material(material_id):
    """Supprimer un matériel
    ---
    tags:
      - Matériels
    security:
      - Bearer: []
    parameters:
      - in: path
        name: material_id
        type: string
        required: true
    responses:
      200:
        description: Matériel supprimé
      404:
        description: Matériel non trouvé
      409:
        description: Matériel actuellement loué
    """
    material = Material.query.get(material_id)
    if not material:
        return jsonify({'erreur': 'Matériel non trouvé'}), 404

    active_rental = material.location_active
    if active_rental:
        return jsonify({
            'erreur': f'Impossible de supprimer : matériel actuellement loué à {active_rental.client_nom}'
        }), 409

    material_nom = material.nom
    if material.photos:
        for photo in material.photos:
            if photo.get('public_id'):
                try:
                    delete_image(photo['public_id'])
                except Exception:
                    pass

    db.session.delete(material)
    db.session.commit()
    return jsonify({'message': f'Matériel "{material_nom}" supprimé avec succès'}), 200


@rentals_bp.route('/materials/<material_id>/photo', methods=['POST'])
@role_required('admin', 'manager')
def upload_material_photo(material_id):
    """Uploader une photo du matériel
    ---
    tags:
      - Matériels
    security:
      - Bearer: []
    consumes:
      - multipart/form-data
    parameters:
      - in: path
        name: material_id
        type: string
        required: true
      - in: formData
        name: photo
        type: file
        required: true
        description: Image (PNG, JPG, JPEG, WEBP)
    responses:
      201:
        description: Photo uploadée
      400:
        description: Fichier manquant ou format invalide
      404:
        description: Matériel non trouvé
    """
    material = Material.query.get(material_id)
    if not material:
        return jsonify({'erreur': 'Matériel non trouvé'}), 404

    if 'photo' not in request.files:
        return jsonify({'erreur': 'Aucun fichier photo fourni'}), 400

    file = request.files['photo']
    if file.filename == '':
        return jsonify({'erreur': 'Nom de fichier vide'}), 400

    allowed_extensions = {'png', 'jpg', 'jpeg', 'webp'}
    ext = file.filename.rsplit('.', 1)[-1].lower() if '.' in file.filename else ''
    if ext not in allowed_extensions:
        return jsonify({'erreur': f'Format non supporté. Formats acceptés : {", ".join(allowed_extensions)}'}), 400

    try:
        result = upload_image(file, folder=f'studio-photo/materials/{material_id}')
        photos = material.photos or []
        photos.append({
            'url': result['url'],
            'thumbnail_url': result['thumbnail_url'],
            'public_id': result['public_id'],
        })
        material.photos = photos
        db.session.add(material)
        db.session.commit()

        return jsonify({
            'message': 'Photo uploadée avec succès',
            'photo': result,
            'material': material.to_dict()
        }), 201

    except Exception as e:
        return jsonify({'erreur': f'Erreur lors de l\'upload : {str(e)}'}), 500


@rentals_bp.route('/materials/<material_id>/qrcode', methods=['GET'])
@jwt_required
def get_material_qrcode(material_id):
    """Générer le QR code d'un matériel
    ---
    tags:
      - Matériels
    security:
      - Bearer: []
    parameters:
      - in: path
        name: material_id
        type: string
        required: true
    produces:
      - image/png
    responses:
      200:
        description: Image PNG du QR code
      404:
        description: Matériel non trouvé
    """
    material = Material.query.get(material_id)
    if not material:
        return jsonify({'erreur': 'Matériel non trouvé'}), 404

    qr_data = f'STUDIO_MATERIAL:{material.id}'
    qr_bytes = generate_qr_code(qr_data)

    return send_file(
        io.BytesIO(qr_bytes),
        mimetype='image/png',
        as_attachment=False,
        download_name=f'qr_{material.nom.replace(" ", "_")}.png'
    )


# ================================================================
# LOCATIONS (RENTALS)
# ================================================================

@rentals_bp.route('/rentals', methods=['POST'])
@role_required('admin', 'manager')
def create_rental():
    """Créer un contrat de location
    ---
    tags:
      - Locations
    security:
      - Bearer: []
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [material_id, client_nom, date_debut, date_fin_prevue, montant_total]
          properties:
            material_id:
              type: string
              description: ID du matériel à louer
            client_nom:
              type: string
              example: Jean Ndayishimiye
            client_telephone:
              type: string
              example: "+257 79 123 456"
            client_email:
              type: string
              example: jean@email.com
            date_debut:
              type: string
              format: date
              example: "2026-03-14"
            date_fin_prevue:
              type: string
              format: date
              example: "2026-03-21"
            caution:
              type: number
              example: 100000
            montant_total:
              type: number
              example: 300000
            notes:
              type: string
    responses:
      201:
        description: Location créée
      404:
        description: Matériel non trouvé
      409:
        description: Matériel non disponible
    """
    data = request.get_json()

    if not data:
        return jsonify({'erreur': 'Données JSON requises'}), 400

    required_fields = ['material_id', 'client_nom', 'date_debut', 'date_fin_prevue', 'montant_total']
    for field in required_fields:
        if not data.get(field):
            return jsonify({'erreur': f'Le champ "{field}" est requis'}), 400

    material = Material.query.get(data['material_id'])
    if not material:
        return jsonify({'erreur': 'Matériel non trouvé'}), 404

    if material.etat != 'disponible':
        return jsonify({'erreur': f'Matériel non disponible (état actuel : {material.etat})'}), 409

    try:
        date_debut = datetime.strptime(data['date_debut'], '%Y-%m-%d').date()
        date_fin_prevue = datetime.strptime(data['date_fin_prevue'], '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'erreur': 'Format de date invalide (YYYY-MM-DD attendu)'}), 400

    if date_fin_prevue <= date_debut:
        return jsonify({'erreur': 'La date de fin doit être après la date de début'}), 400

    rental = Rental(
        material_id=data['material_id'],
        client_nom=data['client_nom'],
        client_telephone=data.get('client_telephone'),
        client_email=data.get('client_email'),
        date_debut=date_debut,
        date_fin_prevue=date_fin_prevue,
        caution=data.get('caution', 0),
        montant_total=data['montant_total'],
        notes=data.get('notes'),
        statut='active',
        created_by=request.current_user['user_id'],
    )
    material.etat = 'loue'

    db.session.add(rental)
    db.session.commit()

    return jsonify({
        'message': f'Location créée pour "{material.nom}" à {rental.client_nom}',
        'rental': rental.to_dict()
    }), 201


@rentals_bp.route('/rentals', methods=['GET'])
@jwt_required
def list_rentals():
    """Liste des locations
    ---
    tags:
      - Locations
    security:
      - Bearer: []
    parameters:
      - in: query
        name: statut
        type: string
        enum: [active, terminee, en_retard]
      - in: query
        name: search
        type: string
        description: Recherche par nom client
      - in: query
        name: page
        type: integer
        default: 1
      - in: query
        name: per_page
        type: integer
        default: 20
    responses:
      200:
        description: Liste paginée des locations
    """
    query = Rental.query

    statut = request.args.get('statut')
    if statut and statut in Rental.STATUTS:
        query = query.filter(Rental.statut == statut)

    search = request.args.get('search', '').strip()
    if search:
        query = query.filter(Rental.client_nom.ilike(f'%{search}%'))

    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)

    pagination = query.order_by(Rental.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )

    return jsonify({
        'rentals': [r.to_dict() for r in pagination.items],
        'total': pagination.total,
        'page': page,
        'pages': pagination.pages,
    }), 200


@rentals_bp.route('/rentals/overdue', methods=['GET'])
@jwt_required
def list_overdue_rentals():
    """Locations en retard
    ---
    tags:
      - Locations
    security:
      - Bearer: []
    responses:
      200:
        description: Liste des locations en retard
    """
    today = date.today()

    overdue_rentals = Rental.query.filter(
        Rental.statut == 'active',
        Rental.date_fin_prevue < today
    ).order_by(Rental.date_fin_prevue).all()

    for rental in overdue_rentals:
        if rental.statut != 'en_retard':
            rental.statut = 'en_retard'
    db.session.commit()

    return jsonify({
        'rentals': [r.to_dict() for r in overdue_rentals],
        'total': len(overdue_rentals),
    }), 200


@rentals_bp.route('/rentals/<rental_id>', methods=['GET'])
@jwt_required
def get_rental(rental_id):
    """Détail d'une location
    ---
    tags:
      - Locations
    security:
      - Bearer: []
    parameters:
      - in: path
        name: rental_id
        type: string
        required: true
    responses:
      200:
        description: Détail de la location
      404:
        description: Location non trouvée
    """
    rental = Rental.query.get(rental_id)
    if not rental:
        return jsonify({'erreur': 'Location non trouvée'}), 404

    result = rental.to_dict()
    result['material'] = rental.material.to_dict() if rental.material else None
    return jsonify({'rental': result}), 200


@rentals_bp.route('/rentals/<rental_id>/return', methods=['PATCH'])
@role_required('admin', 'manager')
def return_rental(rental_id):
    """Enregistrer le retour d'un matériel loué
    ---
    tags:
      - Locations
    security:
      - Bearer: []
    parameters:
      - in: path
        name: rental_id
        type: string
        required: true
      - in: body
        name: body
        schema:
          type: object
          properties:
            etat_retour:
              type: string
              example: Bon état
              description: Description de l'état au retour
            photos_dommages:
              type: array
              items:
                type: string
              description: Liste d'URLs de photos de dommages
            etat_materiel:
              type: string
              enum: [disponible, maintenance]
              description: État du matériel après retour
            notes:
              type: string
    responses:
      200:
        description: Retour enregistré
      404:
        description: Location non trouvée
      409:
        description: Matériel déjà retourné
    """
    rental = Rental.query.get(rental_id)
    if not rental:
        return jsonify({'erreur': 'Location non trouvée'}), 404

    if rental.statut == 'terminee':
        return jsonify({'erreur': 'Ce matériel a déjà été retourné'}), 409

    data = request.get_json() or {}

    rental.date_retour = date.today()
    rental.etat_retour = data.get('etat_retour', 'Bon état')
    rental.statut = 'terminee'

    if data.get('photos_dommages'):
        rental.photos_dommages = data['photos_dommages']
    if data.get('notes'):
        rental.notes = (rental.notes or '') + '\n--- Retour ---\n' + data['notes']

    material = rental.material
    if data.get('etat_materiel') == 'maintenance':
        material.etat = 'maintenance'
    else:
        material.etat = 'disponible'

    db.session.commit()

    return jsonify({
        'message': f'Retour enregistré pour "{material.nom}"',
        'rental': rental.to_dict()
    }), 200


@rentals_bp.route('/rentals/<rental_id>/damage-photo', methods=['POST'])
@role_required('admin', 'manager')
def upload_damage_photo(rental_id):
    """Uploader une photo de dommage
    ---
    tags:
      - Locations
    security:
      - Bearer: []
    consumes:
      - multipart/form-data
    parameters:
      - in: path
        name: rental_id
        type: string
        required: true
      - in: formData
        name: photo
        type: file
        required: true
    responses:
      201:
        description: Photo de dommage uploadée
      404:
        description: Location non trouvée
    """
    rental = Rental.query.get(rental_id)
    if not rental:
        return jsonify({'erreur': 'Location non trouvée'}), 404

    if 'photo' not in request.files:
        return jsonify({'erreur': 'Aucun fichier photo fourni'}), 400

    file = request.files['photo']
    try:
        result = upload_image(file, folder=f'studio-photo/damages/{rental_id}')
        photos = rental.photos_dommages or []
        photos.append({
            'url': result['url'],
            'thumbnail_url': result['thumbnail_url'],
            'public_id': result['public_id'],
        })
        rental.photos_dommages = photos
        db.session.add(rental)
        db.session.commit()

        return jsonify({'message': 'Photo de dommage uploadée', 'photo': result}), 201
    except Exception as e:
        return jsonify({'erreur': f'Erreur upload : {str(e)}'}), 500


# ================================================================
# MAINTENANCES
# ================================================================

@rentals_bp.route('/maintenances', methods=['POST'])
@role_required('admin', 'manager')
def create_maintenance():
    """Ajouter une maintenance
    ---
    tags:
      - Maintenances
    security:
      - Bearer: []
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [material_id, date_debut]
          properties:
            material_id:
              type: string
            date_debut:
              type: string
              format: date
              example: "2026-03-14"
            date_fin:
              type: string
              format: date
            cout:
              type: number
              example: 50000
            prestataire:
              type: string
              example: TechRepair Buja
            description:
              type: string
    responses:
      201:
        description: Maintenance enregistrée
      404:
        description: Matériel non trouvé
    """
    data = request.get_json()

    if not data:
        return jsonify({'erreur': 'Données JSON requises'}), 400
    if not data.get('material_id') or not data.get('date_debut'):
        return jsonify({'erreur': 'material_id et date_debut sont requis'}), 400

    material = Material.query.get(data['material_id'])
    if not material:
        return jsonify({'erreur': 'Matériel non trouvé'}), 404

    try:
        date_debut = datetime.strptime(data['date_debut'], '%Y-%m-%d').date()
        date_fin = datetime.strptime(data['date_fin'], '%Y-%m-%d').date() if data.get('date_fin') else None
    except ValueError:
        return jsonify({'erreur': 'Format de date invalide (YYYY-MM-DD)'}), 400

    maintenance = Maintenance(
        material_id=data['material_id'],
        date_debut=date_debut,
        date_fin=date_fin,
        cout=data.get('cout', 0),
        prestataire=data.get('prestataire'),
        description=data.get('description'),
    )
    material.etat = 'maintenance'

    db.session.add(maintenance)
    db.session.commit()

    return jsonify({
        'message': f'Maintenance enregistrée pour "{material.nom}"',
        'maintenance': maintenance.to_dict()
    }), 201


@rentals_bp.route('/maintenances', methods=['GET'])
@jwt_required
def list_maintenances():
    """Liste des maintenances
    ---
    tags:
      - Maintenances
    security:
      - Bearer: []
    parameters:
      - in: query
        name: material_id
        type: string
        description: Filtrer par matériel
    responses:
      200:
        description: Liste des maintenances
    """
    query = Maintenance.query

    material_id = request.args.get('material_id')
    if material_id:
        query = query.filter(Maintenance.material_id == material_id)

    maintenances = query.order_by(Maintenance.date_debut.desc()).all()
    return jsonify({
        'maintenances': [m.to_dict() for m in maintenances],
        'total': len(maintenances),
    }), 200


@rentals_bp.route('/maintenances/<maintenance_id>/complete', methods=['PATCH'])
@role_required('admin', 'manager')
def complete_maintenance(maintenance_id):
    """Terminer une maintenance
    ---
    tags:
      - Maintenances
    security:
      - Bearer: []
    parameters:
      - in: path
        name: maintenance_id
        type: string
        required: true
      - in: body
        name: body
        schema:
          type: object
          properties:
            cout:
              type: number
              description: Coût final de la maintenance
    responses:
      200:
        description: Maintenance terminée
      404:
        description: Maintenance non trouvée
    """
    maintenance = Maintenance.query.get(maintenance_id)
    if not maintenance:
        return jsonify({'erreur': 'Maintenance non trouvée'}), 404

    data = request.get_json() or {}

    maintenance.date_fin = date.today()
    if data.get('cout'):
        maintenance.cout = data['cout']

    material = maintenance.material
    material.etat = 'disponible'

    db.session.commit()

    return jsonify({
        'message': f'Maintenance terminée pour "{material.nom}"',
        'maintenance': maintenance.to_dict()
    }), 200
