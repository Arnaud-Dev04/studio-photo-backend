import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

/// État du module Équipe
class TeamState {
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> schedules;
  final List<Map<String, dynamic>> attendance;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const TeamState({
    this.members = const [],
    this.tasks = const [],
    this.schedules = const [],
    this.attendance = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  TeamState copyWith({
    List<Map<String, dynamic>>? members,
    List<Map<String, dynamic>>? tasks,
    List<Map<String, dynamic>>? schedules,
    List<Map<String, dynamic>>? attendance,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TeamState(
      members: members ?? this.members,
      tasks: tasks ?? this.tasks,
      schedules: schedules ?? this.schedules,
      attendance: attendance ?? this.attendance,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  int get tasksToDo => tasks.where((t) => t['statut'] == 'a_faire').length;
  int get tasksInProgress => tasks.where((t) => t['statut'] == 'en_cours').length;
  int get tasksDone => tasks.where((t) => t['statut'] == 'terminee').length;
}

final teamProvider = StateNotifierProvider<TeamNotifier, TeamState>((ref) {
  return TeamNotifier(ref.read(apiServiceProvider));
});

class TeamNotifier extends StateNotifier<TeamState> {
  final ApiService _api;

  TeamNotifier(this._api) : super(const TeamState());

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  /// Charger les membres de l'équipe
  Future<void> loadMembers() async {
    try {
      final response = await _api.get('/auth/users');
      final data = response.data;
      final List<dynamic> usersJson = data is Map
          ? (data['users'] as List<dynamic>? ?? [])
          : (data as List<dynamic>);
      state = state.copyWith(
        members: usersJson.cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Erreur de chargement des membres');
    }
  }

  /// Charger les tâches
  Future<void> loadTasks({String? statut, String? assignedTo}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final params = <String, dynamic>{};
      if (statut != null) params['statut'] = statut;
      if (assignedTo != null) params['assigned_to'] = assignedTo;

      final response = await _api.get('/tasks', queryParameters: params);
      final data = response.data;
      final List<dynamic> tasksJson = data is Map
          ? (data['tasks'] as List<dynamic>? ?? [])
          : (data as List<dynamic>);
      state = state.copyWith(
        tasks: tasksJson.cast<Map<String, dynamic>>(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur de chargement des tâches');
    }
  }

  /// Créer une tâche
  Future<bool> createTask(Map<String, dynamic> data) async {
    try {
      await _api.post('/tasks', data: data);
      state = state.copyWith(successMessage: 'Tâche créée');
      await loadTasks();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la création');
      return false;
    }
  }

  /// Modifier une tâche (ex : changer le statut)
  Future<bool> updateTask(String taskId, Map<String, dynamic> data) async {
    try {
      await _api.patch('/tasks/$taskId', data: data);
      state = state.copyWith(successMessage: 'Tâche modifiée');
      await loadTasks();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la modification');
      return false;
    }
  }

  /// Supprimer une tâche
  Future<bool> deleteTask(String taskId) async {
    try {
      await _api.delete('/tasks/$taskId');
      state = state.copyWith(successMessage: 'Tâche supprimée');
      await loadTasks();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la suppression');
      return false;
    }
  }

  /// Check-in
  Future<bool> checkIn({double? lat, double? lng}) async {
    try {
      final data = <String, dynamic>{};
      if (lat != null) data['latitude'] = lat;
      if (lng != null) data['longitude'] = lng;
      await _api.post('/attendance/checkin', data: data);
      state = state.copyWith(successMessage: 'Check-in enregistré');
      await loadAttendance();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur de check-in');
      return false;
    }
  }

  /// Check-out
  Future<bool> checkOut() async {
    try {
      await _api.post('/attendance/checkout');
      state = state.copyWith(successMessage: 'Check-out enregistré');
      await loadAttendance();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur de check-out');
      return false;
    }
  }

  /// Charger le pointage
  Future<void> loadAttendance({String? userId}) async {
    try {
      final params = <String, dynamic>{};
      if (userId != null) params['user_id'] = userId;

      final response = await _api.get('/attendance', queryParameters: params);
      final data = response.data;
      final List<dynamic> json = data is Map
          ? (data['attendance'] as List<dynamic>? ?? [])
          : (data as List<dynamic>);
      state = state.copyWith(attendance: json.cast<Map<String, dynamic>>());
    } catch (e) {
      // Silencieux
    }
  }

  /// Charger les séances
  Future<void> loadSchedules() async {
    try {
      final response = await _api.get('/schedules');
      final data = response.data;
      final List<dynamic> json = data is Map
          ? (data['schedules'] as List<dynamic>? ?? [])
          : (data as List<dynamic>);
      state = state.copyWith(schedules: json.cast<Map<String, dynamic>>());
    } catch (e) {
      // Silencieux
    }
  }
}
