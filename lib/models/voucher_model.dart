import 'package:cloud_firestore/cloud_firestore.dart';

/// Model voucher / promo untuk ekosistem GasKampus
class VoucherModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final String category; // 'ANTAR', 'MAKAN', 'TITIP', 'DOMPET', 'EVENT'
  final String discountType; // 'fixed' (Rp) atau 'percent' (%)
  final int discountValue; // Misal 5000 atau 50 (%)
  final int maxDiscount; // Maksimal potongan (untuk percent)
  final int minOrder; // Minimal belanja (Rp)
  final String validUntilText; // Text label tanggal, misal 'Hingga 30 Des 2026'
  final DateTime? validUntil;
  final bool isActive;
  final int quota; // Jumlah kuota kupon
  final int usedCount;
  final DateTime createdAt;

  const VoucherModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    this.category = 'ANTAR',
    this.discountType = 'fixed',
    required this.discountValue,
    this.maxDiscount = 0,
    this.minOrder = 0,
    required this.validUntilText,
    this.validUntil,
    this.isActive = true,
    this.quota = 100,
    this.usedCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code.toUpperCase().trim(),
      'title': title,
      'description': description,
      'category': category.toUpperCase(),
      'discountType': discountType,
      'discountValue': discountValue,
      'maxDiscount': maxDiscount,
      'minOrder': minOrder,
      'validUntilText': validUntilText,
      'validUntil': validUntil?.toIso8601String(),
      'isActive': isActive,
      'quota': quota,
      'usedCount': usedCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory VoucherModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return VoucherModel(
      id: docId,
      code: map['code'] as String? ?? 'PROMO',
      title: map['title'] as String? ?? 'Diskon Kampus',
      description: map['description'] as String? ?? '',
      category: (map['category'] as String? ?? 'ANTAR').toUpperCase(),
      discountType: map['discountType'] as String? ?? 'fixed',
      discountValue: (map['discountValue'] as num?)?.toInt() ?? 0,
      maxDiscount: (map['maxDiscount'] as num?)?.toInt() ?? 0,
      minOrder: (map['minOrder'] as num?)?.toInt() ?? 0,
      validUntilText: map['validUntilText'] as String? ?? 'Berlaku 30 Hari',
      validUntil: map['validUntil'] != null ? parseDate(map['validUntil']) : null,
      isActive: map['isActive'] as bool? ?? true,
      quota: (map['quota'] as num?)?.toInt() ?? 100,
      usedCount: (map['usedCount'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null ? parseDate(map['createdAt']) : DateTime.now(),
    );
  }

  VoucherModel copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    String? category,
    String? discountType,
    int? discountValue,
    int? maxDiscount,
    int? minOrder,
    String? validUntilText,
    DateTime? validUntil,
    bool? isActive,
    int? quota,
    int? usedCount,
    DateTime? createdAt,
  }) {
    return VoucherModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      minOrder: minOrder ?? this.minOrder,
      validUntilText: validUntilText ?? this.validUntilText,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
      quota: quota ?? this.quota,
      usedCount: usedCount ?? this.usedCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
