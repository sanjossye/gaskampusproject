import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'map_route_service.dart';

class _DriverCandidate {
  final String uid;
  final String name;
  final String role;
  final double? distanceMeters;
  final String vehicleBrand;
  final String vehiclePlate;

  const _DriverCandidate({
    required this.uid,
    required this.name,
    required this.role,
    required this.distanceMeters,
    required this.vehicleBrand,
    required this.vehiclePlate,
  });

  bool get isStudentDriver => role == 'driver_kampus';
  bool get isGeneralDriver => role == 'driver_umum';
}

/// Service pencocokan driver real-time untuk pesanan Antar (tanpa data dummy).
/// Urutan prioritas matching:
/// 1. Driver Mahasiswa (`driver_kampus`) online terdekat (<= 3 km)
/// 2. Jika tidak ada, Driver Umum (`driver_umum`) online terdekat (<= 3 km)
/// 3. Jika tidak ada yang terdekat, masuk ke Driver aktif/online manapun
///    (tetap mendahulukan Mahasiswa aktif lalu Umum aktif).
class RideDispatchService {
  static const double _nearbyRadiusMeters = 3000.0;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Sinkronisasi status online + lokasi GPS driver ke Firestore `users/{uid}`
  /// agar sistem dispatch dapat mendeteksi driver terdekat dan driver aktif.
  Future<void> syncDriverPresence({
    required bool isOnline,
    LatLng? position,
    required String role,
    String? name,
    String? vehicleBrand,
    String? vehiclePlate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now().toIso8601String();
    final payload = <String, dynamic>{
      'isOnline': isOnline,
      'role': role,
      'lastSeenAt': now,
      'updatedAt': now,
      if (position != null) 'lastLat': position.latitude,
      if (position != null) 'lastLng': position.longitude,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (vehicleBrand != null && vehicleBrand.trim().isNotEmpty)
        'vehicleBrand': vehicleBrand.trim(),
      if (vehiclePlate != null && vehiclePlate.trim().isNotEmpty)
        'vehiclePlate': vehiclePlate.trim(),
    };
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .set(payload, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Stream semua pesanan antar (`serviceType == 'antar'`) untuk panel driver.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamRideOrders() {
    return _db
        .collection('orders')
        .where('serviceType', isEqualTo: 'antar')
        .snapshots();
  }

  /// Menentukan dan menawarkan pesanan antar ke driver online terbaik:
  /// 1) Driver Mahasiswa terdekat -> 2) Driver Umum terdekat -> 3) Driver aktif lainnya.
  Future<Map<String, dynamic>> dispatchRideOrder({
    required String orderId,
    required LatLng pickupPos,
    List<String> excludedDriverIds = const [],
  }) async {
    final now = DateTime.now().toIso8601String();
    try {
      final snap = await _db
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .get();

      final candidates = <_DriverCandidate>[];
      for (final doc in snap.docs) {
        if (excludedDriverIds.contains(doc.id)) continue;
        final data = doc.data();
        final role = (data['role'] ?? '').toString();
        if (role != 'driver_kampus' && role != 'driver_umum') continue;

        final isActive = data['isActive'] != false;
        if (!isActive) continue;

        final activeOrderId = (data['activeOrderId'] ?? '').toString().trim();
        if (activeOrderId.isNotEmpty && activeOrderId != orderId) continue;

        final lat = (data['lastLat'] as num?)?.toDouble();
        final lng = (data['lastLng'] as num?)?.toDouble();
        final double? dist = (lat != null && lng != null)
            ? MapRouteService.distanceInMeters(pickupPos, LatLng(lat, lng))
            : null;

        final profile = (data['driverProfile'] as Map<String, dynamic>?) ?? {};
        candidates.add(
          _DriverCandidate(
            uid: doc.id,
            name: (data['name'] ?? 'Driver GasKampus').toString(),
            role: role,
            distanceMeters: dist,
            vehicleBrand: (data['vehicleBrand'] ??
                    profile['vehicleBrand'] ??
                    'Motor Kampus')
                .toString(),
            vehiclePlate:
                (data['vehiclePlate'] ?? profile['vehiclePlate'] ?? '-')
                    .toString(),
          ),
        );
      }

      int byDistance(_DriverCandidate a, _DriverCandidate b) {
        final da = a.distanceMeters ?? double.infinity;
        final db = b.distanceMeters ?? double.infinity;
        return da.compareTo(db);
      }

      // Prioritas 1: Driver Mahasiswa terdekat (<= 3 km)
      final nearbyStudents = candidates
          .where(
            (c) =>
                c.isStudentDriver &&
                c.distanceMeters != null &&
                c.distanceMeters! <= _nearbyRadiusMeters,
          )
          .toList()
        ..sort(byDistance);

      // Prioritas 2: Driver Umum terdekat (<= 3 km)
      final nearbyGeneral = candidates
          .where(
            (c) =>
                c.isGeneralDriver &&
                c.distanceMeters != null &&
                c.distanceMeters! <= _nearbyRadiusMeters,
          )
          .toList()
        ..sort(byDistance);

      // Prioritas 3: Semua driver aktif/online (Mahasiswa dulu lalu Umum)
      final activeStudents =
          candidates.where((c) => c.isStudentDriver).toList()..sort(byDistance);
      final activeGeneral =
          candidates.where((c) => c.isGeneralDriver).toList()..sort(byDistance);

      _DriverCandidate? chosen;
      String tierLabel;

      if (nearbyStudents.isNotEmpty) {
        chosen = nearbyStudents.first;
        tierLabel = 'Driver Mahasiswa Terdekat';
      } else if (nearbyGeneral.isNotEmpty) {
        chosen = nearbyGeneral.first;
        tierLabel = 'Driver Umum Terdekat';
      } else if (activeStudents.isNotEmpty) {
        chosen = activeStudents.first;
        tierLabel = 'Driver Mahasiswa Aktif';
      } else if (activeGeneral.isNotEmpty) {
        chosen = activeGeneral.first;
        tierLabel = 'Driver Umum Aktif';
      } else {
        tierLabel = 'Menunggu Driver Aktif Online';
      }

      final update = <String, dynamic>{
        'status': 'searching',
        'offeredDriverId': chosen?.uid,
        'offeredDriverName': chosen?.name,
        'offeredDriverRole': chosen?.role,
        'offeredDistanceKm': chosen?.distanceMeters != null
            ? double.parse((chosen!.distanceMeters! / 1000.0).toStringAsFixed(2))
            : null,
        'dispatchTierLabel': tierLabel,
        'offeredAt': now,
        'updatedAt': now,
      };

      await _db
          .collection('orders')
          .doc(orderId)
          .set(update, SetOptions(merge: true));

      return update;
    } catch (_) {
      return {
        'status': 'searching',
        'offeredDriverId': null,
        'dispatchTierLabel': 'Menunggu Driver Aktif Online',
      };
    }
  }

  /// Driver menyetujui pesanan antar secara atomik (mencegah diambil 2 driver).
  /// Status langsung berubah ke `onPickup` (driver menjemput user).
  Future<bool> acceptRideOrder({
    required String orderId,
    required String driverId,
    required String driverName,
    required String driverRole,
    required String vehicleBrand,
    required String vehiclePlate,
    LatLng? driverPos,
  }) async {
    final now = DateTime.now().toIso8601String();
    final orderRef = _db.collection('orders').doc(orderId);
    final driverRef = _db.collection('users').doc(driverId);

    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(orderRef);
      if (!snap.exists) return false;
      final data = snap.data() ?? {};
      final currentDriverId = (data['driverId'] ?? '').toString().trim();
      final status = (data['status'] ?? '').toString();
      if (currentDriverId.isNotEmpty ||
          (status != 'searching' && status != 'pending')) {
        return false;
      }

      tx.set(
        orderRef,
        {
          'status': 'onPickup',
          'driverId': driverId,
          'driverName': driverName,
          'driverRole': driverRole,
          'driverVehicle': vehicleBrand,
          'driverPlate': vehiclePlate,
          if (driverPos != null) 'driverLat': driverPos.latitude,
          if (driverPos != null) 'driverLng': driverPos.longitude,
          'offeredDriverId': null,
          'acceptedAt': now,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      tx.set(
        driverRef,
        {
          'activeOrderId': orderId,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );
      return true;
    });
  }

  /// Driver menolak pesanan antar -> otomatis diteruskan ke driver terdekat/aktif berikutnya.
  Future<void> declineRideOrder({
    required String orderId,
    required String driverId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final orderRef = _db.collection('orders').doc(orderId);
    final snap = await orderRef.get();
    if (!snap.exists) return;
    final data = snap.data() ?? {};

    final existingRejected = (data['rejectedDrivers'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    if (!existingRejected.contains(driverId)) {
      existingRejected.add(driverId);
    }

    await orderRef.set({
      'rejectedDrivers': existingRejected,
      'offeredDriverId': null,
      'updatedAt': now,
    }, SetOptions(merge: true));

    final pickupLat = (data['pickupLat'] as num?)?.toDouble();
    final pickupLng = (data['pickupLng'] as num?)?.toDouble();
    final pickupPos = (pickupLat != null && pickupLng != null)
        ? LatLng(pickupLat, pickupLng)
        : MapRouteService.defaultDriverSpawn;

    await dispatchRideOrder(
      orderId: orderId,
      pickupPos: pickupPos,
      excludedDriverIds: existingRejected,
    );
  }

  /// Driver menandai sudah tiba di lokasi penjemputan user.
  Future<void> markArrivedAtPickup(String orderId) async {
    final now = DateTime.now().toIso8601String();
    await _db.collection('orders').doc(orderId).set({
      'status': 'arrived',
      'arrivedAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  /// Driver mulai mengantar user menuju lokasi tujuan.
  Future<void> startRideToDestination(String orderId) async {
    final now = DateTime.now().toIso8601String();
    await _db.collection('orders').doc(orderId).set({
      'status': 'onTrip',
      'startedAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  /// Driver menyelesaikan pengantaran saat sudah sampai di tujuan user.
  Future<void> completeRideOrder({
    required String orderId,
    required String driverId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final batch = _db.batch();
    batch.set(
      _db.collection('orders').doc(orderId),
      {
        'status': 'completed',
        'paymentStatus': 'paid',
        'completedAt': now,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
    batch.set(
      _db.collection('users').doc(driverId),
      {
        'activeOrderId': null,
        'totalTrips': FieldValue.increment(1),
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  /// Penumpang membatalkan pesanan antar saat masih mencari driver.
  Future<void> cancelRideOrderByPassenger(String orderId) async {
    final now = DateTime.now().toIso8601String();
    await _db.collection('orders').doc(orderId).set({
      'status': 'cancelled',
      'offeredDriverId': null,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }
}
