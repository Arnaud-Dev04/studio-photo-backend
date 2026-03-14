# Modèle Material — Catalogue de matériel photo du studio
import uuid
from datetime import datetime, timezone
from app import db


class Material(db.Model):
    __tablename__ = 'materials'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    nom = db.Column(db.String(255), nullable=False)
    marque = db.Column(db.String(255))
    modele = db.Column(db.String(255))
    numero_serie = db.Column(db.String(255), unique=True)
    categorie = db.Column(db.String(100), nullable=False, default='appareil')
    etat = db.Column(db.String(50), nullable=False, default='disponible')
    tarif_journalier = db.Column(db.Numeric(12, 2), default=0)
    tarif_hebdomadaire = db.Column(db.Numeric(12, 2), default=0)
    tarif_mensuel = db.Column(db.Numeric(12, 2), default=0)
    photos = db.Column(db.JSON, default=list)
    date_acquisition = db.Column(db.Date)
    qr_code_data = db.Column(db.String(500))
    description = db.Column(db.Text)
    created_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                           onupdate=lambda: datetime.now(timezone.utc))

    # Relations
    rentals = db.relationship('Rental', backref='material', lazy='dynamic',
                              order_by='Rental.created_at.desc()')
    maintenances = db.relationship('Maintenance', backref='material', lazy='dynamic',
                                   order_by='Maintenance.date_debut.desc()')

    # Catégories valides
    CATEGORIES = ['appareil', 'objectif', 'eclairage', 'trepied', 'drone', 'studio', 'accessoire', 'autre']
    ETATS = ['disponible', 'loue', 'maintenance', 'hors_service']

    def to_dict(self, include_history=False):
        """Convertir en dictionnaire JSON."""
        data = {
            'id': self.id,
            'nom': self.nom,
            'marque': self.marque,
            'modele': self.modele,
            'numero_serie': self.numero_serie,
            'categorie': self.categorie,
            'etat': self.etat,
            'tarif_journalier': float(self.tarif_journalier or 0),
            'tarif_hebdomadaire': float(self.tarif_hebdomadaire or 0),
            'tarif_mensuel': float(self.tarif_mensuel or 0),
            'photos': self.photos or [],
            'date_acquisition': self.date_acquisition.isoformat() if self.date_acquisition else None,
            'qr_code_data': self.qr_code_data,
            'description': self.description,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }

        if include_history:
            data['historique_locations'] = [r.to_dict() for r in self.rentals.limit(20).all()]
            data['historique_maintenances'] = [m.to_dict() for m in self.maintenances.limit(10).all()]

        return data

    @property
    def location_active(self):
        """Retourne la location active en cours, s'il y en a une."""
        from app.models.rental import Rental
        return self.rentals.filter(Rental.statut == 'active').first()

    def __repr__(self):
        return f'<Material {self.nom} ({self.etat})>'
