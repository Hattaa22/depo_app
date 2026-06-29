import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ApiErrorHelper {
  static String message(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.unknown:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return connectionHelp();
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode;
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
    return 'Aplikasi tidak bisa menjangkau server API:\n'
        '${ApiConfig.baseUrl}\n\n'
        '1. Pastikan domain API aktif dan memakai HTTPS\n'
        '2. Pastikan API_BASE_URL pada build aplikasi sudah benar\n'
        '3. Pastikan firewall, SSL, dan web server mengizinkan akses publik\n'
        '4. Coba login ulang setelah koneksi internet stabil';
  }
}
