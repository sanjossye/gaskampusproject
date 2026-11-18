import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service untuk mengelola dokumen driver dan mahasiswa di Cloud Firestore.
/// Format struktur mengikuti skema Firestore:
/// - Mahasiswa    : `users/{uid}/documents/ktm`
/// - Driver Umum  : `users/{uid}/documents/ktp`, `users/{uid}/documents/sim`, `users/{uid}/documents/stnk`
class DocumentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  /// Sample base64 placeholder untuk simulasi upload dokumen KTP
  static const String sampleKtpBase64 =
      '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=';

  /// Menyimpan dokumen KTP untuk Driver Umum
  /// Path: `users/{uid}/documents/ktp`
  Future<void> uploadKtpDriverUmum({
    required String uid,
    required String nik,
    String? base64Data,
    String fileName = 'scaled_IMG_0226.jpg',
    bool? setUnverified,
  }) async {
    final now = DateTime.now().toIso8601String();
    final data = {
      'base64': base64Data ?? sampleKtpBase64,
      'contentType': 'image/jpeg',
      'fileName': fileName,
      'nik': nik,
      'uploadedAt': now,
      'docType': 'ktp',
    };

    final batch = _db.batch();

    // 1. Simpan ke subcollection documents/ktp
    final docRef = _db.collection('users').doc(uid).collection('documents').doc('ktp');
    batch.set(docRef, data, SetOptions(merge: true));

    // 2. Simpan metadata di root user document
    final userRef = _db.collection('users').doc(uid);
    final userUpdate = <String, dynamic>{
      'nik': nik,
      'ktpStorage': 'firestore_base64',
      'ktpUploadedAt': now,
      'updatedAt': now,
    };
    if (setUnverified == true) {
      userUpdate['isVerified'] = false;
    }
    batch.update(userRef, userUpdate);

    await batch.commit();
  }

  /// Mengambil data dokumen KTP Driver Umum
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamKtpDocument(String uid) {
    return _db.collection('users').doc(uid).collection('documents').doc('ktp').snapshots();
  }

  /// Stream seluruh dokumen driver (KTP, SIM, STNK)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllDocuments(String uid) {
    return _db.collection('users').doc(uid).collection('documents').snapshots();
  }
}
