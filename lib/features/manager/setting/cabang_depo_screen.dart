import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/cabang_controller.dart';
import '../../../models/cabang.dart';
import '../../../config/routes.dart';
import '../../../widgets/header_back_button.dart';

class _ScreenMetrics {
  final double width;
  final double height;
  final EdgeInsets padding;
  final bool isCompact;
  final bool isTablet;
  final int gridColumns;
  final double horizontalPad;
  final double maxContentWidth;

  _ScreenMetrics(BuildContext context)
      : width = MediaQuery.sizeOf(context).width,
        height = MediaQuery.sizeOf(context).height,
        padding = MediaQuery.paddingOf(context),
        isCompact = MediaQuery.sizeOf(context).width < 360,
        isTablet = MediaQuery.sizeOf(context).width >= 600,
        gridColumns = MediaQuery.sizeOf(context).width >= 720 ? 2 : 1,
        horizontalPad = MediaQuery.sizeOf(context).width < 360
            ? 14
            : MediaQuery.sizeOf(context).width < 600
                ? 18
                : 24,
        maxContentWidth = 860;
}

class CabangDepoScreen extends StatefulWidget {
  const CabangDepoScreen({super.key});

  @override
  State<CabangDepoScreen> createState() => _CabangDepoScreenState();
}

class _CabangDepoScreenState extends State<CabangDepoScreen> {
  static const Color _primary = Color(0xFF1392EC);

