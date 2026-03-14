# Blueprint Schedules — Planning des séances (MODULE 3)
from flask import Blueprint, request, jsonify
from datetime import datetime

from app import db
from app.models.schedule import Schedule
from app.utils.jwt_helpers import jwt_required, role_required

schedules_bp = Blueprint('schedules', __name__)


@schedules_bp.route('/schedules', methods=['POST'])
@role_required('admin', 'manager')
def create_schedule():
    """Créer une séance / mission
    ---
    tags:
      - Planning
    security:
      - Bearer: []
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [titre, date_seance]
          properties:
            titre:
              type: string
            user_id:
              type: string
            date_seance:
              type: string
              format: date
            heure_debut:
              type: string
              example: "09:00"
            heure_fin:
              type: string
              example: "17:00"
            lieu:
              type: string
            type_seance:
              type: string
            notes:
              type: string
    responses:
      201:
        description: Séance créée
    """
    data = request.get_json()
    if not data or not data.get('titre') or not data.get('date_seance'):
        return jsonify({'erreur': 'Titre et date sont requis'}), 400

    schedule = Schedule(
        titre=data['titre'],
        user_id=data.get('user_id'),
        date_seance=datetime.strptime(data['date_seance'], '%Y-%m-%d').date(),
        heure_debut=datetime.strptime(data['heure_debut'], '%H:%M').time()
            if data.get('heure_debut') else None,
        heure_fin=datetime.strptime(data['heure_fin'], '%H:%M').time()
            if data.get('heure_fin') else None,
        lieu=data.get('lieu'),
        type_seance=data.get('type_seance'),
        notes=data.get('notes'),
    )
    db.session.add(schedule)
    db.session.commit()

    return jsonify({'message': 'Séance créée', 'schedule': schedule.to_dict()}), 201


@schedules_bp.route('/schedules', methods=['GET'])
@jwt_required
def list_schedules():
    """Planning des séances
    ---
    tags:
      - Planning
    security:
      - Bearer: []
    parameters:
      - in: query
        name: user_id
        type: string
      - in: query
        name: date_debut
        type: string
        format: date
      - in: query
        name: date_fin
        type: string
        format: date
    responses:
      200:
        description: Liste du planning
    """
    query = Schedule.query

    user_id = request.args.get('user_id')
    if user_id:
        query = query.filter(Schedule.user_id == user_id)

    date_debut = request.args.get('date_debut')
    if date_debut:
        query = query.filter(Schedule.date_seance >= date_debut)

    date_fin = request.args.get('date_fin')
    if date_fin:
        query = query.filter(Schedule.date_seance <= date_fin)

    schedules = query.order_by(Schedule.date_seance.desc()).all()
    return jsonify({'schedules': [s.to_dict() for s in schedules]}), 200


@schedules_bp.route('/schedules/<schedule_id>', methods=['PATCH'])
@role_required('admin', 'manager')
def update_schedule(schedule_id):
    """Modifier une séance
    ---
    tags:
      - Planning
    security:
      - Bearer: []
    responses:
      200:
        description: Séance modifiée
    """
    schedule = Schedule.query.get(schedule_id)
    if not schedule:
        return jsonify({'erreur': 'Séance non trouvée'}), 404

    data = request.get_json() or {}
    for field in ['titre', 'user_id', 'lieu', 'type_seance', 'notes']:
        if field in data:
            setattr(schedule, field, data[field])

    if 'date_seance' in data:
        schedule.date_seance = datetime.strptime(data['date_seance'], '%Y-%m-%d').date()
    if 'heure_debut' in data and data['heure_debut']:
        schedule.heure_debut = datetime.strptime(data['heure_debut'], '%H:%M').time()
    if 'heure_fin' in data and data['heure_fin']:
        schedule.heure_fin = datetime.strptime(data['heure_fin'], '%H:%M').time()

    db.session.commit()
    return jsonify({'message': 'Séance modifiée', 'schedule': schedule.to_dict()}), 200


@schedules_bp.route('/schedules/<schedule_id>', methods=['DELETE'])
@role_required('admin', 'manager')
def delete_schedule(schedule_id):
    """Supprimer une séance
    ---
    tags:
      - Planning
    security:
      - Bearer: []
    responses:
      200:
        description: Séance supprimée
    """
    schedule = Schedule.query.get(schedule_id)
    if not schedule:
        return jsonify({'erreur': 'Séance non trouvée'}), 404

    db.session.delete(schedule)
    db.session.commit()
    return jsonify({'message': 'Séance supprimée'}), 200
