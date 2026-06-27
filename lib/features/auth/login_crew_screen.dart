import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import 'widgets/server_status_banner.dart';

class LoginCrewScreen extends StatefulWidget {
  const LoginCrewScreen({super.key});

  @override
  State<LoginCrewScreen> createState() => _LoginCrewScreenState();
}

class _LoginCrewScreenState extends State<LoginCrewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinCtrl = TextEditingController();
  bool _obscurePin = true;

  final _auth = Get.find<AuthController>();

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      _auth.loginCrew('', _pinCtrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Login Crew'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed(AppRoutes.pilihPeran),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Selamat Datang,\nCrew!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masuk untuk memulai aktivitas hari ini',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              const ServerStatusBanner(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _pinCtrl,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'PIN Crew',
                  counterText: '',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePin ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
                validator: (v) {
                  final pin = v?.trim() ?? '';
                  if (pin.isEmpty) return 'PIN tidak boleh kosong';
                  if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
                    return 'PIN harus 4-6 digit angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Obx(() {
                final isLoading = _auth.isLoading.value;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onLogin,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Masuk'),
                  ),
                );
              }),
              const SizedBox(height: 16),
              // Tombol Test Login untuk Development
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _pinCtrl.text = '1234';
                    _onLogin();
                  },
                  child: const Text('Coba PIN Test'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
