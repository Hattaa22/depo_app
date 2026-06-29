import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/routes.dart';
import '../utils/api_error_helper.dart';

class AuthController extends GetxController {
  final AuthService _authService;

  AuthController(this._authService);

  final isLoading = false.obs;
  final isAuthenticated = false.obs;
  final token = ''.obs;
  final role = ''.obs;
  final userData = <String, dynamic>{}.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      final savedRole = await _authService.getCurrentRole();
      final savedUser = await _authService.getSavedUserData();
      role.value = savedRole ?? '';
      if (savedUser != null) userData.value = savedUser;
      isAuthenticated.value = true;
    }
  }

  Future<bool> _pastikanServerOnline() async {
    final api = Get.find<ApiService>();
    final ok = await api.cekKoneksiServer();
    if (!ok) {
      Get.snackbar(
        'Server tidak terjangkau',
        ApiErrorHelper.connectionHelp(),
        backgroundColor: const Color(0xFFE63946),
        colorText: Colors.white,
        duration: const Duration(seconds: 8),
      );
    }
    return ok;
  }

  Future<void> loginCrew(String username, String password) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      if (!await _pastikanServerOnline()) return;
      final response = await _authService.loginCrew(username, password);
      token.value = response.accessToken;
      role.value = response.role;
      userData.value = response.userData;
      isAuthenticated.value = true;
      Get.offAllNamed(AppRoutes.crewDashboard);
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar(
        'Gagal login',
        errorMessage.value,
        backgroundColor: const Color(0xFFE63946),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 6),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginManager(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      if (!await _pastikanServerOnline()) return;
      final response = await _authService.loginManager(email, password);
      token.value = response.accessToken;
      role.value = response.role;
      userData.value = response.userData;
      isAuthenticated.value = true;
      Get.offAllNamed(AppRoutes.managerDashboard);
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar(
        'Gagal login',
        errorMessage.value,
        backgroundColor: const Color(0xFFE63946),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 6),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      await _authService.logout();
    } finally {
      token.value = '';
      role.value = '';
      userData.value = {};
      isAuthenticated.value = false;
      isLoading.value = false;
      Get.offAllNamed(AppRoutes.pilihPeran);
    }
  }

  Future<bool> changePassword(String passwordLama, String passwordBaru) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      if (!await _pastikanServerOnline()) return false;
      final api = Get.find<ApiService>();
      await api.changePassword(passwordLama, passwordBaru);
      return true;
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar(
        'Gagal mengubah password',
        errorMessage.value,
        backgroundColor: const Color(0xFFE63946),
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> changePin(String pinLama, String pinBaru) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      if (!await _pastikanServerOnline()) return false;
      final api = Get.find<ApiService>();
      await api.changePin(pinLama, pinBaru);
      return true;
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar(
        'Gagal mengubah PIN',
        errorMessage.value,
        backgroundColor: const Color(0xFFE63946),
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> changeProfile(String nama) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      if (!await _pastikanServerOnline()) return false;
      final api = Get.find<ApiService>();
      await api.changeProfile(nama);
      
      // Update local userData
      userData['nama'] = nama;
      await _authService.saveUserData(userData);
      
      return true;
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar(
        'Gagal mengubah profil',
        errorMessage.value,
        backgroundColor: const Color(0xFFE63946),
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
