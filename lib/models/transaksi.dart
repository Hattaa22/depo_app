import 'pelanggan.dart';
import 'produk.dart';
import 'crew.dart';
import '../utils/numeric_parser.dart';

enum StatusTransaksi {
  pending,
  diproses,
  selesai,
  dibatalkan,
  menungguValidasi
}

enum MetodePembayaran { tunai, qris, transfer }

enum StatusValidasi { belumDivalidasi, valid, invalid }

class ItemTransaksi {
  final String id;
  final String transaksiId;
  final String produkId;
  final Produk? produk;
  final int jumlah;
  final double hargaSatuan;
  final double subtotal;
  final int galonPinjam;
  final int galonKembali;

  const ItemTransaksi({
    required this.id,
    required this.transaksiId,
    required this.produkId,
    this.produk,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    this.galonPinjam = 0,
    this.galonKembali = 0,
  });

  factory ItemTransaksi.fromJson(Map<String, dynamic> json) => ItemTransaksi(
        id: json['id'] as String,
        transaksiId: json['transaksiId'] as String,
        produkId: json['produkId'] as String,
        produk: json['produk'] != null
            ? Produk.fromJson(json['produk'] as Map<String, dynamic>)
            : null,
        jumlah: parseInt(json['jumlah']),
        hargaSatuan: parseDouble(json['hargaSatuan']),
        subtotal: parseDouble(json['subtotal']),
        galonPinjam: parseInt(json['galonPinjam']),
        galonKembali: parseInt(json['galonKembali']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaksiId': transaksiId,
        'produkId': produkId,
        'jumlah': jumlah,
        'hargaSatuan': hargaSatuan,
        'subtotal': subtotal,
        'galonPinjam': galonPinjam,
        'galonKembali': galonKembali,
      };
}

class Transaksi {
  final String id;
  final String nomorTransaksi;
  final String? pelangganId;
  final Pelanggan? pelanggan;
  final String crewId;
  final Crew? crew;
  final Crew? pengirimCrew;
  final List<ItemTransaksi> items;
  final double totalHarga;
  final MetodePembayaran metodePembayaran;
  final StatusTransaksi status;
  final StatusValidasi statusValidasi;
  final double? bayar;
  final double? kembalian;
  final String? qrPaymentId;
  final String? catatan;
  final String? validasiOleh;
  final DateTime? validasiAt;
  final String tipePembelian;
  final int ongkirPerGalon;
  final double totalOngkir;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Transaksi({
    required this.id,
    required this.nomorTransaksi,
    this.pelangganId,
    this.pelanggan,
    required this.crewId,
    this.crew,
    this.pengirimCrew,
    required this.items,
    required this.totalHarga,
    this.metodePembayaran = MetodePembayaran.tunai,
    this.status = StatusTransaksi.pending,
    this.statusValidasi = StatusValidasi.belumDivalidasi,
    this.bayar,
    this.kembalian,
    this.qrPaymentId,
    this.catatan,
    this.validasiOleh,
    this.validasiAt,
    this.tipePembelian = 'diDepo',
    this.ongkirPerGalon = 0,
    this.totalOngkir = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory Transaksi.fromJson(Map<String, dynamic> json) => Transaksi(
        id: json['id'] as String,
        nomorTransaksi: json['nomorTransaksi'] as String? ?? '',
        pelangganId: json['pelangganId'] as String?,
        pelanggan: json['pelanggan'] != null
            ? Pelanggan.fromJson(json['pelanggan'] as Map<String, dynamic>)
            : null,
        crewId: json['crewId'] as String? ?? '',
        crew: json['crew'] != null
            ? Crew.fromJson(json['crew'] as Map<String, dynamic>)
            : null,
        pengirimCrew: json['pengirimCrew'] != null
            ? Crew.fromJson(json['pengirimCrew'] as Map<String, dynamic>)
            : null,
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => ItemTransaksi.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        totalHarga: parseDouble(json['totalHarga']),
        metodePembayaran: _metodePembayaranFromString(
            json['metodePembayaran'] as String? ?? 'tunai'),
        status: _statusFromString(json['status'] as String? ?? 'pending'),
        statusValidasi: _statusValidasiFromString(
            json['statusValidasi'] as String? ?? 'belumDivalidasi'),
        bayar: json['bayar'] != null ? parseDouble(json['bayar']) : null,
        kembalian:
            json['kembalian'] != null ? parseDouble(json['kembalian']) : null,
        qrPaymentId: json['qrPaymentId'] as String?,
        catatan: json['catatan'] as String?,
        validasiOleh: json['validasiOleh'] as String?,
        validasiAt: json['validasiAt'] != null
            ? DateTime.parse(json['validasiAt'] as String)
            : null,
        tipePembelian: _tipePembelianFromString(
            json['tipePembelian'] as String? ?? 'diDepo'),
        ongkirPerGalon: parseInt(json['ongkirPerGalon']),
        totalOngkir: parseDouble(json['totalOngkir']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  static StatusTransaksi _statusFromString(String s) {
    switch (s) {
      case 'diproses':
        return StatusTransaksi.diproses;
      case 'selesai':
        return StatusTransaksi.selesai;
      case 'dibatalkan':
        return StatusTransaksi.dibatalkan;
      case 'menungguValidasi':
        return StatusTransaksi.menungguValidasi;
      default:
        return StatusTransaksi.pending;
    }
  }

  static MetodePembayaran _metodePembayaranFromString(String s) {
    switch (s) {
      case 'qris':
        return MetodePembayaran.qris;
      case 'transfer':
        return MetodePembayaran.transfer;
      default:
        return MetodePembayaran.tunai;
    }
  }

  static StatusValidasi _statusValidasiFromString(String s) {
    switch (s) {
      case 'valid':
        return StatusValidasi.valid;
      case 'invalid':
        return StatusValidasi.invalid;
      default:
        return StatusValidasi.belumDivalidasi;
    }
  }

  static String _tipePembelianFromString(String s) {
    if (s == 'dikirim' || s == 'di_depo') {
      return s == 'dikirim' ? 'dikirim' : 'diDepo';
    }
    return 'diDepo';
  }

  bool get isDikirim => tipePembelian == 'dikirim';

  double get totalGalonPinjam =>
      items.fold(0, (sum, item) => sum + item.galonPinjam);

  double get totalGalonKembali =>
      items.fold(0, (sum, item) => sum + item.galonKembali);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nomorTransaksi': nomorTransaksi,
        'pelangganId': pelangganId,
        'crewId': crewId,
        'items': items.map((e) => e.toJson()).toList(),
        'totalHarga': totalHarga,
        'metodePembayaran': metodePembayaran.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };
}

class LaporanKeuangan {
  final DateTime tanggalMulai;
  final DateTime tanggalAkhir;
  final double totalPendapatan;
  final double totalPengeluaran;
  final double pendapatanBersih;
  final int totalTransaksi;
  final int transaksiSelesai;
  final int transaksiDibatalkan;
  final double pendapatanTunai;
  final double pendapatanQris;
  final double pendapatanTransfer;
  final int totalDikirim;
  final int totalDiDepo;
  final List<dynamic> transaksiCrew;
  final List<dynamic> breakdown;

  const LaporanKeuangan({
    required this.tanggalMulai,
    required this.tanggalAkhir,
    this.totalPendapatan = 0,
    this.totalPengeluaran = 0,
    this.pendapatanBersih = 0,
    this.totalTransaksi = 0,
    this.transaksiSelesai = 0,
    this.transaksiDibatalkan = 0,
    this.pendapatanTunai = 0,
    this.pendapatanQris = 0,
    this.pendapatanTransfer = 0,
    this.totalDikirim = 0,
    this.totalDiDepo = 0,
    this.transaksiCrew = const [],
    this.breakdown = const [],
  });

  factory LaporanKeuangan.fromJson(Map<String, dynamic> json) =>
      LaporanKeuangan(
        tanggalMulai: DateTime.parse(json['tanggalMulai'] as String),
        tanggalAkhir: DateTime.parse(json['tanggalAkhir'] as String),
        totalPendapatan: (json['totalPendapatan'] as num?)?.toDouble() ?? 0,
        totalPengeluaran: (json['totalPengeluaran'] as num?)?.toDouble() ?? 0,
        pendapatanBersih: (json['pendapatanBersih'] as num?)?.toDouble() ?? 0,
        totalTransaksi: json['totalTransaksi'] as int? ?? 0,
        transaksiSelesai: json['transaksiSelesai'] as int? ?? 0,
        transaksiDibatalkan: json['transaksiDibatalkan'] as int? ?? 0,
        pendapatanTunai: (json['pendapatanTunai'] as num?)?.toDouble() ?? 0,
        pendapatanQris: (json['pendapatanQris'] as num?)?.toDouble() ?? 0,
        pendapatanTransfer:
            (json['pendapatanTransfer'] as num?)?.toDouble() ?? 0,
        totalDikirim: parseInt(json['totalDikirim']),
        totalDiDepo: parseInt(json['totalDiDepo']),
        transaksiCrew: json['transaksiCrew'] as List<dynamic>? ?? const [],
        breakdown: json['breakdown'] as List<dynamic>? ?? const [],
      );
}
