import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/merchant_model.dart';

/// Kategori toko makanan yang tersedia saat registrasi dan pengelolaan toko.
const List<String> kMerchantCategories = [
  'Ayam & Nasi',
  'Mie & Bakso',
  'Kopi & Minuman',
  'Snack & Bakery',
  'Aneka Masakan',
];

/// Kategori item menu makanan.
const List<String> kMenuCategories = [
  'Makanan Berat',
  'Paket Hemat',
  'Minuman',
  'Snack & Cemilan',
];

/// Pilihan tema warna banner bawaan untuk toko makanan.
class MerchantBannerThemeStyle {
  final String key;
  final String label;
  final List<Color> gradient;
  final Color textColor;
  final Color badgeBg;
  final Color badgeText;
  final IconData watermarkIcon;

  const MerchantBannerThemeStyle({
    required this.key,
    required this.label,
    required this.gradient,
    required this.textColor,
    required this.badgeBg,
    required this.badgeText,
    required this.watermarkIcon,
  });
}

const List<MerchantBannerThemeStyle> kMerchantBannerThemes = [
  MerchantBannerThemeStyle(
    key: 'lime',
    label: 'Lime Kampus',
    gradient: [Color(0xFFC0F637), Color(0xFF9EE01E)],
    textColor: Color(0xFF0A0F02),
    badgeBg: Color(0xFF0A0F02),
    badgeText: Color(0xFFC0F637),
    watermarkIcon: Icons.restaurant_rounded,
  ),
  MerchantBannerThemeStyle(
    key: 'orange',
    label: 'Hangat Kuliner',
    gradient: [Color(0xFFFF9F43), Color(0xFFFF6B35)],
    textColor: Colors.white,
    badgeBg: Colors.white,
    badgeText: Color(0xFF9A3412),
    watermarkIcon: Icons.local_dining_rounded,
  ),
  MerchantBannerThemeStyle(
    key: 'emerald',
    label: 'Hijau Segar',
    gradient: [Color(0xFF16A34A), Color(0xFF0D7A3B)],
    textColor: Colors.white,
    badgeBg: Color(0xFFC0F637),
    badgeText: Color(0xFF0A0F02),
    watermarkIcon: Icons.eco_rounded,
  ),
  MerchantBannerThemeStyle(
    key: 'berry',
    label: 'Kopi & Dessert',
    gradient: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    textColor: Colors.white,
    badgeBg: Colors.white,
    badgeText: Color(0xFF4C1D95),
    watermarkIcon: Icons.local_cafe_rounded,
  ),
  MerchantBannerThemeStyle(
    key: 'dark',
    label: 'Elegan Gelap',
    gradient: [Color(0xFF1D2210), Color(0xFF2D3917)],
    textColor: Colors.white,
    badgeBg: Color(0xFFC0F637),
    badgeText: Color(0xFF0A0F02),
    watermarkIcon: Icons.storefront_rounded,
  ),
];

MerchantBannerThemeStyle merchantBannerThemeFor(String key) {
  for (final theme in kMerchantBannerThemes) {
    if (theme.key == key) return theme;
  }
  return kMerchantBannerThemes.first;
}

