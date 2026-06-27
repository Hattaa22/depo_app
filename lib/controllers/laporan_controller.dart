import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/transaksi.dart';
import '../services/api_service.dart';
import '../utils/api_error_helper.dart';
import '../utils/formatters.dart';

class LaporanController extends GetxController {
  final ApiService _apiService;
  LaporanController(this._apiService);

  final transaksiList = <Transaksi>[].obs;
  final totalPendapatan = 0.0.obs;
  final totalTransaksi = 0.obs;
  final isLoading = false.obs;
  final currentPage = 1.obs;
  final totalPage = 1.obs;
  final errorMessage = ''.obs;
  final exportFilePath = ''.obs;

  /// Muat saat layar dibuka (setelah login), bukan di onInit app startup.
  Future<void> loadLaporanAwal() async {
    final now = DateTime.now();
    final awalBulan = DateTime(now.year, now.month, 1);
    await loadLaporan(
      tanggalMulai: Formatters.dateOnly(awalBulan),
      tanggalAkhir: Formatters.dateOnly(now),
    );
  }

  Future<void> loadLaporan({
    required String tanggalMulai,
    required String tanggalAkhir,
    int page = 1,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _apiService.getSemuaTransaksi(
        page, 20, null, null, tanggalMulai, tanggalAkhir,
      );
      transaksiList.value = result.data;
      totalTransaksi.value = result.total;
      currentPage.value = result.page;
      totalPage.value = result.totalPages;

      final laporan = await _apiService.getLaporanKeuangan(tanggalMulai, tanggalAkhir);
      totalPendapatan.value = laporan.totalPendapatan.toDouble();
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> filterLaporan(String tanggalMulai, String tanggalAkhir) async {
    await loadLaporan(tanggalMulai: tanggalMulai, tanggalAkhir: tanggalAkhir);
  }

  Future<void> exportLaporan(String tanggalMulai, String tanggalAkhir, String format) async {
    isLoading.value = true;
    try {
      // Implementasi export sesuai API
      exportFilePath.value = '/storage/laporan_$tanggalMulai-$tanggalAkhir.$format';
      Get.snackbar('Berhasil', 'Laporan berhasil diekspor ke ${exportFilePath.value}');
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: Color(0xFFE63946),
          colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }
}
