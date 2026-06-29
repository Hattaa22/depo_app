import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';

class PilihPeranScreen extends StatelessWidget {
  const PilihPeranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoSize = (constraints.maxWidth * 0.5).clamp(140.0, 220.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/fluks_logo.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Depo App',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Text(
                      'Sistem Manajemen Depot Air Minum',
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: constraints.maxHeight < 640 ? 36 : 56),
                    const Text(
                      'Masuk sebagai',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Get.toNamed(AppRoutes.loginCrew),
                        icon: const Icon(Icons.badge_outlined),
                        label:
                            const Text('Crew', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Get.toNamed(AppRoutes.loginManager),
                        icon: const Icon(Icons.manage_accounts_outlined),
                        label: const Text('Manager',
                            style: TextStyle(fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppTheme.primaryColor),
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
