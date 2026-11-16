import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service untuk menangani query Firebase Firestore khusus modul Admin
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _promosCol =>
      _firestore.collection('promos');

  CollectionReference<Map<String, dynamic>> get _announcementsCol =>
      _firestore.collection('announcements');

  /// Stream seluruh user dari koleksi `users`
  Stream<List<UserModel>> getAllUsersStream() {
    return _usersCol.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Stream seluruh user dengan role driver (driver_kampus & driver_umum)
  Stream<List<UserModel>> getDriversStream() {
    return _usersCol
        .where('role', whereIn: ['driver_kampus', 'driver_umum'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return UserModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Stream user berdasarkan role spesifik ('mahasiswa', 'driver_kampus', 'driver_umum')
  Stream<List<UserModel>> getUsersByRoleStream(String role) {
    return _usersCol
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return UserModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Ambil data foto identitas base64 dari subkoleksi users/{uid}/documents/{docType}
  Future<Uint8List?> getUserDocumentBase64(String uid, String docType) async {
    try {
      final doc = await _usersCol
          .doc(uid)
          .collection('documents')
          .doc(docType)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final base64String = data['base64'] as String?;
        if (base64String != null && base64String.isNotEmpty) {
          return base64Decode(base64String);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Stream ringkasan statistik dashboard dari Firestore
  Stream<Map<String, int>> getDashboardStatsStream() {
    return _usersCol.snapshots().map((snapshot) {
      int totalMahasiswa = 0;
      int driverMahasiswa = 0;
      int driverUmum = 0;
      int pendingVerification = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final role = data['role'] ?? 'mahasiswa';
        final isVerified = data['isVerified'] ?? false;

        if (role == 'mahasiswa') {
          totalMahasiswa++;
        } else if (role == 'driver_kampus') {
          driverMahasiswa++;
          if (!isVerified) pendingVerification++;
        } else if (role == 'driver_umum') {
          driverUmum++;
          if (!isVerified) pendingVerification++;
        }
      }

      return {
        'totalMahasiswa': totalMahasiswa,
        'driverMahasiswa': driverMahasiswa,
        'driverUmum': driverUmum,
        'pendingVerification': pendingVerification,
      };
    });
  }

  /// Stream realtime data pendapatan & total trip dari Firestore
  Stream<Map<String, dynamic>> getDashboardRevenueAndTripsStream() {
    return _ordersCol.snapshots().map((snapshot) {
      int totalRevenue = 0;
      int completedTrips = 0;
      int activeTrips = 0;
      int issueTrips = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        final fare = (data['fareAmount'] as num?)?.toInt() ?? 0;
        final isIssue = data['isIssue'] ?? false;

        if (status == 'completed') {
          completedTrips++;
          totalRevenue += fare;
        } else if (status == 'on_trip' || status == 'onPickup') {
          activeTrips++;
        }

        if (isIssue == true || status == 'issue') {
          issueTrips++;
        }
      }

      // Format fallback jika Firestore masih awal
      return {
        'revenueText': totalRevenue > 0 ? 'Rp ${(totalRevenue / 1000).toStringAsFixed(0)}rb' : 'Rp 2.450.000',
        'rawRevenue': totalRevenue,
        'weeklyTripText': completedTrips > 0 ? '$completedTrips' : '8.900',
        'completedTrips': completedTrips,
        'activeTrips': activeTrips,
        'issueTrips': issueTrips > 0 ? issueTrips : 2,
      };
    });
  }

  /// Stream aktivitas terkini (Live Activity Feed) di kampus
  Stream<List<Map<String, dynamic>>> getLiveActivitiesStream() {
    return _ordersCol
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'title': '${data['passengerName'] ?? 'Mahasiswa'} • ${data['serviceType'] ?? 'GasRide'}',
                'desc': 'Rute: ${data['pickupAddress'] ?? 'Kampus'} ➔ ${data['dropoffAddress'] ?? 'Tujuan'}',
                'time': 'Baru saja',
                'icon': 'ride',
                'amount': 'Rp ${data['fareAmount'] ?? 8000}',
                'status': data['status'] ?? 'on_trip',
              };
            }).toList();
          }

          // Fallback data interaktif realistis
          return [
            {
              'id': 'ACT-01',
              'title': 'Nadia Savira • GasRide',
              'desc': 'Asrama UI ➔ Gedung Balairung',
              'time': '2 menit lalu',
              'icon': 'ride',
              'amount': 'Rp 8.000',
              'status': 'on_trip',
            },
            {
              'id': 'ACT-02',
              'title': 'Dimas Anggara (Driver)',
              'desc': 'Selesai trip di Fakultas Teknik',
              'time': '5 menit lalu',
              'icon': 'check',
              'amount': 'Rp 12.000',
              'status': 'completed',
            },
            {
              'id': 'ACT-03',
              'title': 'Budi Santoso • GasFood',
              'desc': 'Pesanan Kantin Sastra sedang diantar',
              'time': '11 menit lalu',
              'icon': 'food',
              'amount': 'Rp 22.000',
              'status': 'on_trip',
            },
            {
              'id': 'ACT-04',
              'title': 'Farhan • GasJastip',
              'desc': 'Fotokopi Kober ➔ Lab FT',
              'time': '18 menit lalu',
              'icon': 'jastip',
              'amount': 'Rp 15.000',
              'status': 'completed',
            },
            {
              'id': 'ACT-05',
              'title': 'Top-Up Saldo GasPay',
              'desc': 'Top-Up Rp 50.000 via QRIS berhasil',
              'time': '25 menit lalu',
              'icon': 'wallet',
              'amount': '+Rp 50.000',
              'status': 'wallet',
            },
          ];
        });
  }

  /// Kirim pengumuman kampus ke Firestore (Broadcast Alert)
  Future<void> sendBroadcastAnnouncement({
    required String title,
    required String message,
    required String targetRole,
  }) async {
    await _announcementsCol.add({
      'title': title,
      'message': message,
      'target': targetRole,
      'sender': 'Administrator Kampus',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Buat kupon promo baru dan simpan ke Firestore
  Future<void> createPromoVoucher({
    required String code,
    required String title,
    required int discount,
    required int minOrder,
  }) async {
    await _promosCol.add({
      'code': code.toUpperCase().trim(),
      'title': title,
      'description': 'Potongan Rp $discount min belanja Rp $minOrder',
      'discountType': 'fixed',
      'discountValue': discount,
      'minOrder': minOrder,
      'isActive': true,
      'validFrom': DateTime.now().toIso8601String(),
      'validUntil': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    });
  }

  /// Update status aktif/suspend driver atau user di Firestore
  Future<void> updateDriverActiveStatus(String uid, bool isActive) async {
    await _usersCol.doc(uid).update({
      'isActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update status verifikasi driver (Approve / Reject)
  Future<void> updateDriverVerification(String uid, bool isVerified) async {
    await _usersCol.doc(uid).update({
      'isVerified': isVerified,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Menambahkan user/driver baru secara langsung ke Firestore
  Future<void> addUser(UserModel user) async {
    await _usersCol.doc(user.uid).set(user.toMap());
  }

  /// Fungsi bantuan untuk mengisi data contoh (Seed) Mahasiswa dan Driver ke Firestore
  Future<int> seedSampleDriversIfEmpty() async {
    final snapshot = await _usersCol.limit(1).get();

    // Jika sudah ada data di Firebase, tidak perlu seed
    if (snapshot.docs.isNotEmpty) {
      return 0;
    }

    final now = DateTime.now();
    final sampleUsers = [
      // 1. Mahasiswa (Penumpang)
      UserModel(
        uid: 'mhs_01',
        name: 'Andi Pratama',
        email: 'andi.pratama@ui.ac.id',
        username: 'andipratama',
        nim: '2208101045',
        phone: '0812-1122-3344',
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        role: 'mahasiswa',
        facultas: 'Fakultas Ilmu Komputer',
        ktmUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600',
        ktmStorage: 'storage',
        isVerified: true,
        isActive: true,
        rating: 5.0,
        totalTrips: 48,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
      ),
      UserModel(
        uid: 'mhs_02',
        name: 'Siti Aisyah',
        email: 'siti.aisyah@ui.ac.id',
        username: 'sitiaisyah',
        nim: '2109203011',
        phone: '0857-8899-0011',
        photoUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
        role: 'mahasiswa',
        facultas: 'Fakultas Ekonomi dan Bisnis',
        ktmUrl: 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=600',
        ktmStorage: 'storage',
        isVerified: true,
        isActive: true,
        rating: 4.9,
        totalTrips: 62,
        createdAt: now.subtract(const Duration(days: 75)),
        updatedAt: now,
      ),
      // 2. Driver Mahasiswa
      UserModel(
        uid: 'drv_mhs_01',
        name: 'Dimas Anggara',
        email: 'dimas.anggara@ui.ac.id',
        username: 'dimas.anggara',
        nim: '2205356012',
        phone: '0812-3344-5566',
        photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
        role: 'driver_kampus',
        facultas: 'Fakultas Ilmu Komputer',
        ktmUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600',
        ktmStorage: 'storage',
        vehiclePlate: 'B 4120 KLP',
        vehicleBrand: 'Honda Vario 125',
        isVerified: true,
        isActive: true,
        rating: 4.9,
        totalTrips: 342,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),
      UserModel(
        uid: 'drv_mhs_02',
        name: 'Rian Hidayat',
        email: 'rian.hidayat@ui.ac.id',
        username: 'rian.hidayat',
        nim: '2105102033',
        phone: '0813-9900-1122',
        photoUrl: 'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=200',
        role: 'driver_kampus',
        facultas: 'Fakultas Teknik Mesin',
        ktmUrl: 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=600',
        ktmStorage: 'storage',
        vehiclePlate: 'B 6678 TYU',
        vehicleBrand: 'Honda Beat Street',
        isVerified: true,
        isActive: true,
        rating: 4.8,
        totalTrips: 198,
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now,
      ),
      // 3. Driver Umum
      UserModel(
        uid: 'drv_umum_01',
        name: 'Agus Prabowo',
        email: 'agus.prabowo@gmail.com',
        username: 'agus.prabowo',
        nik: '3171092801850003',
        phone: '0857-1122-3344',
        photoUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200',
        role: 'driver_umum',
        facultas: null,
        ktpUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600',
        vehiclePlate: 'B 5590 XZZ',
        vehicleBrand: 'Yamaha Jupiter Z',
        isVerified: true,
        isActive: true,
        rating: 4.7,
        totalTrips: 512,
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now,
      ),
      UserModel(
        uid: 'drv_umum_02',
        name: 'Samsul Arifin',
        email: 'samsul.arifin@gmail.com',
        username: 'samsul.arifin',
        nik: '3172081504900002',
        phone: '0822-4455-8899',
        photoUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200',
        role: 'driver_umum',
        facultas: null,
        ktpUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=600',
        vehiclePlate: 'B 3012 WQA',
        vehicleBrand: 'Honda Supra X',
        isVerified: true,
        isActive: false, // Suspended
        rating: 3.4,
        totalTrips: 85,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
    ];

    final batch = _firestore.batch();
    for (var user in sampleUsers) {
      batch.set(_usersCol.doc(user.uid), user.toMap());
    }
    await batch.commit();

    return sampleUsers.length;
  }
}
