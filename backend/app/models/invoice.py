# Modèle Invoice — Factures du studio
import uuid
from datetime import datetime, date, timezone
from app import db


class Invoice(db.Model):
    __tablename__ = 'invoices'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    numero_facture = db.Column(db.String(50), unique=True, nullable=False)
    client_nom = db.Column(db.String(255), nullable=False)
    client_email = db.Column(db.String(255))
    client_telephone = db.Column(db.String(50))
    type_facture = db.Column(db.String(50), nullable=False, default='location')
    reference_id = db.Column(db.String(36))
    montant_total = db.Column(db.Numeric(12, 2), nullable=False)
    montant_paye = db.Column(db.Numeric(12, 2), default=0)
    statut = db.Column(db.String(50), nullable=False, default='non_paye')
    date_emission = db.Column(db.Date, nullable=False, default=date.today)
    date_echeance = db.Column(db.Date)
    notes = db.Column(db.Text)
    created_by = db.Column(db.String(36), db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                           onupdate=lambda: datetime.now(timezone.utc))

    # Relations
    payments = db.relationship('Payment', backref='invoice', lazy='dynamic', cascade='all, delete-orphan')
    creator = db.relationship('User', backref='invoices_created')

    @staticmethod
    def generate_numero():
        """Générer un numéro de facture unique : FAC-YYYYMMDD-XXXX."""
        today = date.today().strftime('%Y%m%d')
        count = Invoice.query.filter(
            Invoice.numero_facture.like(f'FAC-{today}-%')
        ).count()
        return f'FAC-{today}-{count + 1:04d}'

    def update_statut(self):
        """Mettre à jour le statut selon le montant payé."""
        total_paye = sum(p.montant for p in self.payments.all())
        self.montant_paye = total_paye
        if total_paye >= self.montant_total:
            self.statut = 'paye'
        elif total_paye > 0:
            self.statut = 'partiel'
        else:
            self.statut = 'non_paye'

    def to_dict(self, include_payments=False):
        data = {
            'id': self.id,
            'numero_facture': self.numero_facture,
            'client_nom': self.client_nom,
            'client_email': self.client_email,
            'client_telephone': self.client_telephone,
            'type_facture': self.type_facture,
            'reference_id': self.reference_id,
            'montant_total': float(self.montant_total or 0),
            'montant_paye': float(self.montant_paye or 0),
            'reste_a_payer': float((self.montant_total or 0) - (self.montant_paye or 0)),
            'statut': self.statut,
            'date_emission': self.date_emission.isoformat() if self.date_emission else None,
            'date_echeance': self.date_echeance.isoformat() if self.date_echeance else None,
            'notes': self.notes,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
        if include_payments:
            data['paiements'] = [p.to_dict() for p in self.payments.all()]
        return data
