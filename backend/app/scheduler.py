# Scheduler — Vérification automatique des locations en retard
# Exécuté chaque matin à 8h via APScheduler
from datetime import date
from app import db
from app.models.rental import Rental


def check_overdue_rentals(app):
    """Vérifier les locations en retard et mettre à jour les statuts.

    Cette fonction est appelée par APScheduler chaque matin à 8h.
    Elle identifie les locations actives dont la date de fin est dépassée,
    met à jour leur statut en 'en_retard', et pourrait envoyer des
    notifications push via FCM.
    """
    with app.app_context():
        today = date.today()

        # Trouver les locations actives en retard
        overdue_rentals = Rental.query.filter(
            Rental.statut == 'active',
            Rental.date_fin_prevue < today
        ).all()

        if not overdue_rentals:
            app.logger.info(f'[Scheduler] Aucune location en retard le {today}')
            return

        for rental in overdue_rentals:
            # Mettre à jour le statut
            rental.statut = 'en_retard'

            jours = (today - rental.date_fin_prevue).days
            app.logger.warning(
                f'[Scheduler] Location en retard : {rental.client_nom} - '
                f'{rental.material.nom} ({jours} jour(s) de retard)'
            )

            # TODO: Envoyer notification push FCM au créateur et aux admins
            # send_fcm_notification(
            #     title='⚠️ Location en retard',
            #     body=f'{rental.client_nom} - {rental.material.nom} ({jours}j de retard)',
            #     user_ids=[rental.created_by]
            # )

        db.session.commit()
        app.logger.info(f'[Scheduler] {len(overdue_rentals)} location(s) en retard détectée(s)')


def init_scheduler(app):
    """Initialiser l'APScheduler pour les vérifications automatiques."""
    try:
        from apscheduler.schedulers.background import BackgroundScheduler

        scheduler = BackgroundScheduler()

        # Vérifier les retards chaque matin à 8h (heure Bujumbura, UTC+2)
        scheduler.add_job(
            func=lambda: check_overdue_rentals(app),
            trigger='cron',
            hour=6,  # 6h UTC = 8h Bujumbura (UTC+2)
            minute=0,
            id='check_overdue_rentals',
            replace_existing=True,
        )

        scheduler.start()
        app.logger.info('[Scheduler] APScheduler démarré — Vérification des retards à 8h chaque matin')

    except Exception as e:
        app.logger.error(f'[Scheduler] Erreur initialisation : {str(e)}')
