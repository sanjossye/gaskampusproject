import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Service autentikasi: Firebase Auth (email + password) + profil di Firestore `users/{uid}`.
/// Password TIDAK pernah disimpan di Firestore — hanya di Firebase Auth.
///
/// Login menggunakan `login_index` collection di Firestore:
/// - Document ID = identifier yang sudah dinormalisasi (NIM / username / nomor HP)
/// - Fields: { email, uid, type }
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _loginIndex => _db.collection('login_index');

  User? get currentUser => _auth.currentUser;

  // ─── Normalisasi Identifier ────────────────────────────────────────────────

  /// Normalisasi identifier login: trim, lowercase, format nomor HP.
  /// Dipakai saat register, seed, dan login.
  static String normalizeIdentifier(String input) {
    var value = input.trim().toLowerCase();

    // Jika mengandung karakter non-angka khas nomor HP (+ atau -) atau diawali 0/+62,
    // coba normalisasi sebagai nomor HP terlebih dahulu.
    // Hapus semua karakter selain angka dan leading '+'
    final stripped = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Deteksi apakah input bermaksud sebagai nomor HP:
    // - diawali +62 atau 62 (setelah strip)
    // - diawali 0 dan cukup panjang (minimal 9 digit setelah strip)
    if (value.startsWith('+62') || value.startsWith('62') || value.startsWith('0')) {
      String phone = stripped;
      if (phone.startsWith('0')) {
        phone = '62${phone.substring(1)}';
      }
      // Cek apakah hasilnya memenuhi format nomor HP (10-15 digit, diawali 62)
      if (phone.startsWith('62') && phone.length >= 10 && phone.length <= 15) {
        return phone;
      }
    }

    // Bukan nomor HP -> kembalikan apa adanya (trim + lowercase)
    return value;
  }

  /// Deteksi tipe identifier yang sudah dinormalisasi.
  /// - Diawali "62" dan panjang 10–15 digit -> phone
  /// - Seluruhnya angka -> nim
  /// - Selain itu -> username
  static String detectIdentifierType(String normalized) {
    if (RegExp(r'^\d+$').hasMatch(normalized)) {
      if (normalized.startsWith('62') && normalized.length >= 10 && normalized.length <= 15) {
        return 'phone';
      }
      return 'nim';
    }
    return 'username';
  }

  // ─── Register ──────────────────────────────────────────────────────────────

  /// Registrasi: buat user di Auth, lalu simpan profil + login_index di Firestore.
  /// [username] wajib, unik, huruf kecil, tanpa spasi.
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String username,
    required String role, // mahasiswa, driver_kampus, driver_umum, admin
    String? nim,
    String? nik,
    String? phone,
    String? faculty,
  }) async {
    final normalizedUsername = normalizeIdentifier(username);

    // Validasi format username (hanya huruf, angka, underscore, tanpa spasi)
    if (normalizedUsername.contains(' ') || normalizedUsername.isEmpty) {
      throw Exception('Username tidak boleh kosong atau mengandung spasi.');
    }

    // Kumpulkan semua identifier yang perlu dicek
    final identifiers = <String, String>{
      normalizedUsername: 'username',
    };
    if (nim != null && nim.isNotEmpty) {
      identifiers[normalizeIdentifier(nim)] = 'nim';
    }
    if (nik != null && nik.isNotEmpty) {
      identifiers[normalizeIdentifier(nik)] = 'nik';
    }
    if (phone != null && phone.isNotEmpty) {
      identifiers[normalizeIdentifier(phone)] = 'phone';
    }

    // Cek apakah identifier sudah dipakai
    for (final entry in identifiers.entries) {
      final doc = await _loginIndex.doc(entry.key).get();
      if (doc.exists) {
        final label = switch (entry.value) {
          'username' => 'Username',
          'nim' => 'NIM',
          'nik' => 'NIK',
          'phone' => 'Nomor HP',
          _ => 'Identifier',
        };
        throw Exception('$label "${entry.key}" sudah dipakai.');
      }
    }

    // Buat akun di Firebase Auth
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final now = DateTime.now();
    final normalizedPhone = (phone != null && phone.isNotEmpty)
        ? normalizeIdentifier(phone)
        : null;

    final user = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email.trim().toLowerCase(),
      username: normalizedUsername,
      nim: nim,
      nik: nik,
      phone: normalizedPhone,
      role: role,
      facultas: faculty,
      isVerified: role == 'mahasiswa' || role == 'admin',
      createdAt: now,
      updatedAt: now,
    );

    // Tulis users/{uid}, wallets/{uid}, dan semua dokumen login_index dalam satu WriteBatch
    final batch = _db.batch();
    batch.set(_users.doc(user.uid), user.toMap());
    batch.set(_db.collection('wallets').doc(user.uid), {
      'userId': user.uid,
      'balance': role == 'mahasiswa' ? 50000 : 0,
      'coins': 0,
      'updatedAt': now.toIso8601String(),
    });

    for (final entry in identifiers.entries) {
      batch.set(_loginIndex.doc(entry.key), {
        'email': user.email,
        'uid': user.uid,
        'type': entry.value,
      });
    }

    await batch.commit();
    return user;
  }

  // ─── Login ─────────────────────────────────────────────────────────────────

  /// Login dengan NIM, username, atau nomor HP + password.
  /// User TIDAK perlu mengetik email.
  Future<UserModel> login(String identifier, String password) async {
    // 1. Normalisasi identifier
    final normalized = normalizeIdentifier(identifier);

    // 2. Baca dokumen login_index/{identifier}
    final indexDoc = await _loginIndex.doc(normalized).get();
    if (!indexDoc.exists) {
      throw Exception('NIM/username/nomor HP tidak terdaftar.');
    }
    final indexData = indexDoc.data()!;
    final email = indexData['email'] as String;

    // 3. signInWithEmailAndPassword
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 4. Ambil users/{uid}, cek isActive
    final doc = await _users.doc(cred.user!.uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw Exception('Profil user belum ada di Firestore (users/${cred.user!.uid}).');
    }
    final user = UserModel.fromMap(doc.data()!, doc.id);
    if (!user.isActive) {
      await _auth.signOut();
      throw Exception('Akun kamu sedang dinonaktifkan admin.');
    }
    return user;
  }

  Future<void> logout() => _auth.signOut();

  // ─── Error Handling ────────────────────────────────────────────────────────

  /// Ubah error Firebase Auth jadi pesan yang bisa dibaca user.
  static String readableError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Password salah atau akun tidak ditemukan.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'email-already-in-use':
          return 'Email sudah terdaftar.';
        case 'weak-password':
          return 'Password minimal 6 karakter.';
        case 'operation-not-allowed':
          return 'Login Email/Password belum diaktifkan di Firebase Console.';
        case 'network-request-failed':
          return 'Tidak ada koneksi internet.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan, coba lagi beberapa menit lagi.';
        default:
          return 'Gagal (${e.code}).';
      }
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}
