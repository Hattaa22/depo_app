import '../utils/numeric_parser.dart';

class Pengeluaran {
  final String id;
  final String kategoriId;
  final String? kategoriNama;
  final double nominal;
  final String keterangan;
  final DateTime tanggal;
  final DateTime createdAt;

  const Pengeluaran({
    required this.id,
    required this.kategoriId,
    this.kategoriNama,
    required this.nominal,
    required this.keterangan,
    required this.tanggal,
    required this.createdAt,
  });

  factory Pengeluaran.fromJson(Map<String, dynamic> json) {
    // Parse tanggal yang formatnya YYYY-MM-DD
    DateTime parsedTanggal;
    try {
      final tStr = json['tanggal'] as String;
      if (tStr.length == 10) {
        parsedTanggal = DateTime.parse('${tStr}T00:00:00Z');
      } else {
        parsedTanggal = DateTime.parse(tStr);
      }
    } catch (_) {
      parsedTanggal = DateTime.now();
    }

    return Pengeluaran(
      id: json['id'] as String,
      kategoriId: json['kategoriId'] as String,
      kategoriNama: json['kategoriNama'] as String?,
      nominal: parseDouble(json['nominal']),
      keterangan: json['keterangan'] as String? ?? '',
      tanggal: parsedTanggal,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kategoriId': kategoriId,
        'kategoriNama': kategoriNama,
        'nominal': nominal,
        'keterangan': keterangan,
        'tanggal':
            '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}',
        'createdAt': createdAt.toIso8601String(),
      };
}
