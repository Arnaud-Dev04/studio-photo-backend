# Utilitaire Mailer — Envoi d'emails (galerie client, factures)
from flask_mail import Message
from flask import current_app
from app import mail


def send_gallery_link(email, album_title, link, expiration_text='7 jours'):
    """Envoyer le lien de galerie au client par email.

    Args:
        email: Adresse email du client
        album_title: Titre de l'album
        link: URL de la galerie avec token
        expiration_text: Durée de validité du lien
    """
    try:
        msg = Message(
            subject=f'📸 Vos photos sont prêtes — {album_title}',
            recipients=[email],
            html=f"""
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;
                        background: #1a1a2e; color: #ffffff; border-radius: 12px; overflow: hidden;">
                <div style="background: linear-gradient(135deg, #6366f1, #8b5cf6);
                            padding: 30px; text-align: center;">
                    <h1 style="margin: 0; font-size: 24px;">📸 Studio Photo</h1>
                    <p style="margin: 10px 0 0; opacity: 0.9;">Vos photos sont prêtes !</p>
                </div>
                <div style="padding: 30px;">
                    <h2 style="color: #a78bfa; margin-top: 0;">Album : {album_title}</h2>
                    <p>Bonjour,</p>
                    <p>Vos photos de la séance <strong>{album_title}</strong> sont disponibles.
                       Cliquez sur le bouton ci-dessous pour accéder à votre galerie :</p>
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{link}" style="background: linear-gradient(135deg, #6366f1, #8b5cf6);
                           color: white; padding: 14px 32px; text-decoration: none;
                           border-radius: 8px; font-weight: bold; font-size: 16px;">
                            Voir mes photos
                        </a>
                    </div>
                    <p style="color: #9ca3af; font-size: 14px;">
                        ⏰ Ce lien est valide pendant <strong>{expiration_text}</strong>.
                    </p>
                    <p style="color: #9ca3af; font-size: 14px;">
                        Vous pouvez marquer vos photos préférées et les télécharger
                        directement depuis la galerie.
                    </p>
                </div>
                <div style="background: #16162a; padding: 20px; text-align: center;
                            color: #6b7280; font-size: 12px;">
                    © Studio Photo — Tous droits réservés
                </div>
            </div>
            """
        )
        mail.send(msg)
        return True
    except Exception as e:
        current_app.logger.error(f'Erreur envoi email galerie : {str(e)}')
        return False


def send_invoice_email(email, client_nom, numero_facture, montant, pdf_bytes=None):
    """Envoyer une facture par email au client.

    Args:
        email: Adresse email du client
        client_nom: Nom du client
        numero_facture: Numéro de la facture
        montant: Montant total
        pdf_bytes: Bytes du PDF de la facture (optionnel)
    """
    try:
        msg = Message(
            subject=f'Facture {numero_facture} — Studio Photo',
            recipients=[email],
            html=f"""
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <h2>Facture {numero_facture}</h2>
                <p>Bonjour {client_nom},</p>
                <p>Veuillez trouver ci-joint votre facture d'un montant de
                   <strong>{montant:,.0f} BIF</strong>.</p>
                <p>Merci pour votre confiance.</p>
                <p>— Studio Photo</p>
            </div>
            """
        )
        if pdf_bytes:
            msg.attach(
                filename=f'{numero_facture}.pdf',
                content_type='application/pdf',
                data=pdf_bytes
            )
        mail.send(msg)
        return True
    except Exception as e:
        current_app.logger.error(f'Erreur envoi facture email : {str(e)}')
        return False
