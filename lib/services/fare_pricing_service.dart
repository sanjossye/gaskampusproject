import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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

/// Service penarifan GasKampus terpusat yang diatur oleh Admin.
/// Mendukung:
/// 1. Tarif per 1 Km (`pricePerKm`) yang ditetapkan Admin
/// 2. Tabel 10 Tier Jarak (`tiers`)
/// 3. Tarif khusus yang diberikan Admin kepada akun tertentu (`users/{uid}.customFarePerKm`)
class FarePricingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'distance_fare';
  static const String _docId = 'pricing_rules';
  static const String _backupCollection = 'announcements';
  static const String _backupDocId = 'fare_pricing_config';

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

  static List<FareTier> _cachedTiers = List.from(defaultTiers);
  static int _pricePerKm = 5000;
  static bool _usePerKmPricing = true;
  static int? _accountCustomFarePerKm;
  static bool _hasInitialized = false;
  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  /// Notifier agar seluruh layar pengguna otomatis me-refresh harga saat Admin mengubah tarif
  static final ValueNotifier<int> versionNotifier = ValueNotifier<int>(0);

  static List<FareTier> get currentTiers => List.unmodifiable(_cachedTiers);
  static int get pricePerKm => _pricePerKm;
  static bool get usePerKmPricing => _usePerKmPricing;
  static int? get accountCustomFarePerKm => _accountCustomFarePerKm;

  /// Harga efektif untuk jarak 1 km pada akun yang sedang aktif
  static int get effectiveOneKmPrice {
    if (_accountCustomFarePerKm != null && _accountCustomFarePerKm! > 0) {
      return _accountCustomFarePerKm!;
    }
    if (_usePerKmPricing && _pricePerKm > 0) {
      return _pricePerKm;
    }
    return _cachedTiers.isNotEmpty ? _cachedTiers.first.price : _pricePerKm;
  }

  static void _notifyListeners() {
    versionNotifier.value++;
  }

  static void _applyPricingSnapshotData(Map<String, dynamic> data) {
    bool changed = false;

    if (data['pricePerKm'] is num) {
      final newPerKm = (data['pricePerKm'] as num).toInt();
      if (newPerKm > 0 && newPerKm != _pricePerKm) {
        _pricePerKm = newPerKm;
        changed = true;
      }
    }

    if (data['usePerKmPricing'] is bool) {
      final newMode = data['usePerKmPricing'] as bool;
      if (newMode != _usePerKmPricing) {
        _usePerKmPricing = newMode;
        changed = true;
      }
    }

    if (data['tiers'] is List) {
      final list = (data['tiers'] as List)
          .map((e) => FareTier.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (list.isNotEmpty) {
        list.sort((a, b) => a.id.compareTo(b.id));
        _cachedTiers = list;
        if (data['pricePerKm'] == null) {
          _pricePerKm = list.first.price;
        }
        changed = true;
      }
    }

    if (changed) {
      _notifyListeners();
    }
  }

  /// Inisialisasi listener realtime ke Firestore & akun user aktif agar selalu up-to-date
  static void init() {
    if (_hasInitialized) return;
    _hasInitialized = true;

    // 1. Listener koleksi utama distance_fare/pricing_rules
    _firestore.collection(_collection).doc(_docId).snapshots().listen(
      (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          _applyPricingSnapshotData(snapshot.data()!);
        }
      },
      onError: (_) {},
    );

    // 2. Listener koleksi backup announcements/fare_pricing_config
    _firestore.collection(_backupCollection).doc(_backupDocId).snapshots().listen(
      (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          _applyPricingSnapshotData(snapshot.data()!);
        }
      },
      onError: (_) {},
    );

    // 3. Listener ke dokumen akun yang sedang login (users/{uid}) untuk tarif khusus akun dari Admin
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _userSub?.cancel();
      if (user == null) {
        if (_accountCustomFarePerKm != null) {
          _accountCustomFarePerKm = null;
          _notifyListeners();
        }
        return;
      }
      _userSub = _firestore.collection('users').doc(user.uid).snapshots().listen(
        (doc) {
          if (!doc.exists || doc.data() == null) return;
          final data = doc.data()!;
          final customVal = (data['customFarePerKm'] as num?)?.toInt();
          final normalized = (customVal != null && customVal > 0) ? customVal : null;
          if (normalized != _accountCustomFarePerKm) {
            _accountCustomFarePerKm = normalized;
            _notifyListeners();
          }
        },
        onError: (_) {},
      );
    });
  }

  /// Hitung tarif ojek motor berdasarkan jarak (km) sesuai ketetapan Admin
  static int calculateMotorFare(
    double distanceKm, {
    List<FareTier>? customTiers,
    int? overridePerKm,
    bool? overrideUsePerKm,
  }) {
    final double km = distanceKm <= 0 ? 1.0 : distanceKm;

    // 1. Prioritas pertama: Tarif khusus yang diberikan Admin kepada akun ini
    if (overridePerKm == null &&
        customTiers == null &&
        _accountCustomFarePerKm != null &&
        _accountCustomFarePerKm! > 0) {
      final int rate = _accountCustomFarePerKm!;
      if (km <= 1.0) return rate;
      return (km * rate).round();
    }

    // 2. Jika mode tarif per 1 km aktif
    final bool perKmMode = overrideUsePerKm ?? _usePerKmPricing;
    final int perKmRate = overridePerKm ?? _pricePerKm;
    if (customTiers == null && perKmMode && perKmRate > 0) {
      if (km <= 1.0) return perKmRate;
      return (km * perKmRate).round();
    }

    // 3. Menggunakan tabel 10 tier jarak yang diatur Admin
    final tiers = customTiers ?? _cachedTiers;
    for (final tier in tiers) {
      if (km >= tier.minKm && km <= tier.maxKm) {
        return tier.price;
      }
    }

    // Jika jarak di atas batas tier terakhir
    if (tiers.isNotEmpty && km > tiers.last.maxKm) {
      final lastTier = tiers.last;
      final extraKm = (km - lastTier.maxKm).ceil();
      return lastTier.price + (extraKm * (perKmRate > 0 ? (perKmRate ~/ 2) : 1500));
    }

    return perKmRate > 0 ? perKmRate : 5000;
  }

  /// Hitung tarif mobil (Gocar) berdasarkan tarif motor x 1.8
  static int calculateCarFare(double distanceKm) {
    final motorFare = calculateMotorFare(distanceKm);
    return ((motorFare * 1.8) / 500).ceil() * 500;
  }

  /// Format angka integer ke format Rupiah (contoh: 5000 -> "Rp 5.000")
  static String formatRupiah(int amount) {
    final str = amount.abs().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    final formatted = buffer.toString().split('').reversed.join('');
    return amount < 0 ? '-Rp $formatted' : 'Rp $formatted';
  }

  /// Buat daftar 10 tier otomatis berdasarkan harga 1 km yang ditetapkan Admin
  static List<FareTier> buildTiersFromOneKmPrice(int oneKmPrice) {
    final int base = oneKmPrice > 0 ? oneKmPrice : 5000;
    final int step = (base * 0.4).round().clamp(1000, 100000);
    return [
      FareTier(id: 1, minKm: 0, maxKm: 2, price: base),
      FareTier(id: 2, minKm: 2, maxKm: 4, price: base + step),
      FareTier(id: 3, minKm: 4, maxKm: 6, price: base + step * 2),
      FareTier(id: 4, minKm: 6, maxKm: 8, price: base + step * 3),
      FareTier(id: 5, minKm: 8, maxKm: 10, price: base + step * 4),
      FareTier(id: 6, minKm: 10, maxKm: 12, price: base + step * 5),
      FareTier(id: 7, minKm: 12, maxKm: 15, price: base + (step * 6.5).round()),
      FareTier(id: 8, minKm: 15, maxKm: 20, price: base + (step * 8.5).round()),
      FareTier(id: 9, minKm: 20, maxKm: 25, price: base + step * 11),
      FareTier(id: 10, minKm: 25, maxKm: 30, price: base + (step * 13.5).round()),
    ];
  }

  /// Stream seluruh tier konfigurasi tarif dari Firestore untuk Admin
  static Stream<List<FareTier>> streamFareTiers() {
    return _firestore.collection(_collection).doc(_docId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return _cachedTiers;
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
      return _cachedTiers;
    });
  }

  /// Simpan pembaruan daftar tarif dan harga per 1 km yang diubah oleh Admin ke Firestore
  static Future<void> saveFareTiers(
    List<FareTier> tiers, {
    int? pricePerKm,
    bool? usePerKmPricing,
  }) async {
    _cachedTiers = List.from(tiers);
    if (pricePerKm != null && pricePerKm > 0) {
      _pricePerKm = pricePerKm;
    } else if (tiers.isNotEmpty) {
      _pricePerKm = tiers.first.price;
    }
    if (usePerKmPricing != null) {
      _usePerKmPricing = usePerKmPricing;
    }
    _notifyListeners();

    final payload = {
      'updatedAt': DateTime.now().toIso8601String(),
      'updatedBy': 'admin',
      'pricePerKm': _pricePerKm,
      'usePerKmPricing': _usePerKmPricing,
      'tiers': tiers.map((t) => t.toMap()).toList(),
    };

    try {
      await _firestore
          .collection(_collection)
          .doc(_docId)
          .set(payload, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
    } catch (_) {}

    try {
      await _firestore
          .collection(_backupCollection)
          .doc(_backupDocId)
          .set(payload, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  /// Admin menetapkan atau mereset harga khusus per 1 km kepada akun tertentu (`users/{uid}`)
  static Future<void> setAccountCustomFare(String uid, int? farePerKm) async {
    final normalized = (farePerKm != null && farePerKm > 0) ? farePerKm : null;
    await _firestore.collection('users').doc(uid).set({
      'customFarePerKm': normalized,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    if (FirebaseAuth.instance.currentUser?.uid == uid) {
      _accountCustomFarePerKm = normalized;
      _notifyListeners();
    }
  }

  /// Kembalikan pengaturan tarif ke nilai default awal (10 tier standar, 1 km = Rp 5.000)
  static Future<void> resetToDefault() async {
    await saveFareTiers(
      defaultTiers,
      pricePerKm: 5000,
      usePerKmPricing: true,
    );
  }

  /// Terapkan pengali tier ke tarif dasar.
  /// Tier 1 = multiplier dari config/pricing (default 0.70), tier 2 & 3 = tarif penuh.
  static int applyTierMultiplier(int baseFare, int tier, {double? customMultiplier}) {
    if (tier == 1) {
      final m = customMultiplier ?? 0.70;
      return (baseFare * m / 1000).round() * 1000; // Bulatkan ke ribuan
    }
    return baseFare;
  }
}
