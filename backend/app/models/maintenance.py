# Modèle Maintenance — Suivi des maintenances de matériel
import uuid
from datetime import datetime, timezone
from app import db


class Maintenance(db.Model):
    __tablename__ = 'maintenances'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    material_id = db.Column(db.String(36), db.ForeignKey('materials.id'), nullable=False)
    date_debut = db.Column(db.Date, nullable=False)
    date_fin = db.Column(db.Date)
    cout = db.Column(db.Numeric(12, 2), default=0)
    prestataire = db.Column(db.String(255))
    description = db.Column(db.Text)
    created_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    def to_dict(self):
        """Convertir en dictionnaire JSON."""
        return {
            'id': self.id,
            'material_id': self.material_id,
            'material_nom': self.material.nom if self.material else None,
            'date_debut': self.date_debut.isoformat() if self.date_debut else None,
            'date_fin': self.date_fin.isoformat() if self.date_fin else None,
            'cout': float(self.cout or 0),
            'prestataire': self.prestataire,
            'description': self.description,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f'<Maintenance {self.material_id} - {self.date_debut}>'
