import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../login_screen.dart';
import 'verification/driver_verification_screen.dart';
import 'drivers/admin_drivers_screen.dart';
import 'orders/admin_orders_screen.dart';
import 'reports/admin_reports_screen.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBgDark = Color(0xFF1D2210);
const Color kBgLight = Color(0xFFF7F8F5);

TextStyle _body(Color c, double sz, FontWeight w, {double? ls, double? h}) =>
    TextStyle(color: c, fontSize: sz, fontWeight: w, letterSpacing: ls, height: h);

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AdminService _adminService = AdminService();
  int _currentIndex = 0;

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun Admin?'),
        content: const Text('Anda akan diarahkan kembali ke halaman login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showQuickActionModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text('Aksi Cepat Admin', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildQuickActionItem(
              icon: Icons.campaign_rounded,
              color: Colors.blue,
              title: 'Kirim Pengumuman Kampus',
              sub: 'Broadcast pesan notifikasi ke seluruh mahasiswa & driver',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Form Broadcast Pengumuman Kampus')),
                );
              },
            ),
            _buildQuickActionItem(
              icon: Icons.confirmation_number_rounded,
              color: Colors.orange,
              title: 'Buat Voucher Promo Baru',
              sub: 'Tambah kupon potongan tarif ojek/makanan',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Form Tambah Kupon Promo')),
                );
              },
            ),
            _buildQuickActionItem(
              icon: Icons.cloud_done_rounded,
              color: Colors.green,
              title: 'Cek Status Server & API',
              sub: 'Semua layanan operasional normal (Latency: 42ms)',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Status Sistem: 100% Online & Aktif')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required Color color,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kBgDark : kBgLight;
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF2A3518) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Current Page
          IndexedStack(
            index: _currentIndex,
            children: [
              _buildDashboardContent(context, isDark, bg, textColorPrimary, textColorSecondary, borderColor),
              const AdminDriversScreen(),
              const SizedBox(), // Spacer for center FAB
              const AdminOrdersScreen(),
              const AdminReportsScreen(),
            ],
          ),

          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 10),
              decoration: BoxDecoration(
                color: bg.withOpacity(0.96),
                border: Border(top: BorderSide(color: borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItem(Icons.grid_view_rounded, 'Beranda', _currentIndex == 0, () => setState(() => _currentIndex = 0)),
                  _navItem(Icons.two_wheeler_rounded, 'Driver', _currentIndex == 1, () => setState(() => _currentIndex = 1)),
                  // Center Action Button
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: GestureDetector(
                      onTap: _showQuickActionModal,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: kPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                          border: Border.all(color: bg, width: 3),
                        ),
                        child: const Icon(Icons.add, color: Colors.black, size: 28),
                      ),
                    ),
                  ),
                  _navItem(Icons.receipt_long_rounded, 'Pesanan', _currentIndex == 3, () => setState(() => _currentIndex = 3)),
                  _navItem(Icons.assignment_outlined, 'Laporan', _currentIndex == 4, () => setState(() => _currentIndex = 4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    bool isDark,
    Color bg,
    Color textColorPrimary,
    Color textColorSecondary,
    Color borderColor,
  ) {
    final cardBg = isDark ? const Color(0xFF1A1F0C) : Colors.white;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header with Logout ---
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
                          image: NetworkImage(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuAPL6NfzMDQDoi0D2I6FMc9wjPwwAvp7VAzLzuDdCe_xUJ-ggxzh1kZ0M2R7ypwt3R-v4daHBrFk-DaHoWUGVUmVW7H8CKIHWGfUq_Non9yUtY9ut6PF0VYBSdFT35h6GtvfXw1bWs4zUeGdtzgXs9HqAPM7qHve5iAXLBx5Is9dgHTMiQM79SKhM3FRnHB1naOZoAuNRHm1V6ljXIhBRvwG7E9M3IbKZhfgnc8MQ6R7TlVtngV7Td7uIr7tPRNcgxUGLWdQZfysmc',
                          ),
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
                Row(
                  children: [
                    // Notification Button
                    GestureDetector(
                      onTap: () => setState(() => _currentIndex = 4),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.notifications_outlined, color: textColorPrimary, size: 20),
                            Positioned(
                              top: 9,
                              right: 9,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: bg, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Logout Button
                    GestureDetector(
                      onTap: _handleLogout,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),

            // --- Stats Grid ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Statistik Utama', style: _body(textColorPrimary, 20, FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('Live Update', style: _body(kPrimary, 10, FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<Map<String, int>>(
              stream: _adminService.getDashboardStatsStream(),
              builder: (context, snapshot) {
                final stats = snapshot.data ?? {};
                final mhsCount = stats['totalMahasiswa'] ?? 0;
                final driverMhsCount = stats['driverMahasiswa'] ?? 0;
                final driverUmumCount = stats['driverUmum'] ?? 0;

                final mhsDisplay = mhsCount > 0 ? '$mhsCount' : '12.450';
                final driverMhsDisplay = driverMhsCount > 0 ? '$driverMhsCount' : '520';
                final driverUmumDisplay = driverUmumCount > 0 ? '$driverUmumCount' : '330';

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.15,
                  children: [
                    _buildStatCard('Total Mahasiswa', mhsDisplay, '+5.2%', Icons.school_rounded, Colors.blue, cardBg, textColorPrimary, textColorSecondary, borderColor),
                    _buildStatCard('Driver Mahasiswa', driverMhsDisplay, '+1.2%', Icons.moped_rounded, kPrimary, cardBg, textColorPrimary, textColorSecondary, borderColor),
                    _buildStatCard('Driver Umum', driverUmumDisplay, '+2.4%', Icons.person_rounded, Colors.amber, cardBg, textColorPrimary, textColorSecondary, borderColor),
                    _buildStatCard('Total Pendapatan', 'Rp 450jt', '+10%', Icons.payments_rounded, Colors.green, cardBg, textColorPrimary, textColorSecondary, borderColor),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // --- Weekly Stats Banner ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TRIP MINGGU INI', style: _body(Colors.black.withOpacity(0.6), 11, FontWeight.bold, ls: 0.5)),
                      const SizedBox(height: 4),
                      Text('8.900', style: _body(Colors.black, 34, FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text('Target Mingguan: 10.000 Trip', style: _body(Colors.black.withOpacity(0.7), 11, FontWeight.w600)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.trending_up_rounded, color: Colors.black, size: 30),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --- Activity Chart Mockup ---
            Text('Grafik Aktivitas', style: _body(textColorPrimary, 18, FontWeight.bold)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
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
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN']
                        .map((day) => Text(day, style: _body(textColorSecondary.withOpacity(0.5), 10, FontWeight.bold)))
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --- Admin Notifications / Action Center ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Perlu Tindakan', style: _body(textColorPrimary, 18, FontWeight.bold)),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DriverVerificationScreen()),
                    );
                  },
                  child: Text('Lihat Semua', style: _body(kPrimary, 12, FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _buildActionItem(
              title: 'Verifikasi Driver Mahasiswa',
              sub: '8 Pendaftar baru menanti review berkas',
              icon: Icons.how_to_reg_rounded,
              color: kPrimary,
              bg: cardBg,
              text: textColorPrimary,
              textSec: textColorSecondary,
              border: borderColor,
              onProcess: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverVerificationScreen(initialTab: 0)),
                );
              },
            ),
            _buildActionItem(
              title: 'Verifikasi Driver Umum',
              sub: '4 Pendaftar baru mitra luar kampus',
              icon: Icons.badge_outlined,
              color: Colors.amber,
              bg: cardBg,
              text: textColorPrimary,
              textSec: textColorSecondary,
              border: borderColor,
              onProcess: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverVerificationScreen(initialTab: 1)),
                );
              },
            ),
            _buildActionItem(
              title: 'Laporan User',
              sub: '5 Komplain belum ditindaklanjuti',
              icon: Icons.report_problem_rounded,
              color: Colors.red,
              bg: cardBg,
              text: textColorPrimary,
              textSec: textColorSecondary,
              border: borderColor,
              onProcess: () {
                setState(() => _currentIndex = 4);
              },
            ),
            _buildActionItem(
              title: 'Order Bermasalah',
              sub: '2 Order GPS terhenti > 15 menit',
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
              bg: cardBg,
              text: textColorPrimary,
              textSec: textColorSecondary,
              border: borderColor,
              onProcess: () {
                setState(() => _currentIndex = 3);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String percent, IconData icon, Color color, Color bg, Color text, Color textSec, Color border) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
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
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              Text(percent, style: _body(Colors.green, 10, FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Text(label, style: _body(textSec, 11, FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: _body(text, 20, FontWeight.bold, h: 1)),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required String title,
    required String sub,
    required IconData icon,
    required Color color,
    required Color bg,
    required Color text,
    required Color textSec,
    required Color border,
    required VoidCallback onProcess,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _body(text, 13, FontWeight.bold)),
                const SizedBox(height: 2),
                Text(sub, style: _body(textSec, 11, FontWeight.normal)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onProcess,
            style: ElevatedButton.styleFrom(
              backgroundColor: text,
              foregroundColor: bg,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Proses', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? kPrimary : Colors.grey, size: 22),
            const SizedBox(height: 4),
            Text(label, style: _body(active ? kPrimary : Colors.grey, 10, FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
