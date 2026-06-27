import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/cabang.dart';
import '../services/api_service.dart';
import '../utils/api_error_helper.dart';

class CabangController extends GetxController {
  final ApiService _apiService;
  CabangController(this._apiService);

  final cabangList = <CabangDepo>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  int get totalCabang => cabangList.where((c) => c.isAktif).length;

  CabangDepo? get cabangPusat {
    for (final c in cabangList) {
      if (c.isPusat) return c;
    }
    return null;
  }

  Future<void> loadCabang() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      cabangList.value = await _apiService.getSemuaCabang();
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> tambahCabang(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      await _apiService.createCabang(data);
      Get.snackbar(
        'Berhasil',
        'Cabang baru berhasil ditambahkan',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
      await loadCabang();
      return true;
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: const Color(0xFFE63946), colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> editCabang(String id, Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      await _apiService.updateCabang(id, data);
      Get.snackbar(
        'Berhasil',
        'Data cabang diperbarui',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
      await loadCabang();
      return true;
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: const Color(0xFFE63946), colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> hapusCabang(String id) async {
    isLoading.value = true;
    try {
      await _apiService.deleteCabang(id);
      Get.snackbar(
        'Berhasil',
        'Cabang dinonaktifkan',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
      await loadCabang();
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: const Color(0xFFE63946), colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
