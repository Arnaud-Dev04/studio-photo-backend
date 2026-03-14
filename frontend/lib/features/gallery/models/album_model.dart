/// Modèle d'album photo
class Album {
  final int id;
  final String titre;
  final DateTime dateSeance;
  final String? clientNom;
  final String? clientEmail;
  final int? photographeId;
  final String statut; // brouillon, livre, archive
  final Map<String, dynamic>? watermarkConfig;
  final DateTime createdAt;

  const Album({
    required this.id,
    required this.titre,
    required this.dateSeance,
    this.clientNom,
    this.clientEmail,
    this.photographeId,
    required this.statut,
    this.watermarkConfig,
    required this.createdAt,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as int,
      titre: json['titre'] as String,
      dateSeance: DateTime.parse(json['date_seance'] as String),
      clientNom: json['client_nom'] as String?,
      clientEmail: json['client_email'] as String?,
      photographeId: json['photographe_id'] as int?,
      statut: json['statut'] as String,
      watermarkConfig: json['watermark_config'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'date_seance': dateSeance.toIso8601String(),
      'client_nom': clientNom,
      'client_email': clientEmail,
      'photographe_id': photographeId,
      'statut': statut,
      'watermark_config': watermarkConfig,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
