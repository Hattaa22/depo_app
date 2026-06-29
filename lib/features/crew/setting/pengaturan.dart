import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/crew_main_controller.dart';

class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({super.key});

  static const Color _primary = Color(0xFF1392EC);
  static const Color _bgLight = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final mainController = Get.find<CrewMainController>();

    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          Column(
            children: [
              // ── HEADER ───────────────────────────────────────────────────
              _buildHeader(context, mainController),

              // ── MAIN CONTENT (-mt-8 equivalent) ─────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.only(left: 24, right: 24, bottom: 120),
                  child: Transform.translate(
                    offset: const Offset(0, -32),
                    child: Obx(() {
                      final nama = auth.userData['nama'] ?? 'Crew';
                      final noHp = auth.userData['noHp'] ?? '-';

                      return Column(
                        children: [
                          // Profile Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border:
                                  Border.all(color: const Color(0xFFEEF2F6)),
                            ),
                            child: Row(
                              children: [
                                // Profile Icon / Initial
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: _primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      nama.isNotEmpty
                                          ? nama[0].toUpperCase()
                                          : 'C',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nama,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        noHp,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Crew Operasional',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Settings Group
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 0),
                                child: Text(
                                  'AKUN & KEAMANAN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                      color: const Color(0xFFEEF2F6)),
                                ),
                                child: Column(
                                  children: [
                                    // Change Name
                                    _buildSettingItem(
                                      icon: Icons.badge_rounded,
                                      title: 'Ubah Nama',
                                      onTap: () => _showGantiNamaDialog(),
                                    ),
                                    const Divider(
                                        height: 1, color: Color(0xFFF1F5F9)),
                                    // Change PIN
                                    _buildSettingItem(
                                      icon: Icons.lock_reset_rounded,
                                      title: 'Ubah PIN',
                                      onTap: () => _showGantiPinDialog(),
                                    ),
                                    const Divider(
                                        height: 1, color: Color(0xFFF1F5F9)),
                                    // About App
                                    _buildSettingItem(
                                      icon: Icons.info_outline_rounded,
                                      title: 'Tentang Aplikasi',
                                      onTap: () => _showTentangDialog(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 48),

                          // Logout Button
                          GestureDetector(
                            onTap: () => auth.logout(),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFFFEE2E2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.logout_rounded,
                                    color: Color(0xFFDC2626),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Keluar Akun',
                                    style: TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, CrewMainController mainController) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1392EC), Color(0xFF0D79C5)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x331392EC),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 64,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back arrow (switches back to Dashboard Tab)
          GestureDetector(
            onTap: () => mainController.changeTab(0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Text(
            'Pengaturan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 40), // Spacer for center alignment
        ],
      ),
    );
  }

  // ── SETTING ITEM WIDGET ────────────────────────────────────────────────────
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: _primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // ── DIALOGS ────────────────────────────────────────────────────────────────
  void _showGantiPinDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    Get.defaultDialog(
      title: 'Ubah PIN',
      titleStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: oldCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(labelText: 'PIN Lama'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: newCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(labelText: 'PIN Baru (6 digit)'),
          ),
        ],
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
      ),
      confirm: Obx(() {
        final isLoading = Get.find<AuthController>().isLoading.value;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: isLoading ? null : () async {
            final oldPin = oldCtrl.text;
            final newPin = newCtrl.text;
            if (oldPin.isEmpty || newPin.isEmpty) {
              Get.snackbar('Error', 'PIN tidak boleh kosong', backgroundColor: Colors.red, colorText: Colors.white);
              return;
            }
            if (newPin.length != 6) {
              Get.snackbar('Error', 'PIN harus 6 digit', backgroundColor: Colors.red, colorText: Colors.white);
              return;
            }
            final success = await Get.find<AuthController>().changePin(oldPin, newPin);
            if (success) {
              Get.back();
              Future.delayed(const Duration(milliseconds: 300), () {
                Get.snackbar('Berhasil', 'PIN berhasil diubah', backgroundColor: const Color(0xFF10B981), colorText: Colors.white);
              });
            }
          },
          child: isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        );
      }),
    );
  }

  void _showGantiNamaDialog() {
    final namaCtrl = TextEditingController(text: Get.find<AuthController>().userData['nama'] ?? '');
    Get.defaultDialog(
      title: 'Ubah Nama',
      titleStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: namaCtrl,
            decoration: const InputDecoration(labelText: 'Nama Lengkap'),
          ),
        ],
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
      ),
      confirm: Obx(() {
        final isLoading = Get.find<AuthController>().isLoading.value;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: isLoading ? null : () async {
            final namaBaru = namaCtrl.text.trim();
            if (namaBaru.isEmpty) {
              Get.snackbar('Error', 'Nama tidak boleh kosong', backgroundColor: Colors.red, colorText: Colors.white);
              return;
            }
            final success = await Get.find<AuthController>().changeProfile(namaBaru);
            if (success) {
              Get.back();
              Future.delayed(const Duration(milliseconds: 300), () {
                Get.snackbar('Berhasil', 'Profil berhasil diperbarui', backgroundColor: const Color(0xFF10B981), colorText: Colors.white);
              });
            }
          },
          child: isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        );
      }),
    );
  }

  void _showTentangDialog() {
    Get.defaultDialog(
      title: 'Tentang Aplikasi',
      titleStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.water_drop_rounded, color: _primary, size: 56),
          SizedBox(height: 12),
          Text(
            'Depo Air App v1.0.0',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0F172A)),
          ),
          SizedBox(height: 8),
          Text(
            'Aplikasi manajemen operasional depo air isi ulang terintegrasi. Mempermudah pencatatan stok galon, kasir transaksi POS, dan riwayat pesanan secara real-time.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => Get.back(),
        child: const Text('Tutup',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
