import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  int _selectedDayIndex = 4;
  bool _isWithdrawExpanded = false;
  bool _isTopUpExpanded = false;
  String? _selectedMethod;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();

  // Saldo yang dimiliki user
  static const int _saldo = 250000;

  // Pesan error validasi
  String? _amountError;

  static const List<String> _withdrawalMethods = [
    'Bank Mandiri',
    'Bank BRI',
    'Bank BCA',
    'OVO',
    'DANA',
    'GoPay',
  ];

  static const List<String> _topUpMethods = [
    'Bank Transfer',
    'Alfamart',
    'Indomaret',
    'DANA (Link)',
    'GoPay (Link)',
  ];

  static const List<Map<String, dynamic>> _weeklyData = [
    {'day': 'Sen', 'amount': 'Rp 210.000', 'height': 0.4},
    {'day': 'Sel', 'amount': 'Rp 390.000', 'height': 0.6},
    {'day': 'Rab', 'amount': 'Rp 280.000', 'height': 0.55},
    {'day': 'Kam', 'amount': 'Rp 320.000', 'height': 0.75},
    {'day': 'Jum', 'amount': 'Rp 450.000', 'height': 0.95},
    {'day': 'Sab', 'amount': 'Rp 0', 'height': 0.1},
    {'day': 'Min', 'amount': 'Rp 0', 'height': 0.1},
  ];

  @override
  void dispose() {
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
        _amountError = 'Nominal melebihi saldo (Rp ${_formatRupiah(_saldo)})';
      } else {
        _amountError = null;
      }
    });
  }

  /// Format angka ke format Rupiah tanpa "Rp" (misal: 250000 → "250.000")
  String _formatRupiah(int value) {
    final String str = value.toString();
    final StringBuffer result = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write('.');
      result.write(str[i]);
      count++;
    }
    return result.toString().split('').reversed.join();
  }

  bool get _isFormValid {
    // Defensive check for controller initialization in Web/Hot Reload
    try {
      final amountStr = _amountController.text;
      if (amountStr.isEmpty) return false;
      final int? parsed = int.tryParse(amountStr);
      if (parsed == null || parsed <= 0) return false;
      if (_isWithdrawExpanded && parsed > _saldo) return false;
      if (_selectedMethod == null) return false;
      if (_isWithdrawExpanded && _accountController.text.isEmpty) return false;
      return true;
    } catch (_) {
      return false;
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
          'Dompet Saya',
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
              const SizedBox(height: 24),
              _buildEarningsSection(isDark, cardBg, textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaldoSection(bool isDark, Color cardBg, Color textColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kDark,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: kDark.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
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
          const SizedBox(height: 32),
          
          if (!_isWithdrawExpanded && !_isTopUpExpanded)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _isWithdrawExpanded = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 20, fontWeight: FontWeight.bold),
                        SizedBox(width: 10),
                        Text('Tarik', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _isTopUpExpanded = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: kDark,
                      elevation: 10,
                      shadowColor: kPrimary.withOpacity(0.4),
                      minimumSize: const Size(0, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 20, fontWeight: FontWeight.bold),
                        SizedBox(width: 10),
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
              'SALDO SAAT INI',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2),
            ),
            Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.2), size: 20),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('Rp', style: TextStyle(color: kPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text(_formatRupiah(_saldo), style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionForm({required bool isWithdraw}) {
    final bool hasError = _amountError != null;
    final List<String> methods = isWithdraw ? _withdrawalMethods : _topUpMethods;
    final String title = isWithdraw ? 'TARIK SALDO' : 'ISI SALDO (TOP UP)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.white.withOpacity(0.08), height: 32),
        Text(title, style: const TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: hasError ? Colors.red[300] : Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          onChanged: _onAmountChanged,
          decoration: InputDecoration(
            hintText: 'Masukkan nominal...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.18)),
            prefixText: 'Rp ',
            prefixStyle: TextStyle(color: hasError ? Colors.red[300] : kPrimary, fontWeight: FontWeight.bold),
            errorText: _amountError,
            errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11, fontWeight: FontWeight.w600),
            filled: true,
            fillColor: hasError ? Colors.red.withOpacity(0.05) : Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: hasError ? Colors.red.withOpacity(0.4) : Colors.white.withOpacity(0.08))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: hasError ? Colors.red.withOpacity(0.6) : kPrimary.withOpacity(0.4))),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text(
                'Pilih Metode...',
                style: TextStyle(color: Colors.white10, fontSize: 14),
              ),
              dropdownColor: kDark,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              value: _selectedMethod,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withOpacity(0.4)),
              items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _selectedMethod = val),
            ),
          ),
        ),
        
        // --- Added Account/Phone Field for Withdrawals ---
        if (isWithdraw && _selectedMethod != null) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _accountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: _selectedMethod!.toLowerCase().contains('bank') ? 'Masukkan no. rekening...' : 'Masukkan no. HP...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.18)),
              prefixIcon: Icon(
                _selectedMethod!.toLowerCase().contains('bank') ? Icons.account_balance : Icons.phone_android,
                color: kPrimary,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
            ),
          ),
        ],
        
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => setState(() {
                  _isWithdrawExpanded = false;
                  _isTopUpExpanded = false;
                  _amountController.clear();
                  _accountController.clear();
                  _selectedMethod = null;
                  _amountError = null;
                }),
                style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.white.withOpacity(0.08))), minimumSize: const Size(double.infinity, 50)),
                child: Text('Batal', style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isFormValid ? () => _handleActionSuccess(isWithdraw) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  disabledBackgroundColor: kPrimary.withOpacity(0.25),
                  foregroundColor: kDark,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(isWithdraw ? 'Konfirmasi Tarik' : 'Konfirmasi Top Up', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleActionSuccess(bool isWithdraw) {
    final int amount = int.parse(_amountController.text);
    final String type = isWithdraw ? 'Penarikan' : 'Top Up';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type Rp ${_formatRupiah(amount)} via $_selectedMethod berhasil!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {
      _isWithdrawExpanded = false;
      _isTopUpExpanded = false;
      _amountController.clear();
      _accountController.clear();
      _selectedMethod = null;
      _amountError = null;
    });
  }

  Widget _buildEarningsSection(bool isDark, Color cardBg, Color textColor) {
    final selectedDay = _weeklyData[_selectedDayIndex];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pendapatan Mingguan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text('+12% vs minggu lalu', style: TextStyle(color: Colors.green[600], fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TOTAL (${selectedDay['day']})', style: TextStyle(color: Colors.grey[400], fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  Text(selectedDay['amount'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_weeklyData.length, (index) {
              final isSelected = _selectedDayIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 120,
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          height: 120 * (_weeklyData[index]['height'] as double),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isSelected ? kDark : (isDark ? Colors.white.withOpacity(0.1) : Colors.blue.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected ? [BoxShadow(color: kDark.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _weeklyData[index]['day'],
                        style: TextStyle(
                          color: isSelected ? (isDark ? kPrimary : kDark) : Colors.grey[400],
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
}