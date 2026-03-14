# Blueprint Finance — Factures, paiements, dépenses (MODULE 4)
from flask import Blueprint, request, jsonify, send_file
from datetime import datetime, date
from sqlalchemy import func, extract
import io

from app import db
from app.models.invoice import Invoice
from app.models.payment import Payment
from app.models.expense import Expense
from app.models.salary_config import SalaryConfig
from app.models.attendance import Attendance
from app.models.user import User
from app.utils.jwt_helpers import jwt_required, role_required
from app.utils.pdf_generator import generate_invoice_pdf

finance_bp = Blueprint('finance', __name__)


# ================================================================
# FACTURES
# ================================================================

@finance_bp.route('/invoices', methods=['POST'])
@role_required('admin', 'manager')
def create_invoice():
    """Créer une facture
    ---
    tags:
      - Factures
    security:
      - Bearer: []
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [client_nom, montant_total]
          properties:
            client_nom:
              type: string
            client_email:
              type: string
            client_telephone:
              type: string
            type_facture:
              type: string
              enum: [location, seance]
            reference_id:
              type: string
            montant_total:
              type: number
            date_echeance:
              type: string
              format: date
            notes:
              type: string
    responses:
      201:
        description: Facture créée
    """
    data = request.get_json()
    if not data or not data.get('client_nom') or not data.get('montant_total'):
        return jsonify({'erreur': 'client_nom et montant_total sont requis'}), 400

    invoice = Invoice(
        numero_facture=Invoice.generate_numero(),
        client_nom=data['client_nom'],
        client_email=data.get('client_email'),
        client_telephone=data.get('client_telephone'),
        type_facture=data.get('type_facture', 'location'),
        reference_id=data.get('reference_id'),
        montant_total=data['montant_total'],
        date_echeance=datetime.strptime(data['date_echeance'], '%Y-%m-%d').date()
            if data.get('date_echeance') else None,
        notes=data.get('notes'),
        created_by=request.current_user['user_id'],
    )
    db.session.add(invoice)
    db.session.commit()

    return jsonify({'message': 'Facture créée', 'invoice': invoice.to_dict()}), 201


@finance_bp.route('/invoices', methods=['GET'])
@jwt_required
def list_invoices():
    """Liste des factures
    ---
    tags:
      - Factures
    security:
      - Bearer: []
    parameters:
      - in: query
        name: statut
        type: string
        enum: [non_paye, partiel, paye]
      - in: query
        name: search
        type: string
    responses:
      200:
        description: Liste des factures
    """
    query = Invoice.query

    statut = request.args.get('statut')
    if statut:
        query = query.filter(Invoice.statut == statut)

    search = request.args.get('search', '').strip()
    if search:
        query = query.filter(
            db.or_(
                Invoice.client_nom.ilike(f'%{search}%'),
                Invoice.numero_facture.ilike(f'%{search}%'),
            )
        )

    invoices = query.order_by(Invoice.created_at.desc()).all()
    return jsonify({'invoices': [i.to_dict() for i in invoices]}), 200


@finance_bp.route('/invoices/<invoice_id>', methods=['GET'])
@jwt_required
def get_invoice(invoice_id):
    """Détail d'une facture
    ---
    tags:
      - Factures
    security:
      - Bearer: []
    responses:
      200:
        description: Détail de la facture avec paiements
    """
    invoice = Invoice.query.get(invoice_id)
    if not invoice:
        return jsonify({'erreur': 'Facture non trouvée'}), 404

    return jsonify({'invoice': invoice.to_dict(include_payments=True)}), 200


@finance_bp.route('/invoices/<invoice_id>/pdf', methods=['GET'])
@jwt_required
def get_invoice_pdf(invoice_id):
    """Générer le PDF d'une facture
    ---
    tags:
      - Factures
    security:
      - Bearer: []
    produces:
      - application/pdf
    responses:
      200:
        description: PDF de la facture
    """
    invoice = Invoice.query.get(invoice_id)
    if not invoice:
        return jsonify({'erreur': 'Facture non trouvée'}), 404

    try:
        pdf_bytes = generate_invoice_pdf(invoice)
        return send_file(
            io.BytesIO(pdf_bytes),
            mimetype='application/pdf',
            as_attachment=True,
            download_name=f'{invoice.numero_facture}.pdf'
        )
    except Exception as e:
        return jsonify({'erreur': f'Erreur de génération PDF : {str(e)}'}), 500


# ================================================================
# PAIEMENTS
# ================================================================

@finance_bp.route('/payments', methods=['POST'])
@role_required('admin', 'manager')
def create_payment():
    """Enregistrer un paiement
    ---
    tags:
      - Paiements
    security:
      - Bearer: []
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [invoice_id, montant]
          properties:
            invoice_id:
              type: string
            montant:
              type: number
            mode:
              type: string
              enum: [cash, virement, mobile_money]
            reference:
              type: string
            notes:
              type: string
    responses:
      201:
        description: Paiement enregistré
    """
    data = request.get_json()
    if not data or not data.get('invoice_id') or not data.get('montant'):
        return jsonify({'erreur': 'invoice_id et montant sont requis'}), 400

    invoice = Invoice.query.get(data['invoice_id'])
    if not invoice:
        return jsonify({'erreur': 'Facture non trouvée'}), 404

    mode = data.get('mode', 'cash')
    if mode not in Payment.MODES:
        return jsonify({'erreur': f'Mode invalide. Valeurs : {", ".join(Payment.MODES)}'}), 400

    payment = Payment(
        invoice_id=data['invoice_id'],
        montant=data['montant'],
        mode=mode,
        reference=data.get('reference'),
        notes=data.get('notes'),
        created_by=request.current_user['user_id'],
    )
    db.session.add(payment)

    # Mettre à jour le statut de la facture
    invoice.update_statut()
    db.session.commit()

    return jsonify({'message': 'Paiement enregistré', 'payment': payment.to_dict()}), 201


