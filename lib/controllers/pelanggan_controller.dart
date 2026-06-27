import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/pelanggan.dart';
import '../services/api_service.dart';
import '../utils/api_error_helper.dart';

class PelangganController extends GetxController {
  final ApiService _apiService;
  PelangganController(this._apiService);

  final pelangganList = <Pelanggan>[].obs;
  final pelangganDetail = Rxn<Pelanggan>();
  final isLoading = false.obs;
  final currentPage = 1.obs;
  final totalPage = 1.obs;

  /// Error saat memuat daftar (bukan saat tambah/edit).
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPelanggan();
  }

  Future<void> loadPelanggan({int page = 1}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _apiService.getSemuaPelanggan(page, 20, null);
      pelangganList.value = result.data;
      currentPage.value = result.page;
      totalPage.value = result.totalPages;
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cariPelanggan(String keyword) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _apiService.getSemuaPelanggan(1, 20, keyword);
      pelangganList.value = result.data;
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Menyimpan pelanggan baru. Mengembalikan data jika sukses, null jika gagal.
  Future<Pelanggan?> tambahPelanggan(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      final created = await _apiService.createPelanggan({
        'nama': (data['nama'] ?? '').toString().trim(),
        'noHp': (data['noHp'] ?? '').toString().trim(),
        'alamat': (data['alamat'] ?? '').toString().trim(),
        if (data['catatan'] != null) 'catatan': data['catatan'],
      });
      Get.snackbar(
        'Berhasil',
        'Pelanggan berhasil ditambahkan',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
      await loadPelanggan();
      return created;
    } catch (e) {
      Get.snackbar(
        'Gagal menyimpan',
        ApiErrorHelper.message(e),
        backgroundColor: const Color(0xFFE63946),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> editPelanggan(String id, Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      await _apiService.updatePelanggan(id, data);
      Get.snackbar(
        'Berhasil',
        'Data pelanggan berhasil diperbarui',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
      await loadPelanggan();
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal menyimpan',
        ApiErrorHelper.message(e),
        backgroundColor: const Color(0xFFE63946),
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> hapusPelanggan(String id) async {
    isLoading.value = true;
    try {
      await _apiService.deletePelanggan(id);
      Get.snackbar(
        'Berhasil',
        'Pelanggan berhasil dihapus',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
      await loadPelanggan();
    } catch (e) {
      Get.snackbar(
        'Gagal menghapus',
        ApiErrorHelper.message(e),
        backgroundColor: const Color(0xFFE63946),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDetail(String id) async {
    isLoading.value = true;
    try {
      pelangganDetail.value = await _apiService.getPelangganById(id);
    } catch (e) {
      Get.snackbar(
        'Error',
        ApiErrorHelper.message(e),
        backgroundColor: const Color(0xFFE63946),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
