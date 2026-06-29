import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/app_theme.dart';

class AppDialog {
  AppDialog._();

  static Future<T?> show<T>({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    String buttonText = 'OK',
    VoidCallback? onPressed,
    bool barrierDismissible = true,
  }) {
    return Get.dialog<T>(
      _AppDialogContent(
        title: title,
        message: message,
        icon: icon,
        color: color,
        primaryText: buttonText,
        onPrimary: onPressed ?? () => Get.back(),
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  static Future<T?> success<T>({
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return show<T>(
      title: title,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      color: AppTheme.successColor,
      buttonText: buttonText,
      onPressed: onPressed,
    );
  }

  static Future<T?> error<T>({
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return show<T>(
      title: title,
      message: message,
      icon: Icons.error_outline_rounded,
      color: AppTheme.errorColor,
      buttonText: buttonText,
      onPressed: onPressed,
    );
  }

  static Future<T?> warning<T>({
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return show<T>(
      title: title,
      message: message,
      icon: Icons.warning_amber_rounded,
      color: AppTheme.warningColor,
      buttonText: buttonText,
      onPressed: onPressed,
    );
  }

  static Future<T?> info<T>({
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return show<T>(
      title: title,
      message: message,
      icon: Icons.info_outline_rounded,
      color: AppTheme.primaryColor,
      buttonText: buttonText,
      onPressed: onPressed,
    );
  }

  static Future<bool> confirm({
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Tidak',
    IconData icon = Icons.help_outline_rounded,
    Color color = AppTheme.primaryColor,
  }) async {
    final result = await Get.dialog<bool>(
      _AppDialogContent(
        title: title,
        message: message,
        icon: icon,
        color: color,
        primaryText: confirmText,
        secondaryText: cancelText,
        onPrimary: () => Get.back(result: true),
        onSecondary: () => Get.back(result: false),
      ),
    );
    return result ?? false;
  }

  static Future<bool> confirmLogout() {
    return confirm(
      title: 'Keluar',
      message: 'Apakah Anda yakin ingin keluar dari aplikasi?',
      icon: Icons.logout_rounded,
      color: const Color(0xFF64748B),
    );
  }
}

class _AppDialogContent extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String primaryText;
  final String? secondaryText;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;

  const _AppDialogContent({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.primaryText,
    this.secondaryText,
    required this.onPrimary,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width < 420 ? width : 380),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  if (secondaryText != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onSecondary,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          secondaryText!,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onPrimary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryText != null
                            ? color.withValues(alpha: 0.14)
                            : color,
                        foregroundColor:
                            secondaryText != null ? color : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        primaryText,
                        style: TextStyle(
                          color: secondaryText != null ? color : Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
