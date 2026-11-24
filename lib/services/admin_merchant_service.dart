import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/merchant_model.dart';
import 'merchant_service.dart';

/// Service khusus untuk Admin dalam mendata dan memetakan lokasi Merchant / Kantin Kampus.
/// Sesuai konsep Unclaimed Listing: Admin hanya memetakan nama kantin, kategori, dan alamat lokasi
/// tanpa perlu membuatkan akun email/password atau menu makanan (menu & akun diisi oleh pemilik saat klaim).
class AdminMerchantService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream seluruh data merchant secara real-time dari Firestore koleksi `merchants`.
  static Stream<List<MerchantModel>> streamAllMerchants() {
    return _db.collection('merchants').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => MerchantModel.fromMap(doc.data(), doc.id))
          .toList();

      // Urutkan toko: Toko buka di atas, lalu toko yang baru dibuat/diupdate
      list.sort((a, b) {
        if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  /// Tambah Pemetaan Titik Merchant Baru oleh Admin (Unclaimed Store Listing).
  /// Admin menandai toko di kampus (Nama, Kategori, Alamat, Tema).
  /// Toko dibuat dengan status `isClaimed: false` dan `menus: []`.
  static Future<Map<String, dynamic>> addStoreListingByAdmin({
    required String storeName,
    required String category,
    required String address,
    String ownerName = '',
    String phone = '',
    double latitude = 3.5625,
    double longitude = 98.6565,
    String bannerTheme = 'orange',
  }) async {
    try {
      final docRef = _db.collection('merchants').doc();
      final String merchantId = docRef.id;
      final now = DateTime.now();

      final newMerchant = MerchantModel(
        id: merchantId,
        ownerUid: 'unclaimed', // Menandakan belum diklaim oleh akun pemilik
        name: storeName.trim(),
        ownerName: ownerName.trim().isEmpty ? 'Belum Diklaim' : ownerName.trim(),
        phone: phone.trim(),
        category: category.trim(),
        address: address.trim(),
        latitude: latitude,
        longitude: longitude,
        bannerHeadline: 'Kantin resmi kampus GasKampus',
        bannerTheme: bannerTheme,
        isOpen: true,
        isClaimed: false, // Status belum diklaim
        registeredBy: 'admin',
        rating: 5.0,
        totalOrders: 0,
        menus: const [], // Tanpa menu, sesuai kesepakatan tim
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(newMerchant.toMap(), SetOptions(merge: true));

      // Masukkan ke cache sesi jika ada
      final idx =
          MerchantService.sessionMerchants.indexWhere((m) => m.id == merchantId);
      if (idx >= 0) {
        MerchantService.sessionMerchants[idx] = newMerchant;
      } else {
        MerchantService.sessionMerchants.insert(0, newMerchant);
      }

      return {
        'success': true,
        'id': merchantId,
        'storeName': storeName.trim(),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Ubah status Buka / Tutup toko oleh Admin.
  static Future<void> toggleStoreOpen(String merchantId, bool isOpen) async {
    await _db.collection('merchants').doc(merchantId).set({
      'isOpen': isOpen,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// Perbarui informasi pemetaan toko oleh Admin.
  static Future<void> updateMerchant({
    required String merchantId,
    required String name,
    required String ownerName,
    required String phone,
    required String category,
    required String address,
    required String bannerHeadline,
    required String bannerTheme,
  }) async {
    final now = DateTime.now();
    await _db.collection('merchants').doc(merchantId).set({
      'name': name.trim(),
      'ownerName': ownerName.trim(),
      'phone': phone.trim(),
      'category': category.trim(),
      'address': address.trim(),
      'bannerHeadline': bannerHeadline.trim(),
      'bannerTheme': bannerTheme.trim(),
      'updatedAt': now.toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// Hapus titik toko makanan dari Firestore.
  static Future<void> deleteMerchant(String merchantId) async {
    await _db.collection('merchants').doc(merchantId).delete();
    MerchantService.sessionMerchants.removeWhere((m) => m.id == merchantId);
  }
}
