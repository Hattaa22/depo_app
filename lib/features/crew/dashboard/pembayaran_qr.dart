import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_theme.dart';
import '../../../config/routes.dart';
import '../../../services/api_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/formatters.dart';

class PembayaranQrScreen extends StatefulWidget {
  final int totalHarga;
  final String transaksiId;

  const PembayaranQrScreen({
    super.key,
    required this.totalHarga,
    required this.transaksiId,
  });

  @override
  State<PembayaranQrScreen> createState() => _PembayaranQrScreenState();
}

class _PembayaranQrScreenState extends State<PembayaranQrScreen> {
  final ApiService _api = Get.find<ApiService>();

  Timer? _pollingTimer;
  final _qrisString = ''.obs;
  final _qrImageUrl = ''.obs;
  final _redirectUrl = ''.obs;
  final _paymentId = ''.obs;
  final _isLoading = true.obs;
  final _isPolling = false.obs;
  final _isPaid = false.obs;
  final _isExpired = false.obs;
  final _errorMessage = ''.obs;
  final _expiredAt = ''.obs;
  final _jumlah = 0.0.obs;
  bool _isLeavingPage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initQris();
      _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        _cekStatus();
      });
    });
  }

  Future<void> _initQris() async {
    if (_isLeavingPage || !mounted) return;
    _isLoading.value = true;
    _errorMessage.value = '';
    try {
      final payment = await _api.buatPembayaranQris(widget.transaksiId);
      if (_isLeavingPage || !mounted) return;
      _paymentId.value = payment.paymentId;
      _qrisString.value = payment.qrContent;
      _qrImageUrl.value = payment.qrImageUrl ?? '';
      _redirectUrl.value = payment.redirectUrl ?? payment.qrContent;
      _jumlah.value = payment.jumlah;
      final expiredAt = DateTime.tryParse(payment.expiresAt);
      _expiredAt.value = expiredAt != null
          ? Formatters.dateTime(expiredAt)
          : payment.expiresAt;
    } catch (e) {
      if (_isLeavingPage || !mounted) return;
      _errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar(
        'Gagal membuat QRIS',
        _errorMessage.value,
        backgroundColor: const Color(0xFFE63946),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      if (!_isLeavingPage && mounted) {
        _isLoading.value = false;
      }
    }
  }

  Future<void> _cekStatus() async {
    if (_isLeavingPage || !mounted) return;
    if (_paymentId.value.isEmpty || _isPaid.value || _isExpired.value) return;
    if (_isPolling.value) return;

    _isPolling.value = true;
    try {
      final status = await _api.cekStatusPembayaranQris(_paymentId.value);
      if (_isLeavingPage || !mounted) return;
      if (status.isPaid) {
        _onPembayaranBerhasil();
      } else if (status.isExpired) {
        _isExpired.value = true;
        _pollingTimer?.cancel();
      }
    } catch (_) {
      // Tetap polling — koneksi sementara putus
    } finally {
      if (!_isLeavingPage && mounted) {
        _isPolling.value = false;
      }
    }
  }

  void _bukaRiwayatTransaksi() {
    if (_isLeavingPage) return;
    _isLeavingPage = true;
    _pollingTimer?.cancel();
    Get.offAllNamed(AppRoutes.crewRiwayat);
  }

  void _tutupPembayaran() {
    if (_isLeavingPage) return;
    _isLeavingPage = true;
    _pollingTimer?.cancel();
    Get.offAllNamed(AppRoutes.crewDashboard);
  }

  /// Buka halaman checkout Midtrans Snap di browser.
  Future<void> _bukaHalamanWeb() async {
    final paymentUrl =
        _redirectUrl.value.isNotEmpty ? _redirectUrl.value : _qrisString.value;
    if (paymentUrl.isEmpty) return;
    final url = Uri.parse(paymentUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy URL ke clipboard
        await Clipboard.setData(ClipboardData(text: url.toString()));
        Get.snackbar(
          'URL disalin',
          'Buka URL ini di browser: ${url.toString()}',
          duration: const Duration(seconds: 5),
          backgroundColor: const Color(0xFF0284C7),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Tidak dapat membuka browser. Coba lagi.');
    }
  }

  void _onPembayaranBerhasil() {
    if (_isLeavingPage || !mounted || _isPaid.value) return;
    _isPaid.value = true;
    _pollingTimer?.cancel();
    Get.snackbar(
      'Pembayaran Diterima',
      'Menunggu validasi manager.',
      backgroundColor: const Color(0xFF10B981),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || _isLeavingPage) return;
      _isLeavingPage = true;
      Get.offAllNamed(AppRoutes.crewDashboard);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran QRIS'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _tutupPembayaran,
        ),
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_errorMessage.value.isNotEmpty) {
          return _buildErrorState();
        }

        if (_isPaid.value) {
          return _buildPaidState();
        }

        if (_isExpired.value) {
          return _buildExpiredState();
        }

        return _buildQrState();
      }),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              _errorMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _initQris,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaidState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 72, color: Color(0xFF10B981)),
          SizedBox(height: 16),
          Text(
            'Pembayaran Berhasil',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Transaksi menunggu validasi manager',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_off_rounded,
                size: 56, color: Color(0xFFF59E0B)),
            const SizedBox(height: 16),
            const Text(
              'QRIS Kadaluarsa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buat transaksi baru dari kasir.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.offAllNamed(AppRoutes.crewDashboard),
              child: const Text('Kembali ke Kasir'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrState() {
    final amount =
        _jumlah.value > 0 ? _jumlah.value : widget.totalHarga.toDouble();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_rounded, size: 16, color: Color(0xFF1392EC)),
                  SizedBox(width: 6),
                  Text(
                    'Memerlukan koneksi internet',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1392EC),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan QR untuk Membayar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              Formatters.currency(amount),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            // QR Code Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: _buildQrisImage(),
            ),
            const SizedBox(height: 8),
            // Payment badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Text(
                'QRIS Midtrans Sandbox - mode uji coba',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Menunggu pembayaran...'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Berlaku hingga ${_expiredAt.value}',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            // ── Opsi Pembayaran ──
            const Text(
              'OPSI PEMBAYARAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            // Tombol: Buka checkout Midtrans
            ElevatedButton.icon(
              onPressed: _bukaHalamanWeb,
              icon: const Icon(Icons.open_in_browser_rounded),
              label: const Text('Buka Checkout Midtrans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan QR di atas atau buka checkout Midtrans untuk menyelesaikan simulasi pembayaran QRIS sandbox.',
              style: TextStyle(
                  fontSize: 11, color: Color(0xFF64748B), height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _bukaRiwayatTransaksi,
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('Lihat Riwayat Transaksi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0284C7),
                side: const BorderSide(color: Color(0xFF0284C7)),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQrisImage() {
    if (_qrImageUrl.value.isNotEmpty) {
      return Image.network(
        _qrImageUrl.value,
        width: 240,
        height: 240,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => QrImageView(
          data: _qrisString.value,
          size: 240,
          backgroundColor: Colors.white,
        ),
      );
    }

    return QrImageView(
      data: _qrisString.value,
      size: 240,
      backgroundColor: Colors.white,
    );
  }
}
