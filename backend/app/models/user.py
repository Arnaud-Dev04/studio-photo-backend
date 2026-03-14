# Modèle User — Membres de l'équipe du studio
import uuid
from datetime import datetime, timezone
import bcrypt
from app import db


class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    nom = db.Column(db.String(255), nullable=False)
    telephone = db.Column(db.String(50))
    role = db.Column(db.String(50), nullable=False, default='photographe')
    actif = db.Column(db.Boolean, nullable=False, default=True)
    fcm_token = db.Column(db.String(500))
    created_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                           onupdate=lambda: datetime.now(timezone.utc))

    # Relations
    rentals_created = db.relationship('Rental', backref='creator', lazy='dynamic',
                                      foreign_keys='Rental.created_by')
    tasks_assigned = db.relationship('Task', backref='assignee', lazy='dynamic',
                                     foreign_keys='Task.assigned_to')
    schedules = db.relationship('Schedule', backref='user', lazy='dynamic')
    attendances = db.relationship('Attendance', backref='user', lazy='dynamic')
    salary_config = db.relationship('SalaryConfig', backref='user', uselist=False)

    def set_password(self, password):
        """Hasher le mot de passe avec bcrypt."""
        self.password_hash = bcrypt.hashpw(
            password.encode('utf-8'),
            bcrypt.gensalt()
        ).decode('utf-8')

    def check_password(self, password):
        """Vérifier le mot de passe."""
        return bcrypt.checkpw(
            password.encode('utf-8'),
            self.password_hash.encode('utf-8')
        )

    def to_dict(self):
        """Convertir en dictionnaire (sans le hash du mot de passe)."""
        return {
            'id': self.id,
            'email': self.email,
            'nom': self.nom,
            'telephone': self.telephone,
            'role': self.role,
            'actif': self.actif,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f'<User {self.nom} ({self.role})>'
