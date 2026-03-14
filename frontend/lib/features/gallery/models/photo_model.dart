/// Modèle de photo
class Photo {
  final int id;
  final int albumId;
  final String urlOriginale;
  final String? urlMiniature;
  final String? urlWatermark;
  final List<String> tags;
  final bool favoriClient;
  final DateTime uploadedAt;

  const Photo({
    required this.id,
    required this.albumId,
    required this.urlOriginale,
    this.urlMiniature,
    this.urlWatermark,
    this.tags = const [],
    this.favoriClient = false,
    required this.uploadedAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as int,
      albumId: json['album_id'] as int,
      urlOriginale: json['url_originale'] as String,
      urlMiniature: json['url_miniature'] as String?,
      urlWatermark: json['url_watermark'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      favoriClient: json['favori_client'] as bool? ?? false,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'album_id': albumId,
      'url_originale': urlOriginale,
      'url_miniature': urlMiniature,
      'url_watermark': urlWatermark,
      'tags': tags,
      'favori_client': favoriClient,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}
