import 'dart:async';
import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kPrimaryDeep = Color(0xFF8DBF1A);
const Color kTextOnPrimary = Color(0xFF1D2210);
const Color kCardDark = Color(0xFF1C2414);
const Color kBorderDark = Color(0xFF2A3518);
const Color kBorderLight = Color(0xFFE5EAD7);

void showNearbyDriversModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _NearbyDriversSheet(),
  );
}

class _NearbyDriversSheet extends StatefulWidget {
  const _NearbyDriversSheet();

  @override
  State<_NearbyDriversSheet> createState() => _NearbyDriversSheetState();
}

class _NearbyDriversSheetState extends State<_NearbyDriversSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarCtrl;
  bool _isSearching = true;
  String _searchStatusText = 'Mendeteksi sinyal GPS kampus...';
  Timer? _statusTimer;
  Timer? _completeTimer;

  final List<Map<String, dynamic>> _drivers = [
    {
      'name': 'Budi Santoso',
      'role': 'Driver Mahasiswa • Teknik',
      'bike': 'Honda Vario 125',
      'plat': 'B 1234 GJK',
      'rating': '4.9',
      'trips': '142 trip',
      'dist': '250 m',
      'eta': '2 mnt',
      'color': const Color(0xFFC0F637),
    },
    {
      'name': 'Siti Aminah',
      'role': 'Driver Mahasiswa • FEB',
      'bike': 'Yamaha Fazzio',
      'plat': 'D 4567 KMP',
      'rating': '5.0',
      'trips': '98 trip',
      'dist': '480 m',
      'eta': '4 mnt',
      'color': const Color(0xFF54A0FF),
    },
    {
      'name': 'Rizky Pratama',
      'role': 'Driver Umum • Reguler',
      'bike': 'Honda Beat Street',
      'plat': 'B 9012 XYZ',
      'rating': '4.8',
      'trips': '310 trip',
      'dist': '750 m',
      'eta': '5 mnt',
      'color': const Color(0xFFFF9F43),
    },
    {
      'name': 'Andi Wijaya',
      'role': 'Driver Mahasiswa • Fasilkom',
      'bike': 'Scoopy Prestige',
      'plat': 'B 7788 ABC',
      'rating': '4.9',
      'trips': '185 trip',
      'dist': '1.1 km',
      'eta': '7 mnt',
      'color': const Color(0xFF1DD1A1),
    },
  ];

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _startSearchProcess();
  }

  void _startSearchProcess() {
    setState(() {
      _isSearching = true;
      _searchStatusText = 'Mendeteksi sinyal GPS kampus...';
    });

    _statusTimer?.cancel();
    _completeTimer?.cancel();

    _statusTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _searchStatusText = 'Memindai driver aktif di sekitar fakultas...';
        });
      }
    });

    _completeTimer = Timer(const Duration(milliseconds: 2300), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _statusTimer?.cancel();
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF141A0E) : Colors.white;
    final cardBg = isDark ? kCardDark : const Color(0xFFF9FAF6);
    final tp = isDark ? Colors.white : const Color(0xFF0F1A02);
    final ts = isDark ? const Color(0xFF8A9E70) : const Color(0xFF6B7A5A);
    final border = isDark ? kBorderDark : kBorderLight;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: border, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle pill
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.radar_rounded,
                          color: kPrimaryDeep, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Radar Driver Kampus',
                          style: TextStyle(
                            color: tp,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Area Universitas & Sekitar',
                          style: TextStyle(color: ts, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, color: tp, size: 18),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: border, height: 1),

          // Main Animated Body
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _isSearching
                  ? _buildRadarAnimation(tp, ts, isDark)
                  : _buildDriversList(tp, ts, cardBg, border, isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Radar Animation View (Searching State)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRadarAnimation(Color tp, Color ts, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Concentric Pulsing Radar
          SizedBox(
            width: 190,
            height: 190,
            child: AnimatedBuilder(
              animation: _radarCtrl,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Wave 3
                    _buildPulseRing(
                      scale: (_radarCtrl.value + 0.66) % 1.0,
                      maxSize: 190,
                    ),
                    // Wave 2
                    _buildPulseRing(
                      scale: (_radarCtrl.value + 0.33) % 1.0,
                      maxSize: 190,
                    ),
                    // Wave 1
                    _buildPulseRing(
                      scale: _radarCtrl.value,
                      maxSize: 190,
                    ),
                    // Center Glow
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withValues(alpha: 0.6),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.motorcycle_rounded,
                          color: kTextOnPrimary,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Sedang Mencari Driver Terdekat...',
            style: TextStyle(
              color: tp,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _searchStatusText,
              key: ValueKey(_searchStatusText),
              textAlign: TextAlign.center,
              style: TextStyle(color: ts, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: const LinearProgressIndicator(
                backgroundColor: Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPulseRing({required double scale, required double maxSize}) {
    final size = maxSize * scale;
    final opacity = (1.0 - scale).clamp(0.0, 1.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: kPrimary.withValues(alpha: opacity * 0.65),
          width: 2.2,
        ),
        color: kPrimary.withValues(alpha: opacity * 0.08),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Drivers List View (Found State)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDriversList(
      Color tp, Color ts, Color cardBg, Color border, bool isDark) {
    return ListView(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // Found Badge Summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: isDark ? 0.15 : 0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kPrimary.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: kPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: kTextOnPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ditemukan ${_drivers.length} Driver Sekitar Kampus!',
                      style: TextStyle(
                        color: tp,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Siap antar jemput langsung dari lokasimu',
                      style: TextStyle(color: ts, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Drivers Cards
        ..._drivers.map((d) => _buildDriverCard(d, tp, ts, cardBg, border, isDark)),

        const SizedBox(height: 16),

        // Rescan Button
        OutlinedButton.icon(
          onPressed: _startSearchProcess,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Pindai Ulang Radar Driver'),
          style: OutlinedButton.styleFrom(
            foregroundColor: tp,
            side: BorderSide(color: border),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> d, Color tp, Color ts,
      Color cardBg, Color border, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with green status badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF26321B) : const Color(0xFFEAF1DE),
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimary.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Center(
                  child: Icon(Icons.person_rounded,
                      color: isDark ? Colors.white70 : Colors.black54, size: 28),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ED573),
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBg, width: 2),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      d['name']!,
                      style: TextStyle(
                        color: tp,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '⚡ ${d['eta']}',
                        style: const TextStyle(
                          color: kPrimaryDeep,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  d['role']!,
                  style: TextStyle(color: ts, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.two_wheeler_rounded, size: 14, color: ts),
                    const SizedBox(width: 4),
                    Text(
                      '${d['bike']} • ${d['plat']}',
                      style: TextStyle(color: ts, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFA502)),
                    const SizedBox(width: 3),
                    Text(
                      '${d['rating']} (${d['trips']})',
                      style: TextStyle(
                        color: tp,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ts.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.location_on_rounded, size: 13, color: ts),
                    const SizedBox(width: 2),
                    Text(
                      '${d['dist']} dari lokasimu',
                      style: TextStyle(color: ts, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Order / Pilih Button
          InkWell(
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1D2210),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: kPrimary, width: 1),
                  ),
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: kPrimary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Driver ${d['name']} dipilih! Menghubungkan pesanan...',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'Pilih',
                style: TextStyle(
                  color: kTextOnPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
