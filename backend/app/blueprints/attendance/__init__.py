# Blueprint Attendance — Pointage check-in / check-out (MODULE 3)
from flask import Blueprint, request, jsonify
from datetime import datetime, date, timezone

from app import db
from app.models.attendance import Attendance
from app.utils.jwt_helpers import jwt_required, role_required

attendance_bp = Blueprint('attendance', __name__)


@attendance_bp.route('/attendance/checkin', methods=['POST'])
@jwt_required
def checkin():
    """Pointer l'arrivée
    ---
    tags:
      - Pointage
    security:
      - Bearer: []
    parameters:
      - in: body
        name: body
        schema:
          type: object
          properties:
            latitude:
              type: number
            longitude:
              type: number
    responses:
      201:
        description: Check-in enregistré
      409:
        description: Déjà pointé aujourd'hui
    """
    user_id = request.current_user['user_id']
    today = date.today()

    existing = Attendance.query.filter_by(user_id=user_id, date_pointage=today).first()
    if existing and existing.check_in:
        return jsonify({'erreur': 'Vous avez déjà pointé aujourd\'hui'}), 409

    data = request.get_json() or {}

    attendance = existing or Attendance(user_id=user_id, date_pointage=today)
    attendance.check_in = datetime.now(timezone.utc)
    if data.get('latitude'):
        attendance.latitude = data['latitude']
    if data.get('longitude'):
        attendance.longitude = data['longitude']

    if not existing:
        db.session.add(attendance)
    db.session.commit()

    return jsonify({'message': 'Check-in enregistré', 'attendance': attendance.to_dict()}), 201


@attendance_bp.route('/attendance/checkout', methods=['POST'])
@jwt_required
def checkout():
    """Pointer le départ
    ---
    tags:
      - Pointage
    security:
      - Bearer: []
    responses:
      200:
        description: Check-out enregistré
      404:
        description: Pas de check-in aujourd'hui
    """
    user_id = request.current_user['user_id']
    today = date.today()

    attendance = Attendance.query.filter_by(user_id=user_id, date_pointage=today).first()
    if not attendance or not attendance.check_in:
        return jsonify({'erreur': 'Vous n\'avez pas pointé aujourd\'hui'}), 404

    if attendance.check_out:
        return jsonify({'erreur': 'Vous avez déjà pointé votre départ'}), 409

    attendance.check_out = datetime.now(timezone.utc)
    attendance.calculer_heures()
    db.session.commit()

    return jsonify({'message': 'Check-out enregistré', 'attendance': attendance.to_dict()}), 200


@attendance_bp.route('/attendance', methods=['GET'])
@jwt_required
def list_attendance():
    """Historique du pointage
    ---
    tags:
      - Pointage
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
        description: Liste du pointage
    """
    query = Attendance.query

    user_id = request.args.get('user_id')
    if user_id:
        query = query.filter(Attendance.user_id == user_id)

    date_debut = request.args.get('date_debut')
    if date_debut:
        query = query.filter(Attendance.date_pointage >= date_debut)

    date_fin = request.args.get('date_fin')
    if date_fin:
        query = query.filter(Attendance.date_pointage <= date_fin)

    records = query.order_by(Attendance.date_pointage.desc()).all()
    return jsonify({'attendance': [a.to_dict() for a in records]}), 200
