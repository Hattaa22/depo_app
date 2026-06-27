import '../utils/numeric_parser.dart';

class Pelanggan {
  final String id;
  final String nama;
  final String noHp;
  final String? alamat;
  final int totalGalonPinjam;
  final double totalTransaksi;
  final String? catatan;
  final bool isAktif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Pelanggan({
    required this.id,
    required this.nama,
    required this.noHp,
    this.alamat,
    this.totalGalonPinjam = 0,
    this.totalTransaksi = 0,
    this.catatan,
    this.isAktif = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Pelanggan.fromJson(Map<String, dynamic> json) => Pelanggan(
        id: json['id'] as String,
        nama: json['nama'] as String,
        noHp: json['noHp'] as String? ?? '',
        alamat: json['alamat'] as String?,
        totalGalonPinjam: parseInt(json['totalGalonPinjam']),
        totalTransaksi: parseDouble(json['totalTransaksi']),
        catatan: json['catatan'] as String?,
        isAktif: json['isAktif'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'noHp': noHp,
        'alamat': alamat,
        'totalGalonPinjam': totalGalonPinjam,
        'totalTransaksi': totalTransaksi,
        'catatan': catatan,
        'isAktif': isAktif,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
