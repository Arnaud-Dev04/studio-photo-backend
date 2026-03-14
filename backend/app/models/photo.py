# Modèle Photo — Photos stockées sur Cloudinary
import uuid
from datetime import datetime, timezone
from app import db


class Photo(db.Model):
    __tablename__ = 'photos'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    album_id = db.Column(db.String(36), db.ForeignKey('albums.id'), nullable=False)
    url_originale = db.Column(db.String(500), nullable=False)
    url_miniature = db.Column(db.String(500))
    url_watermark = db.Column(db.String(500))
    public_id = db.Column(db.String(255))
    filename = db.Column(db.String(255))
    tags = db.Column(db.JSON, default=list)
    favori_client = db.Column(db.Boolean, default=False)
    taille_bytes = db.Column(db.BigInteger, default=0)
    uploaded_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    def to_dict(self):
        return {
            'id': self.id,
            'album_id': self.album_id,
            'url_originale': self.url_originale,
            'url_miniature': self.url_miniature,
            'url_watermark': self.url_watermark,
            'public_id': self.public_id,
            'filename': self.filename,
            'tags': self.tags or [],
            'favori_client': self.favori_client,
            'taille_bytes': self.taille_bytes,
            'uploaded_at': self.uploaded_at.isoformat() if self.uploaded_at else None,
        }
