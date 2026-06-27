import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/crew_controller.dart';
import '../../../config/app_theme.dart';
import '../../../config/routes.dart';
import '../../../widgets/header_back_button.dart';

class DataCrewScreen extends StatelessWidget {
  const DataCrewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final crew = Get.find<CrewController>();
    if (crew.crewList.isEmpty && !crew.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => crew.loadCrew());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Crew'),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: HeaderBackButton(
              fallbackRoute: AppRoutes.managerDashboard,
            ),
          ),
        ),
        leadingWidth: 52,
      ),
      body: Obx(() {
        if (crew.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (crew.errorMessage.value.isNotEmpty) {
          return Center(child: Text(crew.errorMessage.value));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: crew.crewList.length,
          itemBuilder: (_, i) {
            final c = crew.crewList[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.secondaryColor.withOpacity(0.2),
                  child: Text(
                    c.nama.isNotEmpty ? c.nama[0].toUpperCase() : 'C',
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(c.nama),
                subtitle: Builder(
                  builder: (_) {
                    final stat = crew.pengirimanByCrewId(c.id);
                    final totalKirim = stat?['totalKirim'] ?? 0;
                    final totalOngkir = stat?['totalOngkir'] ?? 0;
                    return Text(
                        '@${c.username} | Kirim: $totalKirim | Ongkir: Rp$totalOngkir');
                  },
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'reset', child: Text('Reset PIN')),
                    const PopupMenuItem(
                        value: 'hapus',
                        child: Text('Hapus',
                            style: TextStyle(color: AppTheme.errorColor))),
                  ],
                  onSelected: (val) {
                    if (val == 'reset') crew.resetPasswordCrew(c.id);
                    if (val == 'hapus') crew.hapusCrew(c.id);
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
