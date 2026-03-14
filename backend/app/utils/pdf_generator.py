# Utilitaire PDF — Génération de factures en PDF (ReportLab)
import io
from datetime import date
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer


def generate_invoice_pdf(invoice_data):
    """Générer un PDF de facture professionnelle.

    Args:
        invoice_data: dict contenant les informations de la facture
            - numero_facture, client_nom, client_email, client_telephone
            - montant_total, montant_paye, statut
            - date_emission, date_echeance, notes
            - paiements (liste optionnelle)

    Returns:
        bytes du fichier PDF
    """
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4,
                            rightMargin=20*mm, leftMargin=20*mm,
                            topMargin=20*mm, bottomMargin=20*mm)

    styles = getSampleStyleSheet()
    elements = []

    # Style personnalisé pour le titre
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=24,
        textColor=colors.HexColor('#6366f1'),
        spaceAfter=6*mm,
    )

    # En-tête : nom du studio
    elements.append(Paragraph('Studio Photo', title_style))
    elements.append(Paragraph('Bujumbura, Burundi', styles['Normal']))
    elements.append(Spacer(1, 10*mm))

    # Numéro de facture et dates
    elements.append(Paragraph(
        f"<b>Facture N° :</b> {invoice_data.get('numero_facture', '')}",
        styles['Normal']
    ))
    elements.append(Paragraph(
        f"<b>Date d'émission :</b> {invoice_data.get('date_emission', date.today().isoformat())}",
        styles['Normal']
    ))
    if invoice_data.get('date_echeance'):
        elements.append(Paragraph(
            f"<b>Date d'échéance :</b> {invoice_data['date_echeance']}",
            styles['Normal']
        ))
    elements.append(Spacer(1, 8*mm))

    # Informations client
    elements.append(Paragraph('<b>Client :</b>', styles['Heading3']))
    elements.append(Paragraph(f"Nom : {invoice_data.get('client_nom', '')}", styles['Normal']))
    if invoice_data.get('client_email'):
        elements.append(Paragraph(f"Email : {invoice_data['client_email']}", styles['Normal']))
    if invoice_data.get('client_telephone'):
        elements.append(Paragraph(f"Téléphone : {invoice_data['client_telephone']}", styles['Normal']))
    elements.append(Spacer(1, 8*mm))

    # Tableau des montants
    montant_total = invoice_data.get('montant_total', 0)
    montant_paye = invoice_data.get('montant_paye', 0)
    reste = montant_total - montant_paye

    table_data = [
        ['Description', 'Montant (BIF)'],
        [f"Prestation — {invoice_data.get('type_facture', 'Service')}", f"{montant_total:,.0f}"],
        ['', ''],
        ['Montant total', f"{montant_total:,.0f}"],
        ['Montant payé', f"{montant_paye:,.0f}"],
        ['Reste à payer', f"{reste:,.0f}"],
    ]

    table = Table(table_data, colWidths=[120*mm, 50*mm])
    table.setStyle(TableStyle([
        # En-tête
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#6366f1')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 12),
        # Corps
        ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 1), (-1, -1), 10),
        ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
        # Lignes totaux
        ('FONTNAME', (0, 3), (-1, -1), 'Helvetica-Bold'),
        ('LINEABOVE', (0, 3), (-1, 3), 1, colors.HexColor('#6366f1')),
        # Grille
        ('GRID', (0, 0), (-1, 0), 1, colors.HexColor('#6366f1')),
        ('LINEBELOW', (0, 1), (-1, 1), 0.5, colors.lightgrey),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
    ]))
    elements.append(table)
    elements.append(Spacer(1, 10*mm))

    # Statut du paiement
    statut = invoice_data.get('statut', 'non_paye')
    statut_text = {
        'non_paye': '❌ Non payé',
        'partiel': '⏳ Partiellement payé',
        'paye': '✅ Payé',
    }.get(statut, statut)

    elements.append(Paragraph(f"<b>Statut :</b> {statut_text}", styles['Normal']))

    # Notes
    if invoice_data.get('notes'):
        elements.append(Spacer(1, 5*mm))
        elements.append(Paragraph(f"<b>Notes :</b> {invoice_data['notes']}", styles['Normal']))

    # Pied de page
    elements.append(Spacer(1, 20*mm))
    footer_style = ParagraphStyle(
        'Footer',
        parent=styles['Normal'],
        fontSize=8,
        textColor=colors.grey,
        alignment=1,  # Centré
    )
    elements.append(Paragraph(
        'Modes de paiement acceptés : Cash • Virement bancaire • Mobile Money (Lumicash, EcoCash)',
        footer_style
    ))
    elements.append(Paragraph('Merci pour votre confiance !', footer_style))

    # Construire le PDF
    doc.build(elements)
    buffer.seek(0)
    return buffer.getvalue()
