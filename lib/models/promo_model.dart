/// Tipe diskon promo.
enum DiscountType {
  percentage,
  fixed,
}

/// Model promo/voucher.
/// Firestore collection: `promos`
class PromoModel {
  final String promoId;
  final String code;
  final String title;
  final String description;
  final DiscountType discountType;
  final int discountValue;
  final int minOrder;
  final int maxDiscount;
  final int usageLimit;
  final int usedCount;
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isActive;

  const PromoModel({
    required this.promoId,
    required this.code,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrder = 0,
    this.maxDiscount = 0,
    this.usageLimit = 0,
    this.usedCount = 0,
    required this.validFrom,
    required this.validUntil,
    this.isActive = true,
  });

  factory PromoModel.fromMap(Map<String, dynamic> data, String docId) {
    return PromoModel(
      promoId: docId,
      code: data['code'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      discountType: _parseDiscountType(data['discountType']),
      discountValue: data['discountValue'] ?? 0,
      minOrder: data['minOrder'] ?? 0,
      maxDiscount: data['maxDiscount'] ?? 0,
      usageLimit: data['usageLimit'] ?? 0,
      usedCount: data['usedCount'] ?? 0,
      validFrom: data['validFrom'] is DateTime
          ? data['validFrom']
          : DateTime.tryParse(data['validFrom']?.toString() ?? '') ?? DateTime.now(),
      validUntil: data['validUntil'] is DateTime
          ? data['validUntil']
          : DateTime.tryParse(data['validUntil']?.toString() ?? '') ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'title': title,
      'description': description,
      'discountType': discountType.name,
      'discountValue': discountValue,
      'minOrder': minOrder,
      'maxDiscount': maxDiscount,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'isActive': isActive,
    };
  }

  PromoModel copyWith({
    String? promoId,
    String? code,
    String? title,
    String? description,
    DiscountType? discountType,
    int? discountValue,
    int? minOrder,
    int? maxDiscount,
    int? usageLimit,
    int? usedCount,
    DateTime? validFrom,
    DateTime? validUntil,
    bool? isActive,
  }) {
    return PromoModel(
      promoId: promoId ?? this.promoId,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minOrder: minOrder ?? this.minOrder,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Format diskon untuk tampilan (contoh: "20%" atau "Rp 5.000")
  String get formattedDiscount {
    if (discountType == DiscountType.percentage) {
      return '$discountValue%';
    }
    final formatted = discountValue.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  /// Format minimum order (contoh: "Min. Rp 20.000")
  String get formattedMinOrder {
    if (minOrder == 0) return 'Tanpa minimum';
    final formatted = minOrder.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Min. Rp $formatted';
  }

  /// Apakah promo masih valid (belum expired & masih aktif)
  bool get isValid {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(validFrom) &&
        now.isBefore(validUntil) &&
        (usageLimit == 0 || usedCount < usageLimit);
  }

  /// Apakah promo sudah kadaluarsa
  bool get isExpired => DateTime.now().isAfter(validUntil);

  /// Sisa kuota penggunaan
  int get remainingUsage => usageLimit > 0 ? usageLimit - usedCount : -1; // -1 = unlimited

  /// Hitung diskon berdasarkan harga order
  int calculateDiscount(int orderAmount) {
    if (!isValid) return 0;
    if (orderAmount < minOrder) return 0;

    int discount;
    if (discountType == DiscountType.percentage) {
      discount = (orderAmount * discountValue / 100).round();
    } else {
      discount = discountValue;
    }

    // Batasi sesuai maxDiscount jika ada
    if (maxDiscount > 0 && discount > maxDiscount) {
      discount = maxDiscount;
    }

    // Diskon tidak boleh melebihi harga order
    if (discount > orderAmount) discount = orderAmount;

    return discount;
  }

  static DiscountType _parseDiscountType(String? value) {
    switch (value) {
      case 'percentage':
        return DiscountType.percentage;
      case 'fixed':
        return DiscountType.fixed;
      default:
        return DiscountType.percentage;
    }
  }

  @override
  String toString() =>
      'PromoModel(id: $promoId, code: $code, discount: $formattedDiscount, valid: $isValid)';
}

