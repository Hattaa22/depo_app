import 'package:get/get.dart';

class GalonUiController extends GetxController {
  final selectedSegment = 0.obs;
  final filterValue = 'semua'.obs;
  final isOut = true.obs;
  final amount = '0'.obs;
  final selectedPelangganId = RxnString();
  final selectedTanggal = Rxn<DateTime>();

  void setSegment(int value) => selectedSegment.value = value;

  void setFilter(String value) => filterValue.value = value;

  void setLogType(bool out) => isOut.value = out;

  void setSelectedPelanggan(String? id) => selectedPelangganId.value = id;

  void setSelectedTanggal(DateTime? date) => selectedTanggal.value = date;

  void addDigit(String value) {
    final current = amount.value;
    if (current == '0') {
      if (value != '0') amount.value = value;
      return;
    }
    if (current.length < 5) {
      amount.value = current + value;
    }
  }

  void backspace() {
    final current = amount.value;
    amount.value =
        current.length > 1 ? current.substring(0, current.length - 1) : '0';
  }

  void clearAmount() => amount.value = '0';

  void resetBulkForm() {
    amount.value = '0';
    selectedPelangganId.value = null;
    selectedTanggal.value = null;
  }
}
