import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/crew_controller.dart';
import '../../../config/routes.dart';
import '../../../models/crew.dart';
import '../../../widgets/header_back_button.dart';

class SettingDataCrewScreen extends StatefulWidget {
  const SettingDataCrewScreen({super.key});

  @override
  State<SettingDataCrewScreen> createState() => _SettingDataCrewScreenState();
}

class _SettingDataCrewScreenState extends State<SettingDataCrewScreen> {
  static const Color _primary = Color(0xFF1392EC);

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<CrewController>().loadCrew();
      _fetchFilteredData();
    });
  }

  void _fetchFilteredData() {
    final crew = Get.find<CrewController>();
    final startStr =
        _startDate != null ? _startDate!.toIso8601String().split('T')[0] : null;
    final endStr =
        _endDate != null ? _endDate!.toIso8601String().split('T')[0] : null;
    crew.loadPengirimanCrew(tanggalMulai: startStr, tanggalAkhir: endStr);
  }

  Future<void> _pickMonth(BuildContext context) async {
    int selectedYear = _startDate?.year ?? DateTime.now().year;
    int selectedMonth = _startDate?.month ?? DateTime.now().month;
    const monthNames = [
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

    final result = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Pilih Bulan',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        onPressed: () => setState(() => selectedYear--),
                      ),
                      Text(
                        '$selectedYear',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () => setState(() => selectedYear++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(12, (index) {
                      final month = index + 1;
                      final isSelected = selectedMonth == month;
                      return InkWell(
                        onTap: () => setState(() => selectedMonth = month),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? _primary : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  isSelected ? _primary : Colors.grey.shade300,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            monthNames[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child:
                      const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                      context, DateTime(selectedYear, selectedMonth, 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Pilih',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final firstDay = DateTime(result.year, result.month, 1);
      final lastDay = DateTime(result.year, result.month + 1, 0);
      setState(() {
        _startDate = firstDay;
        _endDate = lastDay;
      });
      _fetchFilteredData();
    }
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _fetchFilteredData();
  }

  @override
  Widget build(BuildContext context) {
    final crew = Get.find<CrewController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          _buildHeader(context, crew),
          // Removed filter section from body
          Expanded(
            child: Obx(() {
              if (crew.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: _primary),
                );
              }
              if (crew.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFEF4444), size: 48),
                      const SizedBox(height: 12),
                      Text(crew.errorMessage.value,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: crew.loadCrew,
                          child: const Text('Coba Lagi')),
                    ],
                  ),
                );
              }
              if (crew.crewList.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada data crew.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                itemCount: crew.crewList.length,
                itemBuilder: (_, i) => _buildCrewCard(crew.crewList[i]),
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
            onPressed: () => _showTambahDialog(crew),
            icon: const Icon(Icons.person_add_rounded,
                color: Colors.white, size: 20),
            label: const Text(
              'Tambah Crew Baru',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, CrewController crew) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPad + 16,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1392EC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const HeaderBackButton(
            fallbackRoute: AppRoutes.managerSettings,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manajemen Crew',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Obx(() => Text(
                      '${crew.crewList.length} Anggota terdaftar',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    )),
              ],
            ),
          ),
          // Filter section
          Row(
            children: [
              if (_startDate != null)
                GestureDetector(
                  onTap: _clearFilter,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Builder(builder: (_) {
                          const months = [
                            'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                            'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
                          ];
                          final text =
                              '${months[_startDate!.month - 1]} ${_startDate!.year}';
                          return Text(
                            text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }),
                        const SizedBox(width: 4),
                        const Icon(Icons.close_rounded,
                            color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () => _pickMonth(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── CREW CARD ────────────────────────────────────────────────────────────────
  Widget _buildCrewCard(Crew c) {
    final initials = c.nama.isNotEmpty
        ? c.nama.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : 'CR';
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
    ];
    final avatarColor = colors[c.nama.length % colors.length];
    final stat = Get.find<CrewController>().pengirimanByCrewId(c.id);
    final totalKirim = stat?['totalKirim'] ?? 0;

    return GestureDetector(
      onTap: () => _showCrewDetail(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: avatarColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: avatarColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -3,
                  right: -3,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: c.isAktif
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.nama,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    c.noHp,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            // Right side: stats + status + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_shipping_rounded,
                        size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      '$totalKirim pengiriman',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.isAktif
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    c.isAktif ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: c.isAktif
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }

  // ── DIALOGS ──────────────────────────────────────────────────────────────────
  void _showTambahDialog(CrewController crew) {
    final namaCtrl = TextEditingController();
    final noHpCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
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
                'Tambah Crew Baru',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 20),
              _dialogField(namaCtrl, 'Nama Lengkap', Icons.person_outline),
              const SizedBox(height: 12),
              _dialogField(noHpCtrl, 'Nomor HP', Icons.phone_android_rounded),
              const SizedBox(height: 12),
              _dialogField(pinCtrl, 'PIN (6 digit)', Icons.pin_outlined,
                  obscure: true),
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
                      onPressed: () async {
                        final nama = namaCtrl.text.trim();
                        final noHp = noHpCtrl.text.trim();
                        final pin = pinCtrl.text.trim();
                        if (nama.isEmpty || noHp.isEmpty) {
                          Get.snackbar(
                            'Error',
                            'Nama dan Nomor HP wajib diisi',
                            backgroundColor: const Color(0xFFE63946),
                            colorText: Colors.white,
                          );
                          return;
                        }
                        if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
                          Get.snackbar(
                            'Error',
                            'PIN harus tepat 6 digit angka',
                            backgroundColor: const Color(0xFFE63946),
                            colorText: Colors.white,
                          );
                          return;
                        }
                        Get.back();
                        await crew.tambahCrew({
                          'nama': nama,
                          'noHp': noHp,
                          'pin': pin,
                        });
                      },
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── DETAIL CREW BOTTOM SHEET ────────────────────────────────────────────────
  void _showCrewDetail(Crew c) {
    final crewController = Get.find<CrewController>();
    Crew detailCrew = c;
    bool isLoadingStats = true;
    bool called = false;
    bool isEditing = false;
    final namaEditCtrl = TextEditingController(text: c.nama);
    final noHpEditCtrl = TextEditingController(text: c.noHp);

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          if (!called) {
            called = true;
            crewController.getCrewDetail(c.id).then((detail) {
              setSheetState(() {
                detailCrew = detail;
                namaEditCtrl.text = detail.nama;
                noHpEditCtrl.text = detail.noHp;
                isLoadingStats = false;
              });
            }).catchError((_) {
              setSheetState(() => isLoadingStats = false);
            });
          }

          final initials = detailCrew.nama.isNotEmpty
              ? detailCrew.nama.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
              : 'CR';

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 32, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20, 20, 20,
                      MediaQuery.of(context).viewInsets.bottom + 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // ── Hero Profile Card ─────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  color: _primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: _primary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Name & phone
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      detailCrew.nama,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_android_rounded,
                                            size: 12, color: Color(0xFF94A3B8)),
                                        const SizedBox(width: 4),
                                        Text(
                                          detailCrew.noHp.isEmpty ? '-' : detailCrew.noHp,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Status pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: detailCrew.isAktif
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFFE4E6),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6, height: 6,
                                      decoration: BoxDecoration(
                                        color: detailCrew.isAktif
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFDC2626),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      detailCrew.isAktif ? 'Aktif' : 'Nonaktif',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: detailCrew.isAktif
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Stats Row ─────────────────────────────────────────
                        if (isLoadingStats)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              _miniStatCard(
                                value: detailCrew.stats?['totalTransaksi']?.toString() ?? '0',
                                label: 'Transaksi',
                                icon: Icons.receipt_long_rounded,
                              ),
                              const SizedBox(width: 10),
                              _miniStatCard(
                                value: detailCrew.stats?['totalPengiriman']?.toString() ?? '0',
                                label: 'Jml Kirim',
                                icon: Icons.local_shipping_rounded,
                              ),
                            ],
                          ),

                        const SizedBox(height: 14),

                        // ── Info / Edit Section ───────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10, offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Section header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isEditing ? 'Edit Data Crew' : 'Informasi',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF475569),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setSheetState(() {
                                        isEditing = !isEditing;
                                        if (!isEditing) {
                                          namaEditCtrl.text = detailCrew.nama;
                                          noHpEditCtrl.text = detailCrew.noHp;
                                        }
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isEditing
                                              ? const Color(0xFFFFE4E6)
                                              : const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          isEditing ? '✕  Batal' : '✎  Edit',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isEditing
                                                ? const Color(0xFFDC2626)
                                                : _primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Divider(height: 16),
                              ),

                              // Content
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: isEditing
                                    ? Column(
                                        children: [
                                          _compactField(namaEditCtrl, 'Nama Lengkap',
                                              Icons.person_outline_rounded),
                                          const SizedBox(height: 10),
                                          _compactField(noHpEditCtrl, 'No. Telepon',
                                              Icons.phone_android_rounded,
                                              inputType: TextInputType.phone),
                                          const SizedBox(height: 14),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 44,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                final nama = namaEditCtrl.text.trim();
                                                final noHp = noHpEditCtrl.text.trim();
                                                if (nama.isEmpty) {
                                                  Get.snackbar(
                                                    'Peringatan', 'Nama tidak boleh kosong',
                                                    backgroundColor: Colors.orange,
                                                    colorText: Colors.white,
                                                  );
                                                  return;
                                                }
                                                await crewController.editCrew(
                                                    detailCrew.id,
                                                    {'nama': nama, 'noHp': noHp});
                                                crewController
                                                    .getCrewDetail(detailCrew.id)
                                                    .then((updated) => setSheetState(() {
                                                          detailCrew = updated;
                                                          isEditing = false;
                                                        }))
                                                    .catchError((_) {});
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _primary,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12)),
                                                elevation: 0,
                                              ),
                                              child: const Text('Simpan Perubahan',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14)),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          _infoTile(Icons.badge_rounded, 'Nama',
                                              detailCrew.nama),
                                          _infoTile(Icons.phone_android_rounded,
                                              'No. Telepon', detailCrew.noHp.isEmpty ? '-' : detailCrew.noHp),
                                          _infoTile(Icons.calendar_today_rounded,
                                              'Terdaftar',
                                              detailCrew.createdAt.toString().substring(0, 10)),
                                          _infoTile(
                                            Icons.access_time_rounded,
                                            'Login Terakhir',
                                            detailCrew.lastLoginAt ?? '-',
                                            isLast: true,
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Action Buttons ────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _sheetActionBtn(
                                label: 'Reset PIN',
                                sublabel: '123456',
                                icon: Icons.lock_reset_rounded,
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                    title: const Text('Reset PIN',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    content: Text(
                                        'PIN "${detailCrew.nama}" akan direset ke 123456.',
                                        style: const TextStyle(fontSize: 14)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Batal',
                                            style: TextStyle(color: Colors.grey)),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          final ok = await crewController
                                              .resetPin(detailCrew.id);
                                          if (ok) {
                                            Get.snackbar(
                                                'Berhasil', 'PIN direset ke 123456',
                                                backgroundColor:
                                                    const Color(0xFF16A34A),
                                                colorText: Colors.white);
                                          }
                                        },
                                        child: const Text('Reset',
                                            style: TextStyle(color: _primary)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _sheetActionBtn(
                                label: detailCrew.isAktif ? 'Nonaktifkan' : 'Aktifkan',
                                sublabel: detailCrew.isAktif ? 'Akun crew' : 'Akun crew',
                                icon: detailCrew.isAktif
                                    ? Icons.block_rounded
                                    : Icons.check_circle_outline_rounded,
                                isDestructive: detailCrew.isAktif,
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                    title: Text(
                                        detailCrew.isAktif
                                            ? 'Nonaktifkan Crew'
                                            : 'Aktifkan Crew',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    content: Text(
                                        detailCrew.isAktif
                                            ? 'Nonaktifkan akun "${detailCrew.nama}"?'
                                            : 'Aktifkan akun "${detailCrew.nama}"?',
                                        style: const TextStyle(fontSize: 14)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Batal',
                                            style: TextStyle(color: Colors.grey)),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          final ok = await crewController.updateStatus(
                                              detailCrew.id, !detailCrew.isAktif);
                                          if (ok) {
                                            Get.back();
                                            await crewController.loadCrew();
                                            Get.snackbar('Berhasil', 'Status berhasil diubah',
                                                backgroundColor: const Color(0xFF16A34A),
                                                colorText: Colors.white);
                                          }
                                        },
                                        child: Text('Ya',
                                            style: TextStyle(
                                                color: detailCrew.isAktif
                                                    ? Colors.red
                                                    : _primary)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _sheetActionBtn(
                          label: 'Hapus Crew',
                          sublabel: 'Hapus akun crew permanen',
                          icon: Icons.delete_outline_rounded,
                          isDestructive: true,
                          onTap: () => showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: const Text('Hapus Crew',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                              content: Text(
                                  'Anda yakin ingin menghapus akun "${detailCrew.nama}" secara permanen?',
                                  style: const TextStyle(fontSize: 14)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Batal',
                                      style: TextStyle(color: Colors.grey)),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx); // tutup dialog
                                    Get.back(); // tutup bottom sheet
                                    await crewController.hapusCrew(detailCrew.id);
                                  },
                                  child: const Text('Hapus',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ── NEW HELPERS ──────────────────────────────────────────────────────────────

  Widget _miniStatCard({
    required String value,
    required String label,
    required IconData icon,
  }) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primary, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _infoTile(IconData icon, String label, String value,
      {bool isLast = false}) =>
      Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 10),
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          if (!isLast)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            )
          else
            const SizedBox(height: 4),
        ],
      );

  Widget _sheetActionBtn({
    required String label,
    required String sublabel,
    required IconData icon,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDestructive ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isDestructive ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isDestructive ? const Color(0xFFDC2626) : const Color(0xFF64748B), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDestructive ? const Color(0xFFDC2626) : const Color(0xFF334155),
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDestructive ? const Color(0xFFF87171) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _compactField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: inputType,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5)),
        ),
      );

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon,
      {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
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
}

