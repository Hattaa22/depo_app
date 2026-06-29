import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/galon_controller.dart';
import '../../../controllers/pelanggan_controller.dart';
import '../../../config/routes.dart';
import '../../../widgets/header_back_button.dart';
import '../../../widgets/manager_nav_helper.dart';
import '../../../widgets/galon_daftar_tab.dart';

class AssetGalonScreen extends StatefulWidget {
  const AssetGalonScreen({super.key});

  @override
  State<AssetGalonScreen> createState() => _AssetGalonScreenState();
}

class _AssetGalonScreenState extends State<AssetGalonScreen> {
  int _selectedSegment = 0; // 0 = Daftar Galon, 1 = Log Cepat
  bool _isOut = true;
  String _amount = '0';
  String? _selectedPelangganId; // ID Pelanggan
  DateTime? _selectedTanggal; // Tanggal peminjaman/pengembalian

  static const Color _primary = Color(0xFF1392EC);
  static const Color _bgLight = Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    final galon = Get.find<GalonController>();
    galon.loadGalon();
    galon.loadSummary();
    Get.find<PelangganController>().loadPelanggan();
  }

  void _refreshGalon() {
    final galon = Get.find<GalonController>();
    galon.loadSummary();
    galon.loadGalon();
  }

  Future<void> _onKonfirmasi(GalonController galon) async {
    final int amount = int.tryParse(_amount) ?? 0;
    if (amount <= 0) {
      Get.snackbar('Perhatian', 'Masukkan jumlah galon terlebih dahulu',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    // Pelanggan wajib dipilih untuk pinjam maupun kembali
    if (_selectedPelangganId == null) {
      Get.snackbar('Perhatian', 'Pilih pelanggan terlebih dahulu',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    final ok = _isOut
        ? await galon.pinjamGalon(
            amount,
            pelangganId: _selectedPelangganId,
            tanggal: _selectedTanggal,
          )
        : await galon.kembalikanGalon(
            amount,
            pelangganId: _selectedPelangganId,
            tanggal: _selectedTanggal,
          );
    if (ok && mounted) {
      setState(() {
        _amount = '0';
        _selectedPelangganId = null;
        _selectedTanggal = null;
      });
    }
  }

  void _onKeypadTap(String value) {
    setState(() {
      if (_amount == '0') {
        if (value != '0') _amount = value;
      } else {
        if (_amount.length < 5) _amount += value;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  void _onClear() => setState(() => _amount = '0');

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggal ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTanggal = picked);
    }
  }

  String _formatTanggal(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final galon = Get.find<GalonController>();

    return Scaffold(
      backgroundColor: _bgLight,
      body: Column(
        children: [
          // ── HEADER ────────────────────────────────────────────────────────
          _buildHeader(context),

          // ── METRICS CARD (overlapping header) ─────────────────────────────
          Transform.translate(
            offset: const Offset(0, -32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Obx(() {
                final summary = galon.summary.value;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33E2E8F0),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Color(0xFFF1F5F9)),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GALON TERSEDIA',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.warehouse_rounded,
                                      color: Color(0xFF10B981), size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${summary?.tersedia ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GALON DIPINJAM',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.group,
                                    color: _primary, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${summary?.dipinjam ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GALON RUSAK',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.broken_image_rounded,
                                    color: Color(0xFFEF4444), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${summary?.rusak ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
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
              }),
            ),
          ),

          GalonSegmentBar(
            selectedIndex: _selectedSegment,
            onChanged: (i) => setState(() => _selectedSegment = i),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _selectedSegment == 0
                ? const GalonDaftarTab(fabBottomPadding: 24)
                : _buildLogCepatTab(galon),
          ),
        ],
      ),
      bottomNavigationBar: ManagerNavHelper.bottomBar(
        activeIndex: ManagerNavHelper.inventory,
      ),
    );
  }

  Widget _buildLogCepatTab(GalonController galon) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildLogTypeButton(
                  isActive: _isOut,
                  title: 'Pinjam (Out)',
                  icon: Icons.logout_rounded,
                  activeColor: _primary,
                  bgColor: const Color(0xFFF0F9FF),
                  onTap: () => setState(() => _isOut = true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLogTypeButton(
                  isActive: !_isOut,
                  title: 'Kembali (In)',
                  icon: Icons.login_rounded,
                  activeColor: const Color(0xFF10B981),
                  bgColor: const Color(0xFFECFDF5),
                  onTap: () => setState(() => _isOut = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ..._buildPelangganSelector(),
          const SizedBox(height: 16),

          // Tanggal Picker
          GestureDetector(
            onTap: _pilihTanggal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: _selectedTanggal != null
                        ? _primary
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTanggal != null
                        ? _formatTanggal(_selectedTanggal!)
                        : 'Pilih Tanggal (opsional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedTanggal != null
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -16,
                    left: -16,
                    child: Text(
                      '#',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Text(
                    _amount,
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      height: 1,
                      letterSpacing: -2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'TOTAL GALON',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildKeypadBtn('1', onTap: () => _onKeypadTap('1')),
              _buildKeypadBtn('2', onTap: () => _onKeypadTap('2')),
              _buildKeypadBtn('3', onTap: () => _onKeypadTap('3')),
              _buildKeypadBtn('4', onTap: () => _onKeypadTap('4')),
              _buildKeypadBtn('5', onTap: () => _onKeypadTap('5')),
              _buildKeypadBtn('6', onTap: () => _onKeypadTap('6')),
              _buildKeypadBtn('7', onTap: () => _onKeypadTap('7')),
              _buildKeypadBtn('8', onTap: () => _onKeypadTap('8')),
              _buildKeypadBtn('9', onTap: () => _onKeypadTap('9')),
              _buildKeypadActionBtn(
                  icon: Icons.backspace_outlined, onTap: _onBackspace),
              _buildKeypadBtn('0', onTap: () => _onKeypadTap('0')),
              _buildKeypadActionBtn(label: 'CLEAR', onTap: _onClear),
            ],
          ),
          const SizedBox(height: 24),
          Obx(() => GestureDetector(
                onTap:
                    galon.isLoading.value ? null : () => _onKonfirmasi(galon),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: galon.isLoading.value
                        ? _primary.withValues(alpha: 0.5)
                        : _primary,
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (galon.isLoading.value)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else ...[
                        const Text(
                          'Konfirmasi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
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
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 48,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const HeaderBackButton(
            fallbackRoute: AppRoutes.managerDashboard,
          ),
          Column(
            children: [
              const Text(
                'Stok Galon',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'MANAJEMEN GALON',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _refreshGalon,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PELANGGAN SELECTOR ───────────────────────────────────────────────
  List<Widget> _buildPelangganSelector() {
    final pelangganCtrl = Get.find<PelangganController>();
    return [
      const Text(
        'PELANGGAN',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF475569),
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 8),
      Obx(() {
        final list =
            pelangganCtrl.pelangganList.where((p) => p.isAktif).toList();
        // Ensure selected ID exists in list, otherwise reset
        if (_selectedPelangganId != null &&
            !list.any((p) => p.id == _selectedPelangganId)) {
          _selectedPelangganId = null;
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _selectedPelangganId != null
                  ? _primary
                  : const Color(0xFFE2E8F0),
              width: _selectedPelangganId != null ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedPelangganId,
              hint: const Text(
                'Pilih pelanggan...',
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: _primary),
              borderRadius: BorderRadius.circular(16),
              items: list.map((p) {
                return DropdownMenuItem<String>(
                  value: p.id,
                  child: Text(
                    p.nama,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedPelangganId = v),
            ),
          ),
        );
      }),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildLogTypeButton({
    required bool isActive,
    required String title,
    required IconData icon,
    required Color activeColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? activeColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: activeColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              const BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive ? bgColor : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isActive ? activeColor : const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isActive
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadBtn(String number, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadActionBtn({
    IconData? icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, color: const Color(0xFF94A3B8))
            : Text(
                label ?? '',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }
}
