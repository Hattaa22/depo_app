import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/pengeluaran_controller.dart';
import '../../../models/pengeluaran.dart';
import '../../../config/routes.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/header_back_button.dart';

class DataPengeluaranScreen extends StatefulWidget {
  const DataPengeluaranScreen({super.key});

  @override
  State<DataPengeluaranScreen> createState() => _DataPengeluaranScreenState();
}

class _DataPengeluaranScreenState extends State<DataPengeluaranScreen> {
  static const Color _primary = Color(0xFF1392EC);
  static const Color _primaryDark = Color(0xFF0B5FA0);
  static const Color _danger = Color(0xFFEF4444);

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
      final controller = Get.find<PengeluaranController>();
      controller.loadKategoriPengeluaran();
      controller.loadPengeluaran();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PengeluaranController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.pengeluaranList.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: _primary),
                );
              }
              if (controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                );
              }
              if (controller.pengeluaranList.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payments_outlined,
                          size: 64, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada catatan pengeluaran',
                        style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadPengeluaran,
                color: _primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  itemCount: controller.pengeluaranList.length,
                  itemBuilder: (_, i) {
                    final item = controller.pengeluaranList[i];
                    return _buildExpenseItem(item, controller);
                  },
                ),
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
            onPressed: () => _showTambahDialog(context, controller),
            icon: const Icon(Icons.add_circle_rounded,
                color: Colors.white, size: 20),
            label: const Text(
              'Catat Pengeluaran Baru',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
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

  Widget _buildHeader(BuildContext context) {
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
          colors: [_primary, _primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          const HeaderBackButton(fallbackRoute: AppRoutes.managerDashboard),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catat Pengeluaran',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Pencatatan gaji, listrik, sewa tempat, dll',
                  style: TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            final controller = Get.find<PengeluaranController>();
            if (controller.pengeluaranList.isNotEmpty) {
              final total = controller.pengeluaranList
                  .fold<double>(0, (sum, item) => sum + item.nominal);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  Formatters.currency(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }
            return const SizedBox();
          }),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Pengeluaran item, PengeluaranController controller) {
    // Cari ikon kategori (dummy default jika tidak ketemu)
    // Di backend, kategori dicari berdasarkan kategoriId
    final kat = controller.kategoriList
        .firstWhereOrNull((k) => k.id == item.kategoriId);
    final iconName = kat?.ikon ?? 'payments';
    final iconData = _iconMap[iconName] ?? Icons.payments_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, color: _danger, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.keterangan.isNotEmpty
                      ? item.keterangan
                      : 'Pengeluaran tanpa catatan',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item.kategoriNama ?? 'Pengeluaran',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _danger.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('•',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    const SizedBox(width: 6),
                    Text(
                      Formatters.date(item.tanggal),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${Formatters.currency(item.nominal)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _danger,
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => _confirmDelete(item.id, controller),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFF94A3B8),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTambahDialog(
      BuildContext context, PengeluaranController controller) {
    if (controller.kategoriList.isEmpty) {
      Get.snackbar(
        'Kategori Kosong',
        'Harap buat kategori pengeluaran terlebih dahulu di menu Kategori Keuangan',
        backgroundColor: _danger,
        colorText: Colors.white,
      );
      return;
    }

    final nominalCtrl = TextEditingController();
    final keteranganCtrl = TextEditingController();
    final tanggalCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final kategoriId = controller.kategoriList.first.id.obs;
    DateTime tanggalTerpilih = DateTime.now();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catat Pengeluaran Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 20),

                // Dropdown Kategori
                Obx(() => DropdownButtonFormField<String>(
                      initialValue: kategoriId.value,
                      decoration: InputDecoration(
                        labelText: 'Kategori Pengeluaran',
                        prefixIcon: const Icon(Icons.pie_chart_outline_rounded,
                            color: Color(0xFF94A3B8), size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      items: controller.kategoriList
                          .map((k) => DropdownMenuItem(
                                value: k.id,
                                child: Text(k.nama),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) kategoriId.value = v;
                      },
                    )),
                const SizedBox(height: 12),

                // Input Nominal
                TextField(
                  controller: nominalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nominal (Rp)',
                    prefixIcon: const Icon(Icons.payments_outlined,
                        color: Color(0xFF94A3B8), size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 12),

                // Input Tanggal
                TextField(
                  controller: tanggalCtrl,
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tanggalTerpilih,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      tanggalTerpilih = picked;
                      tanggalCtrl.text =
                          picked.toIso8601String().substring(0, 10);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Tanggal',
                    prefixIcon: const Icon(Icons.calendar_today_rounded,
                        color: Color(0xFF94A3B8), size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 12),

                // Input Keterangan
                TextField(
                  controller: keteranganCtrl,
                  decoration: InputDecoration(
                    labelText: 'Keterangan/Catatan',
                    prefixIcon: const Icon(Icons.notes_rounded,
                        color: Color(0xFF94A3B8), size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Dialog
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
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final nominalStr = nominalCtrl.text.trim();
                          final nominal = double.tryParse(nominalStr) ?? 0;
                          final keterangan = keteranganCtrl.text.trim();

                          if (nominal <= 0) {
                            Get.snackbar(
                              'Error',
                              'Nominal harus diisi dengan angka lebih dari 0',
                              backgroundColor: _danger,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          if (keterangan.isEmpty) {
                            Get.snackbar(
                              'Error',
                              'Keterangan pengeluaran wajib diisi',
                              backgroundColor: _danger,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          Get.back();
                          await controller.tambahPengeluaran({
                            'kategoriId': kategoriId.value,
                            'nominal': nominal,
                            'keterangan': keterangan,
                            'tanggal': tanggalCtrl.text,
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
                        child: const Text(
                          'Simpan',
                          style: TextStyle(fontWeight: FontWeight.w700),
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
    );
  }

  void _confirmDelete(String id, PengeluaranController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Catatan',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Apakah Anda yakin ingin menghapus catatan pengeluaran ini?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal',
                style: TextStyle(
                    color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.hapusPengeluaran(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Hapus',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
