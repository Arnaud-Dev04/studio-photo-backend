# Modèle SalaryConfig — Taux horaire par membre
import uuid
from datetime import datetime, timezone
from app import db


class SalaryConfig(db.Model):
    __tablename__ = 'salary_configs'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('users.id'), unique=True, nullable=False)
    taux_horaire = db.Column(db.Numeric(10, 2), nullable=False, default=0)
    devise = db.Column(db.String(10), nullable=False, default='BIF')
    updated_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                           onupdate=lambda: datetime.now(timezone.utc))

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'user_nom': self.user.nom if self.user else None,
            'taux_horaire': float(self.taux_horaire or 0),
            'devise': self.devise,
        }
