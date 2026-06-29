import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/crew_main_controller.dart';
import '../features/auth/login_peran_screen.dart';
import '../features/auth/login_crew_screen.dart';
import '../features/auth/login_manager_screen.dart';
import '../features/crew/dashboard/crew_main_screen.dart';
import '../features/crew/dashboard/pembayaran_qr.dart';
import '../features/crew/dashboard/data_pelanggan.dart';
import '../features/manager/dashboard/managerdashboard_screen.dart';
import '../features/manager/dashboard/data_pelanggan.dart';
import '../features/manager/dashboard/laporan_transaksi.dart';
import '../features/manager/dashboard/analisis_keuangan.dart';
import '../features/manager/dashboard/data_crew.dart';
import '../features/manager/report/analisis_keuangan.dart' as report;
import '../features/manager/inventory/asset_galon.dart';
import '../features/manager/setting/data_produk.dart';
import '../features/manager/setting/validasi_transaksi.dart';
import '../features/manager/setting/data_kategori.dart';
import '../features/manager/setting/data_pengeluaran.dart';
import '../features/manager/setting/data_crew.dart' as setting;
import '../features/manager/setting/manager_settings_screen.dart';
import '../features/manager/setting/cabang_depo_screen.dart';

// Route error handler widget
class RouteNotFoundScreen extends StatelessWidget {
  final String routeName;
  const RouteNotFoundScreen({super.key, required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Error'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              const Text(
                'Route Tidak Ditemukan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Route: $routeName',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1392EC),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppRoutes {
  static const String pilihPeran = '/';
  static const String loginCrew = '/login/crew';
  static const String loginManager = '/login/manager';

  // Crew
  static const String crewDashboard = '/crew/dashboard';
  static const String crewKasir = '/crew/kasir';
  static const String crewTransaksi = '/crew/transaksi';
  static const String crewPembayaranQr = '/crew/pembayaran-qr';
  static const String crewDataPelanggan = '/crew/pelanggan';
  static const String crewRiwayat = '/crew/riwayat';
  static const String crewGalon = '/crew/galon';
  static const String crewPengaturan = '/crew/pengaturan';

  // Manager
  static const String managerDashboard = '/manager/dashboard';
  static const String managerDataPelanggan = '/manager/pelanggan';
  static const String managerLaporan = '/manager/laporan';
  static const String managerAnalisis = '/manager/analisis';
  static const String managerDataCrew = '/manager/crew';
  static const String managerAnalisisReport = '/manager/report/analisis';
  static const String managerAssetGalon = '/manager/inventory/galon';
  static const String managerSettings = '/manager/pengaturan';
  static const String managerDataProduk = '/manager/setting/produk';
  static const String managerValidasiTransaksi = '/manager/setting/validasi';
  static const String managerDataKategori = '/manager/setting/kategori';
  static const String managerSettingCrew = '/manager/setting/crew';
  static const String managerDataPengeluaran = '/manager/setting/pengeluaran';
  static const String managerCabangDepo = '/manager/setting/cabang';

  static GetPage _crewShellPage(String name, int tabIndex) {
    return GetPage(
      name: name,
      page: () {
        Get.find<CrewMainController>().changeTab(tabIndex);
        return const CrewMainScreen();
      },
    );
  }

  static List<GetPage> get pages => [
        GetPage(name: pilihPeran, page: () => const PilihPeranScreen()),
        GetPage(name: loginCrew, page: () => const LoginCrewScreen()),
        GetPage(name: loginManager, page: () => const LoginManagerScreen()),

        // Crew Routes
        _crewShellPage(crewDashboard, 0),
        _crewShellPage(crewKasir, CrewMainController.tabKasir),
        _crewShellPage(crewTransaksi, 1),
        GetPage(
          name: crewPembayaranQr,
          page: () {
            final args = Get.arguments as Map<String, dynamic>? ?? {};
            return PembayaranQrScreen(
              totalHarga: args['totalHarga'] ?? 0,
              transaksiId: args['transaksiId'] ?? '',
            );
          },
        ),
        GetPage(
            name: crewDataPelanggan,
            page: () => const CrewDataPelangganScreen()),
        _crewShellPage(crewRiwayat, 1),
        _crewShellPage(crewGalon, 3),
        _crewShellPage(crewPengaturan, 4),

        // Manager Routes
        GetPage(
            name: managerDashboard, page: () => const ManagerDashboardScreen()),
        GetPage(
            name: managerDataPelanggan,
            page: () => const ManagerDataPelangganScreen()),
        GetPage(
            name: managerLaporan, page: () => const LaporanTransaksiScreen()),
        GetPage(
            name: managerAnalisis, page: () => const AnalisisKeuanganScreen()),
        GetPage(name: managerDataCrew, page: () => const DataCrewScreen()),
        GetPage(
            name: managerAnalisisReport,
            page: () => const report.AnalisisKeuanganReportScreen()),
        GetPage(name: managerAssetGalon, page: () => const AssetGalonScreen()),
        GetPage(
          name: managerSettings,
          page: () => const ManagerSettingsScreen(),
        ),
        GetPage(name: managerDataProduk, page: () => const DataProdukScreen()),
        GetPage(
            name: managerValidasiTransaksi,
            page: () => const ValidasiTransaksiScreen()),
        GetPage(
            name: managerDataKategori, page: () => const DataKategoriScreen()),
        GetPage(
            name: managerSettingCrew,
            page: () => const setting.SettingDataCrewScreen()),
        GetPage(
            name: managerDataPengeluaran,
            page: () => const DataPengeluaranScreen()),
        GetPage(name: managerCabangDepo, page: () => const CabangDepoScreen()),
      ];
}
