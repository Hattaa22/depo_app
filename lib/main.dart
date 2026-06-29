import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';
import 'config/app_theme.dart';
import 'config/constants.dart';
import 'config/routes.dart';
import 'controllers/cabang_controller.dart';
import 'controllers/analisis_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/crew_controller.dart';
import 'controllers/crew_main_controller.dart';
import 'controllers/galon_controller.dart';
import 'controllers/kasir_controller.dart';
import 'controllers/laporan_controller.dart';
import 'controllers/pelanggan_controller.dart';
import 'controllers/produk_controller.dart';
import 'controllers/pengeluaran_controller.dart';
import 'controllers/transaksi_controller.dart';
import 'services/api_interceptor.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/local_storage.dart';
import 'utils/formatters.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Formatters.init();
  if (kDebugMode) {
    debugPrint('Depo API baseUrl: ${ApiConfig.baseUrl}');
  }

  // Inisialisasi async dependencies sebelum runApp
  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  final localStorage = LocalStorage(prefs, secureStorage);

  // Dio & ApiService
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
    receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));
  dio.interceptors.add(ApiInterceptor(localStorage));
  final apiService = ApiService(dio);
  final authService = AuthService(apiService, localStorage);

  // Daftarkan semua dependency ke GetX
  Get.put<LocalStorage>(localStorage, permanent: true);
  Get.put<Dio>(dio, permanent: true);
  Get.put<ApiService>(apiService, permanent: true);
  Get.put<AuthService>(authService, permanent: true);
  Get.put<AuthController>(
    AuthController(authService),
    permanent: true,
  );
  Get.put<CrewMainController>(
    CrewMainController(),
    permanent: true,
  );
  Get.put<TransaksiController>(
    TransaksiController(apiService),
    permanent: true,
  );
  Get.put<KasirController>(
    KasirController(apiService),
    permanent: true,
  );
  Get.put<PelangganController>(
    PelangganController(apiService),
    permanent: true,
  );
  Get.put<GalonController>(
    GalonController(apiService),
    permanent: true,
  );
  Get.put<AnalisisController>(
    AnalisisController(apiService),
    permanent: true,
  );
  Get.put<CrewController>(
    CrewController(apiService),
    permanent: true,
  );
  Get.put<LaporanController>(
    LaporanController(apiService),
    permanent: true,
  );
  Get.put<ProdukController>(
    ProdukController(apiService),
    permanent: true,
  );
  Get.put<PengeluaranController>(
    PengeluaranController(apiService),
    permanent: true,
  );
  Get.put<CabangController>(
    CabangController(apiService),
    permanent: true,
  );

  runApp(const DepoAirApp());
}

class DepoAirApp extends StatelessWidget {
  const DepoAirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Depo Air',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Tidak perlu initialBinding lagi karena sudah di-register di main()
      initialRoute: AppRoutes.pilihPeran,
      getPages: AppRoutes.pages,
      unknownRoute: GetPage(
        name: '/not-found',
        page: () {
          final currentRoute = Get.currentRoute;
          return RouteNotFoundScreen(routeName: currentRoute);
        },
      ),
    );
  }
}
