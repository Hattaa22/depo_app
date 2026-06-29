import 'package:flutter/foundation.dart';

/// Konfigurasi URL API backend Laravel.
///
/// Production wajib mengirim API_BASE_URL yang mengarah ke domain HTTPS.
/// Contoh:
/// flutter build apk --dart-define=API_BASE_URL=https://api.domain.com/api/v1
class ApiConfig {
  static const String _localWifiApiUrl = 'http://192.168.1.80:8000/api/v1';
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const bool allowHttpApi = bool.fromEnvironment('ALLOW_HTTP_API');

  static String get baseUrl {
    final configured = apiBaseUrl.trim();
    final rawUrl = configured.isNotEmpty ? configured : _localWifiApiUrl;

    final normalized = _withApiVersion(rawUrl);
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return _localWifiApiUrl;
    }

    if (uri.scheme != 'https' &&
        !(allowHttpApi || kDebugMode || kProfileMode || _isLocalWifiUrl(uri))) {
      return 'https://api.example.com/api/v1';
    }

    return normalized;
  }

  static bool get isUsingPlaceholderProductionUrl =>
      kReleaseMode && baseUrl == 'https://api.example.com/api/v1';

  static String _withApiVersion(String url) {
    final normalized =
        url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    if (normalized.endsWith('/api/v1') || normalized.endsWith('/v1')) {
      return normalized;
    }
    return '$normalized/api/v1';
  }

  static bool _isLocalWifiUrl(Uri uri) {
    return uri.host == '192.168.1.80';
  }
}
