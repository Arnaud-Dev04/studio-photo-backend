# Utilitaire QR Code — Génération de QR codes pour le matériel
import io
import base64
import qrcode
from qrcode.constants import ERROR_CORRECT_H


def generate_qr_code(data, size=10):
    """Générer un QR code PNG à partir de données.

    Args:
        data: Chaîne de caractères à encoder (ex: ID du matériel)
        size: Facteur de taille du QR code

    Returns:
        bytes du fichier PNG
    """
    qr = qrcode.QRCode(
        version=1,
        error_correction=ERROR_CORRECT_H,
        box_size=size,
        border=4,
    )
    qr.add_data(data)
    qr.make(fit=True)

    # Créer l'image
    img = qr.make_image(fill_color='black', back_color='white')

    # Convertir en bytes
    buffer = io.BytesIO()
    img.save(buffer, format='PNG')
    buffer.seek(0)

    return buffer.getvalue()


def generate_qr_code_base64(data, size=10):
    """Générer un QR code en base64 pour affichage direct.

    Args:
        data: Chaîne de caractères à encoder
        size: Facteur de taille

    Returns:
        Chaîne base64 du QR code PNG
    """
    png_bytes = generate_qr_code(data, size)
    return base64.b64encode(png_bytes).decode('utf-8')
