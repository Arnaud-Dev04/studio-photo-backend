# Modèle Payment — Paiements reçus (cash / virement / mobile money)
import uuid
from datetime import datetime, date, timezone
from app import db


class Payment(db.Model):
    __tablename__ = 'payments'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    invoice_id = db.Column(db.String(36), db.ForeignKey('invoices.id'), nullable=False)
    montant = db.Column(db.Numeric(12, 2), nullable=False)
    date_paiement = db.Column(db.Date, nullable=False, default=date.today)
    mode = db.Column(db.String(50), nullable=False, default='cash')
    reference = db.Column(db.String(255))
    notes = db.Column(db.Text)
    created_by = db.Column(db.String(36), db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    creator = db.relationship('User', backref='payments_created')

    # Modes de paiement valides
    MODES = ['cash', 'virement', 'mobile_money']

    def to_dict(self):
        return {
            'id': self.id,
            'invoice_id': self.invoice_id,
            'montant': float(self.montant or 0),
            'date_paiement': self.date_paiement.isoformat() if self.date_paiement else None,
            'mode': self.mode,
            'reference': self.reference,
            'notes': self.notes,
            'created_by': self.created_by,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
