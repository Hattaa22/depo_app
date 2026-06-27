import 'package:get/get.dart';
import '../models/transaksi.dart';
import '../services/api_service.dart';

class AnalisisController extends GetxController {
  final ApiService _apiService;
  AnalisisController(this._apiService);

  final dashboardData = Rxn<Map<String, dynamic>>();
  final dashboardCrewData = Rxn<Map<String, dynamic>>();
  final chartData = Rxn<Map<String, dynamic>>();
  final ringkasanData = Rxn<LaporanKeuangan>();
  final isLoading = false.obs;
  final isLoadingCrew = false.obs;
  final errorMessage = ''.obs;

  Future<void> loadDashboard() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      dashboardData.value = await _apiService.getDashboardManager();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDashboardCrew() async {
    isLoadingCrew.value = true;
    errorMessage.value = '';
    try {
      dashboardCrewData.value = await _apiService.getDashboardCrew();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoadingCrew.value = false;
    }
  }

  Future<void> loadChart({
    required String periode,
    required int tahun,
    required int bulan,
  }) async {
    isLoading.value = true;
    try {
      dashboardData.value = await _apiService.getDashboardManager();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRingkasan(String tanggalMulai, String tanggalAkhir) async {
    isLoading.value = true;
    try {
      ringkasanData.value = await _apiService.getLaporanKeuangan(tanggalMulai, tanggalAkhir);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
