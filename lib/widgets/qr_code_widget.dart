import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final bool showBorder;
  final double borderWidth;
  final Color? borderColor;
  final BorderRadius? borderRadius;

  const QrCodeWidget({
    super.key,
    required this.data,
    this.size = 200,
    this.foregroundColor,
    this.backgroundColor,
    this.padding,
    this.showBorder = false,
    this.borderWidth = 1,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: showBorder
            ? Border.all(
                color: borderColor ?? Theme.of(context).colorScheme.outline,
                width: borderWidth,
              )
            : null,
      ),
      child: QrImageView(
        data: data,
        size: size,
        backgroundColor: backgroundColor ?? Colors.transparent,
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: foregroundColor ?? Theme.of(context).colorScheme.onSurface,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: foregroundColor ?? Theme.of(context).colorScheme.onSurface,
        ),
        version: QrVersions.auto,
        gapless: true,
        errorStateBuilder: (context, error) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  'QR gagal dimuat',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
