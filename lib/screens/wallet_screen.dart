import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/wallet_service.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kDark = Color(0xFF1A1A1A);
const Color kBg = Color(0xFFF8F9FA);

class WalletScreen extends StatefulWidget {
  final VoidCallback onBack;

  const WalletScreen({super.key, required this.onBack});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();

  int _selectedDayIndex = DateTime.now().weekday - 1; // 0=Sen .. 6=Min
  bool _isWithdrawExpanded = false;
  bool _isTopUpExpanded = false;
  bool _isSubmitting = false;
  String? _selectedMethod;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();

  // Saldo & koin live dari Cloud Firestore (wallets/{uid})
  int _saldo = 0;
  int _coins = 0;
  bool _isLoadingWallet = true;

  // Data transaksi live dari wallets/{uid}/transactions
  List<Map<String, dynamic>> _transactions = [];

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _walletSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _txSub;

  // Pesan error validasi
  String? _amountError;

  static const List<int> _quickAmounts = [25000, 50000, 100000, 200000];

  static const List<String> _withdrawalMethods = [
    'Bank Mandiri',
    'Bank BRI',
    'Bank BCA',
    'OVO',
    'DANA',
    'GoPay',
  ];

  static const List<String> _topUpMethods = [
    'QRIS',
    'Bank Transfer',
    'Alfamart',
    'Indomaret',
    'DANA (Link)',
    'GoPay (Link)',
  ];

