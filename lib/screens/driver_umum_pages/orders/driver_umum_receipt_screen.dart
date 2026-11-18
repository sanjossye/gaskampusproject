import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../driver_umum_home_screen.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBackgroundLight = Color(0xFFFDFDFD);
const Color kBackgroundDark = Color(0xFF1D2210);

class DriverUmumReceiptScreen extends StatefulWidget {
  final String orderId;
  final String passengerName;
  final String passengerRole;
  final int fareAmount;
  final String dropoffAddress;
  final String paymentMethod;
  final String zone;
  final int commission;
  final int netEarnings;

  const DriverUmumReceiptScreen({
    super.key,
    this.orderId = 'order_live_01',
    this.passengerName = 'Andi Pratama',
    this.passengerRole = 'Mahasiswa · Fak. Teknik USU',
    this.fareAmount = 15000,
    this.dropoffAddress = 'Gedung C - Zona B (Fakultas Teknik USU)',
    this.paymentMethod = 'GasPay',
    this.zone = 'Zona B',
    this.commission = 2250,
    this.netEarnings = 12750,
  });

  @override
  State<DriverUmumReceiptScreen> createState() => _DriverUmumReceiptScreenState();
}

class _DriverUmumReceiptScreenState extends State<DriverUmumReceiptScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? kBackgroundDark : kBackgroundLight;
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    final bool isCash = widget.paymentMethod.toLowerCase() == 'cash' ||
        widget.paymentMethod.toLowerCase() == 'tunai';

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const DriverUmumHomeScreen()),
                          (route) => false,
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: Icon(Icons.close, color: textColor),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Struk Digital Mitra Umum',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),

              // Success Icon & Title
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: kPrimary, size: 56),
                    ),
                    Text(
                      'Perjalanan Selesai',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'TIER 3 · MITRA UMUM (TARIF NORMAL 1,00)',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Receipt Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Total Earnings Hero
                    Text(
                      isCash ? 'PENDAPATAN BERSIH SETELAH KOMISI' : 'PENDAPATAN MASUK DOMPET',
                      style: TextStyle(
                        color: textMutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rp ${widget.netEarnings}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Order Details
                    _buildReceiptRow('Nomor Order', '#${widget.orderId}', textColor, isBold: true),
                    _buildReceiptRow('Penumpang', widget.passengerName, textColor),
                    _buildReceiptRow('Peran', widget.passengerRole, textColor),
                    _buildReceiptRow('Tujuan Kampus', '${widget.dropoffAddress} (${widget.zone})', textColor),
                    _buildReceiptRow('Metode Pembayaran', widget.paymentMethod, textColor, isBold: true),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Financial Breakdown (README Bagian 10)
                    _buildReceiptRow('Tarif Kotor (100%)', 'Rp ${widget.fareAmount}', textColor),
                    _buildReceiptRow(
                      'Komisi Platform GasKampus (15%)',
                      '- Rp ${widget.commission}',
                      Colors.redAccent,
                      isBold: true,
                    ),
                    const SizedBox(height: 4),
                    _buildReceiptRow(
                      'Pendapatan Bersih Driver (85%)',
                      'Rp ${widget.netEarnings}',
                      Colors.green,
                      isBold: true,
                    ),

                    const SizedBox(height: 16),

                    // Settlement Notice Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCash ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCash ? Colors.orange.withValues(alpha: 0.4) : Colors.green.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCash ? Icons.info_outline : Icons.check_circle_outline,
                            color: isCash ? Colors.orange : Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isCash
                                  ? 'Penumpang bayar tunai Rp ${widget.fareAmount}. Komisi 15% (Rp ${widget.commission}) telah otomatis dipotong dari saldo dompet GasPay kamu.'
                                  : 'Pembayaran GasPay lunas. Pendapatan bersih Rp ${widget.netEarnings} telah otomatis ditambahkan ke saldo dompet GasPay kamu.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Button Back to Home
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const DriverUmumHomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Kembali ke Beranda', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, Color textColor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
