# Imports de tous les modèles pour faciliter l'accès
from app.models.user import User
from app.models.material import Material
from app.models.rental import Rental
from app.models.maintenance import Maintenance
from app.models.album import Album
from app.models.photo import Photo
from app.models.gallery_token import GalleryToken
from app.models.task import Task
from app.models.schedule import Schedule
from app.models.attendance import Attendance
from app.models.invoice import Invoice
from app.models.payment import Payment
from app.models.expense import Expense
from app.models.salary_config import SalaryConfig

__all__ = [
    'User', 'Material', 'Rental', 'Maintenance',
    'Album', 'Photo', 'GalleryToken',
    'Task', 'Schedule', 'Attendance',
    'Invoice', 'Payment', 'Expense', 'SalaryConfig'
]
