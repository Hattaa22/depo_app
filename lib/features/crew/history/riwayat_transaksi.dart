import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/transaksi_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/crew_main_controller.dart';
import '../../../models/transaksi.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/modern_date_range_sheet.dart';
import '../../../widgets/qr_code_widget.dart';

class RiwayatTransaksiScreen extends StatefulWidget {
  const RiwayatTransaksiScreen({super.key});

  @override
  State<RiwayatTransaksiScreen> createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  static const Color _primary = Color(0xFF1392EC);
  static const Color _bgLight = Color(0xFFF8FAFC);

  final TextEditingController _searchController = TextEditingController();
  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    'Hari Ini',
    'Kemarin',
    '7 Hari Terakhir',
    'Semua'
  ];
  DateTimeRange? _rentangKustom;

  @override
  void initState() {
    super.initState();
    // Load data transaksi khusus crew yang login
    final transaksi = Get.find<TransaksiController>();
    final crewId = Get.find<AuthController>().userData['id']?.toString();
    transaksi.loadTransaksi(crewId: crewId);
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggalRange() async {
    final picked = await ModernDateRangeSheet.show(
      context,
      initial: _rentangKustom,
      title: 'Filter Tanggal',
    );
    if (picked == null) return;

    final transaksi = Get.find<TransaksiController>();
    final crewId = Get.find<AuthController>().userData['id']?.toString();
    final startStr = Formatters.dateOnly(picked.start);
    final endStr = Formatters.dateOnly(picked.end);
    await transaksi.loadTransaksi(
      crewId: crewId,
      tanggalMulai: startStr,
      tanggalAkhir: endStr,
    );
    if (!mounted) return;
    setState(() {
      _rentangKustom = picked;
      _selectedFilterIndex = 3;
    });
  }

  void _onFilterChipTap(int index) {
    setState(() {
      _selectedFilterIndex = index;
      if (index != 3) _rentangKustom = null;
    });
    if (index != 3) {
      final crewId = Get.find<AuthController>().userData['id']?.toString();
      Get.find<TransaksiController>().loadTransaksi(crewId: crewId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaksi = Get.find<TransaksiController>();
    final mainController = Get.find<CrewMainController>();

    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          RefreshIndicator(
            color: _primary,
            onRefresh: () {
              final crewId =
                  Get.find<AuthController>().userData['id']?.toString();
              return transaksi.loadTransaksi(crewId: crewId);
            },
            child: CustomScrollView(
              slivers: [
                // ── HEADER ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildHeader(mainController),
                ),

                // ── FILTER CHIPS ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final isSelected = index == _selectedFilterIndex;
                          return GestureDetector(
                            onTap: () => _onFilterChipTap(index),
                            child: Container(
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color: isSelected ? _primary : Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: isSelected
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color:
                                              _primary.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.02),
                                          blurRadius: 4,
                                        )
                                      ],
                              ),
                              child: Text(
                                _filters[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                if (_rentangKustom != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                      child: GestureDetector(
                        onTap: _pilihTanggalRange,
                        child: Text(
                          '${Formatters.date(_rentangKustom!.start)} – ${Formatters.date(_rentangKustom!.end)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── TRANSACTIONS LIST ───────────────────────────────────
                Obx(() {
                  if (transaksi.isLoading.value) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(color: _primary),
                      ),
                    );
                  }

                  if (transaksi.errorMessage.value.isNotEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            transaksi.errorMessage.value,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    );
                  }

                  // Local Filtering Logic
                  final query = _searchController.text.toLowerCase();
                  var list = transaksi.transaksiList.toList();

                  // Filter by Search Query
                  if (query.isNotEmpty) {
                    list = list.where((tx) {
                      final name = (tx.pelanggan?.nama ?? '').toLowerCase();
                      final code = (tx.nomorTransaksi).toLowerCase();
                      final id = tx.id.toLowerCase();
                      return name.contains(query) ||
                          code.contains(query) ||
                          id.contains(query);
                    }).toList();
                  }

                  // Filter by Date Range Chip
                  final now = DateTime.now();
                  final todayStart = DateTime(now.year, now.month, now.day);
                  final yesterdayStart =
                      todayStart.subtract(const Duration(days: 1));
                  final sevenDaysAgoStart =
                      todayStart.subtract(const Duration(days: 7));

                  if (_rentangKustom != null) {
                    final start = DateTime(
                      _rentangKustom!.start.year,
                      _rentangKustom!.start.month,
                      _rentangKustom!.start.day,
                    );
                    final end = DateTime(
                      _rentangKustom!.end.year,
                      _rentangKustom!.end.month,
                      _rentangKustom!.end.day,
                      23,
                      59,
                      59,
                    );
                    list = list
                        .where((tx) =>
                            !tx.createdAt.isBefore(start) &&
                            !tx.createdAt.isAfter(end))
                        .toList();
                  } else if (_selectedFilterIndex == 0) {
                    list = list
                        .where((tx) => tx.createdAt.isAfter(todayStart))
                        .toList();
                  } else if (_selectedFilterIndex == 1) {
                    list = list
                        .where((tx) =>
                            tx.createdAt.isAfter(yesterdayStart) &&
                            tx.createdAt.isBefore(todayStart))
                        .toList();
                  } else if (_selectedFilterIndex == 2) {
                    list = list
                        .where((tx) => tx.createdAt.isAfter(sevenDaysAgoStart))
                        .toList();
                  }

                  if (list.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildTransactionCard(list[index]),
                        childCount: list.length,
                      ),
                    ),
                  );
                }),

                // Extra bottom padding for BottomBar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(CrewMainController mainController) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1392EC),
            Color(0xFF0D74BC),
          ],
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button (Switches back to Dashboard Tab)
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
                'Riwayat Transaksi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 24),

          // Search Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Cari transaksi atau pelanggan...',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TRANSACTION CARD ───────────────────────────────────────────────────────
  Widget _buildTransactionCard(Transaksi tx) {
    final statusLabel = _statusLabel(tx.status);
    final statusColor = _statusColor(tx.status);
    final statusBg = _statusBgColor(tx.status);
    final pelangganNama = tx.pelanggan?.nama ?? 'Pelanggan';

    return GestureDetector(
      onTap: () => _showDetailBottomSheet(context, tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      pelangganNama.isNotEmpty
                          ? pelangganNama[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name and Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pelangganNama,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.time(tx.createdAt)} • #${tx.nomorTransaksi.isNotEmpty ? tx.nomorTransaksi : tx.id.substring(tx.id.length.clamp(0, 4))}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Payment and Status badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx.metodePembayaran.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // Bottom section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Petugas: ${tx.crew?.nama ?? 'Crew'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  Formatters.currency(tx.totalHarga),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── EMPTY STATE ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.history_toggle_off_rounded,
                size: 64, color: Color(0xFF94A3B8)),
            SizedBox(height: 16),
            Text(
              'Tidak ada transaksi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cobalah mengubah filter pencarian Anda atau segarkan halaman.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
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

              // Title / Header
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
                'No: #${tx.nomorTransaksi.isNotEmpty ? tx.nomorTransaksi : tx.id}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),

              // Info Section
              _buildInfoRow('Waktu', Formatters.dateTime(tx.createdAt)),
              _buildInfoRow('Pelanggan', tx.pelanggan?.nama ?? '-'),
              _buildInfoRow('No HP Pelanggan', tx.pelanggan?.noHp ?? '-'),
              _buildInfoRow(
                  'Metode Bayar', tx.metodePembayaran.name.toUpperCase()),
              _buildInfoRow('Petugas', tx.crew?.nama ?? '-'),
              if (tx.isDikirim)
                _buildInfoRow('Pengirim', tx.pengirimCrew?.nama ?? '-'),
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
              const SizedBox(height: 16),

              // Itemized List
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
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.produk?.nama ?? "Produk"} x${item.jumlah}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            Text(
                              Formatters.currency(item.subtotal),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      )),

              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),

              // Galon Returns / Loans details if any
              if (tx.items
                  .any((i) => i.galonPinjam > 0 || i.galonKembali > 0)) ...[
                const Text(
                  'Status Galon',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                ...tx.items
                    .where((i) => i.galonPinjam > 0 || i.galonKembali > 0)
                    .map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.produk?.nama ?? "Produk",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              Text(
                                'Pinjam: ${item.galonPinjam} • Kembali: ${item.galonKembali}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        )),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
              ],

              // Total Payment section
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

              // Validation Info if validated
              if (tx.statusValidasi == StatusValidasi.valid) ...[
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
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
                          'Divalidasi oleh ${tx.validasiOleh ?? "Manager"}${tx.validasiAt != null ? " pada ${Formatters.dateTime(tx.validasiAt!)}" : ""},',
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
              // Close Button
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
