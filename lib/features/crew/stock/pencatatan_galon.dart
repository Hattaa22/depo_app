import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/galon_controller.dart';
import '../../../controllers/galon_ui_controller.dart';
import '../../../controllers/pelanggan_controller.dart';
import '../../../controllers/crew_main_controller.dart';
import '../../../config/constants.dart';
import '../../../models/galon.dart';
import '../../../models/pelanggan.dart';
import '../../../utils/formatters.dart';

class PencatatanGalonScreen extends StatefulWidget {
  const PencatatanGalonScreen({super.key});

  @override
  State<PencatatanGalonScreen> createState() => _PencatatanGalonScreenState();
}

class _PencatatanGalonScreenState extends State<PencatatanGalonScreen> {
  static const Color _primary = Color(0xFF1392EC);
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const String _uiTag = 'crew_pencatatan_galon';

  late final GalonUiController _ui;
  final ScrollController _scrollController = ScrollController();

  int get _selectedSegment => _ui.selectedSegment.value;
  String get _filterValue => _ui.filterValue.value;
  bool get _isOut => _ui.isOut.value;
  String get _amount => _ui.amount.value;
  String? get _selectedPelangganId => _ui.selectedPelangganId.value;
  DateTime? get _selectedTanggal => _ui.selectedTanggal.value;

  @override
  void initState() {
    super.initState();
    _ui = Get.put(GalonUiController(), tag: _uiTag);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final galon = Get.find<GalonController>();
      galon.loadGalon();
      galon.loadSummary();
      Get.find<PelangganController>().loadPelanggan();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (Get.isRegistered<GalonUiController>(tag: _uiTag)) {
      Get.delete<GalonUiController>(tag: _uiTag);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      Get.find<GalonController>().loadMore();
    }
  }

  void _onKeypadTap(String value) => _ui.addDigit(value);

  void _onBackspace() => _ui.backspace();

