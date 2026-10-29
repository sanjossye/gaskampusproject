/// Tipe transaksi dompet.
enum TransactionType {
  topup,
  payment,
  earning,
  withdrawal,
}

/// Model dompet user.
/// Firestore collection: `wallets`
class WalletModel {
  final String walletId;
  final String userId;
  final int balance;
  final DateTime updatedAt;

  const WalletModel({
    required this.walletId,
    required this.userId,
    required this.balance,
    required this.updatedAt,
  });

  factory WalletModel.fromMap(Map<String, dynamic> data, String docId) {
    return WalletModel(
      walletId: docId,
      userId: data['userId'] ?? '',
      balance: data['balance'] ?? 0,
      updatedAt: data['updatedAt'] is DateTime
          ? data['updatedAt']
          : DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'balance': balance,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  WalletModel copyWith({
    String? walletId,
    String? userId,
    int? balance,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Format saldo ke Rupiah (contoh: "Rp 150.000")
  String get formattedBalance {
    final formatted = balance.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  @override
  String toString() => 'WalletModel(walletId: $walletId, balance: $formattedBalance)';
}

/// Model transaksi (history) dompet.
/// Firestore collection: `wallets/{walletId}/transactions`
class TransactionModel {
  final String transactionId;
  final String walletId;
  final TransactionType type;
  final int amount;
  final String description;
  final String? relatedOrderId;
  final DateTime createdAt;

  const TransactionModel({
    required this.transactionId,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.description,
    this.relatedOrderId,
    required this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> data, String docId) {
    return TransactionModel(
      transactionId: docId,
      walletId: data['walletId'] ?? '',
      type: _parseType(data['type']),
      amount: data['amount'] ?? 0,
      description: data['description'] ?? '',
      relatedOrderId: data['relatedOrderId'],
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt']
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'walletId': walletId,
      'type': type.name,
      'amount': amount,
      'description': description,
      'relatedOrderId': relatedOrderId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? transactionId,
    String? walletId,
    TransactionType? type,
    int? amount,
    String? description,
    String? relatedOrderId,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      transactionId: transactionId ?? this.transactionId,
      walletId: walletId ?? this.walletId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      relatedOrderId: relatedOrderId ?? this.relatedOrderId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Format nominal ke Rupiah (contoh: "Rp 50.000")
  String get formattedAmount {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  /// Apakah transaksi ini menambah saldo
  bool get isCredit => type == TransactionType.topup || type == TransactionType.earning;

  /// Apakah transaksi ini mengurangi saldo
  bool get isDebit => type == TransactionType.payment || type == TransactionType.withdrawal;

  /// Prefix +/- untuk tampilan
  String get signedAmount => '${isCredit ? '+' : '-'} $formattedAmount';

  static TransactionType _parseType(String? value) {
    switch (value) {
      case 'topup':
        return TransactionType.topup;
      case 'payment':
        return TransactionType.payment;
      case 'earning':
        return TransactionType.earning;
      case 'withdrawal':
        return TransactionType.withdrawal;
      default:
        return TransactionType.payment;
    }
  }

  @override
  String toString() =>
      'TransactionModel(id: $transactionId, type: ${type.name}, amount: $formattedAmount)';
}

