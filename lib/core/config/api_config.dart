class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://16.178.139.98',
  );

  static String get baseUrl => _configuredBaseUrl;

  static const Duration requestTimeout = Duration(seconds: 60);
}
