import 'api_config.dart';

class AppConstants {
  // API — lihat ApiConfig.baseUrl (otomatis per platform)
  static String get baseUrl => ApiConfig.baseUrl;
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  /// false = login & data dari Laravel API
  static const bool useMockAuth = false;

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userRoleKey = 'user_role';
  static const String userDataKey = 'user_data';

  // Auth Service Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserRole = 'user_role';
  static const String keyUserId = 'user_id';

  // Roles
  static const String roleCrew = 'crew';
  static const String roleManager = 'manager';

  // Pagination
  static const int defaultPageSize = 20;

  // QR Payment
  static const String qrisPrefix = 'QRIS://';
  static const int qrExpiryMinutes = 15;

  // Validasi
  static const int minPasswordLength = 6;
  static const int maxNamaLength = 100;
  static const int maxAlamatLength = 200;

  // Produk
  static const String kategoriGalon = 'galon';
  static const String kategoriAir = 'air';

  // Status Transaksi (selaras backend)
  static const String statusPending = 'pending';
  static const String statusMenungguValidasi = 'menungguValidasi';
  static const String statusSelesai = 'selesai';
  static const String statusDibatalkan = 'dibatalkan';

  /// Body validasi API
  static const String validasiSukses = 'sukses';
  static const String validasiGagal = 'gagal';

  // Status Galon (selaras model & API)
  static const String galonTersedia = 'tersedia';
  static const String galonDipinjam = 'dipinjam';
  static const String galonRusak = 'rusak';
  static const String galonHilang = 'hilang';

  // Formatter
  static const String currencyLocale = 'id_ID';
  static const String currencySymbol = 'Rp';
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy, HH:mm';
  static const String timeFormat = 'HH:mm';
  static const String dateOnlyFormat = 'yyyy-MM-dd';

  // Test Credentials (untuk development & testing)
  static const String testManagerEmail = 'manager@depoair.com';
  static const String testManagerPassword = 'Password123';
  static const String testCrewUsername = 'crew001';
  static const String testCrewPassword = 'Password123';
}
