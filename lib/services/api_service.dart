import 'package:dio/dio.dart';
import '../models/crew.dart';
import '../models/pelanggan.dart';
import '../models/galon.dart';
import '../models/produk.dart';
import '../models/transaksi.dart';
import '../models/pengeluaran.dart';
import '../models/cabang.dart';
import '../utils/numeric_parser.dart';

// =================== REQUEST/RESPONSE MODELS ===================

class LoginRequest {
  final String username;
  final String password;
  LoginRequest({required this.username, required this.password});
  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class RefreshTokenRequest {
  final String refreshToken;
  RefreshTokenRequest({required this.refreshToken});
  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String role;
  final Map<String, dynamic> userData;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.userData,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        role: json['role'] as String,
        userData: json['user_data'] as Map<String, dynamic>,
      );
}

class PaginatedResponse<T> {
  final List<T> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginatedResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });
}

// =================== API SERVICE ===================

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  /// Cek apakah backend dapat dijangkau (untuk diagnosa timeout login).
  Future<bool> cekKoneksiServer() async {
    try {
      final res = await _dio.get(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────

  Future<AuthResponse> loginCrew(LoginRequest request) async {
    final res = await _dio.post('/auth/login/crew', data: request.toJson());
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AuthResponse> loginManager(LoginRequest request) async {
    final res = await _dio.post('/auth/login/manager', data: request.toJson());
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout({String? refreshToken}) async {
    await _dio.post('/auth/logout', data: {
      if (refreshToken != null && refreshToken.isNotEmpty)
        'refresh_token': refreshToken,
    });
  }

  Future<void> changePassword(String passwordLama, String passwordBaru) async {
    await _dio.put('/auth/change-password', data: {
      'passwordLama': passwordLama,
      'passwordBaru': passwordBaru,
    });
  }

  Future<AuthResponse> refreshToken(RefreshTokenRequest request) async {
    final res = await _dio.post('/auth/refresh', data: request.toJson());
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // ── CREW ──────────────────────────────────────────────────────────────────

  Future<PaginatedResponse<Crew>> getSemuaCrew(
      int page, int limit, String? search) async {
    final res = await _dio.get('/crew', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null) 'search': search,
    });
    final d = res.data as Map<String, dynamic>;
    return PaginatedResponse<Crew>(
      data: (d['data'] as List)
          .map((e) => Crew.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: d['total'] as int? ?? 0,
      page: d['page'] as int? ?? page,
      limit: d['limit'] as int? ?? limit,
      totalPages: d['totalPages'] as int? ?? 1,
    );
  }

  Future<Crew> getCrewById(String id) async {
    final res = await _dio.get('/crew/$id');
    return Crew.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Crew> createCrew(Map<String, dynamic> data) async {
    final res = await _dio.post('/crew', data: data);
    return Crew.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Crew> updateCrew(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/crew/$id', data: data);
    return Crew.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteCrew(String id) async {
    await _dio.delete('/crew/$id');
  }

  // ── PELANGGAN ─────────────────────────────────────────────────────────────

  Future<PaginatedResponse<Pelanggan>> getSemuaPelanggan(
      int page, int limit, String? search) async {
    final res = await _dio.get('/pelanggan', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null) 'search': search,
    });
    final d = res.data as Map<String, dynamic>;
    return PaginatedResponse<Pelanggan>(
      data: (d['data'] as List)
          .map((e) => Pelanggan.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: d['total'] as int? ?? 0,
      page: d['page'] as int? ?? page,
      limit: d['limit'] as int? ?? limit,
      totalPages: d['totalPages'] as int? ?? 1,
    );
  }

  Future<Pelanggan> getPelangganById(String id) async {
    final res = await _dio.get('/pelanggan/$id');
    return Pelanggan.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Pelanggan> createPelanggan(Map<String, dynamic> data) async {
    final res = await _dio.post('/pelanggan', data: data);
    return Pelanggan.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Pelanggan> updatePelanggan(
      String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/pelanggan/$id', data: data);
    return Pelanggan.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deletePelanggan(String id) async {
    await _dio.delete('/pelanggan/$id');
  }

  // ── PRODUK ────────────────────────────────────────────────────────────────

  Future<PaginatedResponse<Produk>> getSemuaProduk(
      int page, int limit, String? kategoriId, String? search) async {
    final res = await _dio.get('/produk', queryParameters: {
      'page': page,
      'limit': limit,
      if (kategoriId != null) 'kategoriId': kategoriId,
      if (search != null) 'search': search,
    });
    final d = res.data as Map<String, dynamic>;
    return PaginatedResponse<Produk>(
      data: (d['data'] as List)
          .map((e) => Produk.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: d['total'] as int? ?? 0,
      page: d['page'] as int? ?? page,
      limit: d['limit'] as int? ?? limit,
      totalPages: d['totalPages'] as int? ?? 1,
    );
  }

  Future<Produk> getProdukById(String id) async {
    final res = await _dio.get('/produk/$id');
    return Produk.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Produk> createProduk(Map<String, dynamic> data) async {
    final res = await _dio.post('/produk', data: data);
    return Produk.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Produk> updateProduk(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/produk/$id', data: data);
    return Produk.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteProduk(String id) async {
    await _dio.delete('/produk/$id');
  }

  // ── KATEGORI ──────────────────────────────────────────────────────────────

  Future<List<KategoriProduk>> getSemuaKategori() async {
    final res = await _dio.get('/kategori');
    return (res.data as List)
        .map((e) => KategoriProduk.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KategoriProduk> createKategori(Map<String, dynamic> data) async {
    final res = await _dio.post('/kategori', data: data);
    return KategoriProduk.fromJson(res.data as Map<String, dynamic>);
  }

  Future<KategoriProduk> updateKategori(
      String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/kategori/$id', data: data);
    return KategoriProduk.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteKategori(String id) async {
    await _dio.delete('/kategori/$id');
  }

  // ── GALON ─────────────────────────────────────────────────────────────────

  Future<PaginatedResponse<Galon>> getSemuaGalon(
      int page, int limit, String? status) async {
    final res = await _dio.get('/galon', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
    });
    final d = res.data as Map<String, dynamic>;
    return PaginatedResponse<Galon>(
      data: (d['data'] as List)
          .map((e) => Galon.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: d['total'] as int? ?? 0,
      page: d['page'] as int? ?? page,
      limit: d['limit'] as int? ?? limit,
      totalPages: d['totalPages'] as int? ?? 1,
    );
  }

  Future<RingkasanGalon> getRingkasanGalon() async {
    final res = await _dio.get('/galon/ringkasan');
    return RingkasanGalon.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createGalon(Map<String, dynamic> data) async {
    final res = await _dio.post('/galon', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Galon> updateGalon(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/galon/$id', data: data);
    return Galon.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RingkasanGalon> pinjamGalon(int jumlah,
      {String? pelangganId, DateTime? tanggal}) async {
    final res = await _dio.put('/galon/pinjam', data: {
      'jumlah': jumlah,
      if (pelangganId != null) 'pelangganId': pelangganId,
      if (tanggal != null) 'tanggal': tanggal.toIso8601String(),
    });
    final data = res.data as Map<String, dynamic>;
    return RingkasanGalon.fromJson(
      (data['summary'] ?? data) as Map<String, dynamic>,
    );
  }

  Future<RingkasanGalon> kembalikanGalon(int jumlah,
      {String? pelangganId, DateTime? tanggal}) async {
    final res = await _dio.put('/galon/kembali', data: {
      'jumlah': jumlah,
      if (pelangganId != null) 'pelangganId': pelangganId,
      if (tanggal != null) 'tanggal': tanggal.toIso8601String(),
    });
    final data = res.data as Map<String, dynamic>;
    return RingkasanGalon.fromJson(
      (data['summary'] ?? data) as Map<String, dynamic>,
    );
  }

  // ── TRANSAKSI ─────────────────────────────────────────────────────────────

  Future<PaginatedResponse<Transaksi>> getSemuaTransaksi(
    int page,
    int limit,
    String? status,
    String? crewId,
    String? tanggalMulai,
    String? tanggalAkhir,
  ) async {
    final res = await _dio.get('/transaksi', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (crewId != null) 'crewId': crewId,
      if (tanggalMulai != null) 'tanggalMulai': tanggalMulai,
      if (tanggalAkhir != null) 'tanggalAkhir': tanggalAkhir,
    });
    final d = res.data as Map<String, dynamic>;
    return PaginatedResponse<Transaksi>(
      data: (d['data'] as List)
          .map((e) => Transaksi.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: d['total'] as int? ?? 0,
      page: d['page'] as int? ?? page,
      limit: d['limit'] as int? ?? limit,
      totalPages: d['totalPages'] as int? ?? 1,
    );
  }

  Future<Transaksi> getTransaksiById(String id) async {
    final res = await _dio.get('/transaksi/$id');
    return Transaksi.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Transaksi> createTransaksi(Map<String, dynamic> data) async {
    final res = await _dio.post('/transaksi', data: data);
    return Transaksi.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Transaksi> updateStatusTransaksi(
      String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/transaksi/$id/status', data: data);
    return Transaksi.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Transaksi> validasiTransaksi(
      String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/transaksi/$id/validasi', data: data);
    return Transaksi.fromJson(res.data as Map<String, dynamic>);
  }

  // ── LAPORAN ───────────────────────────────────────────────────────────────

  Future<LaporanKeuangan> getLaporanKeuangan(
      String tanggalMulai, String tanggalAkhir) async {
    final res = await _dio.get('/laporan/keuangan', queryParameters: {
      'tanggalMulai': tanggalMulai,
      'tanggalAkhir': tanggalAkhir,
    });
    return LaporanKeuangan.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getPengirimanCrew({
    String? tanggalMulai,
    String? tanggalAkhir,
  }) async {
    final res = await _dio.get('/laporan/pengiriman-crew', queryParameters: {
      if (tanggalMulai != null) 'tanggalMulai': tanggalMulai,
      if (tanggalAkhir != null) 'tanggalAkhir': tanggalAkhir,
    });
    return (res.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> getDashboardCrew() async {
    final res = await _dio.get('/laporan/dashboard/crew');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDashboardManager() async {
    final res = await _dio.get('/laporan/dashboard/manager');
    return res.data as Map<String, dynamic>;
  }

  // ── PEMBAYARAN QRIS (online) ──────────────────────────────────────────────

  Future<QrisPaymentResponse> buatPembayaranQris(String transaksiId) async {
    final res =
        await _dio.post('/pembayaran/qris', data: {'transaksiId': transaksiId});
    return QrisPaymentResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<QrisPaymentStatusResponse> cekStatusPembayaranQris(
      String paymentId) async {
    final res = await _dio.get('/pembayaran/qris/$paymentId/status');
    return QrisPaymentStatusResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// Simulasi webhook gateway (uji coba / skripsi).
  Future<QrisPaymentStatusResponse> simulasikanBayarQris(
      String paymentId) async {
    final res = await _dio.post('/pembayaran/qris/$paymentId/simulate-pay');
    final data = res.data as Map<String, dynamic>;
    return QrisPaymentStatusResponse(
      paymentId: paymentId,
      transaksiId: data['transaksiId'] as String? ?? '',
      status: data['status'] as String? ?? 'paid',
      jumlah: 0,
      paidAt: data['paidAt'] as String?,
      expiresAt: null,
    );
  }

  // ── PENGELUARAN ────────────────────────────────────────────────────────────

  Future<List<Pengeluaran>> getSemuaPengeluaran() async {
    final res = await _dio.get('/pengeluaran');
    return (res.data as List)
        .map((e) => Pengeluaran.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Pengeluaran> createPengeluaran(Map<String, dynamic> data) async {
    final res = await _dio.post('/pengeluaran', data: data);
    return Pengeluaran.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deletePengeluaran(String id) async {
    await _dio.delete('/pengeluaran/$id');
  }

  // ── CABANG DEPO ────────────────────────────────────────────────────────────

  Future<List<CabangDepo>> getSemuaCabang() async {
    final res = await _dio.get('/cabang');
    return (res.data as List)
        .map((e) => CabangDepo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CabangDepo> createCabang(Map<String, dynamic> data) async {
    final res = await _dio.post('/cabang', data: data);
    return CabangDepo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CabangDepo> updateCabang(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/cabang/$id', data: data);
    return CabangDepo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteCabang(String id) async {
    await _dio.delete('/cabang/$id');
  }
}

class QrisPaymentResponse {
  final String paymentId;
  final String transaksiId;
  final String qrContent;
  final double jumlah;
  final String status;
  final String expiresAt;
  final String namaDepot;

  QrisPaymentResponse({
    required this.paymentId,
    required this.transaksiId,
    required this.qrContent,
    required this.jumlah,
    required this.status,
    required this.expiresAt,
    required this.namaDepot,
  });

  factory QrisPaymentResponse.fromJson(Map<String, dynamic> json) =>
      QrisPaymentResponse(
        paymentId: json['paymentId'] as String,
        transaksiId: json['transaksiId'] as String,
        qrContent: json['qrContent'] as String,
        jumlah: parseDouble(json['jumlah']),
        status: json['status'] as String? ?? 'pending',
        expiresAt: json['expiresAt'] as String,
        namaDepot: json['namaDepot'] as String? ?? 'Depo Air Minum',
      );
}

class QrisPaymentStatusResponse {
  final String paymentId;
  final String transaksiId;
  final String status;
  final double jumlah;
  final String? paidAt;
  final String? expiresAt;

  QrisPaymentStatusResponse({
    required this.paymentId,
    required this.transaksiId,
    required this.status,
    required this.jumlah,
    this.paidAt,
    this.expiresAt,
  });

  factory QrisPaymentStatusResponse.fromJson(Map<String, dynamic> json) =>
      QrisPaymentStatusResponse(
        paymentId: json['paymentId'] as String,
        transaksiId: json['transaksiId'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        jumlah: parseDouble(json['jumlah']),
        paidAt: json['paidAt'] as String?,
        expiresAt: json['expiresAt'] as String?,
      );

  bool get isPaid => status == 'paid' || paidAt != null;
  bool get isExpired => status == 'expired';
}
