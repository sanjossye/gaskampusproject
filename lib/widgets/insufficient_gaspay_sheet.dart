import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

const Color _kPrimary = Color(0xFFC0F637);
const Color _kPrimaryDeep = Color(0xFF7EB50F);

/// Menampilkan bottom sheet rapi saat saldo GasPay belum mencukupi,
/// menggantikan SnackBar merah datar di bawah layar.
Future<void> showInsufficientGasPaySheet({
  required BuildContext context,
  required int currentBalance,
  required int requiredAmount,
  required VoidCallback onTopUp,
  VoidCallback? onSwitchToCash,
}) {
  final shortfall = (requiredAmount - currentBalance).clamp(0, requiredAmount);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) {
      final isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
      final bg = isDark ? const Color(0xFF171E0F) : Colors.white;
      final tp = isDark ? Colors.white : const Color(0xFF0F1A02);
      final ts = isDark ? const Color(0xFF94A87B) : const Color(0xFF60704E);
      final border = isDark ? const Color(0xFF2B371C) : const Color(0xFFE6ECE0);

      return SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ts.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: _kPrimaryDeep,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Saldo GasPay Belum Cukup',
                      style: TextStyle(
                        color: tp,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Isi saldo GasPay dulu atau ganti metode pembayaran ke Tunai agar pesanan bisa langsung diproses.',
                style: TextStyle(color: ts, fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 16),
              Divider(color: border, height: 1),
              const SizedBox(height: 12),
              _amountRow(
                'Saldo GasPay saat ini',
                'Rp ${WalletService.formatRupiah(currentBalance)}',
                ts,
                tp,
              ),
              const SizedBox(height: 8),
              _amountRow(
                'Total pesanan',
                'Rp ${WalletService.formatRupiah(requiredAmount)}',
                ts,
                tp,
              ),
              const SizedBox(height: 8),
              _amountRow(
                'Kekurangan saldo',
                'Rp ${WalletService.formatRupiah(shortfall)}',
                ts,
                const Color(0xFFD97706),
                boldValue: true,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    onTopUp();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: const Color(0xFF0A0F02),
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
                  label: const Text(
                    'Top Up GasPay',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              if (onSwitchToCash != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      onSwitchToCash();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tp,
                      side: BorderSide(color: border, width: 1.4),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text(
                      'Ganti ke Bayar Tunai',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Widget _amountRow(
  String label,
  String value,
  Color labelColor,
  Color valueColor, {
  bool boldValue = false,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          color: labelColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: valueColor,
          fontSize: 13.5,
          fontWeight: boldValue ? FontWeight.w800 : FontWeight.w700,
        ),
      ),
    ],
  );
}
