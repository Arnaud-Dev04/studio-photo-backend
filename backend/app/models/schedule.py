# Modèle Schedule — Planning des séances et missions
import uuid
from datetime import datetime, timezone
from app import db


class Schedule(db.Model):
    __tablename__ = 'schedules'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    titre = db.Column(db.String(255), nullable=False)
    user_id = db.Column(db.String(36), db.ForeignKey('users.id'))
    date_seance = db.Column(db.Date, nullable=False)
    heure_debut = db.Column(db.Time)
    heure_fin = db.Column(db.Time)
    lieu = db.Column(db.String(255))
    type_seance = db.Column(db.String(100))
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    def to_dict(self):
        return {
            'id': self.id,
            'titre': self.titre,
            'user_id': self.user_id,
            'user_nom': self.user.nom if self.user else None,
            'date_seance': self.date_seance.isoformat() if self.date_seance else None,
            'heure_debut': self.heure_debut.isoformat() if self.heure_debut else None,
            'heure_fin': self.heure_fin.isoformat() if self.heure_fin else None,
            'lieu': self.lieu,
            'type_seance': self.type_seance,
            'notes': self.notes,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
