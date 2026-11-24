import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/merchant_model.dart';
import 'merchant_service.dart';

/// Service khusus untuk Admin dalam mendaftarkan dan mengelola akun Merchant / Kantin Kampus.
/// Menggunakan secondary FirebaseApp agar sesi login Admin saat ini TIDAK ter-logout
/// saat membuatkan akun auth baru untuk merchant.
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

  /// Pendaftaran Merchant Baru oleh Admin.
  /// Membuat akun di Firebase Auth, dokumen `users/{uid}`, dan dokumen `merchants/{uid}`.
  static Future<Map<String, dynamic>> registerMerchantByAdmin({
    required String email,
    required String password,
    required String storeName,
    required String ownerName,
    required String phone,
    required String category,
    required String address,
    double latitude = 3.5625,
    double longitude = 98.6565,
    String bannerTheme = 'orange',
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // 1. Inisialisasi FirebaseApp sementara untuk membuat akun Auth tanpa mengganggu sesi Admin
      final appName = 'MerchantReg_${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      final auth = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final String uid = cred.user!.uid;
      final now = DateTime.now();

      // 2. Simpan profil user dengan role 'merchant' di koleksi `users/{uid}`
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': ownerName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': 'merchant',
        'storeName': storeName.trim(),
        'storeCategory': category.trim(),
        'storeAddress': address.trim(),
        'isActive': true,
        'isVerified': true,
        'registeredBy': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Simpan data toko lengkap di koleksi `merchants/{uid}`
      final newMerchant = MerchantModel(
        id: uid,
        ownerUid: uid,
        name: storeName.trim(),
        ownerName: ownerName.trim(),
        phone: phone.trim(),
        category: category.trim(),
        address: address.trim(),
        latitude: latitude,
        longitude: longitude,
        bannerHeadline: 'Pesan makanan lezat langsung ke kampus!',
        bannerTheme: bannerTheme,
        isOpen: true,
        rating: 5.0,
        totalOrders: 0,
        menus: const [],
        createdAt: now,
        updatedAt: now,
      );

      await _db
          .collection('merchants')
          .doc(uid)
          .set(newMerchant.toMap(), SetOptions(merge: true));

      // Masukkan ke cache sesi MerchantService
      final idx = MerchantService.sessionMerchants.indexWhere((m) => m.id == uid);
      if (idx >= 0) {
        MerchantService.sessionMerchants[idx] = newMerchant;
      } else {
        MerchantService.sessionMerchants.insert(0, newMerchant);
      }

      return {
        'success': true,
        'uid': uid,
        'email': email.trim(),
        'storeName': storeName.trim(),
      };
    } on FirebaseAuthException catch (e) {
      String msg = 'Gagal mendaftarkan merchant: ${e.message}';
      if (e.code == 'email-already-in-use') {
        msg = 'Email "$email" sudah terdaftar di sistem. Gunakan email lain.';
      } else if (e.code == 'weak-password') {
        msg = 'Password terlalu lemah. Minimal 6 karakter.';
      } else if (e.code == 'invalid-email') {
        msg = 'Format email tidak valid.';
      }
      return {'success': false, 'error': msg};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }
    }
  }

  /// Ubah status Buka / Tutup toko oleh Admin.
  static Future<void> toggleStoreOpen(String merchantId, bool isOpen) async {
    await _db.collection('merchants').doc(merchantId).set({
      'isOpen': isOpen,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// Perbarui informasi toko oleh Admin.
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

    // Sinkronkan juga ke koleksi users jika dokumen ada
    await _db.collection('users').doc(merchantId).set({
      'name': ownerName.trim(),
      'phone': phone.trim(),
      'storeName': name.trim(),
      'storeCategory': category.trim(),
      'storeAddress': address.trim(),
    }, SetOptions(merge: true)).catchError((_) {});
  }

  /// Hapus data toko makanan dari Firestore.
  static Future<void> deleteMerchant(String merchantId) async {
    await _db.collection('merchants').doc(merchantId).delete();
    // Nonaktifkan akun di users agar tidak bisa beroperasi
    await _db.collection('users').doc(merchantId).set({
      'isActive': false,
      'status': 'deleted',
      'deletedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((_) {});

    // Hapus dari cache sesi
    MerchantService.sessionMerchants.removeWhere((m) => m.id == merchantId);
  }
}
