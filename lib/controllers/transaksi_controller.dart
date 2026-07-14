import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/galon_controller.dart';
import '../models/transaksi.dart';
import '../services/api_service.dart';
import '../utils/api_error_helper.dart';
import '../widgets/manager_nav_helper.dart';

class TransaksiController extends GetxController {
  final ApiService _apiService;
  TransaksiController(this._apiService);

  final transaksiList = <Transaksi>[].obs;
  final transaksiDetail = Rxn<Transaksi>();
  final transaksiTerbaru = Rxn<Transaksi>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  void _showSnackbar(
    String title,
    String message, {
    Color? backgroundColor,
    Color? colorText,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        title,
        message,
        backgroundColor: backgroundColor,
        colorText: colorText,
      );
    });
  }

  Future<void> loadTransaksi({
    int page = 1,
    String? status,
    String? crewId,
    String? tanggalMulai,
    String? tanggalAkhir,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _apiService.getSemuaTransaksi(
        page,
        20,
        status,
        crewId,
        tanggalMulai,
        tanggalAkhir,
      );
      transaksiList.value = result.data;
    } catch (e) {
      errorMessage.value = e.toString();
      transaksiList.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> buatTransaksi({
    required String pelangganId,
    required List<Map<String, dynamic>> items,
    required String metodePembayaran,
    String tipePembelian = 'diDepo',
    int ongkirPerGalon = 0,
    String? pengirimCrewId,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final crewId =
          Get.find<AuthController>().userData['id']?.toString() ?? '';
      final result = await _apiService.createTransaksi({
        'pelangganId': pelangganId,
        'items': items,
        'metodePembayaran': metodePembayaran,
        'crewId': crewId,
        'tipePembelian': tipePembelian == 'dikirim' ? 'dikirim' : 'diDepo',
        'ongkirPerGalon': ongkirPerGalon,
        if (pengirimCrewId != null && pengirimCrewId.isNotEmpty)
          'pengirimCrewId': pengirimCrewId,
      });
      transaksiTerbaru.value = result;
      await loadTransaksi(crewId: crewId);
      if (Get.isRegistered<GalonController>()) {
        final galon = Get.find<GalonController>();
        await galon.loadSummary();
        await galon.loadGalon();
      }
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      _showSnackbar('Error', errorMessage.value,
          backgroundColor: const Color(0xFFE63946),
          colorText: const Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> validasiTransaksi(String transaksiId, String status,
      {String? reloadStatus}) async {
    isLoading.value = true;
    try {
      final apiStatus = status == AppConstants.validasiSukses ||
              status == AppConstants.statusSelesai
          ? AppConstants.validasiSukses
          : AppConstants.validasiGagal;
      await _apiService.validasiTransaksi(transaksiId, {'status': apiStatus});
      _showSnackbar('Berhasil', 'Transaksi berhasil divalidasi');
      await loadTransaksi(status: reloadStatus);
      ManagerNavHelper.refreshHomeData();
      ManagerNavHelper.refreshLaporanData();
      if (Get.isRegistered<GalonController>()) {
        final galon = Get.find<GalonController>();
        await galon.loadSummary();
        await galon.loadGalon();
      }
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      _showSnackbar('Error', errorMessage.value,
          backgroundColor: Color(0xFFE63946), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDetail(String transaksiId) async {
    isLoading.value = true;
    try {
      transaksiDetail.value = await _apiService.getTransaksiById(transaksiId);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void reset() {
    transaksiList.clear();
    transaksiDetail.value = null;
    transaksiTerbaru.value = null;
    errorMessage.value = '';
  }
}
