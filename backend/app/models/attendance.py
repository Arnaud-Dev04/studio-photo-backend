# Modèle Attendance — Pointage check-in / check-out
import uuid
from datetime import datetime, timezone
from app import db


class Attendance(db.Model):
    __tablename__ = 'attendance'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    date_pointage = db.Column(db.Date, nullable=False, default=datetime.utcnow)
    check_in = db.Column(db.DateTime(timezone=True))
    check_out = db.Column(db.DateTime(timezone=True))
    latitude = db.Column(db.Numeric(10, 7))
    longitude = db.Column(db.Numeric(10, 7))
    total_heures = db.Column(db.Numeric(5, 2), default=0)
    created_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    def calculer_heures(self):
        """Calculer le total d'heures travaillées."""
        if self.check_in and self.check_out:
            delta = self.check_out - self.check_in
            self.total_heures = round(delta.total_seconds() / 3600, 2)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'user_nom': self.user.nom if self.user else None,
            'date_pointage': self.date_pointage.isoformat() if self.date_pointage else None,
            'check_in': self.check_in.isoformat() if self.check_in else None,
            'check_out': self.check_out.isoformat() if self.check_out else None,
            'latitude': float(self.latitude) if self.latitude else None,
            'longitude': float(self.longitude) if self.longitude else None,
            'total_heures': float(self.total_heures or 0),
        }
