import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/produk_controller.dart';
import '../../../models/produk.dart';
import '../../../config/routes.dart';
import '../../../widgets/header_back_button.dart';

class DataKategoriScreen extends StatefulWidget {
  const DataKategoriScreen({super.key});

  @override
  State<DataKategoriScreen> createState() => _DataKategoriScreenState();
}

class _DataKategoriScreenState extends State<DataKategoriScreen> {
  static const Color _primary = Color(0xFF1392EC);
  static const Color _primaryDark = Color(0xFF0B5FA0);

  int _selectedTab = 0; // 0 = Pemasukan, 1 = Pengeluaran

  static const Map<String, IconData> _iconMap = {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ProdukController>().loadKategori();
    });
  }

  @override
  Widget build(BuildContext context) {
    final produk = Get.find<ProdukController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          _buildHeader(context),
          _buildTabRow(),
          Expanded(
            child: Obx(() {
              if (produk.isLoading.value) {
                return const Center(
                    child: CircularProgressIndicator(color: _primary));
              }
              if (produk.errorMessage.value.isNotEmpty) {
                return Center(
                    child: Text(produk.errorMessage.value,
                        style: const TextStyle(color: Color(0xFF64748B))));
              }

              final pList = produk.pemasukanList;
              final eList = produk.pengeluaranList;
              final activeList = _selectedTab == 0 ? pList : eList;
              final isPemasukan = _selectedTab == 0;

              if (activeList.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pie_chart_outline_rounded,
                          size: 56, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 12),
                      Text('Belum ada kategori',
                          style: TextStyle(
                              fontSize: 14, color: Color(0xFF94A3B8))),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  _buildSectionHeader(
                      isPemasukan ? 'Daftar Pemasukan' : 'Daftar Pengeluaran',
                      activeList.length,
                      isPemasukan ? _primary : const Color(0xFFEF4444)),
                  const SizedBox(height: 12),
                  ...activeList.asMap().entries.map(
                      (e) => _buildItem(e.value, isPemasukan, e.key, produk)),
                ],
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _showTambahDialog(Get.find<ProdukController>()),
            icon: const Icon(Icons.add_circle_rounded,
                color: Colors.white, size: 20),
            label: const Text(
              'Tambah Kategori Baru',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _primaryDark],
        ),
      ),
      child: Row(
        children: [
          const HeaderBackButton(fallbackRoute: AppRoutes.managerSettings),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kategori Keuangan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Kelola kategori pengeluaran & pemasukan',
                  style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Row ─────────────────────────────────────────────────────────────────

  Widget _buildTabRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            _buildTabItem(0, 'Pemasukan'),
            _buildTabItem(1, 'Pengeluaran'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? _primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ── Section Header ───────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, int count, Color accentColor) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count KATEGORI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── List Item ────────────────────────────────────────────────────────────────

  Widget _buildItem(
      KategoriProduk k, bool isPemasukan, int index, ProdukController produk) {
    const pColors = [
      Color(0xFF1392EC),
      Color(0xFF0B5FA0),
      Color(0xFF2563EB),
      Color(0xFF0284C7),
      Color(0xFF3B82F6),
    ];
    const eColors = [
      Color(0xFF64748B),
      Color(0xFF475569),
      Color(0xFF334155),
      Color(0xFF94A3B8),
    ];
    final color = isPemasukan
        ? pColors[index % pColors.length]
        : eColors[index % eColors.length];
    final iconData = _iconMap[k.ikon] ?? Icons.label_rounded;
    final isLocked = k.isSystem;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLocked ? color.withValues(alpha: 0.12) : color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(iconData,
                  color: isLocked ? color : Colors.white, size: 24),
            ),
            const SizedBox(width: 14),

            // Name & subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    k.nama,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isLocked
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  if ((k.deskripsi ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      k.deskripsi!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isLocked
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Action buttons
            if (isLocked)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: Color(0xFFCBD5E1), size: 18),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionBtn(
                    icon: Icons.edit_outlined,
                    bg: const Color(0xFFEFF6FF),
                    fg: const Color(0xFF3B82F6),
                    onTap: () => _showEditDialog(k, produk),
                  ),
                  const SizedBox(width: 8),
                  _actionBtn(
                    icon: Icons.delete_outline_rounded,
                    bg: const Color(0xFFFEF2F2),
                    fg: const Color(0xFFEF4444),
                    onTap: () =>
                        _confirmHapus(k.nama, () => produk.hapusKategori(k.id)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: fg, size: 18),
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  void _showTambahDialog(ProdukController produk) {
    final namaCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    String selectedTipe = _selectedTab == 0 ? 'pemasukan' : 'pengeluaran';

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tambah Kategori',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 20),
                _inputField(namaCtrl, 'Nama Kategori', Icons.label_rounded),
                const SizedBox(height: 12),
                _inputField(deskripsiCtrl, 'Sub-tipe / Keterangan',
                    Icons.notes_rounded),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _chipSelect('Pemasukan', 'pemasukan', selectedTipe,
                        (v) => setS(() => selectedTipe = v)),
                    const SizedBox(width: 8),
                    _chipSelect('Pengeluaran', 'pengeluaran', selectedTipe,
                        (v) => setS(() => selectedTipe = v)),
                  ],
                ),
                const SizedBox(height: 24),
                _dialogActions(onSave: () {
                  if (namaCtrl.text.trim().isNotEmpty) {
                    produk.tambahKategori({
                      'nama': namaCtrl.text.trim(),
                      'deskripsi': deskripsiCtrl.text.trim(),
                      'tipe': selectedTipe,
                      'isSystem': false,
                    });
                  }
                  Get.back();
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(KategoriProduk k, ProdukController produk) {
    final namaCtrl = TextEditingController(text: k.nama);
    final deskripsiCtrl = TextEditingController(text: k.deskripsi ?? '');

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Kategori',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 20),
              _inputField(namaCtrl, 'Nama Kategori', Icons.label_rounded),
              const SizedBox(height: 12),
              _inputField(
                  deskripsiCtrl, 'Sub-tipe / Keterangan', Icons.notes_rounded),
              const SizedBox(height: 24),
              _dialogActions(onSave: () {
                if (namaCtrl.text.trim().isNotEmpty) {
                  produk.editKategori(k.id, {
                    'nama': namaCtrl.text.trim(),
                    'deskripsi': deskripsiCtrl.text.trim(),
                  });
                }
                Get.back();
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmHapus(String nama, VoidCallback onHapus) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Hapus Kategori?',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              Text(
                'Kategori "$nama" akan dihapus permanen.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: const Text('Batal',
                          style: TextStyle(color: Color(0xFF64748B))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onHapus();
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _inputField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
    );
  }

  Widget _chipSelect(String label, String value, String selected,
      void Function(String) onTap) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _dialogActions({required VoidCallback onSave}) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child:
                const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Simpan'),
          ),
        ),
      ],
    );
  }
}
