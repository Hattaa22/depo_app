/// Konfigurasi URL API backend Laravel.
class ApiConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.8:8000/api/v1',
  );

  static String get baseUrl => _withApiVersion(apiBaseUrl);

  static String _withApiVersion(String url) {
    final normalized = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    if (normalized.endsWith('/api/v1') || normalized.endsWith('/v1')) {
      return normalized;
    }
    return '$normalized/api/v1';
  }
}
