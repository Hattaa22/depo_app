import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../controllers/auth_controller.dart';
import '../controllers/kasir_controller.dart';
import '../controllers/transaksi_controller.dart';
import '../controllers/pelanggan_controller.dart';
import '../controllers/galon_controller.dart';
import '../controllers/analisis_controller.dart';
import '../controllers/crew_controller.dart';
import '../controllers/laporan_controller.dart';
import '../controllers/produk_controller.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/local_storage.dart';
import '../config/constants.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // LocalStorage
    Get.putAsync<LocalStorage>(() async {
      final prefs = await SharedPreferences.getInstance();
      const secureStorage = FlutterSecureStorage();
      return LocalStorage(prefs, secureStorage);
    }, permanent: true);

    // Dio & ApiService
    Get.lazyPut<Dio>(() {
      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      ));
      return dio;
    }, fenix: true);

    Get.lazyPut<ApiService>(
      () => ApiService(Get.find<Dio>()),
      fenix: true,
    );

    // AuthService
    Get.lazyPut<AuthService>(
      () => AuthService(Get.find<ApiService>(), Get.find<LocalStorage>()),
      fenix: true,
    );

    // Controllers
    Get.lazyPut<AuthController>(
      () => AuthController(Get.find<AuthService>()),
      fenix: true,
    );

    Get.lazyPut<KasirController>(
      () => KasirController(Get.find<ApiService>()),
      fenix: true,
    );

    Get.lazyPut<TransaksiController>(
      () => TransaksiController(Get.find<ApiService>()),
      fenix: true,
    );

    Get.lazyPut<PelangganController>(
      () => PelangganController(Get.find<ApiService>()),
      fenix: true,
    );

    Get.lazyPut<GalonController>(
      () => GalonController(Get.find<ApiService>()),
      fenix: true,
    );

    Get.lazyPut<AnalisisController>(
      () => AnalisisController(Get.find<ApiService>()),
      fenix: true,
    );

    Get.lazyPut<CrewController>(
      () => CrewController(Get.find<ApiService>()),
      fenix: true,
    );

    Get.lazyPut<LaporanController>(
      () => LaporanController(Get.find<ApiService>()),
      fenix: true,
    );

    Get.lazyPut<ProdukController>(
      () => ProdukController(Get.find<ApiService>()),
      fenix: true,
    );
  }
}
