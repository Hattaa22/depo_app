import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/produk_controller.dart';
import '../../../config/routes.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/header_back_button.dart';

class DataProdukScreen extends StatefulWidget {
  const DataProdukScreen({super.key});

  @override
  State<DataProdukScreen> createState() => _DataProdukScreenState();
}

class _DataProdukScreenState extends State<DataProdukScreen> {
  static const Color _primary = Color(0xFF1392EC);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final produk = Get.find<ProdukController>();
      produk.loadKategori();
      produk.loadProduk();
    });
  }

  @override
  Widget build(BuildContext context) {
    final produk = Get.find<ProdukController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          // ── HEADER ──────────────────────────────────────────────────────────
          _buildHeader(context),

          // ── LIST ────────────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (produk.isLoading.value) {
                return const Center(
                    child: CircularProgressIndicator(color: _primary));
              }
              if (produk.errorMessage.value.isNotEmpty) {
                return Center(child: Text(produk.errorMessage.value));
              }
              if (produk.produkList.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 56, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 12),
                      Text('Belum ada produk',
                          style: TextStyle(
                              fontSize: 14, color: Color(0xFF94A3B8))),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: produk.produkList.length,
                itemBuilder: (_, i) {
                  final p = produk.produkList[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.inventory_2_outlined,
                              color: _primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nama,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.currency(p.harga),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'hapus') {
                              produk.hapusProduk(p.id);
                            }
                            if (val == 'edit') {
                              _showEditDialog(produk, p.id, p.nama, p.harga);
                            }
                          },
                          icon: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.more_vert_rounded,
                                color: Color(0xFF94A3B8), size: 20),
                          ),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Produk'),
                              ]),
                            ),
                            const PopupMenuItem(
                              value: 'hapus',
                              child: Row(children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: Color(0xFFEF4444)),
                                SizedBox(width: 8),
                                Text('Hapus',
                                    style: TextStyle(color: Color(0xFFEF4444))),
                              ]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          onPressed: () => _showTambahDialog(produk),
          backgroundColor: _primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Tambah Produk',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1392EC), Color(0xFF0B76C4)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          const HeaderBackButton(
            fallbackRoute: AppRoutes.managerSettings,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harga Produk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Kelola daftar produk & harga',
                  style: TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTambahDialog(ProdukController produk) {
    if (produk.kategoriList.isEmpty) {
      Get.snackbar(
        'Kategori kosong',
        'Buat kategori dulu di menu Kategori Keuangan',
        backgroundColor: const Color(0xFFE63946),
        colorText: Colors.white,
      );
      return;
    }

    final namaCtrl = TextEditingController();
    final hargaCtrl = TextEditingController();
    final kategoriId = produk.kategoriList.first.id.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tambah Produk',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 20),
              Obx(() => DropdownButtonFormField<String>(
                    initialValue: kategoriId.value,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: const Icon(Icons.category_outlined,
                          color: Color(0xFF94A3B8), size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    items: produk.kategoriList
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
              _field(namaCtrl, 'Nama Produk', Icons.inventory_2_outlined),
              const SizedBox(height: 12),
              _field(hargaCtrl, 'Harga', Icons.payments_outlined,
                  type: TextInputType.number),
              const SizedBox(height: 24),
              _dialogButtons(
                onCancel: () => Get.back(),
                onConfirm: () async {
                  final nama = namaCtrl.text.trim();
                  if (nama.isEmpty) {
                    Get.snackbar('Error', 'Nama produk wajib diisi',
                        backgroundColor: const Color(0xFFE63946),
                        colorText: Colors.white);
                    return;
                  }
                  Get.back();
                  await produk.tambahProduk({
                    'nama': nama,
                    'kategoriId': kategoriId.value,
                    'harga': int.tryParse(hargaCtrl.text) ?? 0,
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
      ProdukController produk, String id, String namaSaat, num hargaSaat) {
    final namaCtrl = TextEditingController(text: namaSaat);
    final hargaCtrl = TextEditingController(text: '$hargaSaat');
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Produk',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 20),
              _field(namaCtrl, 'Nama Produk', Icons.inventory_2_outlined),
              const SizedBox(height: 12),
              _field(hargaCtrl, 'Harga', Icons.payments_outlined,
                  type: TextInputType.number),
              const SizedBox(height: 24),
              _dialogButtons(
                onCancel: () => Get.back(),
                onConfirm: () async {
                  final nama = namaCtrl.text.trim();
                  if (nama.isEmpty) {
                    Get.snackbar('Error', 'Nama produk wajib diisi',
                        backgroundColor: const Color(0xFFE63946),
                        colorText: Colors.white);
                    return;
                  }
                  Get.back();
                  await produk.editProduk(id, {
                    'nama': nama,
                    'harga': int.tryParse(hargaCtrl.text) ?? 0,
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
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

  Widget _dialogButtons(
      {required VoidCallback onCancel, required VoidCallback onConfirm}) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
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
            onPressed: onConfirm,
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
