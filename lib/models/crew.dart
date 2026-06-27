class Crew {
  final String id;
  final String nama;
  final String username;
  final String noHp;
  final String alamat;
  final bool isAktif;
  final String? fotoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Crew({
    required this.id,
    required this.nama,
    required this.username,
    required this.noHp,
    required this.alamat,
    this.isAktif = true,
    this.fotoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory Crew.fromJson(Map<String, dynamic> json) => Crew(
        id: json['id'] as String,
        nama: json['nama'] as String? ?? '',
        username: json['username'] as String? ?? '',
        noHp: json['noHp'] as String? ?? '',
        alamat: json['alamat'] as String? ?? '',
        isAktif: json['isAktif'] as bool? ?? true,
        fotoUrl: json['fotoUrl'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'username': username,
        'noHp': noHp,
        'alamat': alamat,
        'isAktif': isAktif,
        'fotoUrl': fotoUrl,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
