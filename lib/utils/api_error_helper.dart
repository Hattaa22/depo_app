import 'package:dio/dio.dart';
import '../config/api_config.dart';

/// Pesan error API yang mudah dibaca pengguna.
class ApiErrorHelper {
  static String message(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.unknown:
          return connectionHelp();
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return connectionHelp();
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode;
          // 502/503/504 berarti server backend tidak terjangkau lewat
          // proxy/tunnel (mis. ngrok mati atau npm start belum jalan),
          // bukan error logika dari aplikasi kita sendiri.
          if (code == 502 || code == 503 || code == 504) {
            return connectionHelp();
          }
          final data = error.response?.data;
          if (data is Map && data['message'] != null) {
            return data['message'].toString();
          }
          if (code == 401) {
            return 'Sesi habis. Silakan login ulang.';
          }
          if (code == 400) {
            return 'Data tidak valid. Periksa input Anda.';
          }
          return 'Server error ($code).';
        default:
          return 'Terjadi kesalahan saat menghubungi server. Coba lagi.';
      }
    }
    return 'Terjadi kesalahan yang tidak terduga. Coba lagi.';
  }

  static String connectionHelp() {
    return 'HP tidak bisa menjangkau server:\n'
        '${ApiConfig.baseUrl}\n\n'
        '1. Terminal PC: cd backend → npm start\n'
        '2. HP & PC harus WiFi yang sama (bukan data seluler saja)\n'
        '3. Cek IP PC (ipconfig), sesuaikan lanHost di lib/config/api_config.dart\n'
        '   (sekarang: ${ApiConfig.lanHost})\n'
        '4. Izinkan firewall Windows port ${ApiConfig.port}\n'
        '5. Stop lalu flutter run (bukan hot reload saja)';
  }
}
