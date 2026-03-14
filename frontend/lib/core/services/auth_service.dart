import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';

/// Service d'authentification — login, logout, stockage token
class AuthService {
  final ApiService _api;
  static const _tokenKey = 'auth_token';
  static const _userKey = 'current_user';
  static const _boxName = 'auth_box';

  AuthService(this._api);

  /// Initialiser Hive et restaurer le token sauvegardé
  Future<void> init() async {
    await Hive.initFlutter();
    final box = await Hive.openBox(_boxName);
    final savedToken = box.get(_tokenKey) as String?;
    if (savedToken != null) {
      _api.setAuthToken(savedToken);
    }
  }

  /// Connexion — envoie email/password, reçoit JWT
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;

    // Sauvegarder le token
    _api.setAuthToken(token);
    final box = Hive.box(_boxName);
    await box.put(_tokenKey, token);
    await box.put(_userKey, data['user']);

    return data;
  }

  /// Déconnexion — effacer le token
  Future<void> logout() async {
    _api.setAuthToken(null);
    final box = Hive.box(_boxName);
    await box.delete(_tokenKey);
    await box.delete(_userKey);
  }

  /// Vérifier si l'utilisateur est connecté
  bool get isLoggedIn {
    final box = Hive.box(_boxName);
    return box.containsKey(_tokenKey);
  }

  /// Récupérer le token sauvegardé
  String? get token {
    final box = Hive.box(_boxName);
    return box.get(_tokenKey) as String?;
  }

  /// Récupérer les infos utilisateur sauvegardées
  Map<String, dynamic>? get currentUser {
    final box = Hive.box(_boxName);
    final userData = box.get(_userKey);
    if (userData == null) return null;
    return Map<String, dynamic>.from(userData as Map);
  }

  /// Récupérer le profil depuis l'API
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _api.get('/auth/me');
    return response.data as Map<String, dynamic>;
  }
}
