import 'package:flutter/material.dart';
import '../login_screen.dart';
import 'topup_modal.dart';
import 'favorite_drivers_screen.dart';
import 'settings_screen.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const Color kPrimary       = Color(0xFFC0F637);
const Color kPrimaryDeep   = Color(0xFF8DBF1A);
const Color kBgDark        = Color(0xFF1D2210);
const Color kBgLight       = Color(0xFFF7F8F5);
const Color kCardDark      = Color(0xFF1C2414);
const Color kCardLight     = Color(0xFFFFFFFF);
const Color kBorderDark    = Color(0xFF2A3518);
const Color kBorderLight   = Color(0xFFE8EDE0);
const Color kTextOnPrimary = Color(0xFF0A0F02);

TextStyle _body(Color c, double sz, FontWeight w, {double? ls, double? h}) =>
    TextStyle(color: c, fontSize: sz, fontWeight: w, letterSpacing: ls, height: h);

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPromo;
  const ProfileScreen({super.key, this.onNavigateToPromo});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _profileImage =
      'https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80';

  final List<Map<String, String>> _avatarPresets = [
    {
      'name': 'Ahmad (Default)',
      'url':
          'https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Casual Tech',
      'url':
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Mahasiswi FEB',
      'url':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Aktivis Kampus',
      'url':
          'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Kreatif Desain',
      'url':
          'https://images.unsplash.com/photo-1580489944761-15a19d654956?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Jaket Almamater',
      'url':
          'https://images.unsplash.com/photo-1628157582853-a796fa650a6a?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80',
    },
  ];

  void _showChangePhotoModal(BuildContext context, Color bg, Color tp, Color ts,
      Color cardBg, Color border) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: border, width: 1.5)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Pill
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ubah Foto Profil',
                        style: _body(tp, 18, FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pilih avatar mahasiswa atau masukkan foto baru',
                        style: _body(ts, 12, FontWeight.w500),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, color: tp, size: 18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Text(
                'PILIH AVATAR MAHASISWA',
                style: _body(kPrimaryDeep, 11, FontWeight.bold, ls: 1.0),
              ),
              const SizedBox(height: 12),

              // Avatars Grid / Row
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _avatarPresets.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final item = _avatarPresets[i];
                    final isSelected = _profileImage == item['url'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _profileImage = item['url']!;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF1D2210),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: kPrimary),
                            ),
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: kPrimary, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Foto profil diganti ke "${item['name']}"!',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? kPrimary : border,
                                    width: isSelected ? 3 : 1.5,
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(item['url']!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: kPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        color: kTextOnPrimary, size: 14),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['name']!,
                            style: _body(
                              isSelected ? kPrimaryDeep : ts,
                              10,
                              isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              Divider(color: border, height: 1),
              const SizedBox(height: 16),

              // Option 1: Unggah dari Galeri
              _buildPhotoActionTile(
                icon: Icons.photo_library_rounded,
                title: 'Pilih dari Galeri Foto',
                subtitle: 'Gunakan foto dari galeri perangkat',
                color: const Color(0xFF54A0FF),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _profileImage =
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF1D2210),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: kPrimary),
                      ),
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: kPrimary, size: 20),
                          const SizedBox(width: 10),
                          const Text('Foto baru dari galeri berhasil dipasang!',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                },
                tp: tp,
                ts: ts,
                cardBg: cardBg,
                border: border,
              ),

              const SizedBox(height: 10),

              // Option 2: Masukkan Link URL
              _buildPhotoActionTile(
                icon: Icons.link_rounded,
                title: 'Gunakan Link URL Foto',
                subtitle: 'Tempel link gambar dari web',
                color: kPrimaryDeep,
                onTap: () {
                  Navigator.pop(ctx);
                  _showUrlInputDialog(context, tp, ts, bg, border);
                },
                tp: tp,
                ts: ts,
                cardBg: cardBg,
                border: border,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUrlInputDialog(
      BuildContext context, Color tp, Color ts, Color bg, Color border) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
        title: Text('Masukkan Link URL Foto',
            style: _body(tp, 16, FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paste URL gambar (JPG/PNG) profil kamu:',
                style: _body(ts, 12, FontWeight.normal)),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              style: TextStyle(color: tp, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://...',
                hintStyle: TextStyle(color: ts.withValues(alpha: 0.6)),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kPrimary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Batal', style: _body(ts, 13, FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () {
              final url = textController.text.trim();
              if (url.isNotEmpty) {
                setState(() {
                  _profileImage = url;
                });
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF1D2210),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: kPrimary),
                    ),
                    content: const Text(
                      'Foto profil berhasil diperbarui dari URL!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: kTextOnPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Simpan Foto',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required Color tp,
    required Color ts,
    required Color cardBg,
    required Color border,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _body(tp, 13, FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: _body(ts, 11, FontWeight.w400)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: ts.withValues(alpha: 0.6), size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF0F172A) : Colors.white;
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

          // ── 2. Profile Info (Dengan Tombol Pensil Aktif) ──
          SliverToBoxAdapter(
              child: _buildProfileInfo(tp, ts, bg, cardBg, border)),

          // ── 3. Stats Grid ──
          SliverToBoxAdapter(child: _buildStatsGrid(tp, ts)),

          // ── 4. Menu List ──
          SliverToBoxAdapter(
              child: _buildMenuList(
                  context, tp, ts, cardBg, cardHover, border)),

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
              const Icon(Icons.school_rounded, color: kPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'GasKampus',
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
  Widget _buildProfileInfo(
      Color tp, Color ts, Color bg, Color cardBg, Color border) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar + Interactive Edit Pencil Button
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Foto Profil (Bisa diklik juga)
              GestureDetector(
                onTap: () => _showChangePhotoModal(
                    context, bg, tp, ts, cardBg, border),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: kPrimary.withValues(alpha: 0.35), width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(_profileImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Tombol Pensil (Hak Ubah Foto Profil)
              Positioned(
                bottom: 2,
                right: 2,
                child: Tooltip(
                  message: 'Ubah Foto Profil',
                  child: InkWell(
                    onTap: () => _showChangePhotoModal(
                        context, bg, tp, ts, cardBg, border),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: bg, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.black87,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name & NIM
          Text('Ahmad Zaki', style: _body(tp, 24, FontWeight.bold, ls: -0.5)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('MAHASISWA',
                    style: _body(kPrimaryDeep, 10, FontWeight.bold, ls: 0.5)),
              ),
              const SizedBox(width: 8),
              Text('NIM 12345678', style: _body(ts, 15, FontWeight.w500)),
            ],
          ),
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

  Widget _buildStatCard(String label, String value, Color tp, Color ts,
      {IconData? icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kPrimary.withValues(alpha: 0.1),
          border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
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
  Widget _buildMenuList(BuildContext context, Color tp, Color ts, Color bg,
      Color hover, Color border) {
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
        'badge': '4',
        'onTap': widget.onNavigateToPromo,
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
        'title': 'Pusat Bantuan Kampus',
        'subtitle': null,
        'badge': null,
      },
      {
        'icon': Icons.settings_rounded,
        'title': 'Pengaturan Akun',
        'subtitle': 'Mode Gelap, Data Mahasiswa, Keamanan',
        'badge': null,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children:
            menus.map((m) => _buildMenuItem(m, tp, ts, bg, border)).toList(),
      ),
    );
  }

  Widget _buildMenuItem(
      Map<String, dynamic> item, Color tp, Color ts, Color bg, Color border) {
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
                    color: kPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(item['icon'] as IconData, color: kPrimaryDeep, size: 20),
                ),
                const SizedBox(width: 16),
                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'] as String,
                          style: _body(tp, 15, FontWeight.w600)),
                      if (item['subtitle'] != null) ...[
                        const SizedBox(height: 3),
                        Text(item['subtitle'] as String,
                            style: _body(ts, 12, FontWeight.normal)),
                      ]
                    ],
                  ),
                ),
                // Badge
                if (item['badge'] != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                Icon(Icons.chevron_right_rounded,
                    color: ts.withValues(alpha: 0.5)),
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
