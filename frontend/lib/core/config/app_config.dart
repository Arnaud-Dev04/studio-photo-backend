/// Configuration de l'application — URL API depuis --dart-define
class AppConfig {
  AppConfig._();

  /// URL de base de l'API backend
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:5000',
  );

  /// Timeout des requêtes en secondes
  static const int requestTimeout = 30;

  /// Timeout de connexion en secondes
  static const int connectTimeout = 15;
}
