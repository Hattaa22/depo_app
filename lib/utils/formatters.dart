import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';

class Formatters {
  Formatters._();

  static late final NumberFormat _currencyFormatter;
  static late final DateFormat _dateFormatter;
  static late final DateFormat _dateTimeFormatter;
  static late final DateFormat _timeFormatter;
  static late final DateFormat _dateOnlyFormatter;

  /// Wajib dipanggil di main() sebelum runApp (locale id_ID untuk tanggal).
  static Future<void> init() async {
    await initializeDateFormatting('id_ID');
    _currencyFormatter = NumberFormat.currency(
      locale: AppConstants.currencyLocale,
      symbol: '${AppConstants.currencySymbol} ',
      decimalDigits: 0,
    );
    _dateFormatter = DateFormat(AppConstants.dateFormat, 'id_ID');
    _dateTimeFormatter = DateFormat(AppConstants.dateTimeFormat, 'id_ID');
    _timeFormatter = DateFormat(AppConstants.timeFormat, 'id_ID');
    _dateOnlyFormatter = DateFormat(AppConstants.dateOnlyFormat);
  }

  /// Menerima int atau double (nilai dari JSON API sering berupa int).
  static String currency(num amount) =>
      _currencyFormatter.format(amount.toDouble());

  static String date(DateTime date) => _dateFormatter.format(date);

  static String dateTime(DateTime date) => _dateTimeFormatter.format(date);

  static String time(DateTime date) => _timeFormatter.format(date);

  static String dateOnly(DateTime date) => _dateOnlyFormatter.format(date);

  static String noHp(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (clean.startsWith('0')) {
      return '+62${clean.substring(1)}';
    }
    return clean;
  }

  static String nomorTransaksi(String prefix, int sequence) {
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    return '$prefix-$date-${sequence.toString().padLeft(4, '0')}';
  }

  /// Nomor transaksi untuk tampilan (tanpa prefix TRX/TXN).
  static String nomorTransaksiTampilan(String nomor) {
    if (nomor.isEmpty) return '-';
    final s = nomor.trim();
    final stripped = s.replaceFirst(
      RegExp(r'^(TRX|TXN|TR)[\-_\s]*', caseSensitive: false),
      '',
    );
    return stripped.isEmpty ? s : stripped;
  }

  static String statusTransaksi(String status) {
    const map = {
      'pending': 'Menunggu',
      'diproses': 'Diproses',
      'selesai': 'Selesai',
      'dibatalkan': 'Dibatalkan',
      'menungguValidasi': 'Menunggu Validasi',
    };
    return map[status] ?? status;
  }

  static String statusGalon(String status) {
    const map = {
      'tersedia': 'Tersedia',
      'dipinjam': 'Dipinjam',
      'rusak': 'Rusak',
      'hilang': 'Hilang',
    };
    return map[status] ?? status;
  }

  static String metodePembayaran(String metode) {
    const map = {
      'tunai': 'Tunai',
      'qris': 'QRIS',
      'transfer': 'Transfer Bank',
    };
    return map[metode] ?? metode;
  }

  static double parseCurrency(String value) {
    final clean = value
        .replaceAll(AppConstants.currencySymbol, '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(clean) ?? 0;
  }
}
