# Modèle Rental — Contrats de location de matériel
import uuid
from datetime import datetime, date, timezone
from app import db


class Rental(db.Model):
    __tablename__ = 'rentals'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    material_id = db.Column(db.String(36), db.ForeignKey('materials.id'), nullable=False)
    client_nom = db.Column(db.String(255), nullable=False)
    client_telephone = db.Column(db.String(50))
    client_email = db.Column(db.String(255))
    date_debut = db.Column(db.Date, nullable=False)
    date_fin_prevue = db.Column(db.Date, nullable=False)
    date_retour = db.Column(db.Date)
    caution = db.Column(db.Numeric(12, 2), default=0)
    montant_total = db.Column(db.Numeric(12, 2), nullable=False)
    etat_retour = db.Column(db.String(100))
    photos_dommages = db.Column(db.JSON, default=list)
    statut = db.Column(db.String(50), nullable=False, default='active')
    notes = db.Column(db.Text)
    created_by = db.Column(db.String(36), db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                           onupdate=lambda: datetime.now(timezone.utc))

    # Statuts valides
    STATUTS = ['active', 'terminee', 'en_retard']

    @property
    def is_overdue(self):
        """Vérifie si la location est en retard."""
        if self.statut == 'active' and self.date_fin_prevue:
            return date.today() > self.date_fin_prevue
        return False

    @property
    def jours_retard(self):
        """Nombre de jours de retard."""
        if self.is_overdue:
            return (date.today() - self.date_fin_prevue).days
        return 0

    def to_dict(self):
        """Convertir en dictionnaire JSON."""
        return {
            'id': self.id,
            'material_id': self.material_id,
            'material_nom': self.material.nom if self.material else None,
            'client_nom': self.client_nom,
            'client_telephone': self.client_telephone,
            'client_email': self.client_email,
            'date_debut': self.date_debut.isoformat() if self.date_debut else None,
            'date_fin_prevue': self.date_fin_prevue.isoformat() if self.date_fin_prevue else None,
            'date_retour': self.date_retour.isoformat() if self.date_retour else None,
            'caution': float(self.caution or 0),
            'montant_total': float(self.montant_total or 0),
            'etat_retour': self.etat_retour,
            'photos_dommages': self.photos_dommages or [],
            'statut': self.statut,
            'notes': self.notes,
            'is_overdue': self.is_overdue,
            'jours_retard': self.jours_retard,
            'created_by': self.created_by,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f'<Rental {self.client_nom} - {self.statut}>'
