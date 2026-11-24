import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../../services/map_route_service.dart';
import '../../widgets/gas_faces.dart';
import 'package:gas_kampusapp/services/zone_service.dart';
import 'promo_screen.dart';
import 'pesanan_screen.dart' as pesanan;
import 'profile_screen.dart';
import 'topup_modal.dart';
import 'nearby_drivers_modal.dart';
import 'service_order_screen.dart';
import 'food_merchants_screen.dart';
import 'jadwal_kuliah_screen.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const Color kPrimary = Color(0xFFC0F637);
const Color kPrimaryDeep = Color(0xFF8DBF1A);
const Color kBgDark = Color(0xFF0E1009);
const Color kBgLight = Color(0xFFF5F7F0);
const Color kSurfaceDark = Color(0xFF181E10);
const Color kCardDark = Color(0xFF1C2414);
const Color kCardLight = Color(0xFFFFFFFF);
const Color kBorderDark = Color(0xFF2A3518);
const Color kBorderLight = Color(0xFFE8EDE0);
const Color kTextOnPrimary = Color(0xFF0A0F02);

// ── Typography Helpers ─────────────────────────────────────────────────────
TextStyle _display(Color c, double sz, FontWeight w, {double? ls}) => TextStyle(
  color: c,
  fontSize: sz,
  fontWeight: w,
  letterSpacing: ls,
  fontFamily: 'serif',
);

TextStyle _body(Color c, double sz, FontWeight w, {double? ls, double? h}) =>
    TextStyle(
      color: c,
      fontSize: sz,
      fontWeight: w,
      letterSpacing: ls,
      height: h,
    );