@finance_bp.route('/payments', methods=['GET'])
@jwt_required
def list_payments():
    """Historique des paiements
    ---
    tags:
      - Paiements
    security:
      - Bearer: []
    responses:
      200:
        description: Liste des paiements
    """
    payments = Payment.query.order_by(Payment.created_at.desc()).all()
    return jsonify({'payments': [p.to_dict() for p in payments]}), 200


# ================================================================
# DÉPENSES
# ================================================================

@finance_bp.route('/expenses', methods=['POST'])
@role_required('admin', 'manager')
def create_expense():
    """Enregistrer une dépense
    ---
    tags:
      - Dépenses
    security:
      - Bearer: []
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required: [description, montant]
          properties:
            description:
              type: string
            montant:
              type: number
            categorie:
              type: string
              enum: [materiel, deplacement, location_local, salaire, marketing, autre]
            date_depense:
              type: string
              format: date
    responses:
      201:
        description: Dépense enregistrée
    """
    data = request.get_json()
    if not data or not data.get('description') or not data.get('montant'):
        return jsonify({'erreur': 'description et montant sont requis'}), 400

    categorie = data.get('categorie', 'autre')
    if categorie not in Expense.CATEGORIES:
        return jsonify({'erreur': 'Catégorie invalide'}), 400

    expense = Expense(
        description=data['description'],
        montant=data['montant'],
        categorie=categorie,
        date_depense=datetime.strptime(data['date_depense'], '%Y-%m-%d').date()
            if data.get('date_depense') else date.today(),
        created_by=request.current_user['user_id'],
    )
    db.session.add(expense)
    db.session.commit()

    return jsonify({'message': 'Dépense enregistrée', 'expense': expense.to_dict()}), 201


@finance_bp.route('/expenses', methods=['GET'])
@jwt_required
def list_expenses():
    """Liste des dépenses
    ---
    tags:
      - Dépenses
    security:
      - Bearer: []
    parameters:
      - in: query
        name: categorie
        type: string
      - in: query
        name: date_debut
        type: string
        format: date
      - in: query
        name: date_fin
        type: string
        format: date
    responses:
      200:
        description: Liste des dépenses
    """
    query = Expense.query

    categorie = request.args.get('categorie')
    if categorie:
        query = query.filter(Expense.categorie == categorie)

    date_debut = request.args.get('date_debut')
    if date_debut:
        query = query.filter(Expense.date_depense >= date_debut)

    date_fin = request.args.get('date_fin')
    if date_fin:
        query = query.filter(Expense.date_depense <= date_fin)

    expenses = query.order_by(Expense.date_depense.desc()).all()
    return jsonify({'expenses': [e.to_dict() for e in expenses]}), 200


# ================================================================
# DASHBOARD FINANCE
# ================================================================

@finance_bp.route('/finance/dashboard', methods=['GET'])
@jwt_required
def finance_dashboard():
    """Dashboard financier — CA du mois, factures en attente, bénéfices
    ---
    tags:
      - Finance
    security:
      - Bearer: []
    responses:
      200:
        description: Résumé financier
    """
    today = date.today()
    current_month = today.month
    current_year = today.year

    # CA du mois (paiements reçus ce mois)
    ca_mois = db.session.query(func.coalesce(func.sum(Payment.montant), 0)).filter(
        extract('month', Payment.date_paiement) == current_month,
        extract('year', Payment.date_paiement) == current_year,
    ).scalar()

    # Dépenses du mois
    depenses_mois = db.session.query(func.coalesce(func.sum(Expense.montant), 0)).filter(
        extract('month', Expense.date_depense) == current_month,
        extract('year', Expense.date_depense) == current_year,
    ).scalar()

    # Factures en attente
    factures_non_payees = Invoice.query.filter(Invoice.statut.in_(['non_paye', 'partiel'])).count()
    montant_en_attente = db.session.query(
        func.coalesce(func.sum(Invoice.montant_total - Invoice.montant_paye), 0)
    ).filter(Invoice.statut.in_(['non_paye', 'partiel'])).scalar()

    # Totaux
    total_factures = Invoice.query.count()
    total_payees = Invoice.query.filter_by(statut='paye').count()

    return jsonify({
        'ca_mois': float(ca_mois),
        'depenses_mois': float(depenses_mois),
        'benefice_mois': float(ca_mois) - float(depenses_mois),
        'factures_en_attente': factures_non_payees,
        'montant_en_attente': float(montant_en_attente),
        'total_factures': total_factures,
        'total_payees': total_payees,
    }), 200
