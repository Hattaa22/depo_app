import 'package:flutter/foundation.dart';

/// Konfigurasi URL API backend Laravel.
///
/// Production wajib mengirim API_BASE_URL yang mengarah ke domain HTTPS.
/// Contoh:
/// flutter build apk --dart-define=API_BASE_URL=https://api.domain.com/api/v1
class ApiConfig {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const bool allowHttpApi = bool.fromEnvironment('ALLOW_HTTP_API');

  static String get baseUrl {
    final configured = apiBaseUrl.trim();
    final rawUrl = configured.isNotEmpty
        ? configured
        : (kReleaseMode
            ? 'https://api.example.com/api/v1'
            : 'http://127.0.0.1:8000/api/v1');

    final normalized = _withApiVersion(rawUrl);
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return kReleaseMode
          ? 'https://api.example.com/api/v1'
          : 'http://127.0.0.1:8000/api/v1';
    }

    if (uri.scheme != 'https' && !(allowHttpApi || kDebugMode || kProfileMode)) {
      return 'https://api.example.com/api/v1';
    }

    return normalized;
  }

  static bool get isUsingPlaceholderProductionUrl =>
      kReleaseMode && apiBaseUrl.trim().isEmpty;

  static String _withApiVersion(String url) {
    final normalized = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    if (normalized.endsWith('/api/v1') || normalized.endsWith('/v1')) {
      return normalized;
    }
    return '$normalized/api/v1';
  }
}
