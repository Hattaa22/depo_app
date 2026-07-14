import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/crew_controller.dart';
import '../../../controllers/crew_main_controller.dart';
import '../../../controllers/kasir_controller.dart';
import '../../../controllers/pelanggan_controller.dart';
import '../../../controllers/transaksi_controller.dart';
import '../../../config/routes.dart';
import '../../../models/crew.dart';
import '../../../models/produk.dart';
import '../../../utils/formatters.dart';
import 'kasir_components.dart';

// =============================================================================
// KASIR SCREEN — GetX State Management
// =============================================================================
class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  static const Color _primary = Color(0xFF1392EC);
  static const Color _bg = Color(0xFFF6F7F8);

  final Map<String, bool> _expandedByKategori = {};
  Worker? _transaksiWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<KasirController>().refreshData();
      final pelangganCtrl = Get.find<PelangganController>();
      final crewCtrl = Get.find<CrewController>();
      if (pelangganCtrl.pelangganList.isEmpty) {
        pelangganCtrl.loadPelanggan();
      }
      if (crewCtrl.crewList.isEmpty) {
        crewCtrl.loadCrew();
      }
    });

    _transaksiWorker =
        ever(Get.find<TransaksiController>().transaksiTerbaru, (t) {
      if (t == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final kasir = Get.find<KasirController>();
        kasir.reset();
        kasir.refreshData();
        if (t.metodePembayaran.name == 'qris') {
          Get.toNamed(AppRoutes.crewPembayaranQr, arguments: {
            'totalHarga': t.totalHarga.round(),
            'transaksiId': t.id,
          });
        } else {
          Get.snackbar('Berhasil', 'Transaksi berhasil!',
              backgroundColor: const Color(0xFF10B981),
              colorText: Colors.white);
        }
        // Reset setelah diproses agar tidak terpicu ganda
        Get.find<TransaksiController>().transaksiTerbaru.value = null;
      });
    });
  }

  @override
  void dispose() {
    _transaksiWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kasir = Get.find<KasirController>();
    final pelangganCtrl = Get.find<PelangganController>();
    final transaksi = Get.find<TransaksiController>();
    final crewCtrl = Get.find<CrewController>();

    return Scaffold(
      backgroundColor: _bg,
      extendBody: true,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Obx(() =>
                      _buildCustomerSelector(context, kasir, pelangganCtrl)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Obx(() => _buildTipePembelian(kasir, crewCtrl)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Produk Tersedia',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3)),
                      SizedBox(height: 2),
                      Text('Ketuk untuk menambah jumlah pesanan',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Obx(() => _buildProdukByKategori(kasir)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 130)),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() => _buildTotalCard(context, kasir, transaksi)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1392EC), Color(0xFF0369A1)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x281392EC), blurRadius: 20, offset: Offset(0, 8))
        ],
      ),
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          left: 20,
          right: 20,
          bottom: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _handleBackFromKasir(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kasir',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3)),
                Text('Sesi Aktif: Crew',
                    style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showAddCustomerSheet(context,
                Get.find<PelangganController>(), Get.find<KasirController>()),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle),
              child: const Icon(Icons.person_add_alt_1_outlined,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSelector(BuildContext context, KasirController kasir,
      PelangganController pelangganCtrl) {
    final selectedCustomer = kasir.pelangganDipilih.value;
    return GestureDetector(
      onTap: () => _showCustomerSheet(context, pelangganCtrl, kasir),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedCustomer != null
                ? _primary.withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0),
            width: selectedCustomer != null ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selectedCustomer != null
                    ? _primary.withValues(alpha: 0.1)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selectedCustomer != null
                    ? Icons.person_rounded
                    : Icons.person_search_rounded,
                color: selectedCustomer != null
                    ? _primary
                    : const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedCustomer != null
                        ? selectedCustomer.nama
                        : 'Pilih Pelanggan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selectedCustomer != null
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  if (selectedCustomer != null)
                    Text(selectedCustomer.noHp,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF94A3B8)))
                  else
                    const Text('Ketuk untuk memilih atau tambah pelanggan',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: selectedCustomer != null
                    ? _primary
                    : const Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  void _handleBackFromKasir(BuildContext context) {
    if (Get.currentRoute == AppRoutes.crewDashboard &&
        Get.isRegistered<CrewMainController>()) {
      Get.find<CrewMainController>().changeTab(0);
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      Get.offAllNamed(AppRoutes.crewDashboard);
    }
  }

  Widget _buildTipePembelian(KasirController kasir, CrewController crewCtrl) {
    final isDikirim = kasir.isDikirim;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Model Pembelian',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTipeChip(
                  label: 'Di Depo',
                  icon: Icons.storefront_outlined,
                  selected: !isDikirim,
                  onTap: () => kasir.setTipePembelian(TipePembelian.diDepo),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTipeChip(
                  label: 'Dikirim',
                  icon: Icons.local_shipping_outlined,
                  selected: isDikirim,
                  onTap: () => kasir.setTipePembelian(TipePembelian.dikirim),
                ),
              ),
            ],
          ),
          if (isDikirim) ...[
            const SizedBox(height: 12),
            const Text(
              'Crew Pengirim',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            _buildCrewPengirimPicker(kasir, crewCtrl),
            const SizedBox(height: 14),
            const Text(
              'Ongkir per galon',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildOngkirChip(
                    label: 'Rp 1.000',
                    selected: kasir.ongkirPerGalon.value == 1000,
                    onTap: () => kasir.setOngkirPerGalon(1000),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOngkirChip(
                    label: 'Rp 2.000',
                    selected: kasir.ongkirPerGalon.value == 2000,
                    onTap: () => kasir.setOngkirPerGalon(2000),
                  ),
                ),
              ],
            ),
            if (kasir.totalItem > 0) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Ongkir: ${Formatters.currency(kasir.totalOngkir.toDouble())} '
                  '(${kasir.totalItem} galon × ${Formatters.currency(kasir.ongkirPerGalon.value.toDouble())})',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _primary),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCrewPengirimPicker(
    KasirController kasir,
    CrewController crewCtrl,
  ) {
    final selected = kasir.crewPengirimDipilih.value;
    final hasSelection = selected != null;
    final displayText =
        selected != null ? selected.nama : 'Pilih crew pengirim';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showCrewPengirimSheet(kasir, crewCtrl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasSelection ? const Color(0xFFF0F9FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasSelection ? _primary : const Color(0xFFE2E8F0),
              width: hasSelection ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hasSelection
                      ? _primary.withValues(alpha: 0.12)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasSelection
                      ? Icons.delivery_dining_rounded
                      : Icons.person_search_rounded,
                  color: hasSelection ? _primary : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (hasSelection)
                      Text(
                        selected.noHp,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      )
                    else
                      const Text(
                        'Crew aktif yang bertugas mengantar galon',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCrewPengirimSheet(
    KasirController kasir,
    CrewController crewCtrl,
  ) {
    final query = ''.obs;

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Crew Pengirim',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Pilih crew aktif untuk transaksi dikirim',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => query.value = value.toLowerCase(),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau nomor HP',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Obx(() {
                    final keyword = query.value;
                    final crews =
                        crewCtrl.crewList.where((c) => c.isAktif).where((c) {
                      final q = '${c.nama} ${c.noHp}'.toLowerCase();
                      return keyword.isEmpty || q.contains(keyword);
                    }).toList();

                    if (crews.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Tidak ada crew aktif yang cocok.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: crews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final crew = crews[index];
                        final selected =
                            kasir.crewPengirimDipilih.value?.id == crew.id;
                        return _buildCrewOptionTile(
                          crew: crew,
                          selected: selected,
                          onTap: () {
                            kasir.pilihCrewPengirim(crew);
                            Get.back();
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildCrewOptionTile({
    required Crew crew,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final name = crew.nama;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F9FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: selected
                  ? _primary.withValues(alpha: 0.14)
                  : const Color(0xFFE2E8F0),
              child: Text(
                name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                style: TextStyle(
                  color: selected ? _primary : const Color(0xFF475569),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    crew.noHp,
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: _primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTipeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? _primary.withValues(alpha: 0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _primary : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18, color: selected ? _primary : const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? _primary : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOngkirChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF10B981).withValues(alpha: 0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF10B981) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildProdukByKategori(KasirController kasir) {
    if (kasir.isLoading.value && kasir.produkList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    final kategoriIds = kasir.kategoriList.map((k) => k.id).toSet();
    final sections = <Widget>[];

    for (final kat in kasir.kategoriList) {
      final products =
          kasir.produkList.where((p) => p.kategoriId == kat.id).toList();
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: products.isEmpty
              ? _buildKategoriKosong(kat.nama)
              : products.length > 1
                  ? _buildKategoriGroup(kat.nama, kat.id, products, kasir)
                  : _buildProductCard(products.first, kasir),
        ),
      );
    }

    final lainnya = kasir.produkList
        .where(
            (p) => p.kategoriId.isEmpty || !kategoriIds.contains(p.kategoriId))
        .toList();
    if (lainnya.isNotEmpty) {
      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (kasir.kategoriList.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Lainnya',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ...lainnya.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildProductCard(p, kasir),
              ),
            ),
          ],
        ),
      );
    }

    if (sections.isEmpty && kasir.kategoriList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Belum ada kategori & produk.\n'
          'Manager: buat kategori lalu tambah produk di Harga Produk.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
        ),
      );
    }

    return Column(children: sections);
  }

  Widget _buildKategoriKosong(String nama) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.category_outlined,
              color: _primary.withValues(alpha: 0.7), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B))),
                const Text(
                  'Belum ada produk — tambah di Harga Produk',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKategoriGroup(
    String namaKategori,
    String kategoriId,
    List<Produk> products,
    KasirController kasir,
  ) {
    final expanded = _expandedByKategori[kategoriId] ?? true;
    int totalQty = 0;
    for (final p in products) {
      final k =
          kasir.keranjang.firstWhereOrNull((item) => item.produk.id == p.id);
      totalQty += k?.jumlah ?? 0;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: expanded
                ? _primary.withValues(alpha: 0.3)
                : const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () =>
                setState(() => _expandedByKategori[kategoriId] = !expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: products[0].gambarUrl != null
                        ? Image.network(products[0].gambarUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder())
                        : _buildPlaceholder(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(namaKategori,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text('${products.length} produk',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _primary.withValues(alpha: 0.8))),
                        if (totalQty > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: _primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999)),
                            child: Text('$totalQty item dipilih',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: _primary,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF94A3B8), size: 26),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ...List.generate(products.length, (i) {
                  final p = products[i];
                  final colors = [
                    const Color(0xFF0EA5E9),
                    const Color(0xFF10B981),
                    const Color(0xFF8B5CF6)
                  ];
                  final icons = [
                    Icons.water_drop_outlined,
                    Icons.eco_outlined,
                    Icons.filter_alt_outlined
                  ];
                  final c = colors[i % colors.length];
                  final ic = icons[i % icons.length];
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  color: c.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(ic, color: c, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.nama,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0F172A))),
                                  Text(Formatters.currency(p.harga),
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: c)),
                                ],
                              ),
                            ),
                            _buildQtyControl(p, kasir),
                          ],
                        ),
                      ),
                      if (i < products.length - 1)
                        const Divider(
                            height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                    ],
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.water_drop_rounded, color: _primary, size: 28),
    );
  }

  Widget _buildProductCard(Produk product, KasirController kasir) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: product.gambarUrl != null
                ? Image.network(product.gambarUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder())
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.nama,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(Formatters.currency(product.harga),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primary)),
              ],
            ),
          ),
          _buildQtyControl(product, kasir),
        ],
      ),
    );
  }

  Widget _buildQtyControl(Produk product, KasirController kasir) {
    final keranjangItem =
        kasir.keranjang.firstWhereOrNull((k) => k.produk.id == product.id);
    final qty = keranjangItem?.jumlah ?? 0;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => kasir.kurangiItem(product.id),
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 4,
                      offset: Offset(0, 1))
                ],
              ),
              child: const Icon(Icons.remove_rounded,
                  size: 15, color: Color(0xFF334155)),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text('$qty',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A))),
          ),
          GestureDetector(
            onTap: () => kasir.tambahItem(product),
            child: Container(
              width: 30,
              height: 30,
              decoration:
                  const BoxDecoration(color: _primary, shape: BoxShape.circle),
              child:
                  const Icon(Icons.add_rounded, size: 15, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context, KasirController kasir,
      TransaksiController transaksi) {
    final int total = kasir.totalHarga;
    final int subtotal = kasir.subtotalProduk;
    final int ongkir = kasir.totalOngkir;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ongkir > 0) ...[
                  Text(
                    'Produk ${Formatters.currency(subtotal.toDouble())} + Ongkir ${Formatters.currency(ongkir.toDouble())}',
                    style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                ],
                const Text('TOTAL TAGIHAN',
                    style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
                const SizedBox(height: 2),
                Text(Formatters.currency(total.toDouble()),
                    style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: total > 0
                ? () {
                    if (kasir.pelangganDipilih.value == null ||
                        kasir.pelangganDipilih.value!.id.isEmpty) {
                      Get.snackbar(
                        'Perhatian',
                        kasir.isDikirim
                            ? 'Pilih pelanggan untuk pengiriman galon'
                            : 'Pilih pelanggan sebelum melakukan pembayaran',
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                      );
                      return;
                    }
                    if (kasir.isDikirim &&
                        kasir.crewPengirimDipilih.value == null) {
                      Get.snackbar(
                        'Perhatian',
                        'Pilih crew pengirim untuk transaksi dikirim',
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                      );
                      return;
                    }
                    final items = kasir.keranjang
                        .map((k) => {
                              'produkId': k.produk.id,
                              'jumlah': k.jumlah,
                            })
                        .toList();
                    final pelangganId = kasir.pelangganDipilih.value?.id ?? '';
                    final tipe = kasir.isDikirim ? 'dikirim' : 'diDepo';
                    final ongkirRate =
                        kasir.isDikirim ? kasir.ongkirPerGalon.value : 0;
                    final pengirimCrewId = kasir.crewPengirimDipilih.value?.id;

                    Get.defaultDialog(
                      title: 'Pilih Pembayaran',
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (kasir.isDikirim)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Pengiriman · Ongkir ${Formatters.currency(ongkir.toDouble())}',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ),
                          ListTile(
                            title: const Text('Tunai'),
                            leading: const Icon(Icons.money),
                            onTap: () {
                              Get.back();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                transaksi.buatTransaksi(
                                  pelangganId: pelangganId,
                                  items: items,
                                  metodePembayaran: 'tunai',
                                  tipePembelian: tipe,
                                  ongkirPerGalon: ongkirRate,
                                  pengirimCrewId: pengirimCrewId,
                                );
                              });
                            },
                          ),
                          ListTile(
                            title: const Text('QRIS'),
                            leading: const Icon(Icons.qr_code),
                            onTap: () {
                              Get.back();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                transaksi.buatTransaksi(
                                  pelangganId: pelangganId,
                                  items: items,
                                  metodePembayaran: 'qris',
                                  tipePembelian: tipe,
                                  ongkirPerGalon: ongkirRate,
                                  pengirimCrewId: pengirimCrewId,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: total > 0 ? _primary : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(14),
                boxShadow: total > 0
                    ? const [
                        BoxShadow(
                            color: Color(0x401392EC),
                            blurRadius: 16,
                            offset: Offset(0, 6))
                      ]
                    : [],
              ),
              child: const Row(
                children: [
                  Text('Bayar',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerSheet(BuildContext context,
      PelangganController pelangganCtrl, KasirController kasir) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerSheet(
        customers: pelangganCtrl.pelangganList,
        selected: kasir.pelangganDipilih.value,
        onSelect: (c) {
          kasir.pilihPelanggan(c);
          Navigator.pop(context);
        },
        onAddNew: () {
          Navigator.pop(context);
          _showAddCustomerSheet(context, pelangganCtrl, kasir);
        },
      ),
    );
  }

  void _showAddCustomerSheet(BuildContext context,
      PelangganController pelangganCtrl, KasirController kasir) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCustomerSheet(
        onSave: (data) async {
          final created = await pelangganCtrl.tambahPelanggan(data);
          if (created != null) {
            kasir.pilihPelanggan(created);
            return true;
          }
          return false;
        },
      ),
    );
  }
}
