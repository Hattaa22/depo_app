import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/produk.dart';
import '../services/api_service.dart';
import '../utils/api_error_helper.dart';

class ProdukController extends GetxController {
  final ApiService _apiService;
  ProdukController(this._apiService);

  final produkList = <Produk>[].obs;
  final kategoriList = <KategoriProduk>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  List<KategoriProduk> get pemasukanList =>
      kategoriList.where((k) => k.tipe == 'pemasukan').toList();

  List<KategoriProduk> get pengeluaranList =>
      kategoriList.where((k) => k.tipe == 'pengeluaran').toList();

  Future<void> loadProduk({String? kategoriId}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _apiService.getSemuaProduk(1, 100, kategoriId, null);
      produkList.value = result.data;
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadKategori() async {
    try {
      kategoriList.value = await _apiService.getSemuaKategori();
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<void> tambahProduk(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      await _apiService.createProduk(data);
      Get.snackbar('Berhasil', 'Produk berhasil ditambahkan');
      await loadProduk();
    } catch (e) {
      errorMessage.value = ApiErrorHelper.message(e);
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: Color(0xFFE63946), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editProduk(String id, Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      await _apiService.updateProduk(id, data);
      Get.snackbar('Berhasil', 'Produk berhasil diperbarui');
      await loadProduk();
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: Color(0xFFE63946), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> hapusProduk(String id) async {
    isLoading.value = true;
    try {
      await _apiService.deleteProduk(id);
      Get.snackbar('Berhasil', 'Produk berhasil dihapus');
      await loadProduk();
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: Color(0xFFE63946), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> tambahKategori(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      await _apiService.createKategori(data);
      Get.snackbar('Berhasil', 'Kategori berhasil ditambahkan');
      await loadKategori();
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: Color(0xFFE63946), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editKategori(String id, Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      await _apiService.updateKategori(id, data);
      Get.snackbar('Berhasil', 'Kategori berhasil diperbarui');
      await loadKategori();
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: Color(0xFFE63946), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> hapusKategori(String id) async {
    isLoading.value = true;
    try {
      await _apiService.deleteKategori(id);
      Get.snackbar('Berhasil', 'Kategori berhasil dihapus');
      await loadKategori();
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar('Error', errorMessage.value,
          backgroundColor: Color(0xFFE63946), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }
}
