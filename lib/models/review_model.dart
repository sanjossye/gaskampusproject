/// Model review/rating setelah trip selesai.
/// Firestore collection: `reviews`
class ReviewModel {
  final String reviewId;
  final String orderId;
  final String reviewerId; // yang memberi review
  final String revieweeId; // yang di-review
  final double rating; // 1.0 - 5.0
  final String? comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.reviewId,
    required this.orderId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> data, String docId) {
    return ReviewModel(
      reviewId: docId,
      orderId: data['orderId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      revieweeId: data['revieweeId'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'],
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt']
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ReviewModel copyWith({
    String? reviewId,
    String? orderId,
    String? reviewerId,
    String? revieweeId,
    double? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      orderId: orderId ?? this.orderId,
      reviewerId: reviewerId ?? this.reviewerId,
      revieweeId: revieweeId ?? this.revieweeId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Jumlah bintang penuh (untuk tampilan UI)
  int get fullStars => rating.floor();

  /// Apakah ada setengah bintang
  bool get hasHalfStar => (rating - fullStars) >= 0.5;

  /// Label rating (Sangat Baik, Baik, dst.)
  String get ratingLabel {
    if (rating >= 4.5) return 'Sangat Baik';
    if (rating >= 3.5) return 'Baik';
    if (rating >= 2.5) return 'Cukup';
    if (rating >= 1.5) return 'Kurang';
    return 'Sangat Kurang';
  }

  @override
  String toString() =>
      'ReviewModel(id: $reviewId, rating: $rating, label: $ratingLabel)';
}

