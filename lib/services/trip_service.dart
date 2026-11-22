import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service untuk menangani alur perjalanan (Trip) dan kalkulasi keuangan
/// sesuai spesifikasi README GasKampus (Sistem Matching 3 Tier & Bagi Hasil).
class TripService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  /// Stream order aktif yang sedang dijalankan oleh driver ini
  Stream<DocumentSnapshot<Map<String, dynamic>>?> streamActiveTrip(String driverId) {
    return _db
        .collection('orders')
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['accepted', 'onPickup', 'arrived', 'onTrip'])
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty ? snap.docs.first : null);
  }

  /// Stream daftar riwayat order untuk driver
  Stream<QuerySnapshot<Map<String, dynamic>>> streamDriverOrderHistory(String driverId) {
    return _db
        .collection('orders')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream order yang sedang mencari driver (status 'searching' atau 'pending')
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAvailableOrders() {
    return _db
        .collection('orders')
        .where('status', whereIn: ['searching', 'pending'])
        .snapshots();
  }

  /// Driver menerima order (README Bagian 7 - Kunci Order & Match Tier 3)
  Future<void> acceptOrder({
    required String orderId,
    required String driverId,
    int matchTier = 3,
  }) async {
    final now = DateTime.now().toIso8601String();
    final batch = _db.batch();

    // 1. Kunci order (gunakan merge agar order simulasi langsung terbuat di Firestore)
    final orderRef = _db.collection('orders').doc(orderId);
    batch.set(
      orderRef,
      {
        'orderId': orderId,
        'status': 'accepted',
        'driverId': driverId,
        'matchTier': matchTier,
        'acceptedAt': now,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );

    // 2. Tandai driver sedang aktif membawa order
    final userRef = _db.collection('users').doc(driverId);
    batch.set(
      userRef,
      {
        'activeOrderId': orderId,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Update status perjalanan (accepted -> onPickup -> arrived -> onTrip)
  Future<void> updateTripStatus({
    required String orderId,
    required String status,
  }) async {
    final now = DateTime.now().toIso8601String();
    final data = <String, dynamic>{
      'orderId': orderId,
      'status': status,
      'updatedAt': now,
    };

    if (status == 'arrived') {
      data['arrivedAt'] = now;
    } else if (status == 'onTrip') {
      data['startedAt'] = now;
    }

    await _db.collection('orders').doc(orderId).set(data, SetOptions(merge: true));
  }

  /// Driver membatalkan pesanan (README Bagian 11)
  Future<void> cancelTripByDriver({
    required String orderId,
    required String driverId,
    required String reason,
  }) async {
    final now = DateTime.now().toIso8601String();
    final batch = _db.batch();

    // Kembalikan status order ke searching agar dicari driver lain
    final orderRef = _db.collection('orders').doc(orderId);
    batch.set(
      orderRef,
      {
        'status': 'searching',
        'driverId': null,
        'cancelReason': reason,
        'rejectedDrivers': FieldValue.arrayUnion([driverId]),
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );

    // Bebaskan driver dari activeOrderId
    final userRef = _db.collection('users').doc(driverId);
    batch.set(
      userRef,
      {
        'activeOrderId': null,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Selesaikan Perjalanan & Eksekusi Bagi Hasil / Pembayaran (README Bagian 10)
  ///
  /// Aturan Perhitungan Keuangan Driver Umum (Tier 3):
  /// - Komisi Platform: 15% dari total tarif final.
  /// - Pendapatan Bersih Driver: 85% dari tarif.
  ///
  /// KASUS A: Pembayaran GasPay / QRIS
  /// - Uang masuk ke sistem platform.
  /// - Saldo dompet driver (wallets/{driverId}) DITAMBAHKAN sebesar Pendapatan Bersih (85%).
  /// - Dicatat transaksi 'earning' (+Rp bersih).
  ///
  /// KASUS B: Pembayaran Tunai (Cash)
  /// - Penumpang membayar tunai 100% langsung ke tangan driver di tempat.
  /// - Komisi hak platform 15% DIPOTONG LANGSUNG dari saldo GasPay driver (wallets/{driverId}).
  /// - Dicatat transaksi 'commission' (-Rp komisi 15%).
  /// - Kalo misalnya
  Future<Map<String, dynamic>> completeTripAndProcessFinancials({
    required String orderId,
    required String driverId,
    required int fareAmount,
    required String paymentMethod,
    String? passengerId,
  }) async {
    final now = DateTime.now().toIso8601String();

    // Kalkulasi bagi hasil (Driver Umum = 15% komisi platform)
    final double commissionRate = 0.15;
    final int commission = (fareAmount * commissionRate).round();
    final int netEarnings = fareAmount - commission;

    final batch = _db.batch();

    // 1. Update Order ke Completed
    final orderRef = _db.collection('orders').doc(orderId);
    batch.set(
      orderRef,
      {
        'orderId': orderId,
        'driverId': driverId,
        'status': 'completed',
        'completedAt': now,
        'fareAmount': fareAmount,
        'commissionAmount': commission,
        'netEarnings': netEarnings,
        'paymentMethod': paymentMethod,
        'fareBreakdown': {
          'totalFare': fareAmount,
          'platformCommission': commission,
          'driverNetEarnings': netEarnings,
          'matchTier': 3,
          'tierLabel': 'Tier 3 · Mitra Umum (100% Normal)',
        },
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );

    // 2. Update Driver: selesaikan order, tambah total trip, update rating
    final driverRef = _db.collection('users').doc(driverId);
    batch.set(
      driverRef,
      {
        'activeOrderId': null,
        'totalTrips': FieldValue.increment(1),
        'todayEarnings': FieldValue.increment(netEarnings),
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );

    // 3. Eksekusi Saldo Dompet Driver (wallets/{driverId})
    final driverWalletRef = _db.collection('wallets').doc(driverId);
    final isCash = paymentMethod.toLowerCase() == 'cash' ||
        paymentMethod.toLowerCase() == 'tunai';

    if (isCash) {
      // Pembayaran TUNAI:
      // Penumpang bayar tunai ke driver, komisi 15% platform dipotong dari saldo GasPay driver.
      batch.set(
        driverWalletRef,
        {
          'balance': FieldValue.increment(-commission),
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      // Catat mutasi komisi debit di subkoleksi transactions
      final txRef = driverWalletRef.collection('transactions').doc();
      batch.set(txRef, {
        'transactionId': txRef.id,
        'walletId': driverId,
        'type': 'commission',
        'amount': commission,
        'description':
            'Potongan komisi platform 15% order tunai #$orderId (Tarif Rp $fareAmount)',
        'relatedOrderId': orderId,
        'createdAt': now,
      });
    } else {
      // Pembayaran GASPAY / QRIS:
      // Pendapatan bersih (85%) dikreditkan ke saldo GasPay driver.
      batch.set(
        driverWalletRef,
        {
          'balance': FieldValue.increment(netEarnings),
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      // Catat mutasi pendapatan kredit di subkoleksi transactions
      final txRef = driverWalletRef.collection('transactions').doc();
      batch.set(txRef, {
        'transactionId': txRef.id,
        'walletId': driverId,
        'type': 'earning',
        'amount': netEarnings,
        'description':
            'Pendapatan bersih trip GasPay #$orderId (Tarif Rp $fareAmount - Komisi Rp $commission)',
        'relatedOrderId': orderId,
        'createdAt': now,
      });

      // Potong saldo penumpang jika ada passengerId
      if (passengerId != null && passengerId.isNotEmpty) {
        final passengerWalletRef = _db.collection('wallets').doc(passengerId);
        batch.set(
          passengerWalletRef,
          {
            'balance': FieldValue.increment(-fareAmount),
            'updatedAt': now,
          },
          SetOptions(merge: true),
        );

        final ptxRef = passengerWalletRef.collection('transactions').doc();
        batch.set(ptxRef, {
          'transactionId': ptxRef.id,
          'walletId': passengerId,
          'type': 'payment',
          'amount': fareAmount,
          'description': 'Pembayaran ojek kampus trip #$orderId',
          'relatedOrderId': orderId,
          'createdAt': now,
        });
      }
    }

    await batch.commit();

    return {
      'totalFare': fareAmount,
      'commission': commission,
      'netEarnings': netEarnings,
      'isCash': isCash,
    };
  }

  /// Rating 2 Arah: Driver menilai penumpang (README Bagian 11)
  Future<void> submitPassengerReview({
    required String orderId,
    required String driverId,
    required String passengerName,
    required double rating,
    required List<String> tags,
    String? feedback,
  }) async {
    final now = DateTime.now().toIso8601String();
    final reviewRef = _db.collection('reviews').doc('rev_$orderId');

    await reviewRef.set({
      'orderId': orderId,
      'reviewerId': driverId,
      'reviewerRole': 'driver_umum',
      'targetName': passengerName,
      'rating': rating,
      'tags': tags,
      'feedback': feedback ?? '',
      'createdAt': now,
    });

    // Tandai di order bahwa driver sudah review
    await _db.collection('orders').doc(orderId).set(
      {
        'driverRated': true,
        'driverRatingValue': rating,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
  }

  /// Buat pesanan simulasi di Firestore untuk pengetesan real-time
  Future<String> createSimulationOrder({
    required String passengerName,
    required String passengerPhone,
    required String fromAddress,
    required String toAddress,
    required String zone,
    required int fareAmount,
    required String paymentMethod,
    String? driverId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final docRef = _db.collection('orders').doc();

    await docRef.set({
      'orderId': docRef.id,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'passengerRole': 'mahasiswa',
      'pickupAddress': fromAddress,
      'dropoffAddress': toAddress,
      'destinationZoneId': zone,
      'fareAmount': fareAmount,
      'paymentMethod': paymentMethod,
      'status': driverId != null ? 'accepted' : 'searching',
      'driverId': driverId,
      'matchTier': 3,
      'distanceKm': 3.2,
      'createdAt': now,
      'updatedAt': now,
    });

    return docRef.id;
  }
}
