/// Modèle de matériel
class MaterialItem {
  final int id;
  final String nom;
  final String marque;
  final String modele;
  final String? numeroSerie;
  final String categorie; // appareil, objectif, éclairage, trépied, drone, studio
  final String etat; // disponible, loue, maintenance, hors_service
  final double tarifJournalier;
  final double? tarifHebdo;
  final double? tarifMensuel;
  final List<String> photos;
  final String? qrCodeData;
  final DateTime? dateAcquisition;
  final DateTime createdAt;

  const MaterialItem({
    required this.id,
    required this.nom,
    required this.marque,
    required this.modele,
    this.numeroSerie,
    required this.categorie,
    required this.etat,
    required this.tarifJournalier,
    this.tarifHebdo,
    this.tarifMensuel,
    this.photos = const [],
    this.qrCodeData,
    this.dateAcquisition,
    required this.createdAt,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'] as int,
      nom: json['nom'] as String,
      marque: json['marque'] as String,
      modele: json['modele'] as String,
      numeroSerie: json['numero_serie'] as String?,
      categorie: json['categorie'] as String,
      etat: json['etat'] as String,
      tarifJournalier: (json['tarif_journalier'] as num).toDouble(),
      tarifHebdo: (json['tarif_hebdo'] as num?)?.toDouble(),
      tarifMensuel: (json['tarif_mensuel'] as num?)?.toDouble(),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      qrCodeData: json['qr_code_data'] as String?,
      dateAcquisition: json['date_acquisition'] != null
          ? DateTime.parse(json['date_acquisition'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'marque': marque,
      'modele': modele,
      'numero_serie': numeroSerie,
      'categorie': categorie,
      'etat': etat,
      'tarif_journalier': tarifJournalier,
      'tarif_hebdo': tarifHebdo,
      'tarif_mensuel': tarifMensuel,
      'photos': photos,
      'qr_code_data': qrCodeData,
      'date_acquisition': dateAcquisition?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
