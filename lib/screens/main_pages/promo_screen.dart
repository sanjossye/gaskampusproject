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

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  int _selectedTab = 0; // 0: Voucher Saya, 1: Promo Menarik, 2: Riwayat
  String _promoFilter = 'Semua';

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

        // ── 2. Tabs Interaktif ──
        SliverToBoxAdapter(child: _buildTabs(tp, ts, border)),

        // ── 3. Content Berdasarkan Tab Terpilih ──
        if (_selectedTab == 0) ...[
          // TAB 0: VOUCHER SAYA
          SliverToBoxAdapter(child: _buildHeroBanner()),
          SliverToBoxAdapter(child: _buildSectionHead('Voucher Tersedia', '4 Siap Pakai', tp)),
          SliverToBoxAdapter(child: _buildVouchers(tp, ts, card, border, bg)),
        ] else if (_selectedTab == 1) ...[
          // TAB 1: PROMO MENARIK MAHASISWA
          SliverToBoxAdapter(child: _buildPromoFilterPills(tp, ts, card, border)),
          SliverToBoxAdapter(child: _buildPromoMenarikContent(tp, ts, card, border, isDark)),
        ] else ...[
          // TAB 2: RIWAYAT PENGGUNAAN & KEDALUWARSA
          SliverToBoxAdapter(child: _buildSavingsSummaryCard(card, border, isDark)),
          SliverToBoxAdapter(child: _buildSectionHead('Riwayat Pemakaian', '5 Catatan', tp)),
          SliverToBoxAdapter(child: _buildRiwayatList(tp, ts, card, border, isDark)),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 36)),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Header
  // ─────────────────────────────────────────────────────────────────────────
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
            child: Icon(Icons.percent_rounded, color: kPrimaryDeep, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Promo Mahasiswa', style: _body(tp, 17, FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Hemat Transportasi & Jajan Kampus', style: _body(ts, 12, FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: kPrimaryDeep, size: 16),
                const SizedBox(width: 6),
                Text('GasKam', style: _body(kPrimaryDeep, 12, FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Tabs
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTabs(Color tp, Color ts, Color border) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
      child: Row(
        children: [
          _buildTabItem(0, 'Voucher Saya', tp, ts),
          _buildTabItem(1, 'Promo Menarik', tp, ts),
          _buildTabItem(2, 'Riwayat', tp, ts),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, Color tp, Color ts) {
    final bool isActive = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.only(bottom: 14, top: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? kPrimary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: _body(
              isActive ? tp : ts,
              13,
              isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 0: Voucher Saya
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: AspectRatio(
        aspectRatio: 21 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E2D0D), Color(0xFF0F1A05)],
            ),
            border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.discount_rounded,
                  size: 130,
                  color: kPrimary.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
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
                        'EDISI BULAN INI',
                        style: _body(kTextOnPrimary, 9, FontWeight.w900, ls: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pesta Makan Kantin\nDiskon s/d 60%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Khusus pembayaran pakai GasPay',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHead(String title, String? tag, Color tp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: _body(tp, 15, FontWeight.bold)),
          if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(tag, style: _body(kPrimaryDeep, 11, FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildVouchers(Color tp, Color ts, Color card, Color border, Color bg) {
    final vouchers = [
      {
        'title': 'Diskon Mahasiswa Baru 50%',
        'desc': 'Min. order Rp10rb untuk semua rute antar kampus',
        'date': 'Hingga 30 Nov 2026',
        'code': 'MABAGAS',
        'icon': Icons.motorcycle_rounded,
        'badge': 'ANTAR',
      },
      {
        'title': 'Gratis Ongkir Kantin Kampus',
        'desc': 'Khusus pesanan makan dari kantin fakultas',
        'date': 'Hingga 15 Des 2026',
        'code': 'MAKANHEMAT',
        'icon': Icons.restaurant_rounded,
        'badge': 'MAKAN',
      },
      {
        'title': 'Cashback 30% Koin GasPay',
        'desc': 'Maksimal Rp10.000 untuk top-up dan bayar ojek',
        'date': 'Hingga 25 Nov 2026',
        'code': 'GASPAYSERU',
        'icon': Icons.account_balance_wallet_rounded,
        'badge': 'DOMPET',
      },
      {
        'title': 'Potongan Jastip ATK & Print Rp5.000',
        'desc': 'Fotokopi, print tugas, dan jastip modul kelas',
        'date': 'Hingga 10 Des 2026',
        'code': 'JASTIPATK',
        'icon': Icons.shopping_bag_rounded,
        'badge': 'TITIP',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: vouchers.map((v) => _buildVoucherCard(v, tp, ts, card, border)).toList(),
      ),
    );
  }

  Widget _buildVoucherCard(
      Map<String, dynamic> v, Color tp, Color ts, Color card, Color border) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(v['icon'] as IconData, color: kPrimaryDeep, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          v['badge'] as String,
                          style: _body(kPrimaryDeep, 9, FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kode: ${v['code']}',
                        style: _body(ts, 10, FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    v['title'] as String,
                    style: _body(tp, 13, FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    v['desc'] as String,
                    style: _body(ts, 11, FontWeight.w400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    v['date'] as String,
                    style: _body(ts.withValues(alpha: 0.7), 10, FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF1D2210),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: kPrimary),
                    ),
                    content: Text(
                      'Voucher "${v['title']}" berhasil dipasang!',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(99),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('Pakai', style: _body(kTextOnPrimary, 11, FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 1: Promo Menarik (Isi Lengkap Promo Kampus)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPromoFilterPills(Color tp, Color ts, Color card, Color border) {
    final filters = ['Semua', 'Antar Kampus', 'Kantin Makan', 'Jastip ATK', 'GasPay'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map((f) {
            final isSel = _promoFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f),
                selected: isSel,
                onSelected: (val) {
                  if (val) setState(() => _promoFilter = f);
                },
                selectedColor: kPrimary,
                backgroundColor: card,
                side: BorderSide(color: isSel ? kPrimary : border),
                labelStyle: TextStyle(
                  color: isSel ? kTextOnPrimary : tp,
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPromoMenarikContent(
      Color tp, Color ts, Color card, Color border, bool isDark) {
    final promoList = [
      {
        'title': 'Paket Minggu Ujian (UTS & UAS)',
        'subtitle': 'Naik Ojek Kampus 5x Gratis 1x Perjalanan!',
        'desc': 'Berlaku rute dari halte/asrama ke seluruh gedung ujian fakultas.',
        'tag': 'EVENT KAMPUS',
        'icon': Icons.menu_book_rounded,
        'badgeColor': const Color(0xFFC0F637),
        'textColor': kTextOnPrimary,
        'valid': 'Berlaku selama periode ujian',
      },
      {
        'title': 'Flash Sale Makan Siang Kantin',
        'subtitle': 'Potongan Rp8.000 Jam 11:30 - 13:30',
        'desc': 'Khusus pemesanan menu kantin saat jam istirahat kuliah.',
        'tag': 'KANTIN MAKAN',
        'icon': Icons.lunch_dining_rounded,
        'badgeColor': const Color(0xFFFF9F43),
        'textColor': Colors.white,
        'valid': 'Setiap Senin s/d Jumat',
      },
      {
        'title': 'Boncengan Bareng Teman Se-Fakultas',
        'subtitle': 'Hemat Rp3.000 Bareng Driver Mahasiswa',
        'desc': 'Pilih driver mahasiswa satu fakultas untuk tarif lebih ramah kantong.',
        'tag': 'RIDE SHARING',
        'icon': Icons.people_alt_rounded,
        'badgeColor': const Color(0xFF54A0FF),
        'textColor': Colors.white,
        'valid': 'Berlaku setiap hari kuliah',
      },
      {
        'title': 'Rabu GasPay: Cashback 40%',
        'subtitle': 'Dapatkan Koin Kampus s/d 10.000 Koin',
        'desc': 'Top up & transaksi apapun di hari Rabu dapat koin berlimpah.',
        'tag': 'GASPAY',
        'icon': Icons.savings_rounded,
        'badgeColor': const Color(0xFF1DD1A1),
        'textColor': Colors.white,
        'valid': 'Setiap hari Rabu',
      },
      {
        'title': 'Jastip Fotokopi & Beli Buku Bebas Antre',
        'subtitle': 'Biaya Jasa Cuma Rp3.000!',
        'desc': 'Driver mahasiswa siap belikan dan antar modul langsung ke mejamu.',
        'tag': 'JASTIP ATK',
        'icon': Icons.print_rounded,
        'badgeColor': const Color(0xFFA55EEA),
        'textColor': Colors.white,
        'valid': 'Buka 08:00 - 17:00 WIB',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: promoList.map((p) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (p['badgeColor'] as Color).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p['tag'] as String,
                          style: TextStyle(
                            color: isDark ? (p['badgeColor'] as Color) : Colors.black87,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: ts),
                          const SizedBox(width: 4),
                          Text(p['valid'] as String, style: _body(ts, 11, FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: (p['badgeColor'] as Color).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(p['icon'] as IconData,
                            color: isDark ? (p['badgeColor'] as Color) : Colors.black87,
                            size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['title'] as String,
                              style: _body(tp, 14, FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              p['subtitle'] as String,
                              style: _body(kPrimaryDeep, 12, FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p['desc'] as String,
                              style: _body(ts, 11, FontWeight.w400, h: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: border, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Syarat & Ketentuan Berlaku',
                          style: _body(ts.withValues(alpha: 0.7), 10, FontWeight.w400)),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF1D2210),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: kPrimary),
                              ),
                              content: Text(
                                'Promo "${p['title']}" berhasil diklaim!',
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              Text('Klaim Promo',
                                  style: _body(kPrimaryDeep, 12, FontWeight.bold)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 14, color: kPrimaryDeep),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 2: Riwayat (Isi Lengkap Riwayat Promo & Penghematan Mahasiswa)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSavingsSummaryCard(Color card, Color border, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1C2712), const Color(0xFF141C0A)]
              : [const Color(0xFFF2F8E8), const Color(0xFFFFFFFF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Penghematan Kampus', style: _body(kPrimaryDeep, 12, FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Semester Ini',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kPrimaryDeep)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Rp 148.000',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kamu berhasil menghemat biaya kuliah & mobilitas dari 12 kali promo!',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatList(
      Color tp, Color ts, Color card, Color border, bool isDark) {
    final historyList = [
      {
        'title': 'Diskon 40% Antar Pagi Kuliah',
        'cat': 'Goride Kampus',
        'date': 'Kemarin, 08:15 WIB',
        'saved': '-Rp 6.000',
        'status': 'Terpakai',
        'isUsed': true,
        'note': 'Rute: Asrama Mahasiswa ➔ Gedung Kuliah Bersama',
      },
      {
        'title': 'Gratis Ongkir Kantin Pusat',
        'cat': 'Campus Food',
        'date': '24 Okt 2026, 12:40 WIB',
        'saved': '-Rp 8.000',
        'status': 'Terpakai',
        'isUsed': true,
        'note': 'Warung Ayam Geprek Sambal Matah',
      },
      {
        'title': 'Cashback GasPay Rp10.000',
        'cat': 'Top Up Dompet',
        'date': '21 Okt 2026, 17:05 WIB',
        'saved': '+10.000 Koin',
        'status': 'Terpakai',
        'isUsed': true,
        'note': 'Reward top-up saldo bulanan mahasiswa',
      },
      {
        'title': 'Diskon Belajar Malam Rp5.000',
        'cat': 'Goride Perpustakaan',
        'date': 'Kedaluwarsa 19 Okt 2026',
        'saved': 'Rp 0',
        'status': 'Kedaluwarsa',
        'isUsed': false,
        'note': 'Tidak sempat digunakan sebelum batas waktu',
      },
      {
        'title': 'Potongan Jastip Modul Rp5.000',
        'cat': 'Titip ATK & Print',
        'date': '15 Okt 2026, 10:20 WIB',
        'saved': '-Rp 5.000',
        'status': 'Terpakai',
        'isUsed': true,
        'note': 'Fotokopi modul praktikum Lab Komputer',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: historyList.map((h) {
          final isUsed = h['isUsed'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isUsed ? Icons.check_circle_rounded : Icons.schedule_rounded,
                          size: 16,
                          color: isUsed ? const Color(0xFF2ED573) : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          h['cat'] as String,
                          style: _body(ts, 11, FontWeight.w600),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isUsed
                            ? const Color(0xFF2ED573).withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        h['status'] as String,
                        style: TextStyle(
                          color: isUsed ? const Color(0xFF2ED573) : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h['title'] as String,
                            style: _body(tp, 13, FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            h['note'] as String,
                            style: _body(ts, 11, FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      h['saved'] as String,
                      style: TextStyle(
                        color: isUsed ? kPrimaryDeep : Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  h['date'] as String,
                  style: _body(ts.withValues(alpha: 0.6), 10, FontWeight.w500),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
