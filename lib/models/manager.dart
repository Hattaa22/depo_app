class Manager {
  final String id;
  final String nama;
  final String email;
  final String noHp;
  final bool isAktif;
  final String? fotoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Manager({
    required this.id,
    required this.nama,
    required this.email,
    required this.noHp,
    this.isAktif = true,
    this.fotoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory Manager.fromJson(Map<String, dynamic> json) => Manager(
        id: json['id'] as String,
        nama: json['nama'] as String,
        email: json['email'] as String? ?? '',
        noHp: json['noHp'] as String? ?? '',
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
        'email': email,
        'noHp': noHp,
        'isAktif': isAktif,
        'fotoUrl': fotoUrl,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
