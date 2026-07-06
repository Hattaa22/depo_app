import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/constants.dart';
import '../controllers/galon_controller.dart';
import '../controllers/pelanggan_controller.dart';
import '../models/galon.dart';
import '../models/pelanggan.dart';
import '../utils/formatters.dart';

/// Tab daftar unit galon — dipakai crew & manager.
class GalonDaftarTab extends StatefulWidget {
  final double fabBottomPadding;

  const GalonDaftarTab({super.key, this.fabBottomPadding = 100});

  @override
  State<GalonDaftarTab> createState() => _GalonDaftarTabState();
}

class _GalonDaftarTabState extends State<GalonDaftarTab> {
  static const Color _primary = Color(0xFF1392EC);
  String _filterValue = 'semua';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      Get.find<GalonController>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final galon = Get.find<GalonController>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Semua', 'semua', galon),
                const SizedBox(width: 8),
                _buildFilterChip('Tersedia', 'tersedia', galon),
                const SizedBox(width: 8),
                _buildFilterChip('Dipinjam', 'dipinjam', galon),
                const SizedBox(width: 8),
                _buildFilterChip('Rusak', 'rusak', galon),
              ],
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (galon.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: _primary),
              );
            }
            if (galon.errorMessage.value.isNotEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    galon.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              );
            }

            final list = galon.galonList;
            if (list.isEmpty) {
              return _buildEmptyState();
            }

            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _buildGalonItemCard(list[i], galon),
                      ),
                    ),
                    if (galon.isFetchingMore.value)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: CircularProgressIndicator(color: _primary),
                      ),
                  ],
                ),
                Positioned(
                  right: 24,
                  bottom: widget.fabBottomPadding - 14,
                  child: FloatingActionButton.extended(
                    onPressed: () => _showCatatDialog(galon),
                    backgroundColor: _primary,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Catat Galon',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, GalonController galon) {
    final isSelected = _filterValue == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filterValue = value);
        galon.loadGalon(status: value == 'semua' ? null : value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border:
              isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildGalonItemCard(Galon g, GalonController galon) {
    final color = _galonColor(g.status);
    final statusLabel = Formatters.statusGalon(g.status.name);

    return GestureDetector(
      onTap: () => _showBorrowingDetails(g),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
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
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.water_drop, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Galon #${g.kodeGalon}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    g.jenis.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  if (g.status == StatusGalon.dipinjam) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 12, color: _primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            g.pelangganNama != null
                                ? 'Dipinjam: ${g.pelangganNama}'
                                : 'Status: Dipinjam',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (g.tanggalPinjam != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${_formatTanggal(g.tanggalPinjam!)} • ${_hitungDurasi(g.tanggalPinjam!)}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
              onSelected: (status) async {
                await galon.updateStatusGalon(g.id, status);
                galon.loadSummary();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'tersedia', child: Text('Tandai Tersedia')),
                PopupMenuItem(
                    value: 'dipinjam', child: Text('Tandai Dipinjam')),
                PopupMenuItem(value: 'rusak', child: Text('Tandai Rusak')),
                PopupMenuItem(value: 'hilang', child: Text('Tandai Hilang')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBorrowingDetails(Galon g) {
    final color = _galonColor(g.status);
    final borrowedAt = g.tanggalPinjam;
    final mutationAt = g.mutasiCreatedAt;
    final actor = g.mutasiCrewNama?.trim();

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.water_drop_rounded,
                          color: color, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Galon #${g.kodeGalon}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _detailPill(
                                Formatters.statusGalon(g.status.name),
                                color,
                              ),
                              _detailPill(g.jenis.name.toUpperCase(),
                                  const Color(0xFF64748B)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _detailSection(
                  title: 'Data Peminjam',
                  icon: Icons.person_outline_rounded,
                  children: [
                    _detailTile('Pelanggan', g.pelangganNama ?? '-'),
                    _detailTile('No. HP', g.pelangganNoHp ?? '-'),
                    _detailTile('Alamat', g.pelangganAlamat ?? '-'),
                  ],
                ),
                const SizedBox(height: 12),
                _detailSection(
                  title: 'Waktu Peminjaman',
                  icon: Icons.schedule_rounded,
                  accentColor: _primary,
                  children: [
                    _detailTile(
                      'Tanggal pinjam',
                      borrowedAt != null ? _formatTanggal(borrowedAt) : '-',
                    ),
                    _detailTile(
                      'Durasi berjalan',
                      borrowedAt != null ? _hitungDurasi(borrowedAt) : '-',
                    ),
                    _detailTile(
                      'Terakhir diperbarui',
                      g.updatedAt != null ? _formatTanggal(g.updatedAt!) : '-',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _detailSection(
                  title: 'Riwayat Petugas',
                  icon: Icons.verified_user_outlined,
                  accentColor: const Color(0xFF10B981),
                  children: [
                    _detailTile('Petugas terakhir',
                        actor != null && actor.isNotEmpty ? actor : '-'),
                    _detailTile(
                      'Peran',
                      actor != null && actor.toLowerCase().contains('manager')
                          ? 'Manager'
                          : actor != null && actor.isNotEmpty
                              ? 'Crew'
                              : '-',
                    ),
                    _detailTile('Jenis mutasi',
                        _formatMutasiLabel(g.mutasiJenis ?? '-')),
                    _detailTile(
                      'Perubahan status',
                      _formatStatusChange(g.mutasiStatusDari, g.mutasiStatusKe),
                    ),
                    _detailTile(
                      'Waktu mutasi',
                      mutationAt != null ? _formatTanggal(mutationAt) : '-',
                    ),
                  ],
                ),
                if (g.catatan != null && g.catatan!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _detailSection(
                    title: 'Catatan',
                    icon: Icons.notes_rounded,
                    accentColor: const Color(0xFFF59E0B),
                    children: [
                      _detailTile('Isi catatan', g.catatan!.trim()),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Get.back(),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _detailPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _detailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color accentColor = _primary,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMutasiLabel(String value) {
    if (value == '-' || value.isEmpty) return '-';
    return value
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _formatStatusChange(String? from, String? to) {
    if ((from == null || from.isEmpty) && (to == null || to.isEmpty)) {
      return '-';
    }
    if (from == null || from.isEmpty) {
      return _formatMutasiLabel(to ?? '-');
    }
    if (to == null || to.isEmpty) {
      return _formatMutasiLabel(from);
    }
    return '${_formatMutasiLabel(from)} ke ${_formatMutasiLabel(to)}';
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

  String _hitungDurasi(DateTime tanggalPinjam) {
    final now = DateTime.now();
    final difference = now.difference(tanggalPinjam);
    final days = difference.inDays;

    if (days == 0) {
      return 'Hari ini';
    } else if (days == 1) {
      return '1 hari';
    } else if (days < 7) {
      return '$days hari';
    } else if (days < 30) {
      final weeks = days ~/ 7;
      return '$weeks minggu';
    } else {
      final months = days ~/ 30;
      return '$months bulan';
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop_outlined, size: 64, color: Color(0xFF94A3B8)),
            SizedBox(height: 16),
            Text(
              'Tidak ada galon',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Data galon dengan status ini belum tercatat.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCatatDialog(GalonController galon) {
    final jumlahCtrl = TextEditingController(text: '1');
    final status = AppConstants.galonTersedia.obs;
    final jenis = 'isi'.obs;
    final pelangganCtrl = Get.find<PelangganController>();
    final selectedPelanggan = Rxn<Pelanggan>();

    Get.defaultDialog(
      title: 'Catat Galon Baru',
      titleStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kode galon akan di-generate otomatis oleh sistem',
                      style: TextStyle(fontSize: 12, color: Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: jumlahCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Galon',
                hintText: 'Masukkan jumlah galon yang ditambahkan',
                suffixText: 'galon',
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<String>(
                  initialValue: status.value,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(18),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: const [
                    DropdownMenuItem(
                      value: AppConstants.galonTersedia,
                      child: Text('Tersedia'),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.galonDipinjam,
                      child: Text('Dipinjam'),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.galonRusak,
                      child: Text('Rusak'),
                    ),
                  ],
                  onChanged: (v) => status.value = v!,
                  decoration: _dropdownDecoration(
                    label: 'Status',
                    icon: Icons.flag_outlined,
                  ),
                )),
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<String>(
                  initialValue: jenis.value,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(18),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: const [
                    DropdownMenuItem(value: 'isi', child: Text('Isi')),
                    DropdownMenuItem(value: 'kosong', child: Text('Kosong')),
                  ],
                  onChanged: (v) => jenis.value = v!,
                  decoration: _dropdownDecoration(
                    label: 'Jenis',
                    icon: Icons.water_drop_outlined,
                  ),
                )),
            const SizedBox(height: 16),
            Obx(() {
              if (status.value != AppConstants.galonDipinjam) {
                return const SizedBox.shrink();
              }
              final list =
                  pelangganCtrl.pelangganList.where((p) => p.isAktif).toList();
              return DropdownButtonFormField<Pelanggan>(
                initialValue: selectedPelanggan.value,
                isExpanded: true,
                borderRadius: BorderRadius.circular(18),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                hint: const Text('Pilih pelanggan...'),
                items: list
                    .map((p) => DropdownMenuItem<Pelanggan>(
                          value: p,
                          child: Text(p.nama, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => selectedPelanggan.value = v,
                decoration: _dropdownDecoration(
                  label: 'Pelanggan Peminjam',
                  icon: Icons.person_outline_rounded,
                ),
              );
            }),
          ],
        ),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () async {
          final jumlah = int.tryParse(jumlahCtrl.text) ?? 0;
          if (jumlah <= 0) {
            Get.snackbar('Error', 'Jumlah galon harus lebih dari 0');
            return;
          }
          if (status.value == AppConstants.galonDipinjam &&
              selectedPelanggan.value == null) {
            Get.snackbar('Error', 'Pilih pelanggan yang meminjam');
            return;
          }
          Get.back();
          await galon.catatGalon({
            'jenis': jenis.value,
            'status': status.value,
            'jumlah': jumlah,
            if (selectedPelanggan.value != null)
              'pelangganId': selectedPelanggan.value!.id,
          });
        },
        child: const Text(
          'Simpan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _galonColor(StatusGalon status) {
    switch (status) {
      case StatusGalon.tersedia:
        return const Color(0xFF10B981);
      case StatusGalon.rusak:
        return const Color(0xFFEF4444);
      case StatusGalon.dipinjam:
        return _primary;
      default:
        return const Color(0xFF94A3B8);
    }
  }

  InputDecoration _dropdownDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
    );
  }
}

/// Toggle Daftar Galon / Log Cepat.
class GalonSegmentBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const GalonSegmentBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _segmentTab(0, 'Daftar Galon'),
          _segmentTab(1, 'Log Cepat'),
        ],
      ),
    );
  }

  Widget _segmentTab(int index, String label) {
    final selected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color:
                  selected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
