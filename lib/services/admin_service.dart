import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service untuk menangani query Firebase Firestore khusus modul Admin
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

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

  /// Update status aktif/suspend driver di Firestore
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

  /// Menambahkan driver baru secara langsung ke Firestore
  Future<void> addDriver(UserModel driver) async {
    await _usersCol.doc(driver.uid).set(driver.toMap());
  }

  /// Fungsi bantuan untuk mengisi data awal (Seed) ke Firestore jika database masih kosong
  Future<int> seedSampleDriversIfEmpty() async {
    final snapshot = await _usersCol
        .where('role', whereIn: ['driver_kampus', 'driver_umum'])
        .limit(1)
        .get();

    // Jika sudah ada data di Firebase, tidak perlu seed
    if (snapshot.docs.isNotEmpty) {
      return 0;
    }

    final now = DateTime.now();
    final sampleDrivers = [
      UserModel(
        uid: 'drv_mhs_01',
        name: 'Dimas Anggara',
        email: 'dimas.anggara@ui.ac.id',
        nim: '2205356012',
        phone: '0812-3344-5566',
        photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
        role: 'driver_kampus',
        facultas: 'Fakultas Ilmu Komputer',
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
        nim: '2105102033',
        phone: '0813-9900-1122',
        photoUrl: 'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=200',
        role: 'driver_kampus',
        facultas: 'Fakultas Teknik Mesin',
        isVerified: true,
        isActive: true,
        rating: 4.8,
        totalTrips: 198,
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now,
      ),
      UserModel(
        uid: 'drv_mhs_03',
        name: 'Kevin Sanjaya',
        email: 'kevin.sanjaya@ui.ac.id',
        nim: '2301103019',
        phone: '0878-5566-7788',
        photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
        role: 'driver_kampus',
        facultas: 'Fakultas Kedokteran Gigi',
        isVerified: true,
        isActive: true,
        rating: 5.0,
        totalTrips: 415,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
      ),
      UserModel(
        uid: 'drv_umum_01',
        name: 'Agus Prabowo',
        email: 'agus.prabowo@gmail.com',
        phone: '0857-1122-3344',
        photoUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200',
        role: 'driver_umum',
        facultas: null,
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
        phone: '0822-4455-8899',
        photoUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200',
        role: 'driver_umum',
        facultas: null,
        isVerified: true,
        isActive: false, // Suspended
        rating: 3.4,
        totalTrips: 85,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
    ];

    final batch = _firestore.batch();
    for (var driver in sampleDrivers) {
      batch.set(_usersCol.doc(driver.uid), driver.toMap());
    }
    await batch.commit();

    return sampleDrivers.length;
  }
}
