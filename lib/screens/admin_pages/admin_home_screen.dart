import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBgDark = Color(0xFF1D2210);
const Color kBgLight = Color(0xFFF7F8F5);

TextStyle _body(Color c, double sz, FontWeight w, {double? ls, double? h}) =>
    TextStyle(color: c, fontSize: sz, fontWeight: w, letterSpacing: ls, height: h);

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kBgDark : kBgLight;
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1A1F0C) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A3518) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: kPrimary,
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuAPL6NfzMDQDoi0D2I6FMc9wjPwwAvp7VAzLzuDdCe_xUJ-ggxzh1kZ0M2R7ypwt3R-v4daHBrFk-DaHoWUGVUmVW7H8CKIHWGfUq_Non9yUtY9ut6PF0VYBSdFT35h6GtvfXw1bWs4zUeGdtzgXs9HqAPM7qHve5iAXLBx5Is9dgHTMiQM79SKhM3FRnHB1naOZoAuNRHm1V6ljXIhBRvwG7E9M3IbKZhfgnc8MQ6R7TlVtngV7Td7uIr7tPRNcgxUGLWdQZfysmc'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ADMINISTRATOR', style: _body(textColorSecondary, 10, FontWeight.bold, ls: 1)),
                              Text('Dashboard Kampus', style: _body(textColorPrimary, 18, FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor),
                            ),
                            child: Icon(Icons.notifications_outlined, color: textColorPrimary),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: bg, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // --- Stats Grid ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Statistik Utama', style: _body(textColorPrimary, 20, FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text('Live Update', style: _body(kPrimary, 10, FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildStatCard('Total Mahasiswa', '12.450', '+5.2%', Icons.school_rounded, Colors.blue, cardBg, textColorPrimary, textColorSecondary, borderColor),
                      _buildStatCard('Driver Mahasiswa', '520', '+1.2%', Icons.moped_rounded, kPrimary, cardBg, textColorPrimary, textColorSecondary, borderColor),
                      _buildStatCard('Driver Umum', '330', '+2.4%', Icons.person_rounded, kPrimary, cardBg, textColorPrimary, textColorSecondary, borderColor),
                      _buildStatCard('Total Pendapatan', 'Rp 450jt', '+10%', Icons.payments_rounded, Colors.green, cardBg, textColorPrimary, textColorSecondary, borderColor),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // --- Weekly Stats Banner ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TRIP MINGGU INI', style: _body(Colors.black.withOpacity(0.6), 12, FontWeight.bold, ls: 0.5)),
                            const SizedBox(height: 4),
                            Text('8.900', style: _body(Colors.black, 36, FontWeight.w900)),
                            const SizedBox(height: 8),
                            Text('Target Mingguan: 10.000 Trip', style: _body(Colors.black.withOpacity(0.7), 11, FontWeight.w500)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.trending_up_rounded, color: Colors.black, size: 32),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- Activity Chart Mockup ---
                  Text('Grafik Aktivitas', style: _body(textColorPrimary, 18, FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _chartLegend('Order/Hari', kPrimary),
                                const SizedBox(width: 12),
                                _chartLegend('Driver Aktif', Colors.grey),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text('7 Hari Terakhir', style: _body(textColorPrimary, 10, FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down_rounded, color: textColorPrimary, size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _chartBar(40, 0.7),
                            _chartBar(60, 0.5),
                            _chartBar(80, 0.9),
                            _chartBar(70, 0.4),
                            _chartBar(100, 1.0),
                            _chartBar(50, 0.6),
                            _chartBar(65, 0.5),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN']
                              .map((day) => Text(day, style: _body(textColorSecondary.withOpacity(0.5), 10, FontWeight.bold)))
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- Admin Notifications ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Perlu Tindakan', style: _body(textColorPrimary, 18, FontWeight.bold)),
                      Text('Lihat Semua', style: _body(textColorSecondary, 12, FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildActionItem('Verifikasi Driver Mahasiswa', '8 Pendaftar baru', Icons.how_to_reg_rounded, kPrimary, cardBg, textColorPrimary, textColorSecondary, borderColor),
                  _buildActionItem('Verifikasi Driver Umum', '4 Pendaftar baru', Icons.how_to_reg_rounded, kPrimary, cardBg, textColorPrimary, textColorSecondary, borderColor),
                  _buildActionItem('Laporan User', '5 Komplain belum dibaca', Icons.report_rounded, Colors.red, cardBg, textColorPrimary, textColorSecondary, borderColor),
                  _buildActionItem('Order Bermasalah', '3 Order terhenti > 15 mnt', Icons.warning_rounded, Colors.orange, cardBg, textColorPrimary, textColorSecondary, borderColor),
                ],
              ),
            ),
          ),

          // --- Bottom Navigation ---
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: bg.withOpacity(0.8),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItem(Icons.grid_view_rounded, 'Beranda', true, textColorPrimary),
                  _navItem(Icons.directions_car_rounded, 'Driver', false, textColorSecondary),
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: bg, width: 4),
                      ),
                      child: const Icon(Icons.add, color: Colors.black, size: 32),
                    ),
                  ),
                  _navItem(Icons.receipt_long_rounded, 'Pesanan', false, textColorSecondary),
                  _navItem(Icons.bar_chart_rounded, 'Laporan', false, textColorSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String percent, IconData icon, Color color, Color bg, Color text, Color textSec, Color border) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(percent, style: _body(Colors.green, 10, FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Text(label, style: _body(textSec, 11, FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: _body(text, 22, FontWeight.bold, h: 1)),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, String sub, IconData icon, Color color, Color bg, Color text, Color textSec, Color border) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _body(text, 14, FontWeight.bold)),
                const SizedBox(height: 2),
                Text(sub, style: _body(textSec, 12, FontWeight.normal)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: text,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Proses', style: _body(bg, 11, FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: _body(Colors.grey, 10, FontWeight.bold)),
      ],
    );
  }

  Widget _chartBar(double height, double fill) {
    return Container(
      width: 20,
      height: height,
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.vertical(top: Radius.circular(6))),
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height * fill,
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(fill < 1 ? 0.4 : 1.0),
          borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: active ? kPrimary : color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: _body(active ? kPrimary : color, 10, FontWeight.bold)),
      ],
    );
  }
}
