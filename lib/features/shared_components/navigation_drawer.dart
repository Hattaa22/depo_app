import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/crew_main_controller.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';

/// Navigation Drawer untuk Crew
class CrewNavigationDrawer extends StatelessWidget {
  final String activeRoute;
  const CrewNavigationDrawer({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    final mainController = Get.find<CrewMainController>();

    return Drawer(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Obx(() {
              final currentTab = mainController.selectedIndex.value;
              final isAtMainShell = activeRoute == AppRoutes.crewDashboard;

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildCrewDrawerItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    targetRoute: AppRoutes.crewDashboard,
                    targetTab: 0,
                    isAtMainShell: isAtMainShell,
                    currentTab: currentTab,
                  ),
                  _buildCrewDrawerItem(
                    icon: Icons.point_of_sale_outlined,
                    title: 'Kasir',
                    targetRoute: AppRoutes.crewKasir,
                    targetTab: 2,
                    isAtMainShell: isAtMainShell,
                    currentTab: currentTab,
                  ),
                  _DrawerItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Transaksi',
                    route: AppRoutes.crewTransaksi,
                    isActive: activeRoute == AppRoutes.crewTransaksi,
                  ),
                  _DrawerItem(
                    icon: Icons.people_outline,
                    title: 'Data Pelanggan',
                    route: AppRoutes.crewDataPelanggan,
                    isActive: activeRoute == AppRoutes.crewDataPelanggan,
                  ),
                  _buildCrewDrawerItem(
                    icon: Icons.history,
                    title: 'Riwayat Transaksi',
                    targetRoute: AppRoutes.crewRiwayat,
                    targetTab: 1,
                    isAtMainShell: isAtMainShell,
                    currentTab: currentTab,
                  ),
                  _buildCrewDrawerItem(
                    icon: Icons.water_drop_outlined,
                    title: 'Pencatatan Galon',
                    targetRoute: AppRoutes.crewGalon,
                    targetTab: 3,
                    isAtMainShell: isAtMainShell,
                    currentTab: currentTab,
                  ),
                  const Divider(),
                  _buildCrewDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan',
                    targetRoute: AppRoutes.crewPengaturan,
                    targetTab: 4,
                    isAtMainShell: isAtMainShell,
                    currentTab: currentTab,
                  ),
                ],
              );
            }),
          ),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildCrewDrawerItem({
    required IconData icon,
    required String title,
    required String targetRoute,
    required int targetTab,
    required bool isAtMainShell,
    required int currentTab,
  }) {
    final bool isActive = isAtMainShell && currentTab == targetTab;
    return ListTile(
      leading: Icon(icon,
          color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppTheme.primaryColor : AppTheme.textPrimary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Get.back(); // close drawer
        final mainController = Get.find<CrewMainController>();
        if (isAtMainShell) {
          mainController.changeTab(targetTab);
        } else {
          Get.offAllNamed(targetRoute);
        }
      },
    );
  }

  Widget _buildHeader() {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final nama = auth.userData['nama'] ?? 'Crew';
      return UserAccountsDrawerHeader(
        decoration: const BoxDecoration(color: AppTheme.primaryColor),
        accountName:
            Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
        accountEmail: const Text('Crew Depot Air'),
        currentAccountPicture: CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            nama.isNotEmpty ? nama[0].toUpperCase() : 'C',
            style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 24),
          ),
        ),
      );
    });
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListTile(
        leading: const Icon(Icons.logout, color: AppTheme.errorColor),
        title:
            const Text('Keluar', style: TextStyle(color: AppTheme.errorColor)),
        onTap: () => Get.find<AuthController>().confirmLogout(),
      ),
    );
  }
}

/// Navigation Drawer untuk Manager
class ManagerNavigationDrawer extends StatelessWidget {
  final String activeRoute;
  const ManagerNavigationDrawer({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    route: AppRoutes.managerDashboard,
                    isActive: activeRoute == AppRoutes.managerDashboard),
                _DrawerItem(
                    icon: Icons.people_outline,
                    title: 'Data Pelanggan',
                    route: AppRoutes.managerDataPelanggan,
                    isActive: activeRoute == AppRoutes.managerDataPelanggan),
                _DrawerItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Laporan Transaksi',
                    route: AppRoutes.managerLaporan,
                    isActive: activeRoute == AppRoutes.managerLaporan),
                _DrawerItem(
                    icon: Icons.bar_chart_outlined,
                    title: 'Analisis Keuangan',
                    route: AppRoutes.managerAnalisis,
                    isActive: activeRoute == AppRoutes.managerAnalisis),
                _DrawerItem(
                    icon: Icons.water_drop_outlined,
                    title: 'Asset Galon',
                    route: AppRoutes.managerAssetGalon,
                    isActive: activeRoute == AppRoutes.managerAssetGalon),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('PENGATURAN',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold)),
                ),
                _DrawerItem(
                    icon: Icons.inventory_2_outlined,
                    title: 'Data Produk',
                    route: AppRoutes.managerDataProduk,
                    isActive: activeRoute == AppRoutes.managerDataProduk),
                _DrawerItem(
                    icon: Icons.category_outlined,
                    title: 'Data Kategori',
                    route: AppRoutes.managerDataKategori,
                    isActive: activeRoute == AppRoutes.managerDataKategori),
                _DrawerItem(
                    icon: Icons.verified_outlined,
                    title: 'Validasi Transaksi',
                    route: AppRoutes.managerValidasiTransaksi,
                    isActive:
                        activeRoute == AppRoutes.managerValidasiTransaksi),
                _DrawerItem(
                    icon: Icons.badge_outlined,
                    title: 'Data Crew',
                    route: AppRoutes.managerSettingCrew,
                    isActive: activeRoute == AppRoutes.managerSettingCrew),
              ],
            ),
          ),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final nama = auth.userData['nama'] ?? 'Manager';
      return UserAccountsDrawerHeader(
        decoration: const BoxDecoration(color: AppTheme.primaryColor),
        accountName:
            Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
        accountEmail: const Text('Manager Depot Air'),
        currentAccountPicture: CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            nama.isNotEmpty ? nama[0].toUpperCase() : 'M',
            style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 24),
          ),
        ),
      );
    });
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListTile(
        leading: const Icon(Icons.logout, color: AppTheme.errorColor),
        title:
            const Text('Keluar', style: TextStyle(color: AppTheme.errorColor)),
        onTap: () => Get.find<AuthController>().confirmLogout(),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isActive;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppTheme.primaryColor : AppTheme.textPrimary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Get.back();
        if (!isActive) Get.offAllNamed(route);
      },
    );
  }
}
