import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../config/routes.dart';

class LoginCrewScreen extends StatefulWidget {
  const LoginCrewScreen({super.key});

  @override
  State<LoginCrewScreen> createState() => _LoginCrewScreenState();
}

class _LoginCrewScreenState extends State<LoginCrewScreen> {
  static const Color _primary = Color(0xFF1392EC);
  static const Color _primaryDark = Color(0xFF0B5FA0);
  static const int _pinLength = 6;

  final _noHpCtrl = TextEditingController();
  String _pin = '';
  bool _isShaking = false;

  final _auth = Get.find<AuthController>();

  @override
  void dispose() {
    _noHpCtrl.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_noHpCtrl.text.trim().isEmpty) {
      Get.snackbar('Error', 'Nomor telepon wajib diisi',
          backgroundColor: Colors.red.shade600, colorText: Colors.white);
      return;
    }
    if (_pin.length < _pinLength) {
      _triggerShake();
      return;
    }
    _auth.loginCrew(_noHpCtrl.text.trim(), _pin.trim());
  }

  void _triggerShake() {
    setState(() => _isShaking = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isShaking = false);
    });
  }

  void _appendDigit(String digit) {
    if (_pin.length < _pinLength) {
      setState(() => _pin += digit);
    }
  }

  void _deleteOne() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _clearAll() {
    setState(() => _pin = '');
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final isSmall = screenH < 680;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF2F6FC),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: mq.padding.top + (isSmall ? 8 : 16),
                left: 20,
                right: 20,
                bottom: isSmall ? 20 : 28,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primary, _primaryDark],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.offAllNamed(AppRoutes.pilihPeran),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Login Crew',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                  SizedBox(height: isSmall ? 12 : 20),
                  Container(
                    width: isSmall ? 60 : 72,
                    height: isSmall ? 60 : 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    child: Icon(Icons.people_alt_rounded,
                        color: Colors.white, size: isSmall ? 28 : 34),
                  ),
                  SizedBox(height: isSmall ? 8 : 12),
                  Text(
                    'Selamat Datang, Crew!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmall ? 17 : 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Masukkan Nomor Telepon & PIN 6 digit Anda',
                    style: TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 13,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),

            // ── PIN Area ────────────────────────────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Input No HP
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: TextField(
                      controller: _noHpCtrl,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Nomor Telepon',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        prefixIcon: const Icon(Icons.phone_android, color: _primary),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  // Dot indicators
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Masukkan PIN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: _isShaking ? 1.0 : 0.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        builder: (context, v, child) => Transform.translate(
                          offset: Offset(v * 8 * (v < 0.5 ? 1 : -1), 0),
                          child: child,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_pinLength, (i) {
                            final filled = i < _pin.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              width: filled ? 20 : 16,
                              height: filled ? 20 : 16,
                              decoration: BoxDecoration(
                                color: filled ? _primary : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      filled ? _primary : Colors.grey.shade300,
                                  width: 2,
                                ),
                                boxShadow: filled
                                    ? [
                                        BoxShadow(
                                          color:
                                              _primary.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : [],
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Error hint
                      AnimatedOpacity(
                        opacity: _isShaking ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Text(
                          'PIN belum lengkap',
                          style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),

                  // ── Custom Keypad ──────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 32 : 48,
                    ),
                    child: Column(
                      children: [
                        _buildKeyRow(['1', '2', '3'], isSmall),
                        SizedBox(height: isSmall ? 10 : 14),
                        _buildKeyRow(['4', '5', '6'], isSmall),
                        SizedBox(height: isSmall ? 10 : 14),
                        _buildKeyRow(['7', '8', '9'], isSmall),
                        SizedBox(height: isSmall ? 10 : 14),
                        Row(
                          children: [
                            // Clear all
                            Expanded(
                              child: _buildSpecialKey(
                                child: const Text(
                                  'C',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                color: const Color(0xFFFEF2F2),
                                onTap: _clearAll,
                                isSmall: isSmall,
                              ),
                            ),
                            SizedBox(width: isSmall ? 10 : 14),
                            Expanded(
                              child: _buildDigitKey('0', isSmall),
                            ),
                            SizedBox(width: isSmall ? 10 : 14),
                            Expanded(
                              child: _buildSpecialKey(
                                child: const Icon(Icons.backspace_rounded,
                                    color: Color(0xFF64748B), size: 22),
                                color: const Color(0xFFF1F5F9),
                                onTap: _deleteOne,
                                onLongPress: _clearAll,
                                isSmall: isSmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Login button
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: isSmall ? 24 : 32),
                    child: Obx(() {
                      final isLoading = _auth.isLoading.value;
                      final pinReady = _pin.length == _pinLength;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: isSmall ? 48 : 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: pinReady && !isLoading
                              ? const LinearGradient(
                                  colors: [_primary, _primaryDark])
                              : null,
                          color: pinReady && !isLoading
                              ? null
                              : Colors.grey.shade300,
                          boxShadow: pinReady && !isLoading
                              ? [
                                  BoxShadow(
                                    color: _primary.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  )
                                ]
                              : [],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _onLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.login_rounded,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      pinReady
                                          ? 'Masuk'
                                          : 'Masukkan PIN (${_pin.length}/$_pinLength)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    }),
                  ),

                  SizedBox(height: mq.padding.bottom + 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> digits, bool isSmall) {
    return Row(
      children: digits.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: e.key < digits.length - 1 ? (isSmall ? 10 : 14) : 0,
            ),
            child: _buildDigitKey(e.value, isSmall),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDigitKey(String digit, bool isSmall) {
    return _KeypadButton(
      onTap: () => _appendDigit(digit),
      isSmall: isSmall,
      child: Text(
        digit,
        style: TextStyle(
          fontSize: isSmall ? 22 : 26,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({
    required Widget child,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    required bool isSmall,
  }) {
    return _KeypadButton(
      onTap: onTap,
      onLongPress: onLongPress,
      bgColor: color,
      isSmall: isSmall,
      child: child,
    );
  }
}

class _KeypadButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color bgColor;
  final bool isSmall;

  const _KeypadButton({
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.bgColor = Colors.white,
    required this.isSmall,
  });

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.isSmall ? 52.0 : 62.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: h,
        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0xFF1392EC).withValues(alpha: 0.1)
              : widget.bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pressed
                ? const Color(0xFF1392EC).withValues(alpha: 0.3)
                : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}
