# Utilitaire Watermark — Application de filigrane via Cloudinary
from app.utils.cloudinary_helper import add_watermark_overlay


def apply_watermark(url, text='Studio Photo', position='center', opacity=50):
    """Appliquer un watermark texte sur une image via Cloudinary.

    Utilise les transformations d'URL Cloudinary pour ajouter
    un overlay texte sans modifier l'image originale.

    Args:
        url: URL Cloudinary de l'image originale
        text: Texte du watermark
        position: Position du watermark
        opacity: Opacité (0-100)

    Returns:
        URL de l'image avec watermark
    """
    return add_watermark_overlay(url, text, position, opacity)


def remove_watermark(url):
    """Retirer le watermark = retourner l'URL originale.

    Comme le watermark est appliqué via transformation d'URL Cloudinary,
    l'image originale n'est pas modifiée. Il suffit de servir l'URL sans
    la transformation.

    Args:
        url: URL de l'image (avec ou sans watermark)

    Returns:
        URL originale sans watermark
    """
    # Supprimer les transformations de watermark de l'URL
    # Les transformations sont entre /upload/ et le public_id
    if '/upload/' in url:
        parts = url.split('/upload/')
        if len(parts) == 2:
            # Vérifier si des transformations sont présentes
            after_upload = parts[1]
            # Les transformations contiennent des virgules et des underscores
            # Le public_id commence après le dernier '/' des transformations
            if 'l_text:' in after_upload:
                # Retirer la partie transformation watermark
                segments = after_upload.split('/')
                # Garder seulement les segments qui ne contiennent pas 'l_text:'
                clean_segments = [s for s in segments if 'l_text:' not in s]
                return parts[0] + '/upload/' + '/'.join(clean_segments)
    return url
