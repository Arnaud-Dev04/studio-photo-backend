# Script pour créer l'administrateur par défaut
# Exécuter une seule fois : python seed.py

from app import create_app
from app import db
from app.models.user import User

app = create_app()

with app.app_context():
    # Vérifier si l'admin existe déjà
    admin = User.query.filter_by(email='admin@studio.com').first()
    if admin:
        print('✅ Admin existe déjà')
    else:
        admin = User(
            email='admin@studio.com',
            nom='Administrateur',
            telephone='+257 79 000 000',
            role='admin',
        )
        admin.set_password('admin123')
        db.session.add(admin)
        db.session.commit()
        print('✅ Admin créé avec succès !')
        print(f'   Email : admin@studio.com')
        print(f'   Mot de passe : admin123')
        print(f'   ID : {admin.id}')
