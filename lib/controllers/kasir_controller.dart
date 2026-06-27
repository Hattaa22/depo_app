import 'package:get/get.dart';
import '../models/produk.dart';
import '../models/pelanggan.dart';
import '../models/crew.dart';
import '../services/api_service.dart';

enum TipePembelian { diDepo, dikirim }

class KeranjangItem {
  final Produk produk;
  int jumlah;
  KeranjangItem({required this.produk, required this.jumlah});
}

class KasirController extends GetxController {
  final ApiService _apiService;
  KasirController(this._apiService);

  final produkList = <Produk>[].obs;
  final kategoriList = <KategoriProduk>[].obs;
  final keranjang = <KeranjangItem>[].obs;
  final pelangganDipilih = Rxn<Pelanggan>();
  final crewPengirimDipilih = Rxn<Crew>();
  final tipePembelian = TipePembelian.diDepo.obs;
  final ongkirPerGalon = 1000.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  int get subtotalProduk => keranjang.fold(
      0, (sum, item) => sum + (item.produk.harga * item.jumlah).round());

  int get totalItem => keranjang.fold(0, (sum, item) => sum + item.jumlah);

  int get totalOngkir {
    if (tipePembelian.value != TipePembelian.dikirim || totalItem == 0) {
      return 0;
    }
    return ongkirPerGalon.value * totalItem;
  }

  int get totalHarga => subtotalProduk + totalOngkir;

  bool get memilikiGalonBaru =>
      keranjang.any((k) => _isProdukGalonBaru(k.produk));

  bool get isDikirim => tipePembelian.value == TipePembelian.dikirim;

  static bool _isProdukGalonBaru(Produk p) {
    final kategori = p.kategori?.nama.toLowerCase().trim() ?? '';
    final nama = p.nama.toLowerCase().trim();
    if (kategori.isEmpty && nama.isEmpty) return false;

    if (kategori.contains('galon baru') || nama.contains('galon baru')) {
      return true;
    }
    if (kategori == 'galon' ||
        kategori.startsWith('galon ') ||
        kategori.contains('penjualan galon')) {
      return true;
    }
    if (nama.contains('galon kosong')) return true;
    if (nama == 'galon' || RegExp(r'^galon(\s|$)').hasMatch(nama)) return true;

    return false;
  }

  void setTipePembelian(TipePembelian tipe) {
    tipePembelian.value = tipe;
    if (tipe != TipePembelian.dikirim) {
      crewPengirimDipilih.value = null;
    }
  }

  void pilihCrewPengirim(Crew? crew) {
    crewPengirimDipilih.value = crew;
  }

  void setOngkirPerGalon(int nominal) {
    ongkirPerGalon.value = nominal == 2000 ? 2000 : 1000;
  }

  /// Muat ulang kategori & produk (panggil saat tab Kasir dibuka).
  Future<void> refreshData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final kategori = await _apiService.getSemuaKategori();
      final produk = await _apiService.getSemuaProduk(1, 100, null, null);
      kategoriList.value = kategori;
      produkList.value = produk.data;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadProduk() async {
    try {
      final result = await _apiService.getSemuaProduk(1, 100, null, null);
      produkList.value = result.data;
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<void> loadKategori() async {
    try {
      kategoriList.value = await _apiService.getSemuaKategori();
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  void tambahItem(Produk produk) {
    final idx = keranjang.indexWhere((k) => k.produk.id == produk.id);
    if (idx >= 0) {
      keranjang[idx].jumlah++;
      keranjang.refresh();
    } else {
      keranjang.add(KeranjangItem(produk: produk, jumlah: 1));
    }
  }

  void kurangiItem(String produkId) {
    final idx = keranjang.indexWhere((k) => k.produk.id == produkId);
    if (idx < 0) return;
    if (keranjang[idx].jumlah <= 1) {
      keranjang.removeAt(idx);
    } else {
      keranjang[idx].jumlah--;
      keranjang.refresh();
    }
  }

  void hapusItem(String produkId) {
    keranjang.removeWhere((k) => k.produk.id == produkId);
  }

  void pilihPelanggan(Pelanggan pelanggan) {
    pelangganDipilih.value = pelanggan;
  }

  void reset() {
    keranjang.clear();
    pelangganDipilih.value = null;
    crewPengirimDipilih.value = null;
    tipePembelian.value = TipePembelian.diDepo;
    ongkirPerGalon.value = 1000;
  }
}
