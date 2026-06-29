import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/crew_controller.dart';
import '../../../config/app_theme.dart';
import '../../../config/routes.dart';
import '../../../widgets/header_back_button.dart';

class DataCrewScreen extends StatefulWidget {
  const DataCrewScreen({super.key});

  @override
  State<DataCrewScreen> createState() => _DataCrewScreenState();
}

class _DataCrewScreenState extends State<DataCrewScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final crew = Get.find<CrewController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (crew.crewList.isEmpty && !crew.isLoading.value) {
        crew.loadCrew();
      } else {
        _fetchFilteredData();
      }
    });
  }

  void _fetchFilteredData() {
    final crew = Get.find<CrewController>();
    final startStr =
        _startDate != null ? _startDate!.toIso8601String().split('T')[0] : null;
    final endStr =
        _endDate != null ? _endDate!.toIso8601String().split('T')[0] : null;
    crew.loadPengirimanCrew(tanggalMulai: startStr, tanggalAkhir: endStr);
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchFilteredData();
    }
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _fetchFilteredData();
  }

  @override
  Widget build(BuildContext context) {
    final crew = Get.find<CrewController>();

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
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() => Text(
                          'Total Crew: ${crew.crewList.length}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        )),
                    if (_startDate != null || _endDate != null)
                      TextButton(
                        onPressed: _clearFilter,
                        child: const Text('Hapus Filter'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _pickDateRange(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (_startDate != null && _endDate != null)
                              ? '${_startDate!.toLocal().toString().split(' ')[0]} s/d ${_endDate!.toLocal().toString().split(' ')[0]}'
                              : 'Filter berdasarkan tanggal',
                          style: TextStyle(
                            color: (_startDate != null && _endDate != null)
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                        const Icon(Icons.date_range,
                            color: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List Section
          Expanded(
            child: Obx(() {
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
                        backgroundColor:
                            AppTheme.secondaryColor.withValues(alpha: 0.2),
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
                          final totalDiDepo = stat?['totalDiDepo'] ?? 0;
                          final totalOngkir = stat?['totalOngkir'] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                                '@${c.username}\nKirim: $totalKirim | Di Depo: $totalDiDepo\nOngkir: Rp$totalOngkir'),
                          );
                        },
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton(
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'reset', child: Text('Reset PIN')),
                          const PopupMenuItem(
                              value: 'hapus',
                              child: Text('Hapus',
                                  style:
                                      TextStyle(color: AppTheme.errorColor))),
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
          ),
        ],
      ),
    );
  }
}
