/// Status enum untuk order.
enum OrderStatus {
  pending,
  accepted,
  onPickup,
  onTrip,
  completed,
  cancelled,
}

/// Metode pembayaran yang tersedia.
enum PaymentMethod {
  gopay,
  cash,
  wallet,
}

/// Model data order/pesanan perjalanan.
/// Firestore collection: `orders`
class OrderModel {
  final String orderId;
  final String passengerId;
  final String? driverId;
  final OrderStatus status;
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String dropoffAddress;
  final double distanceKm;
  final int fareAmount;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelReason;

  const OrderModel({
    required this.orderId,
    required this.passengerId,
    this.driverId,
    required this.status,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.fareAmount,
    required this.paymentMethod,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelReason,
  });

  factory OrderModel.fromMap(Map<String, dynamic> data, String docId) {
    return OrderModel(
      orderId: docId,
      passengerId: data['passengerId'] ?? '',
      driverId: data['driverId'],
      status: _parseOrderStatus(data['status']),
      pickupLatitude: (data['pickupLatitude'] ?? 0).toDouble(),
      pickupLongitude: (data['pickupLongitude'] ?? 0).toDouble(),
      pickupAddress: data['pickupAddress'] ?? '',
      dropoffLatitude: (data['dropoffLatitude'] ?? 0).toDouble(),
      dropoffLongitude: (data['dropoffLongitude'] ?? 0).toDouble(),
      dropoffAddress: data['dropoffAddress'] ?? '',
      distanceKm: (data['distanceKm'] ?? 0).toDouble(),
      fareAmount: data['fareAmount'] ?? 0,
      paymentMethod: _parsePaymentMethod(data['paymentMethod']),
      createdAt: _parseDateTime(data['createdAt']),
      acceptedAt: data['acceptedAt'] != null ? _parseDateTime(data['acceptedAt']) : null,
      completedAt: data['completedAt'] != null ? _parseDateTime(data['completedAt']) : null,
      cancelledAt: data['cancelledAt'] != null ? _parseDateTime(data['cancelledAt']) : null,
      cancelReason: data['cancelReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'passengerId': passengerId,
      'driverId': driverId,
      'status': status.name,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'pickupAddress': pickupAddress,
      'dropoffLatitude': dropoffLatitude,
      'dropoffLongitude': dropoffLongitude,
      'dropoffAddress': dropoffAddress,
      'distanceKm': distanceKm,
      'fareAmount': fareAmount,
      'paymentMethod': paymentMethod.name,
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancelReason': cancelReason,
    };
  }

  OrderModel copyWith({
    String? orderId,
    String? passengerId,
    String? driverId,
    OrderStatus? status,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupAddress,
    double? dropoffLatitude,
    double? dropoffLongitude,
    String? dropoffAddress,
    double? distanceKm,
    int? fareAmount,
    PaymentMethod? paymentMethod,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancelReason,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      passengerId: passengerId ?? this.passengerId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
      dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      distanceKm: distanceKm ?? this.distanceKm,
      fareAmount: fareAmount ?? this.fareAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }

  /// Format harga ke Rupiah (contoh: "Rp 12.000")
  String get formattedFare {
    final formatted = fareAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  /// Cek apakah order masih aktif
  bool get isActive =>
      status == OrderStatus.pending ||
      status == OrderStatus.accepted ||
      status == OrderStatus.onPickup ||
      status == OrderStatus.onTrip;

  /// Cek apakah order sudah selesai
  bool get isDone => status == OrderStatus.completed;

  /// Cek apakah order dibatalkan
  bool get isCancelled => status == OrderStatus.cancelled;

  static OrderStatus _parseOrderStatus(String? value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'onPickup':
        return OrderStatus.onPickup;
      case 'onTrip':
        return OrderStatus.onTrip;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  static PaymentMethod _parsePaymentMethod(String? value) {
    switch (value) {
      case 'gopay':
        return PaymentMethod.gopay;
      case 'cash':
        return PaymentMethod.cash;
      case 'wallet':
        return PaymentMethod.wallet;
      default:
        return PaymentMethod.wallet;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  @override
  String toString() =>
      'OrderModel(orderId: $orderId, status: ${status.name}, fare: $formattedFare)';
}

