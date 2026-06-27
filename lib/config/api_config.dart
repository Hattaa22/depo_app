import 'dart:io';

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
/// Kosongkan [ngrokUrl] → isi [lanHost] dengan IP PC dari `ipconfig`
class ApiConfig {
  static const int port = 3000;

  /// Isi dengan URL ngrok jika pakai ngrok, kosongkan jika pakai LAN.
  /// Contoh: 'https://abcd-1234.ngrok-free.app'
  static const String ngrokUrl = '';

  /// IP PC di jaringan LAN (dipakai jika [ngrokUrl] kosong).
  static const String lanHost = '192.168.0.117';

  static String get baseUrl {
    // Prioritas 1: ngrok URL (semua platform)
    if (ngrokUrl.isNotEmpty) {
      return '$ngrokUrl/v1';
    }

    // Prioritas 2: mode LAN
    if (kIsWeb) {
      return 'http://127.0.0.1:$port/v1';
    }
    if (Platform.isAndroid) {
      // Android emulator: gunakan 10.0.2.2 (rute khusus ke host)
      // Android device fisik: gunakan lanHost (IP PC lokal)
      return 'http://$lanHost:$port/v1';
    }
    return 'http://127.0.0.1:$port/v1';
  }
}
