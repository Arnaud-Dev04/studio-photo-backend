# Modèle GalleryToken — Tokens d'accès galerie client (sans compte)
import uuid
import secrets
from datetime import datetime, timezone
from app import db


class GalleryToken(db.Model):
    __tablename__ = 'gallery_tokens'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    album_id = db.Column(db.String(36), db.ForeignKey('albums.id'), nullable=False)
    token = db.Column(db.String(255), unique=True, nullable=False, default=lambda: secrets.token_urlsafe(32))
    expiration = db.Column(db.DateTime(timezone=True))
    unlocked = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    @property
    def is_expired(self):
        if self.expiration is None:
            return False
        return datetime.now(timezone.utc) > self.expiration

    def to_dict(self):
        return {
            'id': self.id,
            'album_id': self.album_id,
            'token': self.token,
            'expiration': self.expiration.isoformat() if self.expiration else None,
            'unlocked': self.unlocked,
            'is_expired': self.is_expired,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
