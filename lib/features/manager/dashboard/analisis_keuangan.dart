import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/analisis_controller.dart';
import '../../../config/routes.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/header_back_button.dart';
import '../../../widgets/manager_nav_helper.dart';
import 'dart:math' as math;

class AnalisisKeuanganScreen extends StatefulWidget {
  const AnalisisKeuanganScreen({super.key});

  @override
  State<AnalisisKeuanganScreen> createState() => _AnalisisKeuanganScreenState();
}

class _AnalisisKeuanganScreenState extends State<AnalisisKeuanganScreen> {
  static const Color _primary = Color(0xFF1392EC);
  static const Color _bgLight = Color(0xFFF8FAFC);
  final periode = 'semua'.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<AnalisisController>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final analisis = Get.find<AnalisisController>();

    return Scaffold(
      backgroundColor: _bgLight,
      body: Column(
        children: [
          // ── HEADER ────────────────────────────────────────────────────────
          _buildHeader(context, analisis, periode),

          // ── CONTENT ───────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (analisis.isLoading.value) {
                return const Center(
                    child: CircularProgressIndicator(color: _primary));
              }
              final data = analisis.dashboardData.value;
              if (data == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bar_chart_rounded,
                          size: 56, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      const Text('Tidak ada data analisis',
                          style: TextStyle(
                              fontSize: 14, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: analisis.loadDashboard,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Muat Ulang'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                );
              }

              final activePeriod = periode.value;
              final periodData = data[activePeriod] ?? {
                'totalPendapatan': 0,
                'totalTransaksi': 0,
                'totalPengeluaran': 0,
                'pendapatanBersih': 0,
              };

              final totalPendapatan =
                  (periodData['totalPendapatan'] as num? ?? 0).toDouble();
              final totalPengeluaran =
                  (periodData['totalPengeluaran'] as num? ?? 0).toDouble();
              final pendapatanBersih =
                  (periodData['pendapatanBersih'] as num? ?? 0).toDouble();
              final totalTransaksi =
                  (periodData['totalTransaksi'] as num? ?? 0);
              final galonBersih =
                  (data['galonBersih'] ?? data['tersedia'] ?? 0) as num;
              final totalPelanggan = (data['totalPelanggan'] ?? 0) as num;
              final breakdownList = data['breakdown']?[activePeriod] as List<dynamic>?;

              final expenseRatio = totalPendapatan > 0 ? (totalPengeluaran / totalPendapatan).clamp(0.0, 1.0) : 0.0;
              final netRatio = totalPendapatan > 0 ? (pendapatanBersih / totalPendapatan).clamp(0.0, 1.0) : 0.0;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Donut-style Metric Cards ─────────────────────────────
                    const Text(
                      'Ringkasan Keuangan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Donut Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildDonutCard(
                            label: 'Pendapatan',
                            value: Formatters.currency(totalPendapatan),
                            percent: 1.0,
                            color: _primary,
                            icon: Icons.payments_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDonutCard(
                            label: 'Pengeluaran',
                            value: Formatters.currency(totalPengeluaran),
                            percent: expenseRatio,
                            color: const Color(0xFFEF4444),
                            icon: Icons.outbox_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDonutCard(
                            label: 'Pendapatan Bersih',
                            value: Formatters.currency(pendapatanBersih),
                            percent: netRatio,
                            color: const Color(0xFF10B981),
                            icon: Icons.account_balance_wallet_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDonutCard(
                            label: 'Transaksi',
                            value: '$totalTransaksi',
                            percent: 0.58,
                            color: const Color(0xFF8B5CF6),
                            icon: Icons.receipt_long_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Detail List ───────────────────────────────────────────
                    const Text(
                      'Detail Operasional',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildDetailCard([
                      _DetailItem(
                        icon: Icons.inventory_2_rounded,
                        label: 'Galon Bersih Tersedia',
                        value: '$galonBersih pcs',
                        color: _primary,
                      ),
                      _DetailItem(
                        icon: Icons.receipt_long_rounded,
                        label: activePeriod == 'harian'
                            ? 'Total Transaksi Hari Ini'
                            : activePeriod == 'bulanan'
                                ? 'Total Transaksi Bulan Ini'
                                : 'Total Transaksi Keseluruhan',
                        value: '$totalTransaksi',
                        color: const Color(0xFF8B5CF6),
                      ),
                      _DetailItem(
                        icon: Icons.attach_money_rounded,
                        label: activePeriod == 'harian'
                            ? 'Pendapatan Bersih Hari Ini'
                            : activePeriod == 'bulanan'
                                ? 'Pendapatan Bersih Bulan Ini'
                                : 'Pendapatan Bersih Keseluruhan',
                        value: Formatters.currency(pendapatanBersih),
                        color: const Color(0xFF10B981),
                      ),
                      _DetailItem(
                        icon: Icons.people_rounded,
                        label: 'Total Pelanggan Terdaftar',
                        value: '$totalPelanggan orang',
                        color: const Color(0xFFF59E0B),
                      ),
                    ]),
                    const SizedBox(height: 28),
                    const Text(
                      'Analisis Per Kategori',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryBreakdown(breakdownList),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: ManagerNavHelper.bottomBar(
        activeIndex: ManagerNavHelper.reports,
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, AnalisisController analisis, RxString periode) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1392EC), Color(0xFF0B5FA0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x331392EC),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const HeaderBackButton(
                fallbackRoute: AppRoutes.managerDashboard,
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analisis Keuangan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Ringkasan performa finansial',
                      style: TextStyle(
                          color: Color(0xFFBFDBFE), fontSize: 12),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: analisis.loadDashboard,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Period selector
          Obx(() => Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: ['harian', 'bulanan', 'semua'].map((p) {
                    final isActive = periode.value == p;
                    final labels = {
                      'harian': 'Harian',
                      'bulanan': 'Bulanan',
                      'semua': 'Semua'
                    };
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          periode.value = p;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            labels[p]!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? _primary
                                  : Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )),
        ],
      ),
    );
  }

  // ── DONUT CARD ───────────────────────────────────────────────────────────────
  Widget _buildDonutCard({
    required String label,
    required String value,
    required double percent,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              SizedBox(
                width: 44,
                height: 44,
                child: CustomPaint(
                  painter: _DonutPainter(percent: percent, color: color),
                  child: Center(
                    child: Text(
                      '${(percent * 100).round()}%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ── DETAIL CARD ──────────────────────────────────────────────────────────────
  Widget _buildDetailCard(List<_DetailItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(item.icon, color: item.color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<dynamic>? breakdown) {
    if (breakdown == null || breakdown.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: const Center(
          child: Text(
            'Tidak ada data kategori',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ),
      );
    }

    final Map<String, IconData> iconMap = {
      'water_drop': Icons.water_drop_rounded,
      'inventory_2': Icons.inventory_2_rounded,
      'widgets': Icons.widgets_rounded,
      'people': Icons.people_rounded,
      'bolt': Icons.bolt_rounded,
      'store': Icons.store_rounded,
      'build': Icons.build_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'category': Icons.category_rounded,
      'receipt': Icons.receipt_rounded,
      'local_shipping': Icons.local_shipping_rounded,
      'attach_money': Icons.attach_money_rounded,
      'account_balance': Icons.account_balance_rounded,
      'payments': Icons.payments_rounded,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: breakdown.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value as Map<String, dynamic>;
          final String nama = item['nama'] ?? '';
          final String tipe = item['tipe'] ?? 'pemasukan';
          final String? ikon = item['ikon'];
          final double total = (item['total'] ?? 0).toDouble();

          final isPemasukan = tipe == 'pemasukan';
          final color = isPemasukan ? const Color(0xFF10B981) : const Color(0xFFEF4444);
          final iconData = iconMap[ikon] ?? Icons.label_rounded;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(iconData, color: color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPemasukan ? 'Pemasukan' : 'Pengeluaran',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isPemasukan ? const Color(0xFF059669) : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isPemasukan ? "+" : "-"}${Formatters.currency(total)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: total == 0 
                            ? const Color(0xFF94A3B8)
                            : (isPemasukan ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
              ),
              if (idx < breakdown.length - 1)
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Donut painter ─────────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final double percent;
  final Color color;
  const _DonutPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 4.0;

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = color.withOpacity(0.1)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Foreground arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.percent != percent || old.color != color;
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DetailItem(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
}
