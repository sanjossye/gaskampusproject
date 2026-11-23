import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/wallet_service.dart';
import '../payment_success_screen.dart';
import 'service_order_screen.dart';

// Palet sinkronisasi minimum
const Color kPrimary = Color(0xFFC0F637);
const Color kBgDark = Color(0xFF1D2210);
const Color kCardDark = Color(0xFF1C2414);

void showTopUpModal(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isDark ? kCardDark : Colors.white;
  final tp = isDark ? Colors.white : const Color(0xFF0F172A);
  final ts = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  final border = isDark ? const Color(0xFF2A3518) : const Color(0xFFE2E8F0);

  final amountCtrl = TextEditingController(text: '50000');
  String selectedMethod = 'QRIS';
  bool isLoading = false;
  const quickAmounts = [25000, 50000, 100000, 200000];

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (modalCtx) {
      return StatefulBuilder(
        builder: (sheetCtx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              top: 12,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + MediaQuery.of(sheetCtx).padding.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white30 : Colors.black12,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Isi Saldo GasPay',
                            style: TextStyle(color: tp, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(modalCtx),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close_rounded, color: tp, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick nominal chips + Input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: quickAmounts.map((val) {
                            final isSel = amountCtrl.text == '$val';
                            return InkWell(
                              onTap: () => setModalState(() => amountCtrl.text = '$val'),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? kPrimary : (isDark ? Colors.white10 : Colors.grey[100]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Rp ${WalletService.formatRupiah(val)}',
                                  style: TextStyle(
                                    color: isSel ? Colors.black : tp,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: TextStyle(color: tp, fontWeight: FontWeight.bold, fontSize: 16),
                          decoration: InputDecoration(
                            prefixText: 'Rp ',
                            hintText: 'Nominal Top Up',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Opsi Pembayaran QRIS
                  _buildTopUpOption(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'QRIS',
                    subtitle: 'Scan pakai m-banking / e-wallet bebas',
                    tp: tp,
                    ts: ts,
                    border: border,
                    isSelected: selectedMethod == 'QRIS',
                    onTap: () => setModalState(() => selectedMethod = 'QRIS'),
                  ),

                  // Opsi M-Banking
                  _buildTopUpOption(
                    icon: Icons.account_balance_rounded,
                    title: 'M-Banking',
                    subtitle: 'BCA, Mandiri, BNI, BRI, BSI dll',
                    tp: tp,
                    ts: ts,
                    border: border,
                    isSelected: selectedMethod == 'M-Banking',
                    onTap: () => setModalState(() => selectedMethod = 'M-Banking'),
                  ),

                  // Opsi Minimarket
                  _buildTopUpOption(
                    icon: Icons.storefront_rounded,
                    title: 'Minimarket / Merchant',
                    subtitle: 'Indomaret & Alfamart terdekat',
                    tp: tp,
                    ts: ts,
                    border: border,
                    isSelected: selectedMethod == 'Minimarket',
                    onTap: () => setModalState(() => selectedMethod = 'Minimarket'),
                  ),

                  const SizedBox(height: 16),

                  // Submit button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                final user = FirebaseAuth.instance.currentUser;
                                final amount = int.tryParse(amountCtrl.text) ?? 0;
                                if (user == null || amount <= 0) return;

                                setModalState(() => isLoading = true);
                                try {
                                  final newBalance = await WalletService().topUp(
                                    uid: user.uid,
                                    amount: amount,
                                    method: selectedMethod,
                                  );
                                  AppNotificationStore.add(
                                    title: 'Top Up GasPay Berhasil',
                                    message:
                                        'Top Up +Rp ${WalletService.formatRupiah(amount)} via $selectedMethod berhasil. Saldo saat ini: Rp ${WalletService.formatRupiah(newBalance)}.',
                                    icon: Icons.account_balance_wallet_rounded,
                                    color: const Color(0xFF64748B),
                                  );
                                  if (!modalCtx.mounted) return;
                                  Navigator.pop(modalCtx);
                                  if (!context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      fullscreenDialog: true,
                                      builder: (_) => PaymentSuccessScreen(
                                        title: 'Top Up Berhasil!',
                                        receiverName: 'GasPay · Dompet GasKampus',
                                        receiverSub: 'Top Up via $selectedMethod',
                                        amountCaption: 'Nominal Top Up',
                                        amountLabel:
                                            'Rp ${WalletService.formatRupiah(amount)}',
                                        details: [
                                          MapEntry('Metode', selectedMethod),
                                          MapEntry(
                                            'Saldo sekarang',
                                            'Rp ${WalletService.formatRupiah(newBalance)}',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!modalCtx.mounted) return;
                                  setModalState(() => isLoading = false);
                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                    SnackBar(content: Text('Top Up gagal: $e'), backgroundColor: Colors.redAccent),
                                  );
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                              )
                            : const Text('Konfirmasi Top Up Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildTopUpOption({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color tp,
  required Color ts,
  required Color border,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected ? kPrimary.withValues(alpha: 0.12) : Colors.transparent,
        border: Border(bottom: BorderSide(color: border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: tp, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: ts, fontSize: 12)),
              ],
            ),
          ),
          Icon(
            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isSelected ? kPrimary : ts,
            size: 22,
          ),
        ],
      ),
    ),
  );
}