  static const List<String> _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    _initWalletListeners();
  }

  void _initWalletListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingWallet = false);
      return;
    }

    // 1. Stream live saldo dompet
    _walletSub = _walletService.streamWallet(user.uid).listen((doc) {
      if (!mounted) return;
      final data = doc.data() ?? {};
      setState(() {
        _saldo = (data['balance'] as num?)?.toInt() ?? 0;
        _coins = (data['coins'] as num?)?.toInt() ?? 0;
        _isLoadingWallet = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _isLoadingWallet = false);
    });

    // 2. Stream live riwayat transaksi
    _txSub = _walletService.streamTransactions(user.uid).listen((snap) {
      if (!mounted) return;
      setState(() {
        _transactions = snap.docs.map((d) {
          final map = Map<String, dynamic>.from(d.data());
          map['id'] = d.id;
          return map;
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    _txSub?.cancel();
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  /// Validasi nominal saat user mengetik
  void _onAmountChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _amountError = null;
        return;
      }
      final int? parsed = int.tryParse(value);
      if (parsed == null || parsed <= 0) {
        _amountError = 'Masukkan nominal yang valid';
      } else if (_isWithdrawExpanded && parsed > _saldo) {
        _amountError = 'Nominal melebihi saldo (Rp ${WalletService.formatRupiah(_saldo)})';
      } else {
        _amountError = null;
      }
    });
  }

  bool get _isFormValid {
    try {
      if (_isSubmitting) return false;
      final amountStr = _amountController.text;
      if (amountStr.isEmpty) return false;
      final int? parsed = int.tryParse(amountStr);
      if (parsed == null || parsed <= 0) return false;
      if (_isWithdrawExpanded && parsed > _saldo) return false;
      if (_selectedMethod == null) return false;
      if (_isWithdrawExpanded && _accountController.text.trim().isEmpty) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isCreditType(String type) {
    return type == 'topup' || type == 'earning' || type == 'refund';
  }

  /// Hitung total dana masuk & keluar dari transaksi Firestore
  int get _totalCredit => _transactions
      .where((tx) => _isCreditType(tx['type']?.toString() ?? ''))
      .fold(0, (acc, tx) => acc + ((tx['amount'] as num?)?.toInt() ?? 0));

  int get _totalDebit => _transactions
      .where((tx) => !_isCreditType(tx['type']?.toString() ?? ''))
      .fold(0, (acc, tx) => acc + ((tx['amount'] as num?)?.toInt() ?? 0));

  /// Hitung pendapatan per hari (Sen-Min) dari transaksi earning/topup
  List<int> _computeWeeklyEarnings() {
    final List<int> perDay = List<int>.filled(7, 0);
    for (final tx in _transactions) {
      final type = tx['type']?.toString() ?? '';
      if (type != 'earning' && type != 'topup') continue;
      final amount = (tx['amount'] as num?)?.toInt() ?? 0;
      final dt = DateTime.tryParse(tx['createdAt']?.toString() ?? '');
      if (dt != null) {
        final idx = (dt.weekday - 1).clamp(0, 6);
        perDay[idx] += amount;
      }
    }
    return perDay;
  }

  Future<void> _handleActionSubmit(bool isWithdraw) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu untuk bertransaksi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final int amount = int.tryParse(_amountController.text) ?? 0;
    final String method = _selectedMethod ?? '';
    final String account = _accountController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      int updatedBalance;
      if (isWithdraw) {
        updatedBalance = await _walletService.withdraw(
          uid: user.uid,
          amount: amount,
          method: method,
          accountNumber: account,
        );
      } else {
        updatedBalance = await _walletService.topUp(
          uid: user.uid,
          amount: amount,
          method: method,
        );
      }

      if (!mounted) return;
      final String label = isWithdraw ? 'Penarikan' : 'Top Up';
      final String sign = isWithdraw ? '-' : '+';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label $sign Rp ${WalletService.formatRupiah(amount)} via $method berhasil! Saldo sekarang: Rp ${WalletService.formatRupiah(updatedBalance)}',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _saldo = updatedBalance;
        _isWithdrawExpanded = false;
        _isTopUpExpanded = false;
        _amountController.clear();
        _accountController.clear();
        _selectedMethod = null;
        _amountError = null;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi gagal: $msg'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1D2210) : kBg;
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: widget.onBack,
        ),
        title: Text(
          'Dompet GasPay',
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
          child: Column(
            children: [
              _buildSaldoSection(isDark, cardBg, textColor),
              const SizedBox(height: 16),
              _buildSummaryRow(isDark, cardBg, textColor),
              const SizedBox(height: 20),
              _buildEarningsSection(isDark, cardBg, textColor),
              const SizedBox(height: 20),
              _buildTransactionHistorySection(isDark, cardBg, textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaldoSection(bool isDark, Color cardBg, Color textColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kDark,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: kDark.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceInfo(),
          const SizedBox(height: 28),
          if (!_isWithdrawExpanded && !_isTopUpExpanded)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() {
                      _isWithdrawExpanded = true;
                      _isTopUpExpanded = false;
                      _selectedMethod = null;
                      _amountError = null;
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_upward_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Tarik', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() {
                      _isTopUpExpanded = true;
                      _isWithdrawExpanded = false;
                      _selectedMethod = null;
                      _amountError = null;
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: kDark,
                      elevation: 8,
                      shadowColor: kPrimary.withValues(alpha: 0.35),
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Top Up', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else if (_isWithdrawExpanded)
            _buildActionForm(isWithdraw: true)
          else if (_isTopUpExpanded)
            _buildActionForm(isWithdraw: false),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SALDO GASPAY SAAT INI',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: kPrimary, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    '$_coins Koin',
                    style: const TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingWallet)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(color: kPrimary, strokeWidth: 3),
            ),
          )
        else
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text('Rp', style: TextStyle(color: kPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Text(
                  WalletService.formatRupiah(_saldo),
                  style: TextStyle(
                    color: _saldo < 0 ? Colors.red[300] : Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionForm({required bool isWithdraw}) {
    final bool hasError = _amountError != null;
    final List<String> methods = isWithdraw ? _withdrawalMethods : _topUpMethods;
    final String title = isWithdraw ? 'TARIK SALDO (-)' : 'ISI SALDO / TOP UP (+)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.white.withValues(alpha: 0.08), height: 28),
        Text(
          title,
          style: const TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),

        // Quick nominal chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts.map((val) {
            final isSelected = _amountController.text == '$val';
            return InkWell(
              onTap: () {
                _amountController.text = '$val';
                _onAmountChanged('$val');
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimary : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? kPrimary : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  'Rp ${WalletService.formatRupiah(val)}',
                  style: TextStyle(
                    color: isSelected ? kDark : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: hasError ? Colors.red[300] : Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          onChanged: _onAmountChanged,
          decoration: InputDecoration(
            hintText: 'Masukkan nominal...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
            prefixText: 'Rp ',
            prefixStyle: TextStyle(color: hasError ? Colors.red[300] : kPrimary, fontWeight: FontWeight.bold),
            errorText: _amountError,
            errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11, fontWeight: FontWeight.w600),
            filled: true,
            fillColor: hasError ? Colors.red.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: hasError ? Colors.red.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: hasError ? Colors.red.withValues(alpha: 0.6) : kPrimary.withValues(alpha: 0.5)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text(
                'Pilih Metode...',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
              ),
              dropdownColor: kDark,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              value: _selectedMethod,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withValues(alpha: 0.5)),
              items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _selectedMethod = val),
            ),
          ),
        ),

        if (isWithdraw && _selectedMethod != null) ...[
          const SizedBox(height: 14),
          TextField(
            controller: _accountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: _selectedMethod!.toLowerCase().contains('bank') ? 'Masukkan no. rekening...' : 'Masukkan no. HP...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
              prefixIcon: Icon(
                _selectedMethod!.toLowerCase().contains('bank') ? Icons.account_balance : Icons.phone_android,
                color: kPrimary,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() {
                          _isWithdrawExpanded = false;
                          _isTopUpExpanded = false;
                          _amountController.clear();
                          _accountController.clear();
                          _selectedMethod = null;
                          _amountError = null;
                        }),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text('Batal', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isFormValid ? () => _handleActionSubmit(isWithdraw) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  disabledBackgroundColor: kPrimary.withValues(alpha: 0.25),
                  foregroundColor: kDark,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: kDark, strokeWidth: 2.5),
                      )
                    : Text(
                        isWithdraw ? 'Konfirmasi Tarik' : 'Konfirmasi Top Up',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Ringkasan Total Uang Masuk (+) dan Keluar (-) live dari Firestore
  Widget _buildSummaryRow(bool isDark, Color cardBg, Color textColor) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.arrow_downward_rounded, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text('TOTAL MASUK', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '+ Rp ${WalletService.formatRupiah(_totalCredit)}',
                    style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.arrow_upward_rounded, color: Colors.redAccent, size: 16),
                    SizedBox(width: 4),
                    Text('TOTAL KELUAR', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '- Rp ${WalletService.formatRupiah(_totalDebit)}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsSection(bool isDark, Color cardBg, Color textColor) {
    final weeklyValues = _computeWeeklyEarnings();
    final int maxVal = weeklyValues.fold<int>(1, (a, b) => a > b ? a : b);
    final int selectedAmount = weeklyValues[_selectedDayIndex];
    final String selectedDayLabel = _dayLabels[_selectedDayIndex];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pemasukan Mingguan', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.sync, color: Colors.green, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Terhubung ke Firestore',
                            style: TextStyle(color: Colors.green[600], fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TOTAL ($selectedDayLabel)', style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  Text(
                    'Rp ${WalletService.formatRupiah(selectedAmount)}',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final isSelected = _selectedDayIndex == index;
              final double ratio = weeklyValues[index] == 0 ? 0.12 : (weeklyValues[index] / maxVal).clamp(0.18, 1.0);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 110,
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          height: 110 * ratio,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? kPrimary : kDark)
                                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.12)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _dayLabels[index],
                        style: TextStyle(
                          color: isSelected ? (isDark ? kPrimary : kDark) : Colors.grey[500],
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Riwayat Mutasi Transaksi Live dari `wallets/{uid}/transactions`
  Widget _buildTransactionHistorySection(bool isDark, Color cardBg, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Riwayat Mutasi Saldo', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                '${_transactions.length} Transaksi',
                style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada transaksi. Coba Top Up, Tarik Saldo, atau selesaikan order!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              separatorBuilder: (_, _) => Divider(height: 20, color: isDark ? Colors.white12 : Colors.grey[200]),
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                final String type = tx['type']?.toString() ?? 'payment';
                final int amount = (tx['amount'] as num?)?.toInt() ?? 0;
                final String desc = tx['description']?.toString() ?? 'Transaksi GasPay';
                final String createdAtRaw = tx['createdAt']?.toString() ?? '';
                final bool isCredit = _isCreditType(type);

                final IconData icon = switch (type) {
                  'topup' => Icons.add_circle_outline,
                  'earning' => Icons.moped,
                  'commission' => Icons.percent,
                  'withdrawal' => Icons.account_balance,
                  'refund' => Icons.replay,
                  _ => Icons.payments_outlined,
                };

                final Color accentColor = isCredit ? Colors.green : Colors.redAccent;
                final String timeFormatted = _formatShortTime(createdAtRaw);

                return Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            desc,
                            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${type.toUpperCase()} · $timeFormatted',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isCredit ? '+' : '-'} Rp ${WalletService.formatRupiah(amount)}',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatShortTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }
}
