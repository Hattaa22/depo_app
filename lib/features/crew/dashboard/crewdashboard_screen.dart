import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/transaksi_controller.dart';
import '../../../controllers/galon_controller.dart';
import '../../../controllers/analisis_controller.dart';
import '../../../controllers/crew_main_controller.dart';
import '../../../config/routes.dart';
import '../../../models/transaksi.dart';
import '../../../utils/formatters.dart';

class CrewDashboardScreen extends StatelessWidget {
  const CrewDashboardScreen({super.key});

  static const Color _primary = Color(0xFF1392EC);
  static const Color _bgLight = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final transaksi = Get.find<TransaksiController>();
    final galon = Get.find<GalonController>();
    final analisis = Get.find<AnalisisController>();
    final mainController = Get.find<CrewMainController>();

    // Load data saat screen dibuka — filter transaksi hanya milik crew ini
    final crewId = auth.userData['id']?.toString();
    transaksi.loadTransaksi(crewId: crewId);
    analisis.loadDashboardCrew();
    galon.loadSummary();

    return Scaffold(
      backgroundColor: _bgLight,
      extendBody: true,
      body: Obx(() {
        final nama = auth.userData['nama'] ?? 'Crew';
        final dashData = analisis.dashboardCrewData.value;
        final totalPenjualan = (dashData?['totalPenjualanHarian'] as num?)?.toDouble() ?? 0.0;
        final totalGalonTerjual = (dashData?['totalGalonTerjual'] as num?)?.toInt() ?? 0;
        final recentTransaksi = transaksi.transaksiList.take(5).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──────────────────────────────────────────────
              _buildHeader(context, nama),

              // ── STAT CARDS ──────────────────────────────────────────
              Transform.translate(
                offset: const Offset(0, -32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          label: 'TOTAL PENJUALAN',
                          value: analisis.isLoadingCrew.value
                              ? '...'
                              : Formatters.currency(totalPenjualan),
                          badge: _StatBadge(
                            icon: Icons.trending_up,
                            label: '+Hari ini',
                            color: const Color(0xFF10B981),
                            bgColor: const Color(0xFFECFDF5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          label: 'GALON TERJUAL',
                          value: analisis.isLoadingCrew.value
                              ? '...'
                              : '$totalGalonTerjual Unit',
                          badge: _StatBadge(
                            icon: Icons.water_drop,
                            label: 'Hari ini',
                            color: _primary,
                            bgColor: const Color(0xFFEFF6FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── AKSI CEPAT ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Aksi Cepat'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.add_shopping_cart,
                            label: 'Order Baru',
                            isPrimary: true,
                            onTap: () => mainController.changeTab(2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.inventory_2_outlined,
                            label: 'Asset Galon',
                            isPrimary: false,
                            onTap: () => mainController.changeTab(3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.people_outline,
                            label: 'Pelanggan',
                            isPrimary: false,
                            onTap: () => Get.toNamed(AppRoutes.crewDataPelanggan),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.receipt_long_outlined,
                            label: 'Transaksi',
                            isPrimary: false,
                            onTap: () => Get.toNamed(AppRoutes.crewTransaksi),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),


              // ── RINGKASAN GALON ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Stok Galon'),
                    const SizedBox(height: 12),
                    Obx(() {
                      final summary = galon.summary.value;
                      return _buildGalonSummaryCard(
                        tersedia: summary?.tersedia ?? 0,
                        dipinjam: summary?.dipinjam ?? 0,
                        rusak: summary?.rusak ?? 0,
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── TRANSAKSI TERBARU ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle('Transaksi Terbaru'),
                        TextButton(
                          onPressed: () => mainController.changeTab(1),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Lihat Semua',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (transaksi.isLoading.value)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: _primary),
                        ),
                      )
                    else if (recentTransaksi.isEmpty)
                      _buildEmptyTransaksi()
                    else
                      ...recentTransaksi.map(
                        (tx) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildTransactionCard(tx),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String nama) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1392EC), Color(0xFF0369A1)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x331392EC),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 56,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HALO,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    nama,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              // Tombol navigasi drawer / pengaturan
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.crewPengaturan),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    nama.isNotEmpty ? nama[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Dashboard Crew',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STAT CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStatCard({
    required String label,
    required String value,
    required _StatBadge badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badge.bgColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badge.icon, color: badge.color, size: 12),
                const SizedBox(width: 3),
                Text(
                  badge.label,
                  style: TextStyle(
                    color: badge.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTION BUTTON
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isPrimary ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: isPrimary
              ? const [
                  BoxShadow(
                    color: Color(0x331392EC),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isPrimary ? Colors.white : _primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : const Color(0xFF1E293B),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TRANSACTION CARD — data real dari model Transaksi
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTransactionCard(Transaksi tx) {
    final statusLabel = _statusLabel(tx.status);
    final statusColor = _statusColor(tx.status);
    final statusBg = _statusBgColor(tx.status);
    final pelangganNama = tx.pelanggan?.nama ?? 'Pelanggan';
    final jumlahItem = tx.items.fold<int>(0, (s, i) => s + i.jumlah);
    final detail = '$jumlahItem item • ${Formatters.time(tx.createdAt)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar inisial pelanggan
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                pelangganNama.isNotEmpty ? pelangganNama[0].toUpperCase() : 'P',
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Detail
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        pelangganNama,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      detail,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      Formatters.currency(tx.totalHarga),
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GALON SUMMARY CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildGalonSummaryCard({
    required int tersedia,
    required int dipinjam,
    required int rusak,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _GalonStat(
            label: 'Tersedia',
            value: '$tersedia',
            color: const Color(0xFF10B981),
            icon: Icons.check_circle_outline,
          ),
          _buildDivider(),
          _GalonStat(
            label: 'Dipinjam',
            value: '$dipinjam',
            color: _primary,
            icon: Icons.swap_horiz,
          ),
          _buildDivider(),
          _GalonStat(
            label: 'Rusak',
            value: '$rusak',
            color: const Color(0xFFEF4444),
            icon: Icons.warning_amber_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(
        width: 1,
        height: 40,
        color: const Color(0xFFF1F5F9),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyTransaksi() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'Belum ada transaksi hari ini',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
      ),
    );
  }

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
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _StatBadge {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });
}

class _GalonStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _GalonStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
