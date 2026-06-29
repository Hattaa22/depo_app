import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/analisis_controller.dart';
import '../../../config/app_theme.dart';
import '../../../config/routes.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/header_back_button.dart';

class AnalisisKeuanganReportScreen extends StatelessWidget {
  const AnalisisKeuanganReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analisis = Get.find<AnalisisController>();
    final mulai = Rxn<DateTime>();
    final akhir = Rxn<DateTime>();

    Future<void> pilihTanggal() async {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (range != null) {
        mulai.value = range.start;
        akhir.value = range.end;
        analisis.loadRingkasan(
          Formatters.dateOnly(range.start),
          Formatters.dateOnly(range.end),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Analisis'),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: HeaderBackButton(
              fallbackRoute: AppRoutes.managerDashboard,
            ),
          ),
        ),
        leadingWidth: 52,
        actions: [
          IconButton(
              icon: const Icon(Icons.date_range), onPressed: pilihTanggal),
        ],
      ),
      body: Obx(() {
        if (analisis.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final ringkasan = analisis.ringkasanData.value;
        if (ringkasan == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart_outlined,
                    size: 64, color: AppTheme.textSecondary),
                SizedBox(height: 16),
                Text('Pilih rentang tanggal untuk melihat laporan'),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mulai.value != null && akhir.value != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '${Formatters.dateOnly(mulai.value!)} - ${Formatters.dateOnly(akhir.value!)}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ringkasan Keuangan',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _DataRow(
                        label: 'Total Pendapatan',
                        value: Formatters.currency(ringkasan.totalPendapatan),
                      ),
                      _DataRow(
                        label: 'Total Pengeluaran',
                        value: Formatters.currency(ringkasan.totalPengeluaran),
                        color: AppTheme.errorColor,
                      ),
                      _DataRow(
                        label: 'Pendapatan Bersih',
                        value: Formatters.currency(ringkasan.pendapatanBersih),
                        isHighlight: true,
                        color: AppTheme.successColor,
                      ),
                      _DataRow(
                        label: 'Total Transaksi',
                        value: '${ringkasan.totalTransaksi}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Detail Operasional',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _DataRow(
                          label: 'Total Kirim',
                          value: '${ringkasan.totalDikirim} transaksi'),
                      _DataRow(
                          label: 'Total Di Depo',
                          value: '${ringkasan.totalDiDepo} transaksi'),
                      const Divider(height: 24),
                      const Text('Transaksi Per Crew',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (ringkasan.transaksiCrew.isEmpty)
                        const Text('Belum ada transaksi crew pada periode ini',
                            style: TextStyle(color: AppTheme.textSecondary))
                      else
                        ...ringkasan.transaksiCrew.map((raw) {
                          final item = raw as Map<String, dynamic>;
                          final nama = item['crewNama']?.toString() ?? '-';
                          final total = item['totalTransaksi'] ?? 0;
                          final kirim = item['totalKirim'] ?? 0;
                          final diDepo = item['totalDiDepo'] ?? 0;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_outline, size: 18),
                            ),
                            title: Text(nama),
                            subtitle: Text('Kirim $kirim | Di depo $diDepo'),
                            trailing: Text('$total trx',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Analisis Per Kategori',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              _buildCategoryBreakdownList(ringkasan.breakdown),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCategoryBreakdownList(List<dynamic> breakdown) {
    if (breakdown.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
              child: Text('Tidak ada data kategori',
                  style: TextStyle(color: AppTheme.textSecondary))),
        ),
      );
    }

    final Map<String, IconData> iconMap = {
      'water_drop': Icons.water_drop_rounded,
      'inventory_2': Icons.inventory_2_rounded,
      'widgets': Icons.widgets_rounded,
      'people': Icons.people_rounded,
      'bolt': Icons.bolt_rounded,
      'store': Icons.store_rounded,
      'build': Icons.build_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'category': Icons.category_rounded,
      'receipt': Icons.receipt_rounded,
      'local_shipping': Icons.local_shipping_rounded,
      'attach_money': Icons.attach_money_rounded,
      'account_balance': Icons.account_balance_rounded,
      'payments': Icons.payments_rounded,
    };

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: breakdown.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = breakdown[index] as Map<String, dynamic>;
          final String nama = item['nama'] ?? '';
          final String tipe = item['tipe'] ?? 'pemasukan';
          final String? ikon = item['ikon'];
          final double total = (item['total'] ?? 0).toDouble();

          final isPemasukan = tipe == 'pemasukan';
          final color =
              isPemasukan ? AppTheme.successColor : AppTheme.errorColor;
          final iconData = iconMap[ikon] ?? Icons.label_rounded;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(iconData, color: color),
            ),
            title:
                Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isPemasukan ? 'Pemasukan' : 'Pengeluaran',
                style: TextStyle(
                    color: isPemasukan
                        ? AppTheme.successColor
                        : AppTheme.textSecondary,
                    fontSize: 11)),
            trailing: Text(
              '${isPemasukan ? "+" : "-"}${Formatters.currency(total)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: total == 0
                    ? AppTheme.textSecondary
                    : (isPemasukan
                        ? AppTheme.successColor
                        : AppTheme.errorColor),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final Color? color;
  const _DataRow(
      {required this.label,
      required this.value,
      this.isHighlight = false,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ??
                  (isHighlight ? AppTheme.successColor : AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
