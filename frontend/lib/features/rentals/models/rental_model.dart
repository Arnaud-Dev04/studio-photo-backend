/// Modèle de location
class Rental {
  final int id;
  final int materialId;
  final String clientNom;
  final String? clientTelephone;
  final String? clientEmail;
  final DateTime dateDebut;
  final DateTime dateFinPrevue;
  final DateTime? dateRetour;
  final double caution;
  final double montantTotal;
  final String? etatRetour;
  final List<String> photosDommages;
  final String statut; // active, terminee, en_retard
  final int? createdBy;
  final DateTime createdAt;

  const Rental({
    required this.id,
    required this.materialId,
    required this.clientNom,
    this.clientTelephone,
    this.clientEmail,
    required this.dateDebut,
    required this.dateFinPrevue,
    this.dateRetour,
    required this.caution,
    required this.montantTotal,
    this.etatRetour,
    this.photosDommages = const [],
    required this.statut,
    this.createdBy,
    required this.createdAt,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      id: json['id'] as int,
      materialId: json['material_id'] as int,
      clientNom: json['client_nom'] as String,
      clientTelephone: json['client_telephone'] as String?,
      clientEmail: json['client_email'] as String?,
      dateDebut: DateTime.parse(json['date_debut'] as String),
      dateFinPrevue: DateTime.parse(json['date_fin_prevue'] as String),
      dateRetour: json['date_retour'] != null
          ? DateTime.parse(json['date_retour'] as String)
          : null,
      caution: (json['caution'] as num).toDouble(),
      montantTotal: (json['montant_total'] as num).toDouble(),
      etatRetour: json['etat_retour'] as String?,
      photosDommages: (json['photos_dommages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      statut: json['statut'] as String,
      createdBy: json['created_by'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'material_id': materialId,
      'client_nom': clientNom,
      'client_telephone': clientTelephone,
      'client_email': clientEmail,
      'date_debut': dateDebut.toIso8601String(),
      'date_fin_prevue': dateFinPrevue.toIso8601String(),
      'date_retour': dateRetour?.toIso8601String(),
      'caution': caution,
      'montant_total': montantTotal,
      'etat_retour': etatRetour,
      'photos_dommages': photosDommages,
      'statut': statut,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Vérifie si la location est en retard
  bool get isOverdue =>
      statut == 'active' && DateTime.now().isAfter(dateFinPrevue);
}
