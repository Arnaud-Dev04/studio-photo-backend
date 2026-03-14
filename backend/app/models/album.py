# Modèle Album — Albums photo par séance client
import uuid
from datetime import datetime, timezone
from app import db


class Album(db.Model):
    __tablename__ = 'albums'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    titre = db.Column(db.String(255), nullable=False)
    date_seance = db.Column(db.Date)
    client_nom = db.Column(db.String(255))
    client_email = db.Column(db.String(255))
    photographe_id = db.Column(db.String(36), db.ForeignKey('users.id'))
    statut = db.Column(db.String(50), nullable=False, default='brouillon')
    watermark_text = db.Column(db.String(255), default='Studio Photo')
    watermark_position = db.Column(db.String(50), default='center')
    watermark_opacity = db.Column(db.Numeric(3, 2), default=0.5)
    nombre_photos = db.Column(db.Integer, default=0)
    created_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                           onupdate=lambda: datetime.now(timezone.utc))

    # Relations
    photos = db.relationship('Photo', backref='album', lazy='dynamic', cascade='all, delete-orphan')
    tokens = db.relationship('GalleryToken', backref='album', lazy='dynamic', cascade='all, delete-orphan')
    photographe = db.relationship('User', backref='albums')

    def to_dict(self, include_photos=False):
        data = {
            'id': self.id,
            'titre': self.titre,
            'date_seance': self.date_seance.isoformat() if self.date_seance else None,
            'client_nom': self.client_nom,
            'client_email': self.client_email,
            'photographe_id': self.photographe_id,
            'photographe_nom': self.photographe.nom if self.photographe else None,
            'statut': self.statut,
            'watermark_text': self.watermark_text,
            'watermark_position': self.watermark_position,
            'watermark_opacity': float(self.watermark_opacity or 0.5),
            'nombre_photos': self.nombre_photos,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
        if include_photos:
            data['photos'] = [p.to_dict() for p in self.photos.all()]
        return data
