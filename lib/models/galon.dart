enum StatusGalon { tersedia, dipinjam, rusak, hilang }

enum JenisGalon { isi, kosong }

class Galon {
  final String id;
  final String kodeGalon;
  final JenisGalon jenis;
  final StatusGalon status;
  final String? pelangganId;
  final String? pelangganNama;
  final String? pelangganNoHp;
  final String? pelangganAlamat;
  final DateTime? tanggalPinjam;
  final String? catatan;
  final String? mutasiCrewId;
  final String? mutasiCrewNama;
  final String? mutasiJenis;
  final String? mutasiStatusDari;
  final String? mutasiStatusKe;
  final DateTime? mutasiCreatedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Galon({
    required this.id,
    required this.kodeGalon,
    required this.jenis,
    this.status = StatusGalon.tersedia,
    this.pelangganId,
    this.pelangganNama,
    this.pelangganNoHp,
    this.pelangganAlamat,
    this.tanggalPinjam,
    this.catatan,
    this.mutasiCrewId,
    this.mutasiCrewNama,
    this.mutasiJenis,
    this.mutasiStatusDari,
    this.mutasiStatusKe,
    this.mutasiCreatedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Galon.fromJson(Map<String, dynamic> json) => Galon(
        id: json['id'] as String? ?? '',
        kodeGalon: json['kodeGalon'] as String? ?? '',
        jenis: _jenisFromString(json['jenis'] as String? ?? 'isi'),
        status: _statusFromString(json['status'] as String? ?? 'tersedia'),
        pelangganId: json['pelangganId'] as String?,
        pelangganNama: json['pelangganNama'] as String?,
        pelangganNoHp: json['pelangganNoHp'] as String?,
        pelangganAlamat: json['pelangganAlamat'] as String?,
        tanggalPinjam: json['tanggalPinjam'] != null
            ? _parseDate(json['tanggalPinjam'])
            : null,
        catatan: json['catatan'] as String?,
        mutasiCrewId: json['mutasiCrewId'] as String?,
        mutasiCrewNama: json['mutasiCrewNama'] as String?,
        mutasiJenis: json['mutasiJenis'] as String?,
        mutasiStatusDari: json['mutasiStatusDari'] as String?,
        mutasiStatusKe: json['mutasiStatusKe'] as String?,
        mutasiCreatedAt: json['mutasiCreatedAt'] != null
            ? _parseDate(json['mutasiCreatedAt'])
            : null,
        createdAt: _parseDate(json['createdAt']),
        updatedAt:
            json['updatedAt'] != null ? _parseDate(json['updatedAt']) : null,
      );

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static StatusGalon _statusFromString(String s) {
    switch (s) {
      case 'dipinjam':
        return StatusGalon.dipinjam;
      case 'rusak':
        return StatusGalon.rusak;
      case 'hilang':
        return StatusGalon.hilang;
      default:
        return StatusGalon.tersedia;
    }
  }

  static JenisGalon _jenisFromString(String s) {
    return s == 'kosong' ? JenisGalon.kosong : JenisGalon.isi;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kodeGalon': kodeGalon,
        'jenis': jenis.name,
        'status': status.name,
        'pelangganId': pelangganId,
        'pelangganNama': pelangganNama,
        'pelangganNoHp': pelangganNoHp,
        'pelangganAlamat': pelangganAlamat,
        'tanggalPinjam': tanggalPinjam?.toIso8601String(),
        'catatan': catatan,
        'mutasiCrewId': mutasiCrewId,
        'mutasiCrewNama': mutasiCrewNama,
        'mutasiJenis': mutasiJenis,
        'mutasiStatusDari': mutasiStatusDari,
        'mutasiStatusKe': mutasiStatusKe,
        'mutasiCreatedAt': mutasiCreatedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class RingkasanGalon {
  final int totalGalon;
  final int tersedia;
  final int dipinjam;
  final int rusak;
  final int hilang;

  const RingkasanGalon({
    this.totalGalon = 0,
    this.tersedia = 0,
    this.dipinjam = 0,
    this.rusak = 0,
    this.hilang = 0,
  });

  factory RingkasanGalon.fromJson(Map<String, dynamic> json) => RingkasanGalon(
        totalGalon: json['totalGalon'] as int? ?? 0,
        tersedia: json['tersedia'] as int? ?? 0,
        dipinjam: json['dipinjam'] as int? ?? 0,
        rusak: json['rusak'] as int? ?? 0,
        hilang: json['hilang'] as int? ?? 0,
      );
}
