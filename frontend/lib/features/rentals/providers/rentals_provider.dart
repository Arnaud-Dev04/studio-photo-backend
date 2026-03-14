import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/material_model.dart';
import '../models/rental_model.dart';

/// État des matériels et locations
class RentalsState {
  final List<MaterialItem> materials;
  final List<Rental> rentals;
  final MaterialItem? selectedMaterial;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const RentalsState({
    this.materials = const [],
    this.rentals = const [],
    this.selectedMaterial,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  RentalsState copyWith({
    List<MaterialItem>? materials,
    List<Rental>? rentals,
    MaterialItem? selectedMaterial,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearSelected = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return RentalsState(
      materials: materials ?? this.materials,
      rentals: rentals ?? this.rentals,
      selectedMaterial: clearSelected ? null : (selectedMaterial ?? this.selectedMaterial),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  /// Nombre de matériels par état
  int get disponibles => materials.where((m) => m.etat == 'disponible').length;
  int get loues => materials.where((m) => m.etat == 'loue').length;
  int get enMaintenance => materials.where((m) => m.etat == 'maintenance').length;
  int get enRetard => rentals.where((r) => r.statut == 'en_retard').length;
}

/// Provider Riverpod pour les locations et matériels
final rentalsProvider =
    StateNotifierProvider<RentalsNotifier, RentalsState>((ref) {
  return RentalsNotifier(ref.read(apiServiceProvider));
});

class RentalsNotifier extends StateNotifier<RentalsState> {
  final ApiService _api;

  RentalsNotifier(this._api) : super(const RentalsState());

  /// Effacer les messages d'erreur/succès
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  // ================================================================
  // MATÉRIELS
  // ================================================================

  /// Charger les matériels depuis l'API
  Future<void> loadMaterials({String? categorie, String? etat, String? search}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final params = <String, dynamic>{};
      if (categorie != null) params['categorie'] = categorie;
      if (etat != null) params['etat'] = etat;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await _api.get('/materials', queryParameters: params);
      final data = response.data;

      // L'API retourne un objet avec 'materials' et des métadonnées
      final List<dynamic> materialsJson = data is Map
          ? (data['materials'] as List<dynamic>? ?? [])
          : (data as List<dynamic>);
      final materials = materialsJson
          .map((json) => MaterialItem.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(materials: materials, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de chargement des matériels',
      );
    }
  }

  /// Charger le détail d'un matériel
  Future<MaterialItem?> getMaterialDetail(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.get('/materials/$id');
      final data = response.data;
      final materialJson = data is Map ? data['material'] : data;
      final material = MaterialItem.fromJson(materialJson as Map<String, dynamic>);
      state = state.copyWith(selectedMaterial: material, isLoading: false);
      return material;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Matériel non trouvé',
      );
      return null;
    }
  }

  /// Créer un matériel
  Future<bool> createMaterial(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.post('/materials', data: data);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Matériel ajouté avec succès',
      );
      // Recharger la liste
      await loadMaterials();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'ajout du matériel',
      );
      return false;
    }
  }

  /// Modifier un matériel
  Future<bool> updateMaterial(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.patch('/materials/$id', data: data);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Matériel modifié avec succès',
      );
      await loadMaterials();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la modification',
      );
      return false;
    }
  }

  /// Supprimer un matériel
  Future<bool> deleteMaterial(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.delete('/materials/$id');
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Matériel supprimé',
      );
      await loadMaterials();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de supprimer le matériel',
      );
      return false;
    }
  }

  /// Upload photo matériel
  Future<bool> uploadMaterialPhoto(int materialId, String filePath) async {
    try {
      await _api.uploadFile(
        '/materials/$materialId/photo',
        filePath: filePath,
        fieldName: 'photo',
      );
      // Recharger le détail
      await getMaterialDetail(materialId);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de l\'upload de la photo');
      return false;
    }
  }

  // ================================================================
  // LOCATIONS
  // ================================================================

  /// Charger les locations
  Future<void> loadRentals({String? statut}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final params = <String, dynamic>{};
      if (statut != null) params['statut'] = statut;

      final response = await _api.get('/rentals', queryParameters: params);
      final data = response.data;

      final List<dynamic> rentalsJson = data is Map
          ? (data['rentals'] as List<dynamic>? ?? [])
          : (data as List<dynamic>);
      final rentals = rentalsJson
          .map((json) => Rental.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(rentals: rentals, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de chargement des locations',
      );
    }
  }

  /// Créer une location
  Future<bool> createRental(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.post('/rentals', data: data);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Location créée avec succès',
      );
      await loadRentals();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création de la location',
      );
      return false;
    }
  }

  /// Enregistrer le retour d'un matériel
  Future<bool> returnRental(int rentalId, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.patch('/rentals/$rentalId/return', data: data);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Retour enregistré avec succès',
      );
      await loadRentals();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'enregistrement du retour',
      );
      return false;
    }
  }

  /// Charger les locations en retard
  Future<void> loadOverdueRentals() async {
    try {
      final response = await _api.get('/rentals/overdue');
      final data = response.data;
      final List<dynamic> rentalsJson = data is Map
          ? (data['rentals'] as List<dynamic>? ?? [])
          : (data as List<dynamic>);
      final overdueRentals = rentalsJson
          .map((json) => Rental.fromJson(json as Map<String, dynamic>))
          .toList();

      // Mettre à jour seulement les locations en retard dans la liste
      final currentRentals = [...state.rentals];
      for (final overdue in overdueRentals) {
        final index = currentRentals.indexWhere((r) => r.id == overdue.id);
        if (index >= 0) {
          currentRentals[index] = overdue;
        } else {
          currentRentals.add(overdue);
        }
      }
      state = state.copyWith(rentals: currentRentals);
    } catch (e) {
      // Silencieux — pas critique
    }
  }
}
