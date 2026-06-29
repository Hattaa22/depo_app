import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../widgets/header_back_button.dart';
import '../../../widgets/manager_nav_helper.dart';

/// Hub pengaturan Manager (tab Settings) — pola CoreManagerPage depoair.
class ManagerSettingsScreen extends StatefulWidget {
  const ManagerSettingsScreen({super.key});

  @override
  State<ManagerSettingsScreen> createState() => _ManagerSettingsScreenState();
}

class _ManagerSettingsScreenState extends State<ManagerSettingsScreen> {
  static const Color _primary = Color(0xFF1392EC);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: Column(
        children: [
          _buildHeader(topPad),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 24, 8, 16),
                    child: Text(
                      'Manajemen Inti',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D161B),
                      ),
                    ),
                  ),
                  _buildCoreGrid(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 28, 8, 16),
                    child: Text(
                      'Kelola Akun',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D161B),
                      ),
                    ),
                  ),
                  _buildAccountList(),
                  const SizedBox(height: 32),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ManagerNavHelper.bottomBar(
        activeIndex: ManagerNavHelper.settings,
      ),
    );
  }

  Widget _buildHeader(double topPad) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPad + 20,
        left: 24,
        right: 24,
        bottom: 32,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1392EC), Color(0xFF0B76C4)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HeaderBackButton(
                fallbackRoute: AppRoutes.managerDashboard,
              ),
              const Expanded(
                child: Text(
                  'Manajemen Depo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 22),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Konfigurasi operasional depot air minum Anda',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreGrid() {
    const items = [
      _CoreItem(
        icon: Icons.sell_rounded,
        label: 'Harga Produk',
        route: AppRoutes.managerDataProduk,
      ),
      _CoreItem(
        icon: Icons.pie_chart_rounded,
        label: 'Kategori Keuangan',
        route: AppRoutes.managerDataKategori,
      ),
      _CoreItem(
        icon: Icons.verified_rounded,
        label: 'Validasi Transaksi',
        route: AppRoutes.managerValidasiTransaksi,
      ),
      _CoreItem(
        icon: Icons.group_rounded,
        label: 'Manajemen Crew',
        route: AppRoutes.managerSettingCrew,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: items.map(_buildCoreCard).toList(),
    );
  }

  Widget _buildCoreCard(_CoreItem item) {
    return GestureDetector(
      onTap: () => Get.toNamed(item.route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: _primary, size: 22),
            ),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D161B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountList() {
    return Column(
      children: [
        _buildListTile(
          icon: Icons.lock_reset_rounded,
          title: 'Ubah Password',
          onTap: _showUbahPasswordDialog,
        ),
        _buildListTile(
          icon: Icons.store_rounded,
          title: 'Cabang Depo',
          subtitle: 'Kelola jaringan cabang',
          onTap: () => Get.toNamed(AppRoutes.managerCabangDepo),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    String? route,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: _primary),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D161B),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              )
            : null,
        trailing:
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        onTap: onTap ?? (route != null ? () => Get.toNamed(route) : null),
      ),
    );
  }

  // ── UBAH PASSWORD DIALOG ──────────────────────────────────────────────
  void _showUbahPasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final auth = Get.find<AuthController>();
    final obscure = true.obs;

    Get.defaultDialog(
      title: 'Ubah Password',
      titleStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => TextField(
                  controller: oldCtrl,
                  obscureText: obscure.value,
                  decoration: InputDecoration(
                    labelText: 'Password Lama',
                    suffixIcon: IconButton(
                      icon: Icon(obscure.value
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => obscure.value = !obscure.value,
                    ),
                  ),
                )),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Baru'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Konfirmasi Password Baru'),
            ),
          ],
        ),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
      ),
      confirm: Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: auth.isLoading.value
                ? null
                : () async {
                    if (oldCtrl.text.isEmpty ||
                        newCtrl.text.isEmpty ||
                        confirmCtrl.text.isEmpty) {
                      Get.snackbar('Error', 'Semua field wajib diisi');
                      return;
                    }
                    if (newCtrl.text != confirmCtrl.text) {
                      Get.snackbar('Error', 'Konfirmasi password tidak sesuai');
                      return;
                    }
                    if (newCtrl.text.length < 6) {
                      Get.snackbar('Error', 'Password baru minimal 6 karakter');
                      return;
                    }
                    final ok =
                        await auth.changePassword(oldCtrl.text, newCtrl.text);
                    if (ok) Get.back();
                  },
            child: auth.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Simpan',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
          )),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Get.find<AuthController>().logout(),
        icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
        label: const Text(
          'Keluar dari Akun',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFFECACA)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _CoreItem {
  final IconData icon;
  final String label;
  final String route;
  const _CoreItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
