import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service untuk mengelola saldo dompet GasPay dan mutasi transaksi di Cloud Firestore.
/// Semua operasi penambahan (+) dan pengurangan (-) dana dieksekusi langsung ke database:
/// - `wallets/{uid}`
/// - `wallets/{uid}/transactions/{txId}`
class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  /// Stream dokumen dompet user secara real-time
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamWallet(String uid) {
    return _db.collection('wallets').doc(uid).snapshots();
  }

  /// Stream riwayat transaksi dompet user secara real-time (terbaru di atas)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamTransactions(String uid, {int limit = 30}) {
    return _db
        .collection('wallets')
        .doc(uid)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Top Up Saldo (+) ke Firestore secara atomik
  Future<int> topUp({
    required String uid,
    required int amount,
    required String method,
  }) async {
    if (amount <= 0) {
      throw Exception('Nominal top up harus lebih dari Rp 0.');
    }

    final now = DateTime.now().toIso8601String();
    final walletRef = _db.collection('wallets').doc(uid);
    final txRef = walletRef.collection('transactions').doc();

    return _db.runTransaction<int>((transaction) async {
      final snap = await transaction.get(walletRef);
      final int currentBalance = (snap.data()?['balance'] as num?)?.toInt() ?? 0;
      final int newBalance = currentBalance + amount;

      transaction.set(
        walletRef,
        {
          'userId': uid,
          'balance': newBalance,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      transaction.set(txRef, {
        'transactionId': txRef.id,
        'walletId': uid,
        'type': 'topup',
        'amount': amount,
        'description': 'Top Up Saldo via $method',
        'relatedOrderId': null,
        'createdAt': now,
      });

      return newBalance;
    });
  }

  /// Tarik Saldo / Withdraw (-) dari Firestore secara atomik (validasi anti minus)
  Future<int> withdraw({
    required String uid,
    required int amount,
    required String method,
    required String accountNumber,
  }) async {
    if (amount <= 0) {
      throw Exception('Nominal penarikan harus lebih dari Rp 0.');
    }

    final now = DateTime.now().toIso8601String();
    final walletRef = _db.collection('wallets').doc(uid);
    final txRef = walletRef.collection('transactions').doc();

    return _db.runTransaction<int>((transaction) async {
      final snap = await transaction.get(walletRef);
      final int currentBalance = (snap.data()?['balance'] as num?)?.toInt() ?? 0;

      if (amount > currentBalance) {
        throw Exception('Saldo tidak mencukupi (tersedia Rp ${formatRupiah(currentBalance)}).');
      }

      final int newBalance = currentBalance - amount;

      transaction.set(
        walletRef,
        {
          'userId': uid,
          'balance': newBalance,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      transaction.set(txRef, {
        'transactionId': txRef.id,
        'walletId': uid,
        'type': 'withdrawal',
        'amount': amount,
        'description': 'Tarik Saldo ke $method ($accountNumber)',
        'relatedOrderId': null,
        'createdAt': now,
      });

      return newBalance;
    });
  }

  /// Format angka ke Rupiah tanpa awalan "Rp" (contoh: 250000 -> "250.000", -2775 -> "-2.775")
  static String formatRupiah(int value) {
    final bool isNegative = value < 0;
    final String str = value.abs().toString();
    final StringBuffer result = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write('.');
      result.write(str[i]);
      count++;
    }
    final formatted = result.toString().split('').reversed.join();
    return isNegative ? '-$formatted' : formatted;
  }
}
