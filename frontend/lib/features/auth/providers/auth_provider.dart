import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';

/// État d'authentification
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// State de l'authentification
class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    Map<String, dynamic>? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  /// Prénom de l'utilisateur connecté
  String get prenom => user?['nom']?.toString().split(' ').first ?? 'Utilisateur';

  /// Rôle de l'utilisateur
  String get role => user?['role']?.toString() ?? '';
}

/// Provider API service
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// Provider Auth service
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiServiceProvider));
});

/// Provider Auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

/// Notifier d'authentification
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  /// Initialiser — vérifier si un token existe
  Future<void> init() async {
    await _authService.init();
    if (_authService.isLoggedIn) {
      final user = _authService.currentUser;
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Connexion
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final data = await _authService.login(email, password);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: data['user'] as Map<String, dynamic>?,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Email ou mot de passe incorrect',
      );
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
