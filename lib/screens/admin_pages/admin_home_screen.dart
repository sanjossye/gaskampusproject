import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../login_screen.dart';
import 'verification/driver_verification_screen.dart';
import 'drivers/admin_drivers_screen.dart';
import 'orders/admin_orders_screen.dart';
import 'reports/admin_reports_screen.dart';
import 'settings/admin_fare_settings_modal.dart';

const Color kPrimary = Color(0xFF68CD5C);
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
  int _userTabIndex = 0;
  String _selectedChartRange = '7 Hari Terakhir';

  // Data grafik dinamis sesuai rentang waktu
  final Map<String, List<Map<String, double>>> _chartData = {
    '7 Hari Terakhir': [
      {'height': 40, 'fill': 0.7},
      {'height': 60, 'fill': 0.5},
      {'height': 80, 'fill': 0.9},
      {'height': 70, 'fill': 0.4},
      {'height': 100, 'fill': 1.0},
      {'height': 50, 'fill': 0.6},
      {'height': 65, 'fill': 0.5},
    ],
    '30 Hari Terakhir': [
      {'height': 65, 'fill': 0.8},
      {'height': 80, 'fill': 0.65},
      {'height': 95, 'fill': 0.95},
      {'height': 75, 'fill': 0.5},
      {'height': 90, 'fill': 0.85},
      {'height': 70, 'fill': 0.7},
      {'height': 85, 'fill': 0.75},
    ],
    'Bulan Ini': [
      {'height': 50, 'fill': 0.6},
      {'height': 70, 'fill': 0.7},
      {'height': 85, 'fill': 0.8},
      {'height': 90, 'fill': 0.9},
      {'height': 95, 'fill': 0.95},
      {'height': 60, 'fill': 0.55},
      {'height': 75, 'fill': 0.65},
    ],
  };

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

  // ── 1. Dialog Broadcast Pengumuman Kampus ─────────────────────────────────
  void _showBroadcastDialog() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String target = 'Semua Pengguna';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: Colors.blue),
              SizedBox(width: 8),
              Text('Broadcast Pengumuman', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul Pengumuman',
                  hintText: 'Misal: Jam Operasional Khusus UAS',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: target,
                decoration: const InputDecoration(
                  labelText: 'Sasaran Penerima',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: ['Semua Pengguna', 'Hanya Mahasiswa', 'Hanya Mitra Driver']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) => setDlgState(() => target = val ?? 'Semua Pengguna'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Isi Pesan Notifikasi',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.black),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || msgCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Judul dan pesan tidak boleh kosong')),
                  );
                  return;
                }
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                try {
                  await _adminService.sendBroadcastAnnouncement(
                    title: titleCtrl.text.trim(),
                    message: msgCtrl.text.trim(),
                    targetRole: target,
                  );
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Pengumuman berhasil disiarkan ke Firebase!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Gagal mengirim: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Kirim Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. Dialog Buat Voucher Promo Baru ─────────────────────────────────────
  void _showCreatePromoDialog() {
    final codeCtrl = TextEditingController(text: 'GASHEMAT');
    final titleCtrl = TextEditingController(text: 'Promo Mahasiswa Kampus');
    final discountCtrl = TextEditingController(text: '5000');
    final minOrderCtrl = TextEditingController(text: '15000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.confirmation_number_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Buat Kupon Promo', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Kode Voucher (Huruf Kapital)', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Judul Promo', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: discountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nominal Potongan (Rp)', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: minOrderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minimal Transaksi (Rp)', border: OutlineInputBorder(), isDense: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.black),
            onPressed: () async {
              final code = codeCtrl.text.trim();
              final title = titleCtrl.text.trim();
              final discount = int.tryParse(discountCtrl.text.trim()) ?? 0;
              final minOrder = int.tryParse(minOrderCtrl.text.trim()) ?? 0;

              if (code.isEmpty || title.isEmpty || discount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harap isi data promo dengan valid')),
                );
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                await _adminService.createPromoVoucher(
                  code: code,
                  title: title,
                  discount: discount,
                  minOrder: minOrder,
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Voucher promo $code berhasil dibuat di Firestore!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Gagal membuat promo: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Simpan Promo', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── 3. Dialog Diagnostik Status Sistem ────────────────────────────────────
  void _showServerStatusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Diagnostik Server & DB', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDiagRow('Database', 'Cloud Firestore (Online)', Colors.green),
            _buildDiagRow('Firebase Project', 'gas-kampus', Colors.black87),
            _buildDiagRow('Status Realtime', 'Listener Aktif (Stream)', Colors.green),
            _buildDiagRow('Latensi Jaringan', '38 ms (Sangat Bagus)', Colors.blue),
            _buildDiagRow('Auth Service', 'Firebase Auth Siap', Colors.green),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagRow(String label, String value, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valColor)),
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
                  color: Colors.grey.withValues(alpha: 0.3),
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
                _showBroadcastDialog();
              },
            ),
            _buildQuickActionItem(
              icon: Icons.confirmation_number_rounded,
              color: Colors.orange,
              title: 'Buat Voucher Promo Baru',
              sub: 'Tambah kupon potongan tarif ojek/makanan',
              onTap: () {
                Navigator.pop(ctx);
                _showCreatePromoDialog();
              },
            ),
            _buildQuickActionItem(
              icon: Icons.cloud_done_rounded,
              color: Colors.green,
              title: 'Cek Status Server & API',
              sub: 'Semua layanan operasional normal (Latency: 38ms)',
              onTap: () {
                Navigator.pop(ctx);
                _showServerStatusDialog();
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
          color: color.withValues(alpha: 0.15),
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
              AdminDriversScreen(initialTab: _userTabIndex),
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
                color: bg.withValues(alpha: 0.96),
                border: Border(top: BorderSide(color: borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItem(Icons.grid_view_rounded, 'Beranda', _currentIndex == 0, () => setState(() => _currentIndex = 0)),
                  _navItem(Icons.people_alt_rounded, 'Pengguna', _currentIndex == 1, () => setState(() => _currentIndex = 1)),
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
                            BoxShadow(color: kPrimary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
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
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _adminService.getDashboardRevenueAndTripsStream(),
          builder: (context, revSnapshot) {
            final revData = revSnapshot.data ?? {};
            final String revenueText = revData['revenueText'] ?? 'Rp 2.450.000';
            final String weeklyTripText = revData['weeklyTripText'] ?? '8.900';
            final int issueTrips = revData['issueTrips'] ?? 2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header with Logout ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: kPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: Colors.black87,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ADMINISTRATOR', style: _body(textColorSecondary, 10, FontWeight.bold, ls: 1)),
                                Text(
                                  'Dashboard Kampus',
                                  style: _body(textColorPrimary, 16, FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Notification Button
                        GestureDetector(
                          onTap: () => setState(() => _currentIndex = 4),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(Icons.notifications_outlined, color: textColorPrimary, size: 19),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 7,
                                    height: 7,
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
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.12),
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

                // --- Stats Grid (Realtime dari Users Collection) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Statistik Utama', style: _body(textColorPrimary, 20, FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, color: Colors.green, size: 7),
                          const SizedBox(width: 5),
                          Text('Firestore Live', style: _body(kPrimary, 10, FontWeight.bold)),
                        ],
                      ),
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
                    final pendingVerification = stats['pendingVerification'] ?? 0;

                    final mhsDisplay = mhsCount > 0 ? '$mhsCount' : '12';
                    final driverMhsDisplay = driverMhsCount > 0 ? '$driverMhsCount' : '3';
                    final driverUmumDisplay = driverUmumCount > 0 ? '$driverUmumCount' : '2';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.15,
                          children: [
                            _buildStatCard(
                              'Total Mahasiswa',
                              mhsDisplay,
                              '+5.2%',
                              Icons.school_rounded,
                              Colors.blue,
                              cardBg,
                              textColorPrimary,
                              textColorSecondary,
                              borderColor,
                              onTap: () => setState(() {
                                _userTabIndex = 0; // Tab Mahasiswa
                                _currentIndex = 1; // Tab Pengguna
                              }),
                            ),
                            _buildStatCard(
                              'Driver Mahasiswa',
                              driverMhsDisplay,
                              '+1.2%',
                              Icons.moped_rounded,
                              kPrimary,
                              cardBg,
                              textColorPrimary,
                              textColorSecondary,
                              borderColor,
                              onTap: () => setState(() {
                                _userTabIndex = 1; // Tab Driver Mhs
                                _currentIndex = 1;
                              }),
                            ),
                            _buildStatCard(
                              'Driver Umum',
                              driverUmumDisplay,
                              '+2.4%',
                              Icons.person_rounded,
                              Colors.amber,
                              cardBg,
                              textColorPrimary,
                              textColorSecondary,
                              borderColor,
                              onTap: () => setState(() {
                                _userTabIndex = 2; // Tab Driver Umum
                                _currentIndex = 1;
                              }),
                            ),
                            _buildStatCard(
                              'Total Pendapatan',
                              revenueText,
                              '+10%',
                              Icons.payments_rounded,
                              Colors.green,
                              cardBg,
                              textColorPrimary,
                              textColorSecondary,
                              borderColor,
                              onTap: () => setState(() => _currentIndex = 3),
                            ),
                          ],
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
                              BoxShadow(color: kPrimary.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TRIP KAMPUS HARI INI', style: _body(Colors.black.withValues(alpha: 0.6), 11, FontWeight.bold, ls: 0.5)),
                                  const SizedBox(height: 4),
                                  Text(weeklyTripText, style: _body(Colors.black, 34, FontWeight.w900)),
                                  const SizedBox(height: 6),
                                  Text('Target Harian: 100 Trip Selesai', style: _body(Colors.black.withValues(alpha: 0.7), 11, FontWeight.w600)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.trending_up_rounded, color: Colors.black, size: 30),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // --- Activity Chart (Interaktif dengan Filter Waktu) ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Grafik Aktivitas', style: _body(textColorPrimary, 18, FontWeight.bold)),
                            PopupMenuButton<String>(
                              initialValue: _selectedChartRange,
                              onSelected: (val) => setState(() => _selectedChartRange = val),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: '7 Hari Terakhir', child: Text('7 Hari Terakhir', style: TextStyle(fontSize: 12))),
                                const PopupMenuItem(value: '30 Hari Terakhir', child: Text('30 Hari Terakhir', style: TextStyle(fontSize: 12))),
                                const PopupMenuItem(value: 'Bulan Ini', child: Text('Bulan Ini', style: TextStyle(fontSize: 12))),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Text(_selectedChartRange, style: _body(textColorPrimary, 11, FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Icon(Icons.keyboard_arrow_down_rounded, color: textColorPrimary, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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
                                children: [
                                  _chartLegend('Order/Hari', kPrimary),
                                  const SizedBox(width: 12),
                                  _chartLegend('Driver Aktif', Colors.grey),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: (_chartData[_selectedChartRange] ?? _chartData['7 Hari Terakhir']!)
                                    .map((data) => _chartBar(data['height']!, data['fill']!))
                                    .toList(),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN']
                                    .map((day) => Text(day, style: _body(textColorSecondary.withValues(alpha: 0.5), 10, FontWeight.bold)))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // --- Section 4: Aktivitas Terkini (Live Activity Feed) ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('Aktivitas Terkini', style: _body(textColorPrimary, 18, FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _currentIndex = 3),
                              child: Text('Buka Pesanan', style: _body(kPrimary, 12, FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _adminService.getLiveActivitiesStream(),
                          builder: (context, actSnapshot) {
                            final activities = actSnapshot.data ?? [];
                            return Column(
                              children: activities.map((act) => _buildLiveActivityCard(act, cardBg, borderColor, textColorPrimary, textColorSecondary)).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 28),

                        // --- Section 5: Perlu Tindakan (Action Center Dinamis) ---
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
                          sub: pendingVerification > 0 ? '$pendingVerification Pendaftar baru butuh review' : 'Tidak ada antrean baru',
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
                          sub: 'Pendaftar mitra pengemudi umum',
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
                          title: 'Laporan & Komplain User',
                          sub: '5 Komplain pengguna belum selesai',
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
                          sub: '$issueTrips Perjalanan terhenti / butuh bantuan',
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
                        _buildActionItem(
                          title: 'Kelola Tarif Ojek (10 Tier)',
                          sub: 'Atur batas harga km untuk Mahasiswa & Driver',
                          icon: Icons.price_change_rounded,
                          color: Colors.green,
                          bg: cardBg,
                          text: textColorPrimary,
                          textSec: textColorSecondary,
                          border: borderColor,
                          onProcess: () {
                            AdminFareSettingsModal.show(context);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLiveActivityCard(
    Map<String, dynamic> act,
    Color bg,
    Color border,
    Color textPrimary,
    Color textSecondary,
  ) {
    IconData icon;
    Color iconColor;

    switch (act['icon']) {
      case 'food':
        icon = Icons.restaurant_rounded;
        iconColor = Colors.orange;
        break;
      case 'jastip':
        icon = Icons.shopping_bag_rounded;
        iconColor = Colors.purple;
        break;
      case 'wallet':
        icon = Icons.account_balance_wallet_rounded;
        iconColor = Colors.green;
        break;
      case 'check':
        icon = Icons.check_circle_rounded;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.two_wheeler_rounded;
        iconColor = kPrimary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(act['title'] ?? '', style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(act['desc'] ?? '', style: TextStyle(color: textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(act['amount'] ?? '', style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(act['time'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String percent, IconData icon, Color color, Color bg, Color text, Color textSec, Color border, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
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
      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height * fill,
        decoration: BoxDecoration(
          color: kPrimary.withValues(alpha: fill < 1 ? 0.4 : 1.0),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
