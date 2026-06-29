import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/analisis_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../config/routes.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/manager_nav_helper.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  int _selectedIndex = ManagerNavHelper.home;

  static const Color _primary = Color(0xFF1392EC);
  static const Color _bgLight = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ManagerNavHelper.refreshHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final analisis = Get.find<AnalisisController>();

    return Scaffold(
      backgroundColor: _bgLight,
      body: Obx(() {
        final nama = auth.userData['nama'] ?? 'Manager';
        final data = analisis.dashboardData.value;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header (biru penuh sampai status bar) ─────────────────────
              _buildHeader(context, nama),

              // ── Stats Cards (overlap header) ─────────────────────────────
              Transform.translate(
                offset: const Offset(0, -32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: analisis.isLoading.value
                      ? const _StatsLoading()
                      : _buildStatsRow(data),
                ),
              ),

              // ── Section Title ────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Menu Operasional',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Akses cepat ke operasi harian',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Menu Grid ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.05,
                  children:
                      _menuItems.map((item) => _buildMenuCard(item)).toList(),
                ),
              ),

              const SizedBox(height: 112),
            ],
          ),
        );
      }),
      bottomNavigationBar: ManagerNavHelper.bottomBar(
        activeIndex: _selectedIndex,
        fromDashboard: true,
        onDashboardIndexChange: (index) =>
            setState(() => _selectedIndex = index),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String nama) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topPad + 16, 24, 64),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1392EC), Color(0xFF0B5FA0)],
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat Datang,',
                style: TextStyle(
                  color: Color(0xFFBFDBFE),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                nama,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Manager Dashboard',
                style: TextStyle(
                  color: Color(0xFFBFDBFE),
                  fontSize: 12,
                ),
              ),
            ],
          ),

          // Logout button
          GestureDetector(
            onTap: () => Get.find<AuthController>().logout(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow(Map<String, dynamic>? data) {
    // Helper to safely parse num
    num safeParseNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      if (value is String) {
        final parsed = num.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'PENDAPATAN',
            value: Formatters.currency(
                safeParseNum(data?['totalPendapatanHarian'])),
            valueColor: _primary,
            badge: Row(
              children: const [
                Icon(Icons.trending_up, size: 12, color: Color(0xFF10B981)),
                SizedBox(width: 2),
                Text('Hari ini',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'TRANSAKSI',
            value: '${safeParseNum(data?['totalTransaksiHari'])}',
            badge: Row(
              children: const [
                Icon(Icons.receipt_long, size: 12, color: Color(0xFFF59E0B)),
                SizedBox(width: 2),
                Text('Hari ini',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'GALON',
            value: '${safeParseNum(data?['galonBersih'] ?? data?['tersedia'])}',
            valueSuffix: ' pcs',
            badge: Row(
              children: const [
                Icon(Icons.water_drop, size: 12, color: Color(0xFF10B981)),
                SizedBox(width: 2),
                Text('Tersedia',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? valueSuffix,
    Color? valueColor,
    required Widget badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.6,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFF1E293B),
              ),
              children: valueSuffix != null
                  ? [
                      TextSpan(
                        text: valueSuffix,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          badge,
        ],
      ),
    );
  }

  // ── Menu Card ────────────────────────────────────────────────────────────────
  Widget _buildMenuCard(_ManagerMenuItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (item.route == AppRoutes.managerLaporan) {
              ManagerNavHelper.afterPushFromDashboard(
                Get.toNamed(item.route),
              );
              ManagerNavHelper.refreshLaporanData();
            } else {
              ManagerNavHelper.afterPushFromDashboard(
                Get.toNamed(item.route),
              );
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: _primary, size: 30),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final List<_ManagerMenuItem> _menuItems = [
    _ManagerMenuItem(
        icon: Icons.receipt_long_rounded,
        title: 'Laporan',
        subtitle: 'Transaksi',
        route: AppRoutes.managerLaporan),
    _ManagerMenuItem(
        icon: Icons.insights_rounded,
        title: 'Analisis',
        subtitle: 'Keuangan',
        route: AppRoutes.managerAnalisis),
    _ManagerMenuItem(
        icon: Icons.inventory_2_rounded,
        title: 'Stok Galon',
        subtitle: 'Inventaris',
        route: AppRoutes.managerAssetGalon),
    _ManagerMenuItem(
        icon: Icons.payments_rounded,
        title: 'Catat Pengeluaran',
        subtitle: 'Operasional',
        route: AppRoutes.managerDataPengeluaran),
    _ManagerMenuItem(
        icon: Icons.people_rounded,
        title: 'Pelanggan',
        subtitle: 'Data Pelanggan',
        route: AppRoutes.managerDataPelanggan),
    _ManagerMenuItem(
        icon: Icons.fact_check_rounded,
        title: 'Validasi',
        subtitle: 'Transaksi',
        route: AppRoutes.managerValidasiTransaksi),
  ];
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF1392EC),
          ),
        ),
      ),
    );
  }
}

class _ManagerMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  const _ManagerMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}
