import 'package:get/get.dart';
import 'kasir_controller.dart';

class CrewMainController extends GetxController {
  static const int tabKasir = 2;

  final selectedIndex = 0.obs;

  void changeTab(int index) {
    selectedIndex.value = index;
    if (index == tabKasir && Get.isRegistered<KasirController>()) {
      Get.find<KasirController>().refreshData();
    }
  }
}
