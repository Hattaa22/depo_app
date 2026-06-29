import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/laporan_controller.dart';
import '../../../controllers/transaksi_controller.dart';
import '../../../config/routes.dart';
import '../../../models/transaksi.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/header_back_button.dart';
import '../../../widgets/modern_date_range_sheet.dart';
import '../../../widgets/qr_code_widget.dart';

class LaporanTransaksiScreen extends StatefulWidget {
  const LaporanTransaksiScreen({super.key});

  @override
  State<LaporanTransaksiScreen> createState() => _LaporanTransaksiScreenState();
}

class _LaporanTransaksiScreenState extends State<LaporanTransaksiScreen> {
  static const Color _primary = Color(0xFF1392EC);
  static const Color _bgLight = Color(0xFFF1F5F9);

  late DateTime _mulai;
  late DateTime _akhir;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mulai = DateTime(now.year, now.month, 1);
    _akhir = now;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _muatLaporan();
    });
  }

  void _muatLaporan() {
    Get.find<LaporanController>().filterLaporan(
      Formatters.dateOnly(_mulai),
      Formatters.dateOnly(_akhir),
    );
  }

  Future<void> _pilihTanggal() async {
    final range = await ModernDateRangeSheet.show(
      context,
      initial: DateTimeRange(start: _mulai, end: _akhir),
    );
    if (range != null) {
      setState(() {
        _mulai = range.start;
        _akhir = range.end;
      });
      _muatLaporan();
    }
  }

  void _validasiTransaksi(String id, String status) {
    Get.find<TransaksiController>().validasiTransaksi(id, status).then((_) {
      _muatLaporan();
    });
  }

  // ── STATUS HELPERS ─────────────────────────────────────────────────────────
  String _statusLabel(StatusTransaksi status) {
    switch (status) {
      case StatusTransaksi.selesai:
        return 'Lunas';
      case StatusTransaksi.pending:
        return 'Pending';
      case StatusTransaksi.diproses:
        return 'Diproses';
      case StatusTransaksi.dibatalkan:
        return 'Batal';
      case StatusTransaksi.menungguValidasi:
        return 'Validasi';
    }
  }

  Color _statusColor(StatusTransaksi status) {
    switch (status) {
      case StatusTransaksi.selesai:
        return const Color(0xFF065F46);
      case StatusTransaksi.pending:
        return const Color(0xFF92400E);
      case StatusTransaksi.diproses:
        return _primary;
      case StatusTransaksi.dibatalkan:
        return const Color(0xFF991B1B);
      case StatusTransaksi.menungguValidasi:
        return const Color(0xFF5B21B6);
    }
  }

  Color _statusBgColor(StatusTransaksi status) {
    switch (status) {
      case StatusTransaksi.selesai:
        return const Color(0xFFD1FAE5);
      case StatusTransaksi.pending:
        return const Color(0xFFFEF3C7);
      case StatusTransaksi.diproses:
        return const Color(0xFFEFF6FF);
      case StatusTransaksi.dibatalkan:
        return const Color(0xFFFEE2E2);
      case StatusTransaksi.menungguValidasi:
        return const Color(0xFFEDE9FE);
    }
  }

  // ── DETAIL BOTTOM SHEET ────────────────────────────────────────────────────
  void _showDetailBottomSheet(BuildContext context, Transaksi tx) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Header ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detail Transaksi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusBgColor(tx.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(tx.status).toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _statusColor(tx.status),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'No: ${Formatters.nomorTransaksiTampilan(tx.nomorTransaksi)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // ── Info Umum ─────────────────────────────────────────────
              _buildInfoRow('Waktu', Formatters.dateTime(tx.createdAt)),
              _buildInfoRow('Pelanggan', tx.pelanggan?.nama ?? '-'),
              _buildInfoRow('No HP Pelanggan', tx.pelanggan?.noHp ?? '-'),
              _buildInfoRow(
                  'Metode Bayar', tx.metodePembayaran.name.toUpperCase()),
              _buildInfoRow('Petugas', tx.crew?.nama ?? '-'),
              if (tx.isDikirim) ...[
                _buildInfoRow('Tipe Pembelian', 'DIKIRIM'),
                if (tx.pengirimCrew != null)
                  _buildInfoRow('Petugas Pengirim', tx.pengirimCrew!.nama),
                if (tx.totalOngkir > 0)
                  _buildInfoRow(
                      'Total Ongkir', Formatters.currency(tx.totalOngkir)),
              ] else ...[
                _buildInfoRow('Tipe Pembelian', 'DI DEPO'),
              ],
              if (tx.catatan != null && tx.catatan!.isNotEmpty)
                _buildInfoRow('Catatan', tx.catatan!),

              // Show QR code if payment is QRIS and qrPaymentId exists
              if (tx.metodePembayaran == MetodePembayaran.qris &&
                  tx.qrPaymentId != null) ...[
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
                const Text(
                  'Kode QR Pembayaran',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: QrCodeWidget(
                    data: tx.qrPaymentId!,
                    size: 180,
                    showBorder: true,
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // ── Rincian Produk ────────────────────────────────────────
              const Text(
                'Rincian Pembelian',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              ...tx.items
                  .where((item) => item.subtotal > 0)
                  .map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.water_drop_rounded,
                                  color: _primary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.produk?.nama ?? 'Produk',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    '${item.jumlah} x ${Formatters.currency(item.hargaSatuan)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              Formatters.currency(item.subtotal),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      )),

              // ── Status Galon ──────────────────────────────────────────
              if (tx.items
                  .any((i) => i.galonPinjam > 0 || i.galonKembali > 0)) ...[
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                const Text(
                  'Status Galon',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                ...tx.items
                    .where((i) => i.galonPinjam > 0 || i.galonKembali > 0)
                    .map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.swap_horiz_rounded,
                                  size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.produk?.nama ?? 'Produk',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  if (item.galonPinjam > 0)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Pinjam ${item.galonPinjam}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                  if (item.galonKembali > 0)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD1FAE5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Kembali ${item.galonKembali}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF065F46),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        )),
              ],

              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // ── Total Pembayaran ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL BAYAR',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    Formatters.currency(tx.totalHarga),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _primary,
                    ),
                  ),
                ],
              ),

              if (tx.bayar != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bayar',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    Text(
                      Formatters.currency(tx.bayar!),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155)),
                    ),
                  ],
                ),
                if (tx.kembalian != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kembalian',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      Text(
                        Formatters.currency(tx.kembalian!),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ],
              ],

              // ── Info Validasi ─────────────────────────────────────────
              if (tx.statusValidasi == StatusValidasi.valid) ...[
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          color: Color(0xFF065F46), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Divalidasi oleh ${tx.validasiOleh ?? "Manager"}'
                          '${tx.validasiAt != null ? " pada ${Formatters.dateTime(tx.validasiAt!)}" : ""}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              // ── Tombol Validasi (jika menunggu validasi) ─────────────────
              if (tx.status == StatusTransaksi.menungguValidasi) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.back();
                          _validasiTransaksi(tx.id, 'gagal');
                        },
                        icon: const Icon(Icons.cancel_outlined,
                            size: 18, color: Color(0xFFEF4444)),
                        label: const Text(
                          'Tolak',
                          style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFFEE2E2)),
                          backgroundColor: const Color(0xFFFEF2F2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          _validasiTransaksi(tx.id, 'sukses');
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            size: 18, color: Colors.white),
                        label: const Text(
                          'Setujui',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              // ── Tombol Tutup ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF475569),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final laporan = Get.find<LaporanController>();

    return Scaffold(
      backgroundColor: _bgLight,
      body: Column(
        children: [
          _buildHeader(context),
          Transform.translate(
            offset: const Offset(0, -32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildPeriodCard(),
                  const SizedBox(height: 12),
                  Obx(() => Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 20,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSummaryItem(
                                label: 'Total Transaksi',
                                value: '${laporan.totalTransaksi.value}',
                                icon: Icons.receipt_long_rounded,
                                color: _primary,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: const Color(0xFFE2E8F0),
                            ),
                            Expanded(
                              child: _buildSummaryItem(
                                label: 'Total Pendapatan',
                                value: Formatters.currency(
                                    laporan.totalPendapatan.value),
                                icon: Icons.payments_rounded,
                                color: const Color(0xFF10B981),
                                isHighlight: true,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (laporan.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: _primary),
                );
              }
              if (laporan.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      laporan.errorMessage.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }
              if (laporan.transaksiList.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 56, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada transaksi',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: _primary,
                onRefresh: () async => _muatLaporan(),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: laporan.transaksiList.length,
                  itemBuilder: (_, i) {
                    final t = laporan.transaksiList[i];
                    return GestureDetector(
                      onTap: () => _showDetailBottomSheet(context, t),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.receipt_rounded,
                                color: _primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.pelanggan?.nama ?? '-',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.nomorTransaksiTampilan(
                                        t.nomorTransaksi),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    Formatters.dateTime(t.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.currency(t.totalHarga),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusBgColor(t.status),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    _statusLabel(t.status).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _statusColor(t.status),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.metodePembayaran.name.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _pilihTanggal,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  color: _primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${Formatters.date(_mulai)} – ${Formatters.date(_akhir)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final laporan = Get.find<LaporanController>();

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 48,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1392EC), Color(0xFF0B5FA0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x331392EC),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const HeaderBackButton(
            fallbackRoute: AppRoutes.managerDashboard,
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'Laporan Transaksi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tap transaksi untuk detail lengkap',
                  style: TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => laporan.exportLaporan(
              Formatters.dateOnly(_mulai),
              Formatters.dateOnly(_akhir),
              'excel',
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.download_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isHighlight ? color : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, FontWeight? valueFontWeight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: valueFontWeight ?? FontWeight.w600,
                color: valueColor ?? const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