  static const List<Color> _accentColors = [
    Color(0xFF1392EC),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<CabangController>().loadCabang();
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = _ScreenMetrics(context);
    final cabang = Get.find<CabangController>();
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, m, auth),
            Expanded(
              child: Obx(() {
                if (cabang.isLoading.value && cabang.cabangList.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primary),
                  );
                }
                if (cabang.errorMessage.value.isNotEmpty &&
                    cabang.cabangList.isEmpty) {
                  return _buildError(cabang, m);
                }
                return RefreshIndicator(
                  color: _primary,
                  onRefresh: cabang.loadCabang,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxWidth: m.maxContentWidth),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    m.horizontalPad,
                                    0,
                                    m.horizontalPad,
                                    0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: m.isCompact ? 12 : 16),
                                      _buildManagerCard(cabang, m),
                                      SizedBox(height: m.isCompact ? 14 : 20),
                                      _buildSectionTitle(
                                        'Daftar Cabang',
                                        cabang.totalCabang,
                                        m,
                                      ),
                                      SizedBox(height: m.isCompact ? 8 : 12),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (cabang.cabangList.isEmpty)
                            SliverToBoxAdapter(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxWidth: m.maxContentWidth),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: m.horizontalPad),
                                    child: _buildEmptyState(m),
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverToBoxAdapter(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxWidth: m.maxContentWidth),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      m.horizontalPad,
                                      0,
                                      m.horizontalPad,
                                      m.padding.bottom + 88,
                                    ),
                                    child: m.gridColumns > 1
                                        ? GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: cabang.cabangList.length,
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: m.gridColumns,
                                              mainAxisSpacing: 12,
                                              crossAxisSpacing: 12,
                                              childAspectRatio:
                                                  m.isTablet ? 1.55 : 1.35,
                                            ),
                                            itemBuilder: (context, index) =>
                                                _buildCabangCard(
                                              cabang.cabangList[index],
                                              index,
                                              m,
                                            ),
                                          )
                                        : Column(
                                            children: cabang.cabangList
                                                .asMap()
                                                .entries
                                                .map((e) => _buildCabangCard(
                                                      e.value,
                                                      e.key,
                                                      m,
                                                    ))
                                                .toList(),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(m),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget? _buildFab(_ScreenMetrics m) {
    if (m.isCompact) {
      return FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: _primary,
        child: const Icon(Icons.add_business_rounded, color: Colors.white),
      );
    }
    return FloatingActionButton.extended(
      onPressed: () => _showFormDialog(),
      backgroundColor: _primary,
      icon: const Icon(Icons.add_business_rounded, color: Colors.white),
      label: const Text(
        'Tambah Cabang',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, _ScreenMetrics m, AuthController auth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: m.padding.top + (m.isCompact ? 12 : 16),
        left: m.horizontalPad,
        right: m.horizontalPad,
        bottom: m.isCompact ? 20 : 28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1392EC), Color(0xFF0B76C4)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: m.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const HeaderBackButton(
                      fallbackRoute: AppRoutes.managerSettings),
                  Expanded(
                    child: Text(
                      'Cabang Depo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: m.isCompact ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: const CircleBorder(),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          Get.find<CabangController>().loadCabang(),
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: m.isCompact ? 20 : 24,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: m.isCompact ? 12 : 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: m.isCompact ? 10 : 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: m.isCompact ? 14 : 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Manager Utama',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: m.isCompact ? 11 : 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (m.isTablet)
                    TextButton.icon(
                      onPressed: () => _showFormDialog(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah Cabang',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              SizedBox(height: m.isCompact ? 8 : 10),
              Text(
                'Kelola seluruh jaringan depo air minum',
                style: TextStyle(
                  fontSize: m.isCompact ? 12 : 13,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagerCard(CabangController cabang, _ScreenMetrics m) {
    final stats = [
      _StatData(
        icon: Icons.store_mall_directory_rounded,
        label: 'Total Cabang',
        value: '${cabang.totalCabang}',
        color: _primary,
      ),
      _StatData(
        icon: Icons.location_city_rounded,
        label: 'Area',
        value: '${_uniqueKota(cabang.cabangList)}',
        color: const Color(0xFF10B981),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(m.isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: m.isCompact
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildStatTile(stats[0], m)),
                    _statDivider(),
                    Expanded(child: _buildStatTile(stats[1], m)),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildStatTile(stats[0], m)),
                _statDivider(),
                Expanded(child: _buildStatTile(stats[1], m)),
              ],
            ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: const Color(0xFFE2E8F0),
      );

  int _uniqueKota(List<CabangDepo> list) {
    final kota = list
        .map((c) => c.kota?.trim())
        .whereType<String>()
        .where((k) => k.isNotEmpty)
        .toSet();
    return kota.isEmpty ? list.length : kota.length;
  }

  Widget _buildStatTile(_StatData stat, _ScreenMetrics m,
      {bool compact = false}) {
    return SizedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stat.icon, color: stat.color, size: m.isCompact ? 20 : 22),
          SizedBox(height: m.isCompact ? 4 : 6),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact || m.isCompact ? 13 : 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          Text(
            stat.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: m.isCompact ? 9 : 10,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count, _ScreenMetrics m) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: m.isCompact ? 15 : 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCabangCard(CabangDepo cabang, int index, _ScreenMetrics m) {
    final color = _accentColors[index % _accentColors.length];
    final shortName =
        cabang.nama.replaceFirst(RegExp(r'^Depo\s*', caseSensitive: false), '');
    final iconSize = m.isCompact ? 44.0 : 52.0;

    return Container(
      margin: EdgeInsets.only(bottom: m.gridColumns > 1 ? 0 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cabang.isPusat
              ? color.withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
          width: cabang.isPusat ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showFormDialog(existing: cabang),
          child: Padding(
            padding: EdgeInsets.all(m.isCompact ? 12 : 16),
            child: m.gridColumns > 1
                ? _buildCardContentVertical(
                    cabang, shortName, color, iconSize, m)
                : _buildCardContentHorizontal(
                    cabang, shortName, color, iconSize, m),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContentHorizontal(
    CabangDepo cabang,
    String shortName,
    Color color,
    double iconSize,
    _ScreenMetrics m,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardIcon(color, iconSize),
        SizedBox(width: m.isCompact ? 10 : 14),
        Expanded(child: _buildCardDetails(cabang, shortName, color, m)),
        _buildCardMenu(cabang),
      ],
    );
  }

  Widget _buildCardContentVertical(
    CabangDepo cabang,
    String shortName,
    Color color,
    double iconSize,
    _ScreenMetrics m,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardIcon(color, iconSize),
            const SizedBox(width: 12),
            Expanded(
                child: _buildCardDetails(cabang, shortName, color, m,
                    dense: true)),
            _buildCardMenu(cabang),
          ],
        ),
      ],
    );
  }

  Widget _buildCardIcon(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child:
          Icon(Icons.water_drop_rounded, color: Colors.white, size: size * 0.5),
    );
  }

  Widget _buildCardDetails(
    CabangDepo cabang,
    String shortName,
    Color color,
    _ScreenMetrics m, {
    bool dense = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                shortName.isNotEmpty ? shortName : cabang.nama,
                maxLines: dense ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: m.isCompact ? 14 : 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            if (cabang.isPusat) ...[
              const SizedBox(width: 6),
              _buildBadge('Pusat', color),
            ],
          ],
        ),
        if (cabang.kota != null && cabang.kota!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  cabang.kota!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Text(
          cabang.alamat ?? 'Alamat belum diisi',
          maxLines: dense ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        if (cabang.noHp != null && cabang.noHp!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  cabang.noHp!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCardMenu(CabangDepo cabang) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
      onSelected: (v) {
        if (v == 'edit') {
          _showFormDialog(existing: cabang);
        } else if (v == 'hapus') {
          _confirmHapus(cabang);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit Cabang')),
        const PopupMenuItem(
          value: 'hapus',
          child:
              Text('Nonaktifkan', style: TextStyle(color: Color(0xFFEF4444))),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _buildEmptyState(_ScreenMetrics m) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(m.isCompact ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.store_outlined,
              size: m.isCompact ? 40 : 48, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            'Belum ada cabang terdaftar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: m.isCompact ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tambahkan cabang depo pertama Anda',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(CabangController cabang, _ScreenMetrics m) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(m.horizontalPad + 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(cabang.errorMessage.value, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: cabang.loadCabang,
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              child: const Text('Coba Lagi',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmHapus(CabangDepo cabang) {
    Get.dialog(
      AlertDialog(
        title: const Text('Nonaktifkan Cabang?'),
        content:
            Text('Cabang "${cabang.nama}" akan dinonaktifkan dari daftar.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.find<CabangController>().hapusCabang(cabang.id);
            },
            child: const Text('Nonaktifkan',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _showFormDialog({CabangDepo? existing}) {
    final namaCtrl = TextEditingController(text: existing?.nama ?? '');
    final kotaCtrl = TextEditingController(text: existing?.kota ?? '');
    final alamatCtrl = TextEditingController(text: existing?.alamat ?? '');
    final hpCtrl = TextEditingController(text: existing?.noHp ?? '');
    final isEdit = existing != null;

    void disposeCtrls() {
      namaCtrl.dispose();
      kotaCtrl.dispose();
      alamatCtrl.dispose();
      hpCtrl.dispose();
    }

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.sizeOf(Get.context!).height * 0.72,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEdit
                                ? Icons.edit_location_alt_rounded
                                : Icons.add_business_rounded,
                            color: _primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'Edit Cabang' : 'Tambah Cabang',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                isEdit
                                    ? 'Perbarui data cabang'
                                    : 'Cabang baru di jaringan depo',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF94A3B8), size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _dialogField(namaCtrl, 'Nama Cabang', Icons.store_outlined),
                    const SizedBox(height: 10),
                    _dialogField(kotaCtrl, 'Kota / Kecamatan',
                        Icons.location_city_outlined),
                    const SizedBox(height: 10),
                    _dialogField(hpCtrl, 'No. Telepon', Icons.phone_outlined,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 10),
                    _dialogField(
                        alamatCtrl, 'Alamat', Icons.location_on_outlined,
                        maxLines: 2),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (namaCtrl.text.trim().isEmpty) {
                                Get.snackbar(
                                    'Perhatian', 'Nama cabang wajib diisi');
                                return;
                              }
                              final data = {
                                'nama': namaCtrl.text.trim(),
                                'kota': kotaCtrl.text.trim().isEmpty
                                    ? null
                                    : kotaCtrl.text.trim(),
                                'alamat': alamatCtrl.text.trim().isEmpty
                                    ? null
                                    : alamatCtrl.text.trim(),
                                'noHp': hpCtrl.text.trim().isEmpty
                                    ? null
                                    : hpCtrl.text.trim(),
                              };
                              final ctrl = Get.find<CabangController>();
                              // Close dialog FIRST to avoid snackbar/dialog navigation conflict
                              Get.back();
                              if (isEdit) {
                                ctrl.editCabang(existing.id, data);
                              } else {
                                ctrl.tambahCabang(data);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              isEdit ? 'Simpan' : 'Tambah',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
    ).whenComplete(disposeCtrls);
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final effectiveKeyboardType =
        maxLines > 1 ? TextInputType.multiline : keyboardType;
    return TextField(
      controller: ctrl,
      keyboardType: effectiveKeyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
