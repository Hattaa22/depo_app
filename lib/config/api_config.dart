import 'package:flutter/foundation.dart';

/// Konfigurasi URL API backend.
///
/// ## Mode ngrok (direkomendasikan — tidak perlu ganti IP)
/// 1. Jalankan: `ngrok http 3000`
/// 2. Copy URL dari ngrok (contoh: https://xxxx-xx-xx.ngrok-free.app)
/// 3. Paste ke [ngrokUrl] di bawah
/// 4. Hot-restart Flutter
///
/// ## Mode LAN (default)
/// Kosongkan [ngrokUrl] → isi [mode] sesuai penggunaanmu
class ApiConfig {
  static const int port = int.fromEnvironment('API_PORT', defaultValue: 3000);

  /// Override untuk production/staging build.
  /// Contoh:
  /// flutter build apk --dart-define=API_BASE_URL=https://api.domain.com/v1
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Isi dengan URL ngrok jika pakai ngrok, kosongkan jika pakai LAN.
  /// Contoh: 'https://abcd-1234.ngrok-free.app'
  static const String ngrokUrl =
      String.fromEnvironment('NGROK_URL', defaultValue: '');

  /// Pilih mode koneksi:
  /// - 'emulator' untuk Android Emulator (otomatis 10.0.2.2)
  /// - 'hp_fisik' untuk HP fisik (gunakan [lanHostForHp])
  /// - 'ios_simulator' untuk iOS Simulator (127.0.0.1)
  static const String mode =
      String.fromEnvironment('API_MODE', defaultValue: 'hp_fisik');

  /// IP PC di jaringan LAN (untuk mode 'hp_fisik') — cek via `ipconfig` di Windows!
  static const String lanHostForHp =
      String.fromEnvironment('LAN_HOST', defaultValue: '192.168.100.8');

  static String get lanHost {
    if (mode == 'emulator') return '10.0.2.2';
    if (mode == 'hp_fisik') return lanHostForHp;
    return '127.0.0.1'; // iOS Simulator / desktop
  }

  static String get baseUrl {
    if (apiBaseUrl.isNotEmpty) return _withApiVersion(apiBaseUrl);
    if (ngrokUrl.isNotEmpty) return _withApiVersion(ngrokUrl);

    if (kIsWeb) {
      return 'http://127.0.0.1:$port/v1';
    }
    return 'http://$lanHost:$port/v1';
  }

  static String _withApiVersion(String url) {
    final normalized =
        url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    return normalized.endsWith('/v1') ? normalized : '$normalized/v1';
  }
}
