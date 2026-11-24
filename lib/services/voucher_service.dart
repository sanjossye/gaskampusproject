import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voucher_model.dart';

/// Service untuk mengelola voucher & promo secara realtime di Cloud Firestore.
/// Koleksi Firestore: `vouchers` (English collection name).
class VoucherService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'vouchers';

  static CollectionReference<Map<String, dynamic>> get _vouchersCol =>
      _firestore.collection(collectionName);

  /// Default voucher sampel awal jika di Firestore belum ada data
  static List<VoucherModel> get defaultVouchers => [
    VoucherModel(
      id: 'default_1',
      code: 'MABAGAS',
      title: 'Diskon Mahasiswa Baru 50%',
      description: 'Min. order Rp10rb untuk semua rute antar kampus',
      category: 'ANTAR',
      discountType: 'percent',
      discountValue: 50,
      maxDiscount: 5000,
      minOrder: 10000,
      validUntilText: 'Hingga 30 Nov 2026',
      quota: 200,
      usedCount: 24,
      createdAt: DateTime.now(),
    ),
    VoucherModel(
      id: 'default_2',
      code: 'MAKANHEMAT',
      title: 'Gratis Ongkir Kantin Kampus',
      description: 'Khusus pesanan makan dari kantin fakultas',
      category: 'MAKAN',
      discountType: 'fixed',
      discountValue: 4000,
      minOrder: 15000,
      validUntilText: 'Hingga 15 Des 2026',
      quota: 150,
      usedCount: 42,
      createdAt: DateTime.now(),
    ),
    VoucherModel(
      id: 'default_3',
      code: 'GASPAYSERU',
      title: 'Cashback 30% Koin GasPay',
      description: 'Maksimal Rp10.000 untuk top-up dan bayar ojek',
      category: 'DOMPET',
      discountType: 'percent',
      discountValue: 30,
      maxDiscount: 10000,
      minOrder: 20000,
      validUntilText: 'Hingga 25 Nov 2026',
      quota: 100,
      usedCount: 65,
      createdAt: DateTime.now(),
    ),
    VoucherModel(
      id: 'default_4',
      code: 'JASTIPATK',
      title: 'Potongan Jastip ATK & Print Rp5.000',
      description: 'Fotokopi, print tugas, dan jastip modul kelas',
      category: 'TITIP',
      discountType: 'fixed',
      discountValue: 5000,
      minOrder: 10000,
      validUntilText: 'Hingga 10 Des 2026',
      quota: 80,
      usedCount: 18,
      createdAt: DateTime.now(),
    ),
  ];

  /// Stream seluruh voucher untuk Admin (semua status: aktif & nonaktif)
  static Stream<List<VoucherModel>> streamAllVouchers() {
    return _vouchersCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return defaultVouchers;
      }
      return snapshot.docs
          .map((doc) => VoucherModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream voucher aktif untuk Mahasiswa di halaman Promo & Pesanan
  static Stream<List<VoucherModel>> streamActiveVouchers() {
    return _vouchersCol
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return defaultVouchers;
      }
      final list = snapshot.docs
          .map((doc) => VoucherModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Tambah voucher baru oleh Admin ke Firestore
  static Future<String> createVoucher(VoucherModel voucher) async {
    final docRef = await _vouchersCol.add(voucher.toMap());
    return docRef.id;
  }

  /// Update data voucher
  static Future<void> updateVoucher(VoucherModel voucher) async {
    await _vouchersCol.doc(voucher.id).update(voucher.toMap());
  }

  /// Ubah status aktif/nonaktif voucher
  static Future<void> toggleVoucherStatus(String id, bool isActive) async {
    await _vouchersCol.doc(id).update({
      'isActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Hapus voucher dari Firestore
  static Future<void> deleteVoucher(String id) async {
    await _vouchersCol.doc(id).delete();
  }

  /// Inisialisasi awal voucher default ke Firestore jika kosong
  static Future<void> seedDefaultVouchersIfEmpty() async {
    try {
      final snap = await _vouchersCol.limit(1).get();
      if (snap.docs.isEmpty) {
        final batch = _firestore.batch();
        for (final v in defaultVouchers) {
          final ref = _vouchersCol.doc();
          batch.set(ref, v.toMap());
        }
        await batch.commit();
      }
    } catch (_) {}
  }
}
