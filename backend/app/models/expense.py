# Modèle Expense — Dépenses du studio
import uuid
from datetime import datetime, date, timezone
from app import db


class Expense(db.Model):
    __tablename__ = 'expenses'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    description = db.Column(db.String(500), nullable=False)
    montant = db.Column(db.Numeric(12, 2), nullable=False)
    date_depense = db.Column(db.Date, nullable=False, default=date.today)
    categorie = db.Column(db.String(100), default='autre')
    created_by = db.Column(db.String(36), db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    creator = db.relationship('User', backref='expenses_created')

    CATEGORIES = ['materiel', 'deplacement', 'location_local', 'salaire', 'marketing', 'autre']

    def to_dict(self):
        return {
            'id': self.id,
            'description': self.description,
            'montant': float(self.montant or 0),
            'date_depense': self.date_depense.isoformat() if self.date_depense else None,
            'categorie': self.categorie,
            'created_by': self.created_by,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
