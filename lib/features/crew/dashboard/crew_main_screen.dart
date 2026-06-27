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

    return Scaffold(
      body: Obx(() => IndexedStack(
            index: controller.selectedIndex.value,
            children: const [
              CrewDashboardScreen(),
              RiwayatTransaksiScreen(),
              KasirScreen(),
              PencatatanGalonScreen(),
              PengaturanScreen(),
            ],
          )),
      bottomNavigationBar: Obx(() => BottomBar(
            initialIndex: controller.selectedIndex.value,
            onTabChanged: (index) {
              controller.changeTab(index);
            },
          )),
    );
  }
}