  void _onClear() => _ui.clearAmount();

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
      _ui.setSelectedTanggal(picked);
    }
  }

  Future<void> _onKonfirmasiBulk(GalonController galon) async {
    final val = int.tryParse(_amount) ?? 0;
    if (val <= 0) {
      Get.snackbar(
        'Peringatan',
        'Masukkan jumlah galon terlebih dahulu',
        backgroundColor: const Color(0xFFF59E0B),
        colorText: Colors.white,
      );
      return;
    }

    // Pelanggan wajib dipilih untuk pinjam maupun kembali
    if (_selectedPelangganId == null) {
      Get.snackbar(
        'Peringatan',
        'Pilih pelanggan terlebih dahulu',
        backgroundColor: const Color(0xFFF59E0B),
        colorText: Colors.white,
      );
      return;
    }

    final ok = _isOut
        ? await galon.pinjamGalon(val,
            pelangganId: _selectedPelangganId, tanggal: _selectedTanggal)
        : await galon.kembalikanGalon(val,
            pelangganId: _selectedPelangganId, tanggal: _selectedTanggal);
    if (ok && mounted) {
      _ui.resetBulkForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final galon = Get.find<GalonController>();
    final mainController = Get.find<CrewMainController>();

    return Scaffold(
      backgroundColor: _bgLight,
      body: Obx(() => Column(
            children: [
              // ── HEADER ─────────────────────────────────────────────────────
              _buildHeader(mainController),

              // ── MIDDLE METRICS CARD ────────────────────────────────────────
              Transform.translate(
                offset: const Offset(0, -32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFEEF2F6)),
                    ),
                    child: Obx(() {
                      final summaryVal = galon.summary.value;
                      return Row(
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
                                        '${summaryVal?.tersedia ?? 0}',
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
                                      '${summaryVal?.dipinjam ?? 0}',
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
                      );
                    }),
                  ),
                ),
              ),

              // Custom Segment Toggles
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _ui.setSegment(0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedSegment == 0
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedSegment == 0
                                ? [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Daftar Galon',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _selectedSegment == 0
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _ui.setSegment(1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedSegment == 1
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedSegment == 1
                                ? [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Log Cepat',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _selectedSegment == 1
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── DYNAMIC CONTENT CONTAINER ──────────────────────────────────
              Expanded(
                child: _selectedSegment == 0
                    ? _buildDaftarGalonTab(galon)
                    : _buildLogCepatTab(galon),
              ),
            ],
          )),
    );
  }

  // ── DAFTAR GALON VIEW ──────────────────────────────────────────────────────
  Widget _buildDaftarGalonTab(GalonController galon) {
    return Column(
      children: [
        // Horizontal filter chips
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

        // List builder
        Expanded(
          child: Obx(() {
            if (galon.isLoading.value) {
              return const Center(
                  child: CircularProgressIndicator(color: _primary));
            }
            if (galon.errorMessage.value.isNotEmpty) {
              return Center(child: Text(galon.errorMessage.value));
            }

            final list = galon.galonList;
            if (list.isEmpty) {
              return _buildEmptyGalonState();
            }

            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final g = list[i];
                          return _buildGalonItemCard(g, galon);
                        },
                      ),
                    ),
                    if (galon.isFetchingMore.value)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: CircularProgressIndicator(color: _primary),
                      ),
                  ],
                ),

                // Absolute Floating Button inside tab context
                Positioned(
                  right: 24,
                  bottom: 100, // Stay above BottomBar
                  child: FloatingActionButton.extended(
                    onPressed: () => _showCatatDialog(galon),
                    backgroundColor: _primary,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Catat Galon',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, GalonController galon) {
    final bool isSelected = _filterValue == value;
    return GestureDetector(
      onTap: () {
        _ui.setFilter(value);
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                if (g.status == StatusGalon.dipinjam &&
                    g.pelangganNama != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: GestureDetector(
                      onTap: () => _showBorrowingDetails(g),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 12, color: _primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  g.pelangganNama!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (g.tanggalPinjam != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 10, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${_formatTanggal(g.tanggalPinjam!)} • ${_hitungDurasi(g.tanggalPinjam!)}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF64748B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
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
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'tersedia', child: Text('Tandai Tersedia')),
              const PopupMenuItem(
                  value: 'dipinjam', child: Text('Tandai Dipinjam')),
              const PopupMenuItem(value: 'rusak', child: Text('Tandai Rusak')),
              const PopupMenuItem(
                  value: 'hilang', child: Text('Tandai Hilang')),
            ],
          ),
        ],
      ),
    );
  }

  // ── LOG CEPAT VIEW (KEYPAD BULK LOGGER) ───────────────────────────────────
  Widget _buildLogCepatTab(GalonController galon) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Radio selection
          Row(
            children: [
              Expanded(
                child: _buildLogTypeButton(
                  isActive: _isOut,
                  title: 'Pinjam (Out)',
                  icon: Icons.logout_rounded,
                  activeColor: _primary,
                  bgColor: const Color(0xFFF0F9FF),
                  onTap: () => _ui.setLogType(true),
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
                  onTap: () => _ui.setLogType(false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── PILIH PELANGGAN (untuk pinjam dan kembali) ────────────────────
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

          // Total Number Display
          Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -16,
                    left: -20,
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
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      height: 1,
                      letterSpacing: -2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'TOTAL JUMLAH GALON',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Keypad Grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildKeypadBtn("1", onTap: () => _onKeypadTap("1")),
              _buildKeypadBtn("2", onTap: () => _onKeypadTap("2")),
              _buildKeypadBtn("3", onTap: () => _onKeypadTap("3")),
              _buildKeypadBtn("4", onTap: () => _onKeypadTap("4")),
              _buildKeypadBtn("5", onTap: () => _onKeypadTap("5")),
              _buildKeypadBtn("6", onTap: () => _onKeypadTap("6")),
              _buildKeypadBtn("7", onTap: () => _onKeypadTap("7")),
              _buildKeypadBtn("8", onTap: () => _onKeypadTap("8")),
              _buildKeypadBtn("9", onTap: () => _onKeypadTap("9")),
              _buildKeypadActionBtn(
                icon: Icons.backspace_outlined,
                onTap: _onBackspace,
              ),
              _buildKeypadBtn("0", onTap: () => _onKeypadTap("0")),
              _buildKeypadActionBtn(
                label: 'CLEAR',
                onTap: _onClear,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Confirm Button
          GestureDetector(
            onTap: () => _onKonfirmasiBulk(galon),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _isOut ? _primary : const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: (_isOut ? _primary : const Color(0xFF10B981))
                        .withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Konfirmasi Catatan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 120), // Bottom padding to clear bottom bar
        ],
      ),
    );
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
            fontSize: 22,
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

  // ── PELANGGAN SELECTOR (untuk pinjam galon) ─────────────────────────────
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
        final selectedId = list.any((p) => p.id == _selectedPelangganId)
            ? _selectedPelangganId
            : null;
        if (selectedId != _selectedPelangganId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _ui.setSelectedPelanggan(null);
          });
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selectedId != null ? _primary : const Color(0xFFE2E8F0),
              width: selectedId != null ? 2 : 1,
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
              value: selectedId,
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
              onChanged: _ui.setSelectedPelanggan,
            ),
          ),
        );
      }),
      const SizedBox(height: 8),
    ];
  }

  // ── DIALOG CATAT INDIVIDU ──────────────────────────────────────────────────
  void _showCatatDialog(GalonController galon) {
    final jumlahCtrl = TextEditingController(text: '1');
    final status = AppConstants.galonTersedia.obs;
    final jenis = 'isi'.obs;
    final pelangganCtrl = Get.find<PelangganController>();
    final selectedPelanggan = Rxn<Pelanggan>();
    final selectedTanggal = Rxn<DateTime>(DateTime.now());

    Widget modernDropdown<T>({
      required T value,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChanged,
      required String label,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            value: value,
            items: items,
            onChanged: onChanged,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF94A3B8)),
            hint: Text(label),
          ),
        ),
      );
    }

    Get.defaultDialog(
      title: 'Catat Galon Baru',
      titleStyle: const TextStyle(
          fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E293B)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      radius: 20,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Color(0xFF0284C7)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kode galon dibuat otomatis oleh sistem',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Jumlah Galon',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            TextField(
              controller: jumlahCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '1',
                suffixText: 'galon',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Tanggal',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            Obx(() => GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: Get.context!,
                      initialDate: selectedTanggal.value ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: _primary, onPrimary: Colors.white),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) selectedTanggal.value = picked;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 18, color: _primary),
                        const SizedBox(width: 12),
                        Text(
                          _formatTanggal(
                              selectedTanggal.value ?? DateTime.now()),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      Obx(() => modernDropdown<String>(
                            value: status.value,
                            label: 'Status',
                            items: const [
                              DropdownMenuItem(
                                  value: AppConstants.galonTersedia,
                                  child: Text('Tersedia')),
                              DropdownMenuItem(
                                  value: AppConstants.galonDipinjam,
                                  child: Text('Dipinjam')),
                              DropdownMenuItem(
                                  value: AppConstants.galonRusak,
                                  child: Text('Rusak')),
                            ],
                            onChanged: (v) => status.value = v!,
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jenis',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      Obx(() => modernDropdown<String>(
                            value: jenis.value,
                            label: 'Jenis',
                            items: const [
                              DropdownMenuItem(
                                  value: 'isi', child: Text('Isi')),
                              DropdownMenuItem(
                                  value: 'kosong', child: Text('Kosong')),
                            ],
                            onChanged: (v) => jenis.value = v!,
                          )),
                    ],
                  ),
                ),
              ],
            ),
            Obx(() {
              if (status.value != AppConstants.galonDipinjam) {
                return const SizedBox.shrink();
              }
              final list =
                  pelangganCtrl.pelangganList.where((p) => p.isAktif).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text('Pelanggan Peminjam',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  modernDropdown<Pelanggan?>(
                    value: selectedPelanggan.value,
                    label: 'Pilih pelanggan...',
                    items: list
                        .map((p) => DropdownMenuItem<Pelanggan>(
                            value: p,
                            child:
                                Text(p.nama, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => selectedPelanggan.value = v,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Batal',
            style: TextStyle(
                color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          final jumlah = int.tryParse(jumlahCtrl.text) ?? 0;
          if (jumlah <= 0) {
            Get.snackbar('Peringatan', 'Jumlah galon harus lebih dari 0',
                backgroundColor: Colors.orange, colorText: Colors.white);
            return;
          }
          if (status.value == AppConstants.galonDipinjam &&
              selectedPelanggan.value == null) {
            Get.snackbar('Peringatan', 'Pilih pelanggan yang meminjam',
                backgroundColor: Colors.orange, colorText: Colors.white);
            return;
          }
          Get.back();
          await galon.catatGalon({
            'jenis': jenis.value,
            'status': status.value,
            'jumlah': jumlah,
            'tanggal': selectedTanggal.value
                ?.toIso8601String(), // Optional: kirim tanggal ke API
            if (selectedPelanggan.value != null)
              'pelangganId': selectedPelanggan.value!.id,
          });
        },
        child: const Text('Simpan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(CrewMainController mainController) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1392EC), Color(0xFF0D74BC)],
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
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 56,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
          Column(
            children: [
              const Text(
                'Stok & Asset Galon',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ASSET MANAGEMENT',
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
            onTap: () => Get.find<GalonController>().loadSummary(),
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

  // ── EMPTY STATE ────────────────────────────────────────────────────────────
  Widget _buildEmptyGalonState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
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

  // ── UTILS ──────────────────────────────────────────────────────────────────
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

  // ── BORROWING DETAILS HELPER ───────────────────────────────────────────────
  void _showBorrowingDetails(Galon g) {
    Get.defaultDialog(
      title: 'Detail Peminjaman',
      titleStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      titlePadding: const EdgeInsets.only(top: 20, bottom: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Galon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Galon',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Kode: ${g.kodeGalon}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(g.jenis.name.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Info Pelanggan
          _detailRow('Pelanggan', g.pelangganNama ?? '-'),
          const SizedBox(height: 12),
          _detailRow('No. HP', g.pelangganNoHp ?? '-'),
          const SizedBox(height: 12),
          _detailRow('Alamat', g.pelangganAlamat ?? '-'),
          const SizedBox(height: 16),

          // Info Tanggal
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tanggal Peminjaman',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  g.tanggalPinjam != null
                      ? '${_formatTanggal(g.tanggalPinjam!)} (${_hitungDurasi(g.tanggalPinjam!)})'
                      : '-',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (g.catatan != null && g.catatan!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _detailRow('Catatan', g.catatan!),
          ],
        ],
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => Get.back(),
        child: const Text('Tutup', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
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
}
