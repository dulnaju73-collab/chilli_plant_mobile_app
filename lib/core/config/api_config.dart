class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://16.179.128.119',
  );

  static String get baseUrl {
    final trimmed = _configuredBaseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static const Duration requestTimeout = Duration(seconds: 60);
}