/// Service pengelolaan data Merchant Toko Makanan & Menu (`merchants/{uid}` di Firestore).
class MerchantService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _merchants =>
      _db.collection('merchants');

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  /// Cache lokal sesi bila offline / Firebase belum diisi.
  static final List<MerchantModel> sessionMerchants = [];

  /// Contoh merchant bawaan kampus USU yang ditampilkan sebagai fallback bila koleksi
  /// `merchants` di Firestore masih kosong (sebelum merchant asli mendaftar atau di-seed).
  static List<MerchantModel> get fallbackDemoMerchants {
    final now = DateTime.now();
    return [
      MerchantModel(
        id: 'demo_merchant_bunda',
        ownerUid: 'demo_merchant_bunda',
        name: 'Warung Geprek Bunda USU',
        ownerName: 'Ibu Sari',
        phone: '081200008801',
        category: 'Ayam & Nasi',
        address: 'Kantin Pusat USU Lt. 1, Jl. Universitas No. 9, Medan',
        latitude: 3.5628,
        longitude: 98.6578,
        bannerHeadline: 'Gratis Es Teh setiap pembelian Paket Komplit!',
        bannerTheme: 'orange',
        isOpen: true,
        rating: 4.9,
        totalOrders: 248,
        createdAt: now,
        updatedAt: now,
        menus: const [
          MerchantMenuItem(
            id: 'm1',
            name: 'Paket Ayam Geprek Komplit',
            description: 'Nasi putih, ayam geprek sambal bawang, tahu & lalapan',
            price: 15000,
            category: 'Paket Hemat',
          ),
          MerchantMenuItem(
            id: 'm2',
            name: 'Ayam Bakar Madu + Nasi',
            description: 'Bumbu madu bakar khas dengan sambal kecap terasi',
            price: 18000,
            category: 'Makanan Berat',
          ),
          MerchantMenuItem(
            id: 'm3',
            name: 'Indomie Goreng Telur Kornet',
            description: 'Topping telur mata sapi + sawi + bawang goreng',
            price: 12000,
            category: 'Makanan Berat',
          ),
          MerchantMenuItem(
            id: 'm4',
            name: 'Es Teh Manis Jumbo',
            description: 'Segar dingin manis pas untuk menemani makan siang',
            price: 5000,
            category: 'Minuman',
          ),
        ],
      ),
      MerchantModel(
        id: 'demo_merchant_kopi',
        ownerUid: 'demo_merchant_kopi',
        name: 'Kedai Kopi & Mie Fasilkom',
        ownerName: 'Bang Rizky',
        phone: '081200008802',
        category: 'Kopi & Minuman',
        address: 'Jl. Dr. T. Mansyur Pintu 1 USU, Padang Bulan, Medan',
        latitude: 3.5648,
        longitude: 98.6562,
        bannerHeadline: 'Kopi Susu Gula Aren mulai Rp 10.000 khusus Mahasiswa!',
        bannerTheme: 'lime',
        isOpen: true,
        rating: 4.8,
        totalOrders: 175,
        createdAt: now,
        updatedAt: now,
        menus: const [
          MerchantMenuItem(
            id: 'k1',
            name: 'Es Kopi Susu Gula Aren',
            description: 'Espresso robusta Medan + susu segar + gula aren asli',
            price: 12000,
            category: 'Minuman',
          ),
          MerchantMenuItem(
            id: 'k2',
            name: 'Matcha Latte Creamy',
            description: 'Pure matcha Jepang dengan susu full cream dingin',
            price: 15000,
            category: 'Minuman',
          ),
          MerchantMenuItem(
            id: 'k3',
            name: 'Mie Ayam Jamur Spesial',
            description: 'Mie kenyal dengan topping ayam kecap & pangsit renyah',
            price: 16000,
            category: 'Makanan Berat',
          ),
          MerchantMenuItem(
            id: 'k4',
            name: 'Roti Bakar Coklat Keju',
            description: 'Roti tebal panggang mentega isi coklat lumer & keju parut',
            price: 10000,
            category: 'Snack & Cemilan',
          ),
        ],
      ),
    ];
  }

  /// Stream seluruh toko makanan dari Firestore (diurutkan buka terlebih dulu).
  Stream<List<MerchantModel>> streamMerchants() {
    return _merchants.snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => MerchantModel.fromMap(doc.data(), doc.id))
          .toList();
      for (final local in sessionMerchants) {
        if (!list.any((m) => m.id == local.id)) {
          list.add(local);
        }
      }
      list.sort((a, b) {
        if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return list;
    });
  }

  /// Stream profil satu merchant milik user yang sedang login.
  Stream<MerchantModel?> streamMerchantById(String merchantId) {
    return _merchants.doc(merchantId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return MerchantModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Simpan atau perbarui data toko makanan (termasuk alamat, banner, kategori).
  Future<void> upsertMerchant(MerchantModel merchant) async {
    final idx = sessionMerchants.indexWhere((m) => m.id == merchant.id);
    if (idx >= 0) {
      sessionMerchants[idx] = merchant;
    } else {
      sessionMerchants.insert(0, merchant);
    }
    await _merchants
        .doc(merchant.id)
        .set(merchant.toMap(), SetOptions(merge: true));
  }

  /// Perbarui daftar menu makanan pada toko.
  Future<void> updateMenus(
    String merchantId,
    List<MerchantMenuItem> menus,
  ) async {
    final idx = sessionMerchants.indexWhere((m) => m.id == merchantId);
    if (idx >= 0) {
      sessionMerchants[idx] = sessionMerchants[idx].copyWith(
        menus: menus,
        updatedAt: DateTime.now(),
      );
    }
    await _merchants.doc(merchantId).set({
      'menus': menus.map((m) => m.toMap()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// Ubah status buka / tutup toko makanan.
  Future<void> setStoreOpen(String merchantId, bool isOpen) async {
    await _merchants.doc(merchantId).set({
      'isOpen': isOpen,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// Stream pesanan makanan masuk khusus merchant tertentu.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMerchantOrders(
    String merchantId,
  ) {
    return _orders
        .where('merchantId', isEqualTo: merchantId)
        .snapshots();
  }

  /// Perbarui status pesanan makanan oleh merchant (`accepted`, `preparing`, `onTrip`, `completed`, `cancelled`).
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _orders.doc(orderId).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
      if (status == 'completed') 'completedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Ubah bytes gambar yang dipilih dari galeri menjadi data URI base64 untuk disimpan di Firestore.
  static String bytesToDataUri(Uint8List bytes, String fileName) {
    final lower = fileName.toLowerCase();
    final mime = lower.endsWith('.png')
        ? 'image/png'
        : (lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  static String formatRupiah(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    var count = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(s[i]);
      count++;
    }
    return 'Rp ${buf.toString().split('').reversed.join()}';
  }
}

/// Widget gambar serbaguna (mendukung `data:image;base64`, URL network, atau fallback).
class MerchantImageRenderer extends StatelessWidget {
  final String imageData;
  final Widget fallback;
  final BoxFit fit;

  const MerchantImageRenderer({
    super.key,
    required this.imageData,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = imageData.trim();
    if (trimmed.isEmpty) return fallback;

    if (trimmed.startsWith('data:image')) {
      final commaIdx = trimmed.indexOf(',');
      if (commaIdx > 0 && commaIdx < trimmed.length - 1) {
        try {
          final bytes = base64Decode(trimmed.substring(commaIdx + 1));
          return Image.memory(
            bytes,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => fallback,
          );
        } catch (_) {
          return fallback;
        }
      }
      return fallback;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return fallback;
  }
}

/// Banner toko makanan yang tampil baik di sisi Mahasiswa maupun Preview di Merchant.
class MerchantBannerView extends StatelessWidget {
  final MerchantModel merchant;
  final double height;
  final BorderRadius? borderRadius;
  final bool showStoreTextOverlay;

  const MerchantBannerView({
    super.key,
    required this.merchant,
    this.height = 148,
    this.borderRadius,
    this.showStoreTextOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = merchantBannerThemeFor(merchant.bannerTheme);
    final hasCustomImage = merchant.bannerData.trim().isNotEmpty;

    final Widget themedBackground = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: style.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -18,
            child: Icon(
              style.watermarkIcon,
              size: 120,
              color: style.textColor.withValues(alpha: 0.12),
            ),
          ),
          if (showStoreTextOverlay)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: style.badgeBg,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      merchant.category.toUpperCase(),
                      style: TextStyle(
                        color: style.badgeText,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    merchant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: style.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (merchant.bannerHeadline.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      merchant.bannerHeadline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: style.textColor.withValues(alpha: 0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasCustomImage)
              MerchantImageRenderer(
                imageData: merchant.bannerData,
                fallback: themedBackground,
              )
            else
              themedBackground,
            if (hasCustomImage &&
                showStoreTextOverlay &&
                merchant.bannerHeadline.trim().isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 22, 14, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                  child: Text(
                    merchant.bannerHeadline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: merchant.isOpen
                      ? const Color(0xFF16A34A)
                      : Colors.black87,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  merchant.isOpen ? 'BUKA' : 'TUTUP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
