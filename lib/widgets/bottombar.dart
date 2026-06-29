import 'package:flutter/material.dart';

class BottomBar extends StatefulWidget {
  /// Index tab yang aktif saat pertama kali ditampilkan
  final int initialIndex;

  /// Callback dipanggil setiap kali tab berubah
  final ValueChanged<int>? onTabChanged;

  const BottomBar({
    super.key,
    this.initialIndex = 0,
    this.onTabChanged,
  });

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  static const Color _primary = Color(0xFF1392EC);
  static const Color _inactive = Color(0xFFADB5C7);

  // Ukuran FAB
  static const double _fabSize = 72;
  static const double _barTopPadding = 10;
  static const double _barHeight = 68; // tinggi bar (tanpa safe-area)

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant BottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _selectedIndex = widget.initialIndex;
      });
    }
  }

  void _onTap(int index) {
    setState(() => _selectedIndex = index);
    widget.onTabChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, -6),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFEEF2F7), width: 1),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── Bar background + tab items ───────────────────────────────
          SizedBox(
            height: _barHeight + bottomPad,
            child: Padding(
              padding: EdgeInsets.only(
                top: _barTopPadding,
                left: 8,
                right: 8,
                bottom: bottomPad,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.history_rounded,
                    label: 'Riwayat',
                    index: 1,
                  ),
                  // Spacer untuk FAB
                  SizedBox(width: _fabSize),
                  _buildNavItem(
                    icon: Icons.assignment_turned_in_outlined,
                    label: 'Stok',
                    index: 3,
                  ),
                  _buildNavItem(
                    icon: Icons.settings_outlined,
                    label: 'Pengaturan',
                    index: 4,
                  ),
                ],
              ),
            ),
          ),

          // ── FAB Kasir (melayang di tengah) ──────────────────────────
          Positioned(
            top: -2,
            child: _buildFab(),
          ),
        ],
      ),
    );
  }

  // ── FAB Kasir ──────────────────────────────────────────────────────────────
  Widget _buildFab() {
    final bool isActive = _selectedIndex == 2;
    return GestureDetector(
      onTap: () => _onTap(2),
      child: Container(
        width: _fabSize,
        height: _fabSize,
        decoration: BoxDecoration(
          color: _primary,
          shape: BoxShape.circle,
          // Ring putih tebal (seperti gambar)
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: isActive ? 0.45 : 0.30),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 28),
            SizedBox(height: 2),
            Text(
              'KASIR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Satu item tab ──────────────────────────────────────────────────────────
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon dengan ukuran lebih besar
            Icon(
              icon,
              size: 28,
              color: isActive ? _primary : _inactive,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? _primary : _inactive,
                letterSpacing: isActive ? 0.1 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
