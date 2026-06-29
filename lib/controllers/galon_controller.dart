import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/galon.dart';
import '../services/api_service.dart';
import '../utils/api_error_helper.dart';

class GalonController extends GetxController {
  final ApiService _apiService;
  GalonController(this._apiService);

  final galonList = <Galon>[].obs;
  final summary = Rxn<RingkasanGalon>();
  final isLoading = false.obs;
  final currentPage = 1.obs;
  final totalPage = 1.obs;
  final errorMessage = ''.obs;
  final isFetchingMore = false.obs;
  String? _lastStatusFilter;

  @override
  void onInit() {
    super.onInit();
    loadGalon();
    loadSummary();
  }

  Future<void> loadGalon({int page = 1, String? status, bool refresh = true}) async {
    _lastStatusFilter = status;
    
    if (refresh) {
      isLoading.value = true;
      galonList.clear();
      currentPage.value = 1;
    } else {
      isFetchingMore.value = true;
    }
    
    errorMessage.value = '';
    
    try {
      final result = await _apiService.getSemuaGalon(page, 20, status);
      
      if (refresh) {
        galonList.value = result.data;
      } else {
        galonList.addAll(result.data);
      }
      
      currentPage.value = result.page;
      totalPage.value = result.totalPages;
    } catch (e) {
      if (refresh) {
        errorMessage.value = ApiErrorHelper.message(e);
      } else {
        Get.snackbar('Error', 'Gagal memuat lebih banyak galon: ${ApiErrorHelper.message(e)}');
      }
    } finally {
      if (refresh) {
        isLoading.value = false;
      } else {
        isFetchingMore.value = false;
      }
    }
  }

  void loadMore() {
    if (!isLoading.value && !isFetchingMore.value && currentPage.value < totalPage.value) {
      loadGalon(page: currentPage.value + 1, status: _lastStatusFilter, refresh: false);
    }
  }

  Future<void> catatGalon(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      final result = await _apiService.createGalon(data);
      final createdCount = result['createdCount'] as int? ?? 1;

      if (createdCount > 1) {
        Get.snackbar(
          'Berhasil',
          '$createdCount galon berhasil dicatat dengan kode otomatis',
          backgroundColor: const Color(0xFF10B981),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar('Berhasil', 'Galon berhasil dicatat');
      }

      await loadGalon();
      await loadSummary();
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: const Color(0xFFE63946),
          colorText: const Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateStatusGalon(String id, String status) async {
    isLoading.value = true;
    try {
      await _apiService.updateGalon(id, {'status': status});
      Get.snackbar('Berhasil', 'Status galon berhasil diperbarui');
      await loadGalon();
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: const Color(0xFFE63946),
          colorText: const Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> pinjamGalon(int jumlah,
      {String? pelangganId, DateTime? tanggal}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      summary.value = await _apiService.pinjamGalon(
        jumlah,
        pelangganId: pelangganId,
        tanggal: tanggal,
      );
      Get.snackbar('Berhasil', 'Berhasil mencatat pinjaman $jumlah galon',
          backgroundColor: const Color(0xFF1392EC),
          colorText: const Color(0xFFFFFFFF));
      // Reload semua data untuk update daftar dan rekap
      await loadGalon(page: currentPage.value, status: _lastStatusFilter);
      await loadSummary();
      return true;
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: const Color(0xFFE63946),
          colorText: const Color(0xFFFFFFFF));
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> kembalikanGalon(int jumlah,
      {String? pelangganId, DateTime? tanggal}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      summary.value = await _apiService.kembalikanGalon(
        jumlah,
        pelangganId: pelangganId,
        tanggal: tanggal,
      );
      Get.snackbar('Berhasil', 'Berhasil mencatat pengembalian $jumlah galon',
          backgroundColor: const Color(0xFF10B981),
          colorText: const Color(0xFFFFFFFF));
      // Reload semua data untuk update daftar dan rekap
      await loadGalon(page: currentPage.value, status: _lastStatusFilter);
      await loadSummary();
      return true;
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: const Color(0xFFE63946),
          colorText: const Color(0xFFFFFFFF));
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadSummary() async {
    try {
      summary.value = await _apiService.getRingkasanGalon();
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
    }
  }
}
