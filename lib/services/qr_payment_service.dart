import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../config/constants.dart';
import '../utils/numeric_parser.dart';
import 'local_storage.dart';

class QrPaymentService {
  final LocalStorage _localStorage;
  final _uuid = const Uuid();

  QrPaymentService(this._localStorage);

  /// Generate QR payload untuk pembayaran
  Future<QrPaymentData> generateQrPayment({
    required String transaksiId,
    required double jumlah,
    required String namaDepot,
    String? catatan,
  }) async {
    final paymentId = _uuid.v4();
    final expiresAt = DateTime.now().add(
      const Duration(minutes: AppConstants.qrExpiryMinutes),
    );

    final payload = QrPaymentData(
      paymentId: paymentId,
      transaksiId: transaksiId,
      jumlah: jumlah,
      namaDepot: namaDepot,
      catatan: catatan,
      expiresAt: expiresAt,
    );

    // Simpan sementara ke local storage untuk verifikasi
    await _localStorage.setString(
      'qr_payment_$paymentId',
      jsonEncode(payload.toJson()),
    );

    return payload;
  }

  /// Verifikasi QR yang di-scan
  Future<QrVerificationResult> verifyQrPayment(String qrString) async {
    try {
      final decoded = jsonDecode(qrString) as Map<String, dynamic>;
      final paymentId = decoded['payment_id'] as String;

      final storedJson = _localStorage.getString('qr_payment_$paymentId');
      if (storedJson == null) {
        return QrVerificationResult.invalid('QR tidak ditemukan');
      }

      final stored = QrPaymentData.fromJson(
        jsonDecode(storedJson) as Map<String, dynamic>,
      );

      if (DateTime.now().isAfter(stored.expiresAt)) {
        await _localStorage.remove('qr_payment_$paymentId');
        return QrVerificationResult.invalid('QR sudah kadaluarsa');
      }

      return QrVerificationResult.valid(stored);
    } catch (e) {
      return QrVerificationResult.invalid('QR tidak valid');
    }
  }

  /// Hapus QR setelah berhasil digunakan
  Future<void> invalidateQr(String paymentId) async {
    await _localStorage.remove('qr_payment_$paymentId');
  }

  /// Generate string QR code
  String generateQrString(QrPaymentData data) {
    return jsonEncode({
      'payment_id': data.paymentId,
      'transaksi_id': data.transaksiId,
      'jumlah': data.jumlah,
      'expires_at': data.expiresAt.toIso8601String(),
    });
  }
}

class QrPaymentData {
  final String paymentId;
  final String transaksiId;
  final double jumlah;
  final String namaDepot;
  final String? catatan;
  final DateTime expiresAt;

  QrPaymentData({
    required this.paymentId,
    required this.transaksiId,
    required this.jumlah,
    required this.namaDepot,
    this.catatan,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
        'payment_id': paymentId,
        'transaksi_id': transaksiId,
        'jumlah': jumlah,
        'nama_depot': namaDepot,
        'catatan': catatan,
        'expires_at': expiresAt.toIso8601String(),
      };

  factory QrPaymentData.fromJson(Map<String, dynamic> json) => QrPaymentData(
        paymentId: json['payment_id'],
        transaksiId: json['transaksi_id'],
        jumlah: parseDouble(json['jumlah']),
        namaDepot: json['nama_depot'],
        catatan: json['catatan'],
        expiresAt: DateTime.parse(json['expires_at']),
      );
}

class QrVerificationResult {
  final bool isValid;
  final String? errorMessage;
  final QrPaymentData? data;

  QrVerificationResult._({
    required this.isValid,
    this.errorMessage,
    this.data,
  });

  factory QrVerificationResult.valid(QrPaymentData data) =>
      QrVerificationResult._(isValid: true, data: data);

  factory QrVerificationResult.invalid(String message) =>
      QrVerificationResult._(isValid: false, errorMessage: message);
}