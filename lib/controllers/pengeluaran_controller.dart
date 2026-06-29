import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/pengeluaran.dart';
import '../models/produk.dart';
import '../services/api_service.dart';
import '../utils/api_error_helper.dart';

class PengeluaranController extends GetxController {
  final ApiService _apiService;
  PengeluaranController(this._apiService);

  final pengeluaranList = <Pengeluaran>[].obs;
  final kategoriList = <KategoriProduk>[].obs; // Hanya untuk tipe pengeluaran
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadKategoriPengeluaran();
  }

  Future<void> loadPengeluaran() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final list = await _apiService.getSemuaPengeluaran();
      pengeluaranList.value = list;
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadKategoriPengeluaran() async {
    try {
      final allKategori = await _apiService.getSemuaKategori();
      kategoriList.value =
          allKategori.where((k) => k.tipe == 'pengeluaran').toList();
    } catch (e) {
      debugPrint('Gagal memuat kategori pengeluaran: $e');
    }
  }

  Future<bool> tambahPengeluaran(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      await _apiService.createPengeluaran(data);
      Get.snackbar(
        'Berhasil',
        'Pengeluaran berhasil dicatat',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
      await loadPengeluaran();
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        ApiErrorHelper.message(e),
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> hapusPengeluaran(String id) async {
    isLoading.value = true;
    try {
      await _apiService.deletePengeluaran(id);
      Get.snackbar(
        'Berhasil',
        'Pengeluaran berhasil dihapus',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
      await loadPengeluaran();
    } catch (e) {
      Get.snackbar(
        'Error',
        ApiErrorHelper.message(e),
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
