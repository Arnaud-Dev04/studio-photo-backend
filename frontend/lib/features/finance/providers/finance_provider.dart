import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

/// État du module Finance
class FinanceState {
  final Map<String, dynamic> dashboard;
  final List<Map<String, dynamic>> invoices;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> payments;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const FinanceState({
    this.dashboard = const {},
    this.invoices = const [],
    this.expenses = const [],
    this.payments = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  FinanceState copyWith({
    Map<String, dynamic>? dashboard,
    List<Map<String, dynamic>>? invoices,
    List<Map<String, dynamic>>? expenses,
    List<Map<String, dynamic>>? payments,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return FinanceState(
      dashboard: dashboard ?? this.dashboard,
      invoices: invoices ?? this.invoices,
      expenses: expenses ?? this.expenses,
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  double get caMois => (dashboard['ca_mois'] as num?)?.toDouble() ?? 0;
  double get depensesMois => (dashboard['depenses_mois'] as num?)?.toDouble() ?? 0;
  double get beneficeMois => (dashboard['benefice_mois'] as num?)?.toDouble() ?? 0;
  int get facturesEnAttente => (dashboard['factures_en_attente'] as int?) ?? 0;
  double get montantEnAttente => (dashboard['montant_en_attente'] as num?)?.toDouble() ?? 0;
}

final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  return FinanceNotifier(ref.read(apiServiceProvider));
});

class FinanceNotifier extends StateNotifier<FinanceState> {
  final ApiService _api;

  FinanceNotifier(this._api) : super(const FinanceState());

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  /// Charger le dashboard financier
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.get('/finance/dashboard');
      state = state.copyWith(
        dashboard: response.data as Map<String, dynamic>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur de chargement');
    }
  }

  /// Charger les factures
  Future<void> loadInvoices({String? statut, String? search}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final params = <String, dynamic>{};
      if (statut != null) params['statut'] = statut;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await _api.get('/invoices', queryParameters: params);
      final data = response.data;
      final List<dynamic> json = data is Map
          ? (data['invoices'] as List<dynamic>? ?? [])
          : (data as List<dynamic>);
      state = state.copyWith(
        invoices: json.cast<Map<String, dynamic>>(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur de chargement');
    }
  }

  /// Créer une facture
  Future<bool> createInvoice(Map<String, dynamic> data) async {
    try {
      await _api.post('/invoices', data: data);
      state = state.copyWith(successMessage: 'Facture créée');
      await loadInvoices();
      await loadDashboard();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la création');
      return false;
    }
  }

  /// Enregistrer un paiement
  Future<bool> createPayment(Map<String, dynamic> data) async {
    try {
      await _api.post('/payments', data: data);
      state = state.copyWith(successMessage: 'Paiement enregistré');
      await loadInvoices();
      await loadDashboard();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur d\'enregistrement du paiement');
      return false;
    }
  }

  /// Charger les dépenses
  Future<void> loadExpenses({String? categorie}) async {
    try {
      final params = <String, dynamic>{};
      if (categorie != null) params['categorie'] = categorie;

      final response = await _api.get('/expenses', queryParameters: params);
      final data = response.data;
      final List<dynamic> json = data is Map
          ? (data['expenses'] as List<dynamic>? ?? [])
          : (data as List<dynamic>);
      state = state.copyWith(
        expenses: json.cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Erreur de chargement');
    }
  }

  /// Ajouter une dépense
  Future<bool> createExpense(Map<String, dynamic> data) async {
    try {
      await _api.post('/expenses', data: data);
      state = state.copyWith(successMessage: 'Dépense enregistrée');
      await loadExpenses();
      await loadDashboard();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de l\'ajout');
      return false;
    }
  }
}
