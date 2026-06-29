import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Tombol panah kembali di header biru — sama dengan menu Crew.
class HeaderBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String? fallbackRoute;

  const HeaderBackButton({
    super.key,
    this.onTap,
    this.fallbackRoute,
  });

  void _handleTap() {
    if (onTap != null) {
      onTap!();
      return;
    }
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    } else if (fallbackRoute != null) {
      Get.offAllNamed(fallbackRoute!);
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
