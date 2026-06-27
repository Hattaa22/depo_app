import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/crew.dart';
import '../services/api_service.dart';
import '../utils/api_error_helper.dart';

class CrewController extends GetxController {
  final ApiService _apiService;
  CrewController(this._apiService);

  final crewList = <Crew>[].obs;
  final isLoading = false.obs;
  final currentPage = 1.obs;
  final totalPage = 1.obs;
  final errorMessage = ''.obs;
  final pengirimanCrewList = <Map<String, dynamic>>[].obs;

  Map<String, dynamic>? pengirimanByCrewId(String crewId) =>
      pengirimanCrewList.firstWhereOrNull((e) => e['crewId'] == crewId);

  Future<void> loadCrew({int page = 1}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _apiService.getSemuaCrew(page, 20, null);
      crewList.value = result.data;
      await loadPengirimanCrew();
      currentPage.value = result.page;
      totalPage.value = result.totalPages;
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPengirimanCrew(
      {String? tanggalMulai, String? tanggalAkhir}) async {
    try {
      pengirimanCrewList.value = await _apiService.getPengirimanCrew(
        tanggalMulai: tanggalMulai,
        tanggalAkhir: tanggalAkhir,
      );
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
    }
  }

  Future<void> tambahCrew(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      await _apiService.createCrew(data);
      Get.snackbar('Berhasil', 'Crew berhasil ditambahkan');
      await loadCrew();
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: Color(0xFFE63946), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editCrew(String id, Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      await _apiService.updateCrew(id, data);
      Get.snackbar('Berhasil', 'Data crew berhasil diperbarui');
      await loadCrew();
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: Color(0xFFE63946), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> hapusCrew(String id) async {
    isLoading.value = true;
    try {
      await _apiService.deleteCrew(id);
      Get.snackbar('Berhasil', 'Crew berhasil dihapus');
      await loadCrew();
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: Color(0xFFE63946), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPasswordCrew(String id) async {
    isLoading.value = true;
    try {
      // Endpoint reset password crew
      await _apiService.updateCrew(id, {'resetPassword': true, 'pin': '1234'});
      Get.snackbar('Berhasil', 'PIN crew berhasil direset ke 1234');
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: Color(0xFFE63946), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }
}
