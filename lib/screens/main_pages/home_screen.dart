import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'promo_screen.dart';
import 'pesanan_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const Color kPrimary       = Color(0xFFC0F637);
const Color kPrimaryDeep   = Color(0xFF8DBF1A);
const Color kBgDark        = Color(0xFF0E1009);
const Color kBgLight       = Color(0xFFF5F7F0);
const Color kSurfaceDark   = Color(0xFF181E10);
const Color kCardDark      = Color(0xFF1C2414);
const Color kCardLight     = Color(0xFFFFFFFF);
const Color kBorderDark    = Color(0xFF2A3518);
const Color kBorderLight   = Color(0xFFE8EDE0);
const Color kTextOnPrimary = Color(0xFF0A0F02);

// ── Typography Helpers ─────────────────────────────────────────────────────
TextStyle _display(Color c, double sz, FontWeight w, {double? ls}) =>
    TextStyle(color: c, fontSize: sz, fontWeight: w, letterSpacing: ls, fontFamily: 'serif');

TextStyle _body(Color c, double sz, FontWeight w, {double? ls, double? h}) =>
    TextStyle(color: c, fontSize: sz, fontWeight: w, letterSpacing: ls, height: h);

// ══════════════════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Hapus 'surface' & 'card' yang tidak terpakai ──
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? kBgDark     : kBgLight;
    final border = isDark ? kBorderDark : kBorderLight;
    final tp     = isDark ? Colors.white           : const Color(0xFF0F1A02);
    final ts     = isDark ? const Color(0xFF8A9E70) : const Color(0xFF6B7A5A);

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      backgroundColor: bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: _buildBodyContent(tp, ts, isDark, border),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Body Router
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBodyContent(Color tp, Color ts, bool isDark, Color border) {
    if (_navIndex == 1) return const PromoScreen();
    if (_navIndex == 2) return const PesananScreen();
    if (_navIndex == 3) return const ChatScreen();
    if (_navIndex == 4) return const ProfileScreen();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(tp, ts, isDark)),
        SliverToBoxAdapter(child: _buildWalletCard()),
        SliverToBoxAdapter(child: _buildSearchBar(ts, border, isDark)),
        SliverToBoxAdapter(child: _buildSectionLabel('Layanan', tp, ts)),
        SliverToBoxAdapter(child: _buildServiceGrid(tp, isDark)),
        SliverToBoxAdapter(child: _buildMapCard()),
        SliverToBoxAdapter(child: _buildSectionLabel('Promo Untukmu', tp, ts)),
        SliverToBoxAdapter(child: _buildPromoBanner()),
        SliverToBoxAdapter(child: _buildSectionLabel('Driver Aktif', tp, ts, action: 'Lihat Semua')),
        SliverToBoxAdapter(child: _buildDriversRow(tp, ts, isDark)),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Header
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(Color tp, Color ts, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: kPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded,
                color: kTextOnPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat pagi 👋',
                    style: _body(ts, 12, FontWeight.w500, ls: 0.2)),
                const SizedBox(height: 2),
                Text('Ahmad Zaki', style: _body(tp, 16, FontWeight.bold)),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildIconBtn(Icons.notifications_outlined, tp, isDark),
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? kBgDark : kBgLight,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? kCardDark : kCardLight,
        shape: BoxShape.circle,
        border: Border.all(color: isDark ? kBorderDark : kBorderLight),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Wallet Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWalletCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kTextOnPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: kTextOnPrimary.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded,
                        size: 13, color: kTextOnPrimary.withOpacity(0.65)),
                    const SizedBox(width: 4),
                    Text(
                      'GoPay Campus',
                      style: _body(kTextOnPrimary.withOpacity(0.65), 11,
                          FontWeight.w700, ls: 0.4),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _buildWalletAction(Icons.add_rounded),
              const SizedBox(width: 8),
              _buildWalletAction(Icons.history_rounded),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo',
                        style: _body(kTextOnPrimary.withOpacity(0.55), 11,
                            FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text('Rp 50.000',
                        style: _display(kTextOnPrimary, 26, FontWeight.w800)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('GoCoin',
                      style: _body(kTextOnPrimary.withOpacity(0.55), 11,
                          FontWeight.w500)),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.toll_rounded,
                          size: 15, color: kTextOnPrimary.withOpacity(0.75)),
                      const SizedBox(width: 4),
                      Text('2.500',
                          style: _body(kTextOnPrimary, 17, FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletAction(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: kTextOnPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: kTextOnPrimary, size: 17),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Search Bar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar(Color ts, Color border, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? kCardDark : kCardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, color: ts, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Mau ke mana hari ini?',
                  style: _body(ts, 13, FontWeight.w400)),
            ),
            Container(
              margin: const EdgeInsets.all(6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(99),
              ),
              child:
                  Text('Cari', style: _body(kTextOnPrimary, 12, FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Section Label
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String title, Color tp, Color ts,
      {String? action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: _body(tp, 15, FontWeight.bold)),
          if (action != null)
            Text(action, style: _body(kPrimaryDeep, 13, FontWeight.w600)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Service Grid  –– responsif dengan LayoutBuilder
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildServiceGrid(Color tp, bool isDark) {
    final services = [
      _ServiceItem('Antar',   Icons.motorcycle_rounded,   kPrimary,                kTextOnPrimary),
      _ServiceItem('Makan',   Icons.restaurant_rounded,   const Color(0xFFFF9F43), Colors.white),
      _ServiceItem('Beliin',  Icons.shopping_bag_rounded, const Color(0xFF54A0FF), Colors.white),
      _ServiceItem('Laundry', Icons.dry_cleaning_rounded, const Color(0xFFD980FA), Colors.white),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemW = (constraints.maxWidth - 12 * 3) / 4;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: services
                .map((s) => _buildServiceItem(s, tp, isDark, itemW))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildServiceItem(
      _ServiceItem s, Color tp, bool isDark, double itemW) {
    final boxSz  = (itemW * 0.72).clamp(44.0, 60.0);
    final iconBg = boxSz * 0.65;
    final iconSz = boxSz * 0.36;

    return SizedBox(
      width: itemW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: boxSz,
            height: boxSz,
            decoration: BoxDecoration(
              color: isDark ? kCardDark : kCardLight,
              borderRadius: BorderRadius.circular(boxSz * 0.30),
              border: Border.all(
                  color: isDark ? kBorderDark : kBorderLight),
            ),
            child: Center(
              child: Container(
                width: iconBg,
                height: iconBg,
                decoration: BoxDecoration(
                  color: s.bg,
                  borderRadius: BorderRadius.circular(iconBg * 0.30),
                ),
                child: Icon(s.icon, color: s.iconColor, size: iconSz),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            s.label,
            style: _body(tp, 11, FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. Map Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMapCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2E0A), Color(0xFF0D1A05)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                      color: kPrimary, shape: BoxShape.circle),
                  child: const Icon(Icons.location_on_rounded,
                      color: kTextOnPrimary, size: 20),
                ),
                const SizedBox(height: 10),
                Text('Lihat Driver Terdekat',
                    style: _body(Colors.white, 14, FontWeight.bold)),
                const SizedBox(height: 3),
                Text('3 driver aktif di sekitarmu',
                    style: _body(Colors.white54, 12, FontWeight.w400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 7. Promo Banner
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: kTextOnPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('PROMO KAMPUS',
                      style:
                          _body(kTextOnPrimary, 10, FontWeight.w800, ls: 1.1)),
                ),
                const SizedBox(height: 8),
                Text('Diskon 50%',
                    style: _display(kTextOnPrimary, 22, FontWeight.w900)),
                const SizedBox(height: 5),
                Text(
                  'Makan siang hemat\ndi kantin favoritmu!',
                  style: _body(kTextOnPrimary.withOpacity(0.6), 12,
                      FontWeight.w500, h: 1.5),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: kTextOnPrimary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('Klaim Sekarang',
                      style: _body(kPrimary, 12, FontWeight.bold)),
                ),
              ],
            ),
          ),
          // Dekorasi angka — dibatasi SizedBox agar tidak overflow
          SizedBox(
            width: 70,
            child: Text(
              '50',
              textAlign: TextAlign.center,
              style: _display(
                  kTextOnPrimary.withOpacity(0.08), 72, FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 8. Driver Row
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDriversRow(Color tp, Color ts, bool isDark) {
    final drivers = [
      {'name': 'Budi S.',  'rating': '4.9', 'dist': '1 km'},
      {'name': 'Andi W.',  'rating': '4.8', 'dist': '2 km'},
      {'name': 'Rizky P.', 'rating': '5.0', 'dist': '500 m'},
    ];

    return SizedBox(
      height: 136,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: drivers.length,
        itemBuilder: (ctx, i) {
          final d = drivers[i];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? kCardDark : kCardLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isDark ? kBorderDark : kBorderLight),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? kBorderDark
                            : const Color(0xFFEDF2E5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_rounded,
                          color: isDark ? Colors.white38 : Colors.black26,
                          size: 22),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ED573),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? kCardDark : kCardLight,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  d['name']!,
                  style: _body(tp, 12, FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, size: 12, color: kPrimaryDeep),
                    const SizedBox(width: 3),
                    Text(d['rating']!,
                        style: _body(ts, 11, FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(d['dist']!,
                    style: _body(ts, 11, FontWeight.w400),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom Nav  –– LayoutBuilder: label hanya muncul jika layar ≥ 360px
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomNav(bool isDark) {
    final bg = isDark ? kSurfaceDark : kCardLight;

    const items = [
      _NavItem(Icons.home_rounded,          Icons.home_outlined,               'Beranda'),
      _NavItem(Icons.local_offer_rounded,   Icons.local_offer_outlined,        'Promo'),
      _NavItem(Icons.receipt_long_rounded,  Icons.receipt_long_outlined,       'Pesanan'),
      _NavItem(Icons.chat_bubble_rounded,   Icons.chat_bubble_outline_rounded,  'Chat'),
      _NavItem(Icons.person_rounded,        Icons.person_outline_rounded,       'Profil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
            top: BorderSide(color: isDark ? kBorderDark : kBorderLight)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showLabel = constraints.maxWidth >= 360;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final sel  = i == _navIndex;
                  final item = items[i];

                  return GestureDetector(
                    onTap: () => setState(() => _navIndex = i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.symmetric(
                        horizontal: sel && showLabel ? 14 : 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? kPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            sel ? item.activeIcon : item.inactiveIcon,
                            color: sel
                                ? kTextOnPrimary
                                : (isDark ? Colors.white38 : Colors.black38),
                            size: 22,
                          ),
                          if (sel && showLabel) ...[
                            const SizedBox(width: 6),
                            Text(item.label,
                                style:
                                    _body(kTextOnPrimary, 12, FontWeight.bold)),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Data Models ───────────────────────────────────────────────────────────────
class _ServiceItem {
  final String   label;
  final IconData icon;
  final Color    bg;
  final Color    iconColor;
  const _ServiceItem(this.label, this.icon, this.bg, this.iconColor);
}

class _NavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String   label;
  const _NavItem(this.activeIcon, this.inactiveIcon, this.label);
}

// ── Dot Grid Painter (map texture) ───────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()
      ..color     = Colors.white.withOpacity(0.06)
      ..strokeCap = StrokeCap.round;
    const step = 22.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5, dot);
      }
    }
    final road = Paint()
      ..color       = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.5
      ..style       = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * 0.2, 0),
        Offset(size.width * 0.35, size.height), road);
    canvas.drawLine(Offset(size.width * 0.6, 0),
        Offset(size.width * 0.75, size.height), road);
    canvas.drawLine(Offset(0, size.height * 0.4),
        Offset(size.width, size.height * 0.55), road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}