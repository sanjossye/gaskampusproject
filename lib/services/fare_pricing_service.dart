import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model tier jarak penarifan ojek GasKampus
class FareTier {
  final int id;
  final double minKm;
  final double maxKm;
  final int price;

  const FareTier({
    required this.id,
    required this.minKm,
    required this.maxKm,
    required this.price,
  });

  String get label => maxKm >= 999
      ? '> ${minKm.toInt()} km'
      : '${minKm.toInt()}–${maxKm.toInt()} km';

  Map<String, dynamic> toMap() => {
        'id': id,
        'minKm': minKm,
        'maxKm': maxKm,
        'price': price,
      };

  factory FareTier.fromMap(Map<String, dynamic> map) {
    return FareTier(
      id: (map['id'] as num?)?.toInt() ?? 0,
      minKm: (map['minKm'] as num?)?.toDouble() ?? 0.0,
      maxKm: (map['maxKm'] as num?)?.toDouble() ?? 0.0,
      price: (map['price'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Service penarifan GasKampus terpusat yang diatur oleh Admin
/// Sesuai spesifikasi tabel penarifan bertingkat (Distance Tiered Pricing).
class FarePricingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'distance_fare';
  static const String _docId = 'pricing_rules';

  /// Default 10 tier tarif sesuai tabel standar GasKampus
  static const List<FareTier> defaultTiers = [
    FareTier(id: 1, minKm: 0, maxKm: 2, price: 5000),
    FareTier(id: 2, minKm: 2, maxKm: 4, price: 7000),
    FareTier(id: 3, minKm: 4, maxKm: 6, price: 9000),
    FareTier(id: 4, minKm: 6, maxKm: 8, price: 11000),
    FareTier(id: 5, minKm: 8, maxKm: 10, price: 13000),
    FareTier(id: 6, minKm: 10, maxKm: 12, price: 15000),
    FareTier(id: 7, minKm: 12, maxKm: 15, price: 18000),
    FareTier(id: 8, minKm: 15, maxKm: 20, price: 22000),
    FareTier(id: 9, minKm: 20, maxKm: 25, price: 27000),
    FareTier(id: 10, minKm: 25, maxKm: 30, price: 32000),
  ];

  static List<FareTier> _cachedTiers = defaultTiers;
  static bool _hasInitialized = false;

  /// Inisialisasi listener realtime ke Firestore agar selalu up-to-date
  static void init() {
    if (_hasInitialized) return;
    _hasInitialized = true;

    _firestore.collection(_collection).doc(_docId).snapshots().listen(
      (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          if (data['tiers'] is List) {
            final list = (data['tiers'] as List)
                .map((e) => FareTier.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList();
            if (list.isNotEmpty) {
              list.sort((a, b) => a.id.compareTo(b.id));
              _cachedTiers = list;
            }
          }
        }
      },
      onError: (_) {
        // Fallback ke default jika offline
        _cachedTiers = defaultTiers;
      },
    );
  }

  /// Hitung tarif ojek motor berdasarkan jarak (km)
  /// Menggunakan 10 tier tabel resmi GasKampus
  static int calculateMotorFare(double distanceKm, {List<FareTier>? customTiers}) {
    final tiers = customTiers ?? _cachedTiers;
    final km = distanceKm < 0 ? 0.0 : distanceKm;

    for (final tier in tiers) {
      if (km >= tier.minKm && km <= tier.maxKm) {
        return tier.price;
      }
    }

    // Jika jarak di atas 30 km (di luar batas tier 10)
    if (km > 30) {
      final tier10Price = tiers.isNotEmpty ? tiers.last.price : 32000;
      final extraKm = (km - 30).ceil();
      return tier10Price + (extraKm * 1500);
    }

    // Default minimum
    return 5000;
  }

  /// Hitung tarif mobil (Gocar) jika diperlukan (standar ojek motor x 1.8 atau tier mobil)
  static int calculateCarFare(double distanceKm) {
    final motorFare = calculateMotorFare(distanceKm);
    return ((motorFare * 1.8) / 1000).ceil() * 1000;
  }

  /// Format angka integer ke format Rupiah (contoh: 5000 -> "Rp 5.000")
  static String formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  /// Stream seluruh tier konfigurasi tarif dari Firestore untuk Admin
  static Stream<List<FareTier>> streamFareTiers() {
    return _firestore.collection(_collection).doc(_docId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return defaultTiers;
      }
      final data = snap.data()!;
      if (data['tiers'] is List) {
        final list = (data['tiers'] as List)
            .map((e) => FareTier.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (list.isNotEmpty) {
          list.sort((a, b) => a.id.compareTo(b.id));
          return list;
        }
      }
      return defaultTiers;
    });
  }

  /// Simpan pembaruan daftar tarif yang diubah oleh Admin ke Firestore
  static Future<void> saveFareTiers(List<FareTier> tiers) async {
    final docRef = _firestore.collection(_collection).doc(_docId);
    await docRef.set({
      'updatedAt': DateTime.now().toIso8601String(),
      'updatedBy': 'admin',
      'tiers': tiers.map((t) => t.toMap()).toList(),
    }, SetOptions(merge: true));

    _cachedTiers = List.from(tiers);
  }

  /// Kembalikan pengaturan tarif ke nilai default awal (10 tier standar)
  static Future<void> resetToDefault() async {
    await saveFareTiers(defaultTiers);
  }
}
