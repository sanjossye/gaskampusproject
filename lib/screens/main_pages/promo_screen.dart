import 'package:flutter/material.dart';

// ── Palette (Disamakan dengan home_screen) ──────────────────────────────────
const Color kPrimary       = Color(0xFFC0F637);
const Color kPrimaryDeep   = Color(0xFF8DBF1A);
const Color kBgDark        = Color(0xFF0E1009);
const Color kBgLight       = Color(0xFFF5F7F0);
const Color kCardDark      = Color(0xFF1C2414);
const Color kCardLight     = Color(0xFFFFFFFF);
const Color kBorderDark    = Color(0xFF2A3518);
const Color kBorderLight   = Color(0xFFE8EDE0);
const Color kTextOnPrimary = Color(0xFF0A0F02);

TextStyle _body(Color c, double sz, FontWeight w, {double? ls, double? h}) =>
    TextStyle(color: c, fontSize: sz, fontWeight: w, letterSpacing: ls, height: h);

class PromoScreen extends StatelessWidget {
  const PromoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? kBgDark : kBgLight;
    final tp     = isDark ? Colors.white : const Color(0xFF0F1A02);
    final ts     = isDark ? const Color(0xFF8A9E70) : const Color(0xFF6B7A5A);
    final border = isDark ? kBorderDark : kBorderLight;
    final card   = isDark ? kCardDark : kCardLight;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── 1. Header ──
        SliverToBoxAdapter(child: _buildHeader(tp, ts, border, card, isDark)),

        // ── 2. Tabs ──
        SliverToBoxAdapter(child: _buildTabs(tp, ts, border)),

        // ── 3. Hero Banner ──
        SliverToBoxAdapter(child: _buildHeroBanner()),

        // ── 4. Voucher Saya ──
        SliverToBoxAdapter(child: _buildSectionHead('Voucher Saya', '3 Tersedia', tp)),
        SliverToBoxAdapter(child: _buildVouchers(tp, ts, card, border, bg)),

        // ── 5. Promo Menarik ──
        SliverToBoxAdapter(child: _buildSectionHead('Promo Menarik Lainnya', null, tp)),
        SliverToBoxAdapter(child: _buildPromoGrid(tp, ts, card, border)),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  // 1. Header
  Widget _buildHeader(Color tp, Color ts, Color border, Color card, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: card,
              shape: BoxShape.circle,
              border: Border.all(color: border),
            ),
            child: Icon(Icons.arrow_back_rounded, color: tp, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Promo Mahasiswa', style: _body(tp, 16, FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Khusus Anak Kampus', style: _body(ts, 12, FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(Icons.school_rounded, color: kPrimary, size: 16),
                const SizedBox(width: 6),
                Text('Help', style: _body(tp, 12, FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Tabs
  Widget _buildTabs(Color tp, Color ts, Color border) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
      child: Row(
        children: [
          _TabItem('Voucher Saya', isActive: true, tp: tp, ts: ts),
          _TabItem('Promo Menarik', isActive: false, tp: tp, ts: ts),
          _TabItem('Riwayat', isActive: false, tp: tp, ts: ts),
        ],
      ),
    );
  }

  // 3. Hero Banner
  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: AspectRatio(
        aspectRatio: 21 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[800],
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1523240795612-9a054b0db644?q=80&w=1000&auto=format&fit=crop'), // Placeholder mahasiswa
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'LIMIT TERBATAS',
                    style: _body(kTextOnPrimary, 9, FontWeight.w900, ls: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pesta Makan\nKantin Hemat 60%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 4. Section Label
  Widget _buildSectionHead(String title, String? tag, Color tp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: _body(tp, 16, FontWeight.bold)),
          if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(tag, style: _body(kPrimary, 11, FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // 5. Vouchers List
  Widget _buildVouchers(Color tp, Color ts, Color card, Color border, Color bg) {
    final vouchers = [
      {'title': 'Diskon Makan 50%', 'desc': 'Min. belanja Rp20rb di GoFood', 'date': 'Hingga 24 Okt 2023', 'icon': Icons.restaurant_rounded, 'color': kPrimary, 'op': 1.0},
      {'title': 'Gratis Ongkir Antar Teman', 'desc': 'Khusus pengiriman area Kampus', 'date': 'Hingga 30 Okt 2023', 'icon': Icons.motorcycle_rounded, 'color': kPrimary.withOpacity(0.3), 'op': 1.0},
      {'title': 'Potongan GoRide Rp5rb', 'desc': 'Berlaku rute ke Fakultas', 'date': 'Hingga 22 Okt 2023', 'icon': Icons.pedal_bike_rounded, 'color': Colors.grey.withOpacity(0.2), 'op': 0.6},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: vouchers.map((v) => _buildVoucherCard(v, tp, ts, card, border, bg)).toList(),
      ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> v, Color tp, Color ts, Color card, Color border, Color bg) {
    return Opacity(
      opacity: v['op'],
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 100,
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            // Kiri: Block icon
            Container(
              width: 80,
              decoration: BoxDecoration(
                color: v['color'],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(v['icon'], size: 32, color: tp.withOpacity(0.8)),
                  // Efek titik/bolong pemisah voucher
                  Positioned(
                    right: -6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (i) => Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(vertical: 2), decoration: BoxDecoration(color: bg, shape: BoxShape.circle)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Kanan: Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v['title'], style: _body(tp, 13, FontWeight.bold), maxLines: 1),
                        const SizedBox(height: 2),
                        Text(v['desc'], style: _body(ts, 11, FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(v['date'], style: _body(ts.withOpacity(0.6), 9, FontWeight.w500)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(99)),
                          child: Text('Pakai', style: _body(kTextOnPrimary, 11, FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 6. Promo Menarik Grid
  Widget _buildPromoGrid(Color tp, Color ts, Color card, Color border) {
    final promos = [
      {'title': 'Kopi Pagi Hemat Rp10rb', 'tag': 'GOFOOD', 'img': 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=500&auto=format&fit=crop&q=60'},
      {'title': 'Rame-rame ke Mal Diskon 40%', 'tag': 'GOCAR', 'img': 'https://images.unsplash.com/photo-1543269865-cbf427effbad?w=500&auto=format&fit=crop&q=60'}
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: promos.map((p) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: p == promos.first ? 12 : 0),
            decoration: BoxDecoration(
              color: card,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(p['img']!, height: 90, width: double.infinity, fit: BoxFit.cover),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['tag']!, style: _body(kPrimaryDeep, 9, FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(p['title']!, style: _body(tp, 12, FontWeight.bold, h: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color tp;
  final Color ts;

  const _TabItem(this.label, {required this.isActive, required this.tp, required this.ts});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isActive ? kPrimary : Colors.transparent, width: 2)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: _body(isActive ? tp : ts, 13, isActive ? FontWeight.bold : FontWeight.w600),
        ),
      ),
    );
  }
}
