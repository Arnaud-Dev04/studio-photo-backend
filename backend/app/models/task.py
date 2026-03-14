# Modèle Task — Tâches assignées aux membres de l'équipe
import uuid
from datetime import datetime, timezone
from app import db


class Task(db.Model):
    __tablename__ = 'tasks'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    titre = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    assigned_to = db.Column(db.String(36), db.ForeignKey('users.id'))
    type_tache = db.Column(db.String(50), nullable=False, default='seance')
    priorite = db.Column(db.String(20), nullable=False, default='normale')
    statut = db.Column(db.String(50), nullable=False, default='a_faire')
    date_echeance = db.Column(db.Date)
    created_by = db.Column(db.String(36), db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                           onupdate=lambda: datetime.now(timezone.utc))

    # Relation vers le créateur
    creator = db.relationship('User', foreign_keys=[created_by], backref='tasks_created')

    def to_dict(self):
        return {
            'id': self.id,
            'titre': self.titre,
            'description': self.description,
            'assigned_to': self.assigned_to,
            'assignee_nom': self.assignee.nom if self.assignee else None,
            'type_tache': self.type_tache,
            'priorite': self.priorite,
            'statut': self.statut,
            'date_echeance': self.date_echeance.isoformat() if self.date_echeance else None,
            'created_by': self.created_by,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
