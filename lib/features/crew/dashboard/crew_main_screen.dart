import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/crew_main_controller.dart';
import '../../../widgets/bottombar.dart';
import 'crewdashboard_screen.dart';
import '../history/riwayat_transaksi.dart';
import 'kasir.dart';
import '../stock/pencatatan_galon.dart';
import '../setting/pengaturan.dart';

class CrewMainScreen extends StatelessWidget {
  const CrewMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CrewMainController controller = Get.find<CrewMainController>();

    return Obx(() {
      final selectedIndex = controller.selectedIndex.value;

      return PopScope(
        canPop: selectedIndex == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && controller.selectedIndex.value != 0) {
            controller.changeTab(0);
          }
        },
        child: Scaffold(
          body: IndexedStack(
            index: selectedIndex,
            children: const [
              CrewDashboardScreen(),
              RiwayatTransaksiScreen(),
              KasirScreen(),
              PencatatanGalonScreen(),
              PengaturanScreen(),
            ],
          ),
          bottomNavigationBar: BottomBar(
            initialIndex: selectedIndex,
            onTabChanged: controller.changeTab,
          ),
        ),
      );
    });
  }
}
