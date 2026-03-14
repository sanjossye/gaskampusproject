import 'package:flutter/material.dart';
import '../login_screen.dart';
import 'topup_modal.dart';
import 'favorite_drivers_screen.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const Color kPrimary       = Color(0xFFC0F637);
const Color kBgDark        = Color(0xFF1D2210); // Atau 0xFF0E1009 dari home
const Color kBgLight       = Color(0xFFF7F8F5);
const Color kCardDark      = Color(0xFF1C2414);
const Color kCardLight     = Color(0xFFFFFFFF);
const Color kBorderDark    = Color(0xFF2A3518);
const Color kBorderLight   = Color(0xFFE8EDE0);
const Color kTextOnPrimary = Color(0xFF0A0F02);

TextStyle _body(Color c, double sz, FontWeight w, {double? ls, double? h}) =>
    TextStyle(color: c, fontSize: sz, fontWeight: w, letterSpacing: ls, height: h);

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onNavigateToPromo;
  const ProfileScreen({super.key, this.onNavigateToPromo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Menggunakan warna background yang lebih sesuai dengan HTML (bg-white / dark:bg-slate-900 di HTML asli)
    // Di aplikasi ini kita selaraskan dengan palet utama:
    final bg     = isDark ? const Color(0xFF0F172A) : Colors.white; // Mengikuti slate-900 / white dari HTML
    final tp     = isDark ? Colors.white : const Color(0xFF0F172A);
    final ts     = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final border = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardHover = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. Header ──
          SliverToBoxAdapter(child: _buildHeader(tp, bg, border, isDark)),
          
          // ── 2. Profile Info ──
          SliverToBoxAdapter(child: _buildProfileInfo(tp, ts, bg)),
          
          // ── 3. Stats Grid ──
          SliverToBoxAdapter(child: _buildStatsGrid(tp, ts)),
          
          // ── 4. Menu List ──
          SliverToBoxAdapter(child: _buildMenuList(context, tp, ts, cardBg, cardHover, border)),
          
          // ── 5. Logout Button ──
          SliverToBoxAdapter(child: _buildLogoutButton(context, isDark)),
          
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // 1. Header
  Widget _buildHeader(Color tp, Color bg, Color border, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.arrow_back_rounded, color: tp, size: 24),
          Row(
            children: [
              Icon(Icons.school_rounded, color: kPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Gojek Kampus',
                style: _body(tp, 18, FontWeight.bold, ls: -0.5),
              ),
            ],
          ),
          Icon(Icons.more_vert_rounded, color: tp, size: 24),
        ],
      ),
    );
  }

  // 2. Profile Info
  Widget _buildProfileInfo(Color tp, Color ts, Color bg) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar + Edit Icon
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimary.withOpacity(0.2), width: 4),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: bg, width: 2),
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.black87, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name & NIM
          Text('Ahmad Zaki', style: _body(tp, 24, FontWeight.bold, ls: -0.5)),
          const SizedBox(height: 4),
          Text('NIM 12345678', style: _body(ts, 16, FontWeight.w500)),
        ],
      ),
    );
  }

  // 3. Stats Grid
  Widget _buildStatsGrid(Color tp, Color ts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard('PERJALANAN', '24', tp, ts),
          const SizedBox(width: 12),
          _buildStatCard('RATING', '4.9', tp, ts, icon: Icons.star_rounded),
          const SizedBox(width: 12),
          _buildStatCard('HEMAT', '150k', tp, ts),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color tp, Color ts, {IconData? icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.1),
          border: Border.all(color: kPrimary.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(label, style: _body(ts, 10, FontWeight.w600, ls: 1.0)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: kPrimary, size: 16),
                  const SizedBox(width: 4),
                ],
                Text(value, style: _body(tp, 20, FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 4. Menu List
  Widget _buildMenuList(BuildContext context, Color tp, Color ts, Color bg, Color hover, Color border) {
    final menus = [
      {
        'icon': Icons.account_balance_wallet_rounded,
        'title': 'Dompet & Top Up',
        'subtitle': 'Saldo: Rp 75.000',
        'badge': null,
        'onTap': () => showTopUpModal(context),
      },
      {
        'icon': Icons.confirmation_number_rounded,
        'title': 'Voucher Saya',
        'subtitle': null,
        'badge': '3',
        'onTap': onNavigateToPromo,
      },
      {
        'icon': Icons.favorite_rounded,
        'title': 'Driver Favorit',
        'subtitle': null,
        'badge': null,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FavoriteDriversScreen()),
        ),
      },
      {
        'icon': Icons.help_center_rounded,
        'title': 'Pusat Bantuan',
        'subtitle': null,
        'badge': null,
      },
      {
        'icon': Icons.settings_rounded,
        'title': 'Pengaturan',
        'subtitle': null,
        'badge': null,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: menus.map((m) => _buildMenuItem(m, tp, ts, bg, border)).toList(),
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item, Color tp, Color ts, Color bg, Color border) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: item['onTap'] as VoidCallback? ?? () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item['icon'] as IconData, color: kPrimary, size: 20),
                ),
                const SizedBox(width: 16),
                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'] as String, style: _body(tp, 16, FontWeight.w600)),
                      if (item['subtitle'] != null) ...[
                        const SizedBox(height: 4),
                        Text(item['subtitle'] as String, style: _body(ts, 12, FontWeight.normal)),
                      ]
                    ],
                  ),
                ),
                // Badge
                if (item['badge'] != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[500],
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      item['badge'] as String,
                      style: _body(Colors.white, 10, FontWeight.bold),
                    ),
                  ),
                // Arrow
                Icon(Icons.chevron_right_rounded, color: ts.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 5. Logout Button
  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red[500]!, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: Colors.red[500], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Keluar',
                  style: _body(Colors.red[500]!, 16, FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
