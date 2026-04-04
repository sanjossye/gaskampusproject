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
    final textColorPrimary = isDark ? Colors.white : const Color.fromARGB(255, 96, 98, 104);
    final cardBg = isDark ? const Color(0xFF232A18) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('Admin Dashboard', style: _body(textColorPrimary, 20, FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.logout_rounded, color: textColorPrimary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCard(
              'Total Pendapatan',
              'Rp 2.450.000',
              Icons.payments_rounded,
              kPrimary,
              cardBg,
              textColorPrimary,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Order',
                    '142',
                    Icons.shopping_bag_rounded,
                    Colors.blueAccent,
                    cardBg,
                    textColorPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Driver Aktif',
                    '12',
                    Icons.motorcycle_rounded,
                    Colors.orangeAccent,
                    cardBg,
                    textColorPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Manajemen', style: _body(textColorPrimary, 18, FontWeight.bold)),
            const SizedBox(height: 16),
            _buildMenuItem(Icons.people_alt_rounded, 'Manajemen User', 'Kelola data mahasiswa', cardBg, textColorPrimary),
            _buildMenuItem(Icons.delivery_dining_rounded, 'Manajemen Driver', 'Kelola data driver & verifikasi', cardBg, textColorPrimary),
            _buildMenuItem(Icons.history_rounded, 'Riwayat Transaksi', 'Lihat semua riwayat order', cardBg, textColorPrimary),
            _buildMenuItem(Icons.settings_suggest_rounded, 'Pengaturan Sistem', 'Tarif, promo, & lainnya', cardBg, textColorPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(label, style: _body(text.withOpacity(0.6), 13, FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: _body(text, 22, FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String sub, Color bg, Color text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: kPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _body(text, 15, FontWeight.bold)),
                Text(sub, style: _body(text.withOpacity(0.5), 12, FontWeight.normal)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: text.withOpacity(0.3)),
        ],
      ),
    );
  }
}
