import '../config/constants.dart';

class Validators {
  Validators._();

  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username tidak boleh kosong';
    }
    if (value.length < 3) return 'Username minimal 3 karakter';
    if (value.length > 50) return 'Username maksimal 50 karakter';
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regex.hasMatch(value)) {
      return 'Username hanya boleh huruf, angka, dan underscore';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password minimal ${AppConstants.minPasswordLength} karakter';
    }
    return null;
  }

  static String? noHp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor HP tidak boleh kosong';
    }
    final clean = value.replaceAll(RegExp(r'[\s\-+]'), '');
    if (clean.length < 10 || clean.length > 15) return 'Nomor HP tidak valid';
    if (!RegExp(r'^[0-9]+$').hasMatch(clean)) {
      return 'Nomor HP hanya boleh angka';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value)) return 'Format email tidak valid';
    return null;
  }

  static String? harga(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Harga tidak boleh kosong';
    }
    final parsed =
        double.tryParse(value.replaceAll('.', '').replaceAll(',', '.'));
    if (parsed == null) return 'Format harga tidak valid';
    if (parsed <= 0) return 'Harga harus lebih dari 0';
    return null;
  }

  static String? jumlah(String? value, {int min = 1}) {
    if (value == null || value.trim().isEmpty) {
      return 'Jumlah tidak boleh kosong';
    }
    final parsed = int.tryParse(value);
    if (parsed == null) return 'Jumlah harus berupa angka';
    if (parsed < min) return 'Jumlah minimal $min';
    return null;
  }

  static String? kodeGalon(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kode galon tidak boleh kosong';
    }
    if (value.length > 20) return 'Kode galon maksimal 20 karakter';
    return null;
  }

  static String? nama(String? value, {String fieldName = 'Nama'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    if (value.length > AppConstants.maxNamaLength) {
      return '$fieldName maksimal ${AppConstants.maxNamaLength} karakter';
    }
    return null;
  }

  static String? alamat(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Alamat tidak boleh kosong';
    }
    if (value.length > AppConstants.maxAlamatLength) {
      return 'Alamat maksimal ${AppConstants.maxAlamatLength} karakter';
    }
    return null;
  }
}
