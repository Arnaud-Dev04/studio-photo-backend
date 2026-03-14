# Utilitaire Cloudinary — Upload et gestion des images
import cloudinary
import cloudinary.uploader
import cloudinary.api


def upload_image(file, folder='studio-photo'):
    """Uploader une image vers Cloudinary.

    Args:
        file: Fichier (FileStorage Flask) ou chemin local
        folder: Dossier de destination sur Cloudinary

    Returns:
        dict avec 'url', 'public_id', 'thumbnail_url'
    """
    try:
        result = cloudinary.uploader.upload(
            file,
            folder=folder,
            resource_type='image',
            transformation=[
                {'quality': 'auto', 'fetch_format': 'auto'}
            ]
        )
        return {
            'url': result['secure_url'],
            'public_id': result['public_id'],
            'thumbnail_url': get_thumbnail_url(result['secure_url']),
            'width': result.get('width'),
            'height': result.get('height'),
            'bytes': result.get('bytes'),
        }
    except Exception as e:
        raise Exception(f'Erreur Cloudinary : {str(e)}')


def delete_image(public_id):
    """Supprimer une image de Cloudinary par son public_id."""
    try:
        result = cloudinary.uploader.destroy(public_id)
        return result.get('result') == 'ok'
    except Exception as e:
        raise Exception(f'Erreur suppression Cloudinary : {str(e)}')


def get_thumbnail_url(url, width=400, height=400):
    """Générer l'URL de la miniature via transformation Cloudinary.

    Cloudinary permet de transformer les images via l'URL :
    /upload/ → /upload/c_fill,w_400,h_400/
    """
    if '/upload/' in url:
        return url.replace(
            '/upload/',
            f'/upload/c_fill,w_{width},h_{height},q_auto,f_auto/'
        )
    return url


def add_watermark_overlay(url, text='Studio Photo', position='center', opacity=50):
    """Ajouter un watermark texte à une image via transformation Cloudinary.

    Args:
        url: URL de l'image originale
        text: Texte du watermark
        position: Position (center, south_east, north_west, etc.)
        opacity: Opacité (0-100)

    Returns:
        URL de l'image avec watermark
    """
    # Mapping des positions Flutter vers Cloudinary
    gravity_map = {
        'center': 'center',
        'bottom_right': 'south_east',
        'bottom_left': 'south_west',
        'top_right': 'north_east',
        'top_left': 'north_west',
        'bottom': 'south',
        'top': 'north',
    }
    gravity = gravity_map.get(position, 'center')

    # Transformation Cloudinary pour le watermark
    watermark_transform = (
        f'l_text:Arial_40_bold:{text},'
        f'o_{opacity},g_{gravity},co_white'
    )

    if '/upload/' in url:
        return url.replace('/upload/', f'/upload/{watermark_transform}/')
    return url
