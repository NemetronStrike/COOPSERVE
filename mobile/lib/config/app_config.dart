class AppConfig {
  static const env = String.fromEnvironment('ENV', defaultValue: 'development');
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');
}
