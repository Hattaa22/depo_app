import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
  ),
);

class AppHelpers {
  AppHelpers._();

  static void showToast(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Error' : 'Info',
      message,
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  static void showSnackbar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDangerous
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  static String getErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Exception) {
      final msg = error.toString();
      if (msg.contains('SocketException') || msg.contains('Connection')) {
        return 'Tidak ada koneksi internet';
      }
      if (msg.contains('TimeoutException')) {
        return 'Koneksi timeout, coba lagi';
      }
      if (msg.contains('401')) return 'Sesi berakhir, silakan login kembali';
      if (msg.contains('403')) return 'Anda tidak memiliki akses';
      if (msg.contains('404')) return 'Data tidak ditemukan';
      if (msg.contains('500')) return 'Terjadi kesalahan server';
    }
    return 'Terjadi kesalahan, coba lagi';
  }

  static double hitungKembalian(double bayar, double total) {
    return bayar - total;
  }

  static bool isTanggalValid(DateTime? tanggal) {
    if (tanggal == null) return false;
    return !tanggal.isAfter(DateTime.now());
  }
}
