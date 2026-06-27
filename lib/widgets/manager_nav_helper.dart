import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/routes.dart';
import '../controllers/analisis_controller.dart';
import '../controllers/laporan_controller.dart';
import 'bottom_nav_manager.dart';

/// Helper navigasi bottom bar Manager (pola dari depoair).
class ManagerNavHelper {
  static const int home = 0;
  static const int reports = 1;
  static const int inventory = 2;
  static const int settings = 3;

  static const Map<int, String> tabRoutes = {
    home: AppRoutes.managerDashboard,
    reports: AppRoutes.managerAnalisis,
    inventory: AppRoutes.managerAssetGalon,
    settings: AppRoutes.managerSettings,
  };

  /// Muat ulang ringkasan dashboard setelah ada transaksi baru dari crew.
  static void refreshHomeData() {
    if (Get.isRegistered<AnalisisController>()) {
      Get.find<AnalisisController>().loadDashboard();
    }
  }

  static void refreshLaporanData() {
    if (Get.isRegistered<LaporanController>()) {
      Get.find<LaporanController>().loadLaporanAwal();
    }
  }

  static Widget bottomBar({
    required int activeIndex,
    bool fromDashboard = false,
    void Function(int index)? onDashboardIndexChange,
  }) {
    return ManagerBottomNav(
      activeIndex: activeIndex,
      onTap: (index) {
        if (fromDashboard && onDashboardIndexChange != null) {
          onDashboardTap(index, onDashboardIndexChange);
        } else {
          onTabTap(activeIndex, index);
        }
      },
    );
  }

  /// Dari dashboard: push tab (jangan offNamed — bisa kosongkan stack).
  static void onDashboardTap(
    int index,
    void Function(int index) onIndexChange,
  ) {
    if (index == home) {
      onIndexChange(home);
      refreshHomeData();
      return;
    }
    final route = tabRoutes[index];
    if (route == null) return;
    Get.toNamed(route, preventDuplicates: false)?.then((_) {
      refreshHomeData();
      if (index == reports) refreshLaporanData();
      if (Get.currentRoute == AppRoutes.managerDashboard) {
        onIndexChange(home);
      }
    });
  }

  /// Dari halaman tab / menu grid.
  static void onTabTap(int activeIndex, int index) {
    if (index == activeIndex) return;
    final route = tabRoutes[index];
    if (route == null) return;

    if (index == home) {
      Get.offAllNamed(route);
      refreshHomeData();
      return;
    }

    // Ganti tab tanpa menghapus dashboard di bawahnya
    if (Get.currentRoute == AppRoutes.managerDashboard) {
      Get.toNamed(route, preventDuplicates: false)?.then((_) {
        refreshHomeData();
        if (index == reports) refreshLaporanData();
      });
    } else {
      Get.offNamed(route);
    }
  }

  /// Setelah buka menu dari dashboard (Laporan, Validasi, dll).
  static void afterPushFromDashboard(Future<dynamic>? navigation) {
    navigation?.then((_) => refreshHomeData());
  }
}
