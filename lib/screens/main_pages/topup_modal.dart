import 'package:flutter/material.dart';

// Palet sinkronisasi minimum
const Color kPrimary       = Color(0xFFC0F637);
const Color kBgDark        = Color(0xFF1D2210);
const Color kCardDark      = Color(0xFF1C2414);

void showTopUpModal(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isDark ? kCardDark : Colors.white;
  final tp = isDark ? Colors.white : const Color(0xFF0F172A);
  final ts = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  final border = isDark ? const Color(0xFF2A3518) : const Color(0xFFE2E8F0);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? Colors.white30 : Colors.black12,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Isi Saldo GoPay Campus',
                    style: TextStyle(color: tp, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, color: tp, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Opsi Pembayaran QRIS
            _buildTopUpOption(
              icon: Icons.qr_code_scanner_rounded,
              title: 'QRIS',
              subtitle: 'Scan pakai m-banking / e-wallet bebas',
              tp: tp,
              ts: ts,
              border: border,
              onTap: () {
                // Di sini dapat ditambahkan fungsionalitas popup menampilkan QR
              },
            ),
            
            // Opsi M-Banking
            _buildTopUpOption(
              icon: Icons.account_balance_rounded,
              title: 'Perbankan Bergerak (M-Banking)',
              subtitle: 'BCA, Mandiri, BNI, BRI, BSI dll',
              tp: tp,
              ts: ts,
              border: border,
              onTap: () {},
            ),

            // Opsi Minimarket
            _buildTopUpOption(
              icon: Icons.storefront_rounded,
              title: 'Minimarket / Merchant',
              subtitle: 'Indomaret & Alfamart terdekat',
              tp: tp,
              ts: ts,
              border: border,
              onTap: () {},
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ],
        ),
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
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: tp, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: ts, fontSize: 13, fontWeight: FontWeight.normal)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: ts),
        ],
      ),
    ),
  );
}
