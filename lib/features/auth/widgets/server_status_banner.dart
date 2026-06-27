import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/api_config.dart';
import '../../../services/api_service.dart';

/// Panel diagnosa koneksi backend (cegah timeout login tanpa petunjuk).
class ServerStatusBanner extends StatefulWidget {
  const ServerStatusBanner({super.key});

  @override
  State<ServerStatusBanner> createState() => _ServerStatusBannerState();
}

class _ServerStatusBannerState extends State<ServerStatusBanner> {
  bool? _ok;
  bool _checking = false;

  Future<void> _cek() async {
    setState(() {
      _checking = true;
      _ok = null;
    });
    final api = Get.find<ApiService>();
    final ok = await api.cekKoneksiServer();
    if (mounted) {
      setState(() {
        _ok = ok;
        _checking = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cek());
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String status;

    if (_checking) {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
      icon = Icons.sync_rounded;
      status = 'Mengecek server...';
    } else if (_ok == true) {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
      icon = Icons.check_circle_rounded;
      status = 'Server terhubung';
    } else {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFB91C1C);
      icon = Icons.error_outline_rounded;
      status = 'Server tidak terjangkau';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: fg,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: _checking ? null : _cek,
                child: const Text('Cek lagi'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ApiConfig.baseUrl,
            style: TextStyle(fontSize: 11, color: fg.withOpacity(0.9)),
          ),
          if (_ok == false) ...[
            const SizedBox(height: 8),
            Text(
              'Jalankan: cd backend → npm start\n'
              'HP & PC satu WiFi • IP: ${ApiConfig.lanHost}',
              style: TextStyle(fontSize: 11, color: fg, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
