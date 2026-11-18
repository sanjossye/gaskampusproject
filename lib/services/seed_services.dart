import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_services.dart';

/// Mengisi data dummy ke Firebase (Auth + Firestore). Hanya untuk development.
/// Akun demo (password semua: gaskampus123):
///   mahasiswa  -> username "mahasiswa",  NIM "140610240001", HP "081200000001"
///   mahasiswa2 -> username "mahasiswa2", NIM "140610240010", HP "081200000010"
///   mahasiswa3 -> username "mahasiswa3", NIM "140610240011", HP "081200000011"
///   driverm    -> username "driverm",    NIM "140810230002", HP "081200000002"
///   driverm2   -> username "driverm2",   NIM "140810230012", HP "081200000012"
///   driveru    -> username "driveru",    tanpa NIM,          HP "081200000003"
///   driveru2   -> username "driveru2",   tanpa NIM,          HP "081200000013"
///   admin      -> username "admin",      tanpa NIM,          tanpa HP
class SeedService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String demoPassword = 'gaskampus123';

  static final List<Map<String, dynamic>> _demoUsers = [
    // ── Mahasiswa ────────────────────────────────────────────────────────────
    {
      'username': 'mahasiswa',
      'email': 'mahasiswa.demo@gaskampus-dev.com',
      'name': 'Ahmad Zaki',
      'role': 'mahasiswa',
      'nim': '140610240001',
      'phone': '081200000001',
      'facultas': 'FISIP',
      'isVerified': true,
      'walletBalance': 75000,
      'walletCoins': 3500,
    },
    {
      'username': 'mahasiswa2',
      'email': 'mahasiswa2.demo@gaskampus-dev.com',
      'name': 'Siti Nurhaliza',
      'role': 'mahasiswa',
      'nim': '140610240010',
      'phone': '081200000010',
      'facultas': 'Fakultas Teknik',
      'isVerified': true,
      'walletBalance': 125000,
      'walletCoins': 8200,
    },
    {
      'username': 'mahasiswa3',
      'email': 'mahasiswa3.demo@gaskampus-dev.com',
      'name': 'Rafi Alamsyah',
      'role': 'mahasiswa',
      'nim': '140610240011',
      'phone': '081200000011',
      'facultas': 'FMIPA',
      'isVerified': true,
      'walletBalance': 32000,
      'walletCoins': 1250,
    },

    // ── Driver Kampus ────────────────────────────────────────────────────────
    {
      'username': 'driverm',
      'email': 'driverm.demo@gaskampus-dev.com',
      'name': 'Budi Santoso',
      'role': 'driver_kampus',
      'nim': '140810230002',
      'phone': '081200000002',
      'facultas': 'FMIPA',
      'isVerified': true,
      'rating': 4.9,
      'totalTrips': 120,
      'walletBalance': 210000,
      'walletCoins': 500,
      'driverProfile': {
        'vehicleType': 'motor',
        'vehiclePlate': 'D 1234 GKS',
        'vehicleBrand': 'Honda Vario 125',
        'isOnline': true,
      },
      'schedules': [
        {'courseName': 'Kalkulus II', 'room': 'R.302', 'building': 'Gedung C', 'dayOfWeek': 1, 'startTime': '08:00', 'endTime': '10:00'},
        {'courseName': 'Fisika Dasar', 'room': 'R.204', 'building': 'Gedung B', 'dayOfWeek': 1, 'startTime': '13:00', 'endTime': '15:00'},
        {'courseName': 'Algoritma Pemrograman', 'room': 'Lab Kom 2', 'building': 'Gedung D', 'dayOfWeek': 3, 'startTime': '10:00', 'endTime': '12:00', 'courseType': 'praktikum'},
      ],
    },
    {
      'username': 'driverm2',
      'email': 'driverm2.demo@gaskampus-dev.com',
      'name': 'Siti Aminah',
      'role': 'driver_kampus',
      'nim': '140810230012',
      'phone': '081200000012',
      'facultas': 'FEB',
      'isVerified': true,
      'rating': 5.0,
      'totalTrips': 98,
      'walletBalance': 165000,
      'walletCoins': 750,
      'driverProfile': {
        'vehicleType': 'motor',
        'vehiclePlate': 'D 4567 KMP',
        'vehicleBrand': 'Yamaha Fazzio',
        'isOnline': true,
      },
      'schedules': [
        {'courseName': 'Ekonomi Mikro', 'room': 'R.101', 'building': 'Gedung A', 'dayOfWeek': 2, 'startTime': '08:00', 'endTime': '10:00'},
        {'courseName': 'Akuntansi Dasar', 'room': 'R.205', 'building': 'Gedung B', 'dayOfWeek': 4, 'startTime': '10:00', 'endTime': '12:00'},
      ],
    },

    // ── Driver Umum ──────────────────────────────────────────────────────────
    {
      'username': 'driveru',
      'email': 'driveru.demo@gaskampus-dev.com',
      'name': 'Agus Prabowo',
      'role': 'driver_umum',
      'nik': '3276012345670001',
      // tanpa NIM
      'phone': '081200000003',
      'isVerified': true,
      'rating': 4.7,
      'totalTrips': 512,
      'walletBalance': 340000,
      'walletCoins': 300,
      'driverProfile': {
        'vehicleType': 'motor',
        'vehiclePlate': 'D 5678 UMM',
        'vehicleBrand': 'Honda Beat',
        'isOnline': true,
      },
    },
    {
      'username': 'driveru2',
      'email': 'driveru2.demo@gaskampus-dev.com',
      'name': 'Rizky Pratama',
      'role': 'driver_umum',
      'nik': '3276012345670013',
      // tanpa NIM
      'phone': '081200000013',
      'isVerified': true,
      'rating': 4.8,
      'totalTrips': 310,
      'walletBalance': 85000,
      'walletCoins': 100,
      'driverProfile': {
        'vehicleType': 'motor',
        'vehiclePlate': 'D 9012 UMM',
        'vehicleBrand': 'Honda Beat Street',
        'isOnline': false,
      },
    },

    // ── Admin ────────────────────────────────────────────────────────────────
    {
      'username': 'admin',
      'email': 'admin.demo@gaskampus-dev.com',
      'name': 'Admin Kampus',
      'role': 'admin',
      // tanpa NIM, tanpa HP
      'isVerified': true,
      'walletBalance': 0,
      'walletCoins': 0,
    },
  ];

  /// Buat akun demo di Auth + profil + login_index di Firestore. Aman dijalankan berulang.
  Future<List<String>> seedDemoAccounts() async {
    final log = <String>[];
    final now = DateTime.now().toIso8601String();

    for (final u in _demoUsers) {
      final email = u['email'] as String? ?? '${u['username']}@gaskampus-dev.com';
      final username = u['username'] as String;
      String uid;

      // ── 1. Buat / ambil akun Auth ──────────────────────────────────────────
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: demoPassword,
        );
        uid = cred.user!.uid;
        log.add('Auth dibuat: $email');
      } on FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') rethrow;
        final cred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: demoPassword,
        );
        uid = cred.user!.uid;
        log.add('Auth sudah ada: $email');
      }

      // ── 2. Normalisasi identifier ──────────────────────────────────────────
      final normalizedUsername = AuthService.normalizeIdentifier(username);
      final String? normalizedNim = u['nim'] != null
          ? AuthService.normalizeIdentifier(u['nim'] as String)
          : null;
      final String? normalizedPhone = u['phone'] != null
          ? AuthService.normalizeIdentifier(u['phone'] as String)
          : null;

      // ── 3. Tulis users/{uid} dan login_index dalam satu batch ──────────────
      final dp = u['driverProfile'] as Map<String, dynamic>?;
      final bool isOnline = dp != null ? (dp['isOnline'] == true) : false;

      final batch = _db.batch();

      batch.set(_db.collection('users').doc(uid), {
        'name': u['name'],
        'email': email,
        'username': normalizedUsername,
        'nim': normalizedNim,
        'phone': normalizedPhone,
        'photoUrl': null,
        'role': u['role'],
        'facultas': u['facultas'],
        'isVerified': u['isVerified'] ?? false,
        'isActive': true,
        'isOnline': isOnline,
        'vehiclePlate': dp?['vehiclePlate'],
        'vehicleBrand': dp?['vehicleBrand'],
        'rating': u['rating'] ?? 0.0,
        'totalTrips': u['totalTrips'] ?? 0,
        'createdAt': now,
        'updatedAt': now,
      });

      // login_index: username (selalu ada)
      batch.set(_db.collection('login_index').doc(normalizedUsername), {
        'email': email,
        'uid': uid,
        'type': 'username',
      });

      // login_index: NIM (jika ada)
      if (normalizedNim != null) {
        batch.set(_db.collection('login_index').doc(normalizedNim), {
          'email': email,
          'uid': uid,
          'type': 'nim',
        });
      }

      // login_index: phone (jika ada)
      if (normalizedPhone != null) {
        batch.set(_db.collection('login_index').doc(normalizedPhone), {
          'email': email,
          'uid': uid,
          'type': 'phone',
        });
      }

      await batch.commit();

      // ── 4. Sub-collection driver_profile ───────────────────────────────────
      if (dp != null) {
        await _db
            .collection('users')
            .doc(uid)
            .collection('driver_profile')
            .doc(uid)
            .set({
          ...dp,
          'status': isOnline ? 'available' : 'offline',
          'memberSince': now,
        });
      }

      // ── 5. Sub-collection schedules ────────────────────────────────────────
      final schedules = (u['schedules'] as List? ?? []);
      for (var i = 0; i < schedules.length; i++) {
        final s = schedules[i] as Map<String, dynamic>;
        await _db
            .collection('users')
            .doc(uid)
            .collection('schedules')
            .doc('seed_$i')
            .set({
          'userId': uid,
          'courseType': 'regular',
          ...s,
          'createdAt': now,
        });
      }

      // ── 6. Wallet ─────────────────────────────────────────────────────────
      final walletBal = u['walletBalance'] ?? (u['role'] == 'mahasiswa' ? 50000 : 0);
      await _db.collection('wallets').doc(uid).set({
        'userId': uid,
        'balance': walletBal,
        'coins': u['walletCoins'] ?? 0,
        'updatedAt': now,
      });

      // Transaksi awal dompet demo
      await _db
          .collection('wallets')
          .doc(uid)
          .collection('transactions')
          .doc('init_balance')
          .set({
        'transactionId': 'init_balance',
        'walletId': uid,
        'type': 'topup',
        'amount': walletBal,
        'description': 'Saldo Awal Akun Demo',
        'createdAt': now,
      });

      // ── 7. Dokumen (KTP untuk Driver Umum, KTM untuk Mahasiswa) ─────────────
      if (u['role'] == 'driver_umum') {
        final nik = u['nik'] ?? '3276012345670001';
        // Subkoleksi documents/ktp
        await _db
            .collection('users')
            .doc(uid)
            .collection('documents')
            .doc('ktp')
            .set({
          'base64':
              '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=',
          'contentType': 'image/jpeg',
          'fileName': 'scaled_IMG_0226.jpg',
          'nik': nik,
          'uploadedAt': now,
          'docType': 'ktp',
        });

        // Subkoleksi documents/sim
        await _db
            .collection('users')
            .doc(uid)
            .collection('documents')
            .doc('sim')
            .set({
          'base64':
              '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=',
          'contentType': 'image/jpeg',
          'fileName': 'sim_c_driver.jpg',
          'uploadedAt': now,
          'docType': 'sim',
        });

        // Buat 1 contoh pesanan aktif dan 1 riwayat selesai untuk driver umum
        if (username == 'driveru') {
          // Order Selesai (GasPay)
          await _db.collection('orders').doc('demo_order_completed').set({
            'orderId': 'demo_order_completed',
            'driverId': uid,
            'passengerName': 'Andi Pratama',
            'passengerPhone': '08123456789',
            'passengerRole': 'mahasiswa',
            'pickupAddress': 'Stasiun Depok Baru',
            'dropoffAddress': 'Gedung C - Zona B (Fakultas Teknik)',
            'destinationZoneId': 'Zona B',
            'fareAmount': 15000,
            'commissionAmount': 2250,
            'netEarnings': 12750,
            'paymentMethod': 'GasPay',
            'matchTier': 3,
            'distanceKm': 2.5,
            'status': 'completed',
            'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
            'completedAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          });

          // Transaksi pendapatan
          await _db
              .collection('wallets')
              .doc(uid)
              .collection('transactions')
              .doc('tx_order_demo')
              .set({
            'transactionId': 'tx_order_demo',
            'walletId': uid,
            'type': 'earning',
            'amount': 12750,
            'description': 'Pendapatan Bersih Trip GasPay #demo_order_completed (Tarif Rp 15.000 - Komisi Rp 2.250)',
            'relatedOrderId': 'demo_order_completed',
            'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          });
        }
      }

      log.add('Firestore diisi: users/$uid (${u['role']})');
      await _auth.signOut();
    }
    return log;
  }
}