// ══════════════════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _navIndex = 0;

  /// Sinyal untuk membuka tab Riwayat Pesanan dari Beranda.
  int _historySignal = 0;

  /// Sinyal untuk membuka Halaman Pesanan (Antar) dari Beranda.
  int _orderSignal = 0;

  /// Tujuan yang dipilih otomatis (mis. dari Jadwal Kuliah atau Radar).
  String? _presetDestination;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final AnimationController _gpsPulseCtrl;

  String _userName = 'Mahasiswa';
  String _userFaculty = 'Kampus USU Medan';
  String _userPhotoUrl = '';
  int _walletBalance = 0;
  int _coinBalance = 0;

  // Live GPS State untuk Mahasiswa (tetap meminta lokasi real perangkat)
  LatLng _studentGps =
      MapRouteService.lastKnownDriverGps?.position ??
      MapRouteService.defaultKampusCenter;
  bool _isRealGps =
      MapRouteService.lastKnownDriverGps?.isRealDeviceGps ?? false;
  StreamSubscription<DriverGpsResult>? _gpsStreamSub;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return 'Selamat Pagi 👋';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang ☀️';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore 🌤️';
    } else {
      return 'Selamat Malam 🌙';
    }
  }

  String _formatCurrency(int val) {
    return val.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
            if (doc.exists && mounted) {
              final data = doc.data();
              if (data != null) {
                setState(() {
                  if (data['name'] != null &&
                      (data['name'] as String).isNotEmpty) {
                    _userName = data['name'] as String;
                  }
                  if (data['facultas'] != null &&
                      (data['facultas'] as String).isNotEmpty) {
                    _userFaculty = facultyDisplayName(data['facultas'] as String);
                  }
                  _userPhotoUrl = (data['photoUrl'] ?? '').toString().trim();
                });
              }
            }
          });

      FirebaseFirestore.instance
          .collection('wallets')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
            if (mounted) {
              final data = doc.data();
              setState(() {
                _walletBalance = (data?['balance'] as num?)?.toInt() ?? 0;
                _coinBalance = (data?['coins'] as num?)?.toInt() ?? 0;
              });
            }
          });
    }
  }

  Future<void> _initStudentGps() async {
    final gps = await MapRouteService.getCurrentDriverPosition(
      campusFallback: MapRouteService.defaultKampusCenter,
    );
    if (!mounted) return;
    setState(() {
      _studentGps = gps.position;
      _isRealGps = gps.isRealDeviceGps;
    });

    _gpsStreamSub?.cancel();
    _gpsStreamSub = MapRouteService.watchDriverPosition().listen((liveGps) {
      if (!mounted) return;
      setState(() {
        _studentGps = liveGps.position;
        _isRealGps = liveGps.isRealDeviceGps;
      });
    });
  }

  void _openOrderWithDestination(String destination) {
    setState(() {
      _presetDestination = destination;
      _navIndex = 2;
      _orderSignal++;
    });
  }

  void _openJadwalKuliahScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JadwalKuliahScreen(
          onOrderRideToClass: (dest) => _openOrderWithDestination(dest),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initStudentGps();
    SessionOrderStore.purgeOlderThanOneMonthDatabase();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _gpsPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _gpsStreamSub?.cancel();
    _gpsPulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kBgDark : kBgLight;
    final border = isDark ? kBorderDark : kBorderLight;
    final tp = isDark ? Colors.white : const Color(0xFF0F1A02);
    final ts = isDark ? const Color(0xFF8A9E70) : const Color(0xFF6B7A5A);

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      backgroundColor: bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(child: _buildBodyContent(tp, ts, isDark, border)),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Body Router
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBodyContent(Color tp, Color ts, bool isDark, Color border) {
    if (_navIndex == 1) return const PromoScreen();
    if (_navIndex == 2) {
      return pesanan.PesananScreen(
        openHistorySignal: _historySignal,
        openOrderSignal: _orderSignal,
        initialDestination: _presetDestination,
        onBackToHome: () => setState(() => _navIndex = 0),
      );
    }
    if (_navIndex == 3) {
      return ProfileScreen(
        onNavigateToPromo: () {
          setState(() {
            _navIndex = 1;
          });
        },
        onOpenJadwalKuliah: _openJadwalKuliahScreen,
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(tp, ts, isDark)),
        SliverToBoxAdapter(child: _buildWalletCard()),
        SliverToBoxAdapter(child: _buildSectionLabel('Promo Untukmu', tp, ts)),
        SliverToBoxAdapter(child: _buildPromoBanner()),
        SliverToBoxAdapter(child: _buildSearchBar(ts, border, isDark)),
        SliverToBoxAdapter(child: _buildSectionLabel('Layanan', tp, ts)),
        SliverToBoxAdapter(child: _buildServiceGrid(tp, isDark)),
        SliverToBoxAdapter(
          child: MahasiswaScheduleSection(
            onOrderRideToClass: _openOrderWithDestination,
            onOpenFullSchedule: _openJadwalKuliahScreen,
          ),
        ),
        SliverToBoxAdapter(
          child: _buildSectionLabel(
            'Radar Driver Kampus (Driver Aktif)',
            tp,
            ts,
            action: 'Buka Radar',
            onActionTap: () => showNearbyDriversModal(
              context,
              onOrderWithDriver: (drv) {
                _openOrderWithDestination(
                  (drv['locationName'] as String?) ?? 'Gedung Biro Rektor USU',
                );
              },
            ),
          ),
        ),
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
          GestureDetector(
            onTap: () => setState(() => _navIndex = 3),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
              ),
              child: GasProfileImage(photoUrl: _userPhotoUrl, size: 44),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()} • $_userFaculty',
                  style: _body(ts, 11.5, FontWeight.w500, ls: 0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(_userName, style: _body(tp, 16, FontWeight.bold)),
              ],
            ),
          ),
          _buildGpsStatusIndicator(isDark),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _openJadwalKuliahScreen,
            child: Tooltip(
              message: 'Jadwal Kuliah Saya',
              child: _buildIconBtn(
                Icons.calendar_month_rounded,
                kPrimaryDeep,
                isDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: AppNotificationStore.version,
            builder: (context, _, _) {
              final unread = AppNotificationStore.unreadCount;
              return GestureDetector(
                onTap: () => _showNotificationsSheet(
                  context,
                  tp,
                  ts,
                  isDark,
                  isDark ? kBorderDark : kBorderLight,
                ),
                child: Tooltip(
                  message: 'Notifikasi',
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildIconBtn(Icons.notifications_outlined, tp, isDark),
                      if (unread > 0)
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
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showNotificationsSheet(
    BuildContext context,
    Color tp,
    Color ts,
    bool isDark,
    Color border,
  ) {
    AppNotificationStore.markAllAsRead();
    final sheetBg = isDark ? kCardDark : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            final list = AppNotificationStore.items;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.72,
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(ctx).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifikasi',
                        style: _body(tp, 18, FontWeight.bold),
                      ),
                      if (list.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            AppNotificationStore.clearAll();
                            setSheet(() {});
                          },
                          child: Text(
                            'Hapus Semua',
                            style: _body(
                              Colors.redAccent,
                              12.5,
                              FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: border, height: 1),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 42),
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 46,
                            color: ts.withValues(alpha: 0.45),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Belum ada notifikasi',
                            style: _body(ts, 14, FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(top: 12),
                        itemCount: list.length,
                        separatorBuilder: (_, _) =>
                            Divider(color: border, height: 20),
                        itemBuilder: (_, i) {
                          final item = list[i];
                          final hh = item.createdAt.hour
                              .toString()
                              .padLeft(2, '0');
                          final mm = item.createdAt.minute
                              .toString()
                              .padLeft(2, '0');
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(item.icon, color: item.color, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: _body(
                                              tp,
                                              13.5,
                                              FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '$hh:$mm',
                                          style: _body(
                                            ts,
                                            11,
                                            FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.message,
                                      style: _body(
                                        ts,
                                        12.5,
                                        FontWeight.normal,
                                        h: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGpsStatusIndicator(bool isDark) {
    final Color activeColor = _isRealGps
        ? const Color(0xFF22C55E)
        : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: _initStudentGps,
      child: Tooltip(
        message: _isRealGps
            ? 'GPS Aktif (${_studentGps.latitude.toStringAsFixed(4)}, ${_studentGps.longitude.toStringAsFixed(4)})'
            : 'GPS Belum Aktif (Ketuk untuk meminta izin lokasi)',
        child: SizedBox(
          width: 34,
          height: 34,
          child: AnimatedBuilder(
            animation: _gpsPulseCtrl,
            builder: (context, _) {
              final double t = _gpsPulseCtrl.value;
              final double pulseSize = 12 + (18 * t);
              final double pulseOpacity = (1.0 - t) * (_isRealGps ? 0.55 : 0.30);
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: pulseSize,
                    height: pulseSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeColor.withValues(alpha: pulseOpacity),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(
                            alpha: _isRealGps ? 0.5 : 0.25,
                          ),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: kTextOnPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: kTextOnPrimary.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 13,
                      color: kTextOnPrimary.withOpacity(0.65),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'GasPay Campus',
                      style: _body(
                        kTextOnPrimary.withOpacity(0.65),
                        11,
                        FontWeight.w700,
                        ls: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _buildWalletAction(
                Icons.add_rounded,
                onTap: () => showTopUpModal(context),
              ),
              const SizedBox(width: 8),
              _buildWalletAction(
                Icons.history_rounded,
                onTap: () => setState(() {
                  _navIndex = 2;
                  _historySignal++;
                }),
              ),
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
                    Text(
                      'Saldo',
                      style: _body(
                        kTextOnPrimary.withOpacity(0.55),
                        11,
                        FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Rp ${_formatCurrency(_walletBalance)}',
                      style: _display(kTextOnPrimary, 26, FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'GasCoin',
                    style: _body(
                      kTextOnPrimary.withOpacity(0.55),
                      11,
                      FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.toll_rounded,
                        size: 15,
                        color: kTextOnPrimary.withOpacity(0.75),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCurrency(_coinBalance),
                        style: _body(kTextOnPrimary, 17, FontWeight.bold),
                      ),
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

  Widget _buildWalletAction(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kTextOnPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: kTextOnPrimary, size: 17),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Search Bar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar(Color ts, Color border, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: GestureDetector(
        onTap: () => setState(() {
          _presetDestination = null;
          _navIndex = 2;
          _orderSignal++;
        }),
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
                child: Text(
                  'Mau ke fakultas atau mana hari ini?',
                  style: _body(ts, 13, FontWeight.w400),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Cari',
                  style: _body(kTextOnPrimary, 12, FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Section Label
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(
    String title,
    Color tp,
    Color ts, {
    String? action,
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: _body(tp, 15, FontWeight.bold)),
          if (action != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  action,
                  style: _body(kPrimaryDeep, 13, FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Service Grid  –– Antar, Makan, Titip, Jadwal Kuliah
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildServiceGrid(Color tp, bool isDark) {
    final services = [
      _ServiceItem(
        'Antar',
        Icons.motorcycle_rounded,
        kPrimary,
        kTextOnPrimary,
        onTap: () => setState(() {
          _presetDestination = null;
          _navIndex = 2;
          _orderSignal++;
        }),
      ),
      _ServiceItem(
        'Makan',
        Icons.restaurant_rounded,
        const Color(0xFFFF9F43),
        Colors.white,
        onTap: _openFoodMerchants,
      ),
      _ServiceItem(
        'Titip',
        Icons.shopping_bag_rounded,
        const Color(0xFF54A0FF),
        Colors.white,
        onTap: () => _openServiceOrder('titip'),
      ),
      _ServiceItem(
        'Jadwal',
        Icons.calendar_month_rounded,
        const Color(0xFFA78BFA),
        Colors.white,
        onTap: _openJadwalKuliahScreen,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemW =
              (constraints.maxWidth - 12 * (services.length - 1)) /
              services.length;
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

  /// Buka daftar Merchant Toko Makanan (banner, alamat, menu), lalu arahkan ke Riwayat jika pesan.
  Future<void> _openFoodMerchants() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FoodMerchantsScreen()),
    );
    if (result == true && mounted) {
      setState(() {
        _navIndex = 2;
        _historySignal++;
      });
    }
  }

  /// Buka formulir Makan / Titip, lalu arahkan ke halaman Pesanan (riwayat).
  Future<void> _openServiceOrder(String type) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ServiceOrderScreen(serviceType: type)),
    );
    if (result == true && mounted) {
      setState(() {
        _navIndex = 2;
        _historySignal++;
      });
    }
  }

  Widget _buildServiceItem(
    _ServiceItem s,
    Color tp,
    bool isDark,
    double itemW,
  ) {
    final boxSz = (itemW * 0.64).clamp(44.0, 56.0);
    final iconSz = boxSz * 0.48;

    return GestureDetector(
      onTap: s.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: itemW,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: boxSz,
              height: boxSz,
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius: BorderRadius.circular(boxSz * 0.32),
              ),
              child: Icon(s.icon, color: s.iconColor, size: iconSz),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kTextOnPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PROMO KAMPUS',
                    style: _body(kTextOnPrimary, 10, FontWeight.w800, ls: 1.1),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Diskon 50%',
                  style: _display(kTextOnPrimary, 22, FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  'Makan siang hemat\ndi kantin favoritmu!',
                  style: _body(
                    kTextOnPrimary.withOpacity(0.6),
                    12,
                    FontWeight.w500,
                    h: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => setState(() => _navIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: kTextOnPrimary,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Klaim Sekarang',
                      style: _body(kPrimary, 12, FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '50',
              textAlign: TextAlign.center,
              style: _display(
                kTextOnPrimary.withOpacity(0.08),
                72,
                FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 8. Driver Row (Terintegrasi Estimasi Jarak GPS Real-Time)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDriversRow(Color tp, Color ts, bool isDark) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['driver_kampus', 'driver_umum'])
          .where('isOnline', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final landmarkPool = [
          'Fakultas Teknik USU',
          'Biro Rektor USU',
          'Perpustakaan Pusat USU',
          'Pintu 1 USU',
          'Vokasi USU',
        ];

        List<Map<String, String>> drivers = [];

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          int idx = 0;
          drivers = snapshot.data!.docs.map((doc) {
            final data = doc.data();
            final fullName = (data['name'] as String? ?? 'Driver').trim();
            final parts = fullName.split(' ');
            final shortName = parts.length > 1
                ? '${parts[0]} ${parts[1][0]}.'
                : parts[0];
            final ratingVal = (data['rating'] as num?)?.toDouble() ?? 5.0;
            final landmark = landmarkPool[idx % landmarkPool.length];
            final metrics = MapRouteService.estimateMetricsFromDevice(
              _studentGps,
              landmark,
            );
            final km = (metrics['distanceKm'] as double).toStringAsFixed(1);
            final eta = metrics['etaMinutes'] as int;
            idx++;

            return {
              'name': shortName,
              'rating': ratingVal.toStringAsFixed(1),
              'dist': '$km km (~$eta mnt)',
              'landmark': landmark,
            };
          }).toList();
        } else {
          drivers = List.generate(3, (i) {
            final names = ['Budi S.', 'Siti A.', 'Agus P.'];
            final ratings = ['4.9', '5.0', '4.8'];
            final landmark = landmarkPool[i % landmarkPool.length];
            final metrics = MapRouteService.estimateMetricsFromDevice(
              _studentGps,
              landmark,
            );
            final km = (metrics['distanceKm'] as double).toStringAsFixed(1);
            final eta = metrics['etaMinutes'] as int;
            return {
              'name': names[i],
              'rating': ratings[i],
              'dist': '$km km (~$eta mnt)',
              'landmark': landmark,
            };
          });
        }

        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: drivers.length,
            itemBuilder: (ctx, i) {
              final d = drivers[i];
              return GestureDetector(
                onTap: () => _openOrderWithDestination(d['landmark']!),
                child: Container(
                  width: 128,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? kCardDark : kCardLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? kBorderDark : kBorderLight,
                    ),
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
                            child: Icon(
                              Icons.two_wheeler_rounded,
                              color: isDark ? kPrimary : kPrimaryDeep,
                              size: 22,
                            ),
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
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: kPrimaryDeep,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            d['rating']!,
                            style: _body(ts, 11, FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        d['dist']!,
                        style: _body(ts, 10.5, FontWeight.w500),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom Nav
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomNav(bool isDark) {
    final bg = isDark ? kSurfaceDark : kCardLight;

    const items = [
      _NavItem(Icons.home_rounded, Icons.home_outlined, 'Beranda'),
      _NavItem(Icons.local_offer_rounded, Icons.local_offer_outlined, 'Promo'),
      _NavItem(
        Icons.receipt_long_rounded,
        Icons.receipt_long_outlined,
        'Pesanan',
      ),
      _NavItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: isDark ? kBorderDark : kBorderLight),
        ),
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
                  final sel = i == _navIndex;
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
                            Text(
                              item.label,
                              style: _body(kTextOnPrimary, 12, FontWeight.bold),
                            ),
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
  final String label;
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback? onTap;
  const _ServiceItem(
    this.label,
    this.icon,
    this.bg,
    this.iconColor, {
    this.onTap,
  });
}

class _NavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  const _NavItem(this.activeIcon, this.inactiveIcon, this.label);
}
