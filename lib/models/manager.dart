class Manager {
  final String id;
  final String nama;
  final String username;
  final String noHp;
  final String email;
  final bool isAktif;
  final String? fotoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Manager({
    required this.id,
    required this.nama,
    required this.username,
    required this.noHp,
    required this.email,
    this.isAktif = true,
    this.fotoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory Manager.fromJson(Map<String, dynamic> json) => Manager(
        id: json['id'] as String,
        nama: json['nama'] as String,
        username: json['username'] as String,
        noHp: json['noHp'] as String? ?? '',
        email: json['email'] as String? ?? '',
        isAktif: json['isAktif'] as bool? ?? true,
        fotoUrl: json['fotoUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'username': username,
        'noHp': noHp,
        'email': email,
        'isAktif': isAktif,
        'fotoUrl': fotoUrl,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
