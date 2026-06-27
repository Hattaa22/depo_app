class CabangDepo {
  final String id;
  final String nama;
  final String? alamat;
  final String? kota;
  final String? noHp;
  final bool isPusat;
  final bool isAktif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CabangDepo({
    required this.id,
    required this.nama,
    this.alamat,
    this.kota,
    this.noHp,
    this.isPusat = false,
    this.isAktif = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory CabangDepo.fromJson(Map<String, dynamic> json) => CabangDepo(
        id: json['id'] as String,
        nama: json['nama'] as String? ?? '',
        alamat: json['alamat'] as String?,
        kota: json['kota'] as String?,
        noHp: json['noHp'] as String?,
        isPusat: json['isPusat'] as bool? ?? false,
        isAktif: json['isAktif'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  String get lokasiTampilan {
    final parts = <String>[];
    if (kota != null && kota!.trim().isNotEmpty) parts.add(kota!.trim());
    if (alamat != null && alamat!.trim().isNotEmpty) parts.add(alamat!.trim());
    return parts.isEmpty ? 'Alamat belum diisi' : parts.join(' · ');
  }

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'alamat': alamat,
        'kota': kota,
        'noHp': noHp,
        'isPusat': isPusat,
        'isAktif': isAktif,
      };
}
