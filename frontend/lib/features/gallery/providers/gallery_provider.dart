import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/album_model.dart';
import '../models/photo_model.dart';

/// État de la galerie
class GalleryState {
  final List<Album> albums;
  final List<Photo> photos;
  final bool isLoading;
  final String? error;

  const GalleryState({
    this.albums = const [],
    this.photos = const [],
    this.isLoading = false,
    this.error,
  });

  GalleryState copyWith({
    List<Album>? albums,
    List<Photo>? photos,
    bool? isLoading,
    String? error,
  }) {
    return GalleryState(
      albums: albums ?? this.albums,
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider Riverpod pour la galerie
final galleryProvider =
    StateNotifierProvider<GalleryNotifier, GalleryState>((ref) {
  return GalleryNotifier(ref.read(apiServiceProvider));
});

class GalleryNotifier extends StateNotifier<GalleryState> {
  final ApiService _api;

  GalleryNotifier(this._api) : super(const GalleryState());

  /// Charger les albums
  Future<void> loadAlbums() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get('/albums');
      final data = response.data as List<dynamic>;
      final albums = data
          .map((json) => Album.fromJson(json as Map<String, dynamic>))
          .toList();
      state = state.copyWith(albums: albums, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de chargement des albums',
      );
    }
  }

  /// Charger les photos d'un album
  Future<void> loadPhotos(int albumId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get('/albums/$albumId');
      final albumData = response.data as Map<String, dynamic>;
      final photosData = albumData['photos'] as List<dynamic>? ?? [];
      final photos = photosData
          .map((json) => Photo.fromJson(json as Map<String, dynamic>))
          .toList();
      state = state.copyWith(photos: photos, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de chargement des photos',
      );
    }
  }
}
