# Blueprint Tasks — Gestion des tâches de l'équipe (MODULE 3)
from flask import Blueprint, request, jsonify
from datetime import datetime, date

from app import db
from app.models.task import Task
from app.models.user import User
from app.utils.jwt_helpers import jwt_required, role_required

tasks_bp = Blueprint('tasks', __name__)


@tasks_bp.route('/tasks', methods=['POST'])
@role_required('admin', 'manager')
def create_task():
    """Créer une tâche
    ---
    tags:
      - Tâches
    security:
      - Bearer: []
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [titre]
          properties:
            titre:
              type: string
            description:
              type: string
            assigned_to:
              type: string
            type_tache:
              type: string
              enum: [seance, retouche, verification, livraison, autre]
            priorite:
              type: string
              enum: [basse, normale, haute, urgente]
            date_echeance:
              type: string
              format: date
    responses:
      201:
        description: Tâche créée
    """
    data = request.get_json()
    if not data or not data.get('titre'):
        return jsonify({'erreur': 'Le titre est requis'}), 400

    task = Task(
        titre=data['titre'],
        description=data.get('description'),
        assigned_to=data.get('assigned_to'),
        type_tache=data.get('type_tache', 'seance'),
        priorite=data.get('priorite', 'normale'),
        statut='a_faire',
        date_echeance=datetime.strptime(data['date_echeance'], '%Y-%m-%d').date()
            if data.get('date_echeance') else None,
        created_by=request.current_user['user_id'],
    )
    db.session.add(task)
    db.session.commit()

    return jsonify({'message': 'Tâche créée', 'task': task.to_dict()}), 201


@tasks_bp.route('/tasks', methods=['GET'])
@jwt_required
def list_tasks():
    """Liste des tâches
    ---
    tags:
      - Tâches
    security:
      - Bearer: []
    parameters:
      - in: query
        name: assigned_to
        type: string
      - in: query
        name: statut
        type: string
        enum: [a_faire, en_cours, terminee]
      - in: query
        name: type_tache
        type: string
    responses:
      200:
        description: Liste des tâches
    """
    query = Task.query

    assigned_to = request.args.get('assigned_to')
    if assigned_to:
        query = query.filter(Task.assigned_to == assigned_to)

    statut = request.args.get('statut')
    if statut:
        query = query.filter(Task.statut == statut)

    type_tache = request.args.get('type_tache')
    if type_tache:
        query = query.filter(Task.type_tache == type_tache)

    tasks = query.order_by(Task.created_at.desc()).all()
    return jsonify({'tasks': [t.to_dict() for t in tasks]}), 200


@tasks_bp.route('/tasks/<task_id>', methods=['PATCH'])
@jwt_required
def update_task(task_id):
    """Modifier une tâche
    ---
    tags:
      - Tâches
    security:
      - Bearer: []
    parameters:
      - in: path
        name: task_id
        type: string
        required: true
      - in: body
        name: body
        schema:
          type: object
          properties:
            titre:
              type: string
            statut:
              type: string
              enum: [a_faire, en_cours, terminee]
            priorite:
              type: string
    responses:
      200:
        description: Tâche modifiée
    """
    task = Task.query.get(task_id)
    if not task:
        return jsonify({'erreur': 'Tâche non trouvée'}), 404

    data = request.get_json() or {}
    for field in ['titre', 'description', 'assigned_to', 'type_tache', 'priorite', 'statut']:
        if field in data:
            setattr(task, field, data[field])

    if 'date_echeance' in data and data['date_echeance']:
        task.date_echeance = datetime.strptime(data['date_echeance'], '%Y-%m-%d').date()

    db.session.commit()
    return jsonify({'message': 'Tâche modifiée', 'task': task.to_dict()}), 200


@tasks_bp.route('/tasks/<task_id>', methods=['DELETE'])
@role_required('admin', 'manager')
def delete_task(task_id):
    """Supprimer une tâche
    ---
    tags:
      - Tâches
    security:
      - Bearer: []
    responses:
      200:
        description: Tâche supprimée
    """
    task = Task.query.get(task_id)
    if not task:
        return jsonify({'erreur': 'Tâche non trouvée'}), 404

    db.session.delete(task)
    db.session.commit()
    return jsonify({'message': 'Tâche supprimée'}), 200
