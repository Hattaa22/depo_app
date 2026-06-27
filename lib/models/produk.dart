import '../utils/numeric_parser.dart';

class KategoriProduk {
  final String id;
  final String nama;
  final String? deskripsi;
  final String tipe; // 'pemasukan' | 'pengeluaran'
  final String? ikon;
  final bool isSystem;
  final bool isAktif;
  final DateTime createdAt;

  const KategoriProduk({
    required this.id,
    required this.nama,
    this.deskripsi,
    this.tipe = 'pemasukan',
    this.ikon,
    this.isSystem = false,
    this.isAktif = true,
    required this.createdAt,
  });

  factory KategoriProduk.fromJson(Map<String, dynamic> json) => KategoriProduk(
        id: json['id'] as String,
        nama: json['nama'] as String,
        deskripsi: json['deskripsi'] as String?,
        tipe: json['tipe'] as String? ?? 'pemasukan',
        ikon: json['ikon'] as String?,
        isSystem: json['isSystem'] as bool? ?? false,
        isAktif: json['isAktif'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'deskripsi': deskripsi,
        'tipe': tipe,
        'ikon': ikon,
        'isSystem': isSystem,
        'isAktif': isAktif,
        'createdAt': createdAt.toIso8601String(),
      };
}

class Produk {
  final String id;
  final String nama;
  final String kategoriId;
  final KategoriProduk? kategori;
  final double harga;
  final int stok;
  final String? deskripsi;
  final String? gambarUrl;
  final bool isAktif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Produk({
    required this.id,
    required this.nama,
    required this.kategoriId,
    this.kategori,
    required this.harga,
    this.stok = 0,
    this.deskripsi,
    this.gambarUrl,
    this.isAktif = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Produk.fromJson(Map<String, dynamic> json) => Produk(
        id: json['id'] as String,
        nama: json['nama'] as String? ?? '',
        kategoriId: json['kategoriId'] as String? ?? '',
        kategori: json['kategori'] != null
            ? KategoriProduk.fromJson(json['kategori'] as Map<String, dynamic>)
            : null,
        harga: parseDouble(json['harga']),
        stok: parseInt(json['stok']),
        deskripsi: json['deskripsi'] as String?,
        gambarUrl: json['gambarUrl'] as String?,
        isAktif: json['isAktif'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'kategoriId': kategoriId,
        'harga': harga,
        'stok': stok,
        'deskripsi': deskripsi,
        'gambarUrl': gambarUrl,
        'isAktif': isAktif,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
