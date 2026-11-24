import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'orders/driver_umum_orders_screen.dart';
import 'orders/driver_umum_navigation_screen.dart';
import 'jadwal/driver_umum_jadwal_screen.dart';
import 'driver_umum_profile_screen.dart';
import '../notifications_screen.dart';
import '../wallet_screen.dart';
import '../../services/trip_service.dart';
import '../../services/document_service.dart';
import '../../services/map_route_service.dart';
import '../../services/ride_dispatch_service.dart';
import '../../widgets/driver_food_orders_section.dart';
import '../../widgets/driver_ride_orders_section.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBackgroundLight = Color(0xFFF7F8F5);
const Color kBackgroundDark = Color(0xFF1D2210);

class DriverUmumHomeScreen extends StatefulWidget {
  const DriverUmumHomeScreen({super.key});

  @override
  State<DriverUmumHomeScreen> createState() => _DriverUmumHomeScreenState();
}

class _DriverUmumHomeScreenState extends State<DriverUmumHomeScreen> {
  final TripService _tripService = TripService();
  final DocumentService _docService = DocumentService();
  final RideDispatchService _dispatch = RideDispatchService();

  bool _isWorking = true;
  int _navIndex = 0;
  bool _isLeaderboardExpanded = false;

  // Data profil dari Firestore
  String _driverName = 'Agus Prabowo';
  String _vehiclePlate = 'BK 5678 UMM';
  String _vehicleBrand = 'Honda Beat';
  String _photoUrl = '';
  double _rating = 4.8;
  int _totalTrips = 512;
  int _todayEarnings = 0;
  int _walletBalance = 0;
  bool _isActive = true;

  // Stream subscription
  StreamSubscription? _userSub;
  StreamSubscription? _walletSub;
  StreamSubscription<DriverGpsResult>? _gpsStreamSub;

  // Lokasi perangkat real-time (GPS)
  LatLng _driverGps = MapRouteService.lastKnownDriverGps?.position ??
      MapRouteService.defaultDriverSpawn;
  String _driverAddress = 'Mendeteksi lokasi perangkat...';
  bool _isRealGps = MapRouteService.lastKnownDriverGps?.isRealDeviceGps ?? false;
  DateTime _lastGeocodeTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Timer dialog orderan masuk
  Timer? _orderTimer;
  int _countdownSeconds = 15;

  List<Map<String, dynamic>> _activeOrders = [];
  Timer? _presenceTimer;
  bool _didInitialPresenceSync = false;

  @override
  void initState() {
    super.initState();
    // Tanpa orderan dummy: semua orderan antar & makan masuk real-time dari Firestore.
    _activeOrders = [];

    _listenToFirebaseData();
    _initDeviceGps();
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _syncPresence(),
    );
  }

  Future<void> _syncPresence() async {
    await _dispatch.syncDriverPresence(
      isOnline: _isWorking,
      position: _driverGps,
      role: 'driver_umum',
      name: _driverName,
      vehicleBrand: _vehicleBrand,
      vehiclePlate: _vehiclePlate,
    );
  }

  Future<void> _initDeviceGps() async {
    final gps = await MapRouteService.getCurrentDriverPosition();
    if (!mounted) return;
    setState(() {
      _driverGps = gps.position;
      _isRealGps = gps.isRealDeviceGps;
    });
    _syncPresence();
    await _refreshDriverAddress(gps.position);

    _gpsStreamSub?.cancel();
    _gpsStreamSub = MapRouteService.watchDriverPosition().listen((liveGps) {
      if (!mounted) return;
      final moved = MapRouteService.distanceInMeters(_driverGps, liveGps.position);
      setState(() {
        _driverGps = liveGps.position;
        _isRealGps = true;
      });
      if (moved > 25) {
        _syncPresence();
      }
      if (moved > 35 ||
          DateTime.now().difference(_lastGeocodeTime).inSeconds > 20) {
        _refreshDriverAddress(liveGps.position);
      }
    });
  }

  Future<void> _refreshDriverAddress(LatLng pos) async {
    _lastGeocodeTime = DateTime.now();
    final addr = await MapRouteService.reverseGeocodePosition(pos);
    if (!mounted) return;
    setState(() => _driverAddress = addr);
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _orderTimer?.cancel();
    _userSub?.cancel();
    _walletSub?.cancel();
    _gpsStreamSub?.cancel();
    _dispatch.syncDriverPresence(
      isOnline: false,
      position: _driverGps,
      role: 'driver_umum',
      name: _driverName,
      vehicleBrand: _vehicleBrand,
      vehiclePlate: _vehiclePlate,
    );
    super.dispose();
  }

  void _listenToFirebaseData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _ensureKtpDocumentExists(user.uid);

      // 1. Listen Firestore: users/{uid}
      _userSub = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists && mounted) {
          final data = doc.data() ?? {};
          final profile = (data['driverProfile'] as Map<String, dynamic>?) ?? {};
          setState(() {
            _driverName = data['name'] ?? _driverName;
            _photoUrl = (data['photoUrl'] ?? '').toString().trim();
            _vehiclePlate = data['vehiclePlate'] ?? profile['vehiclePlate'] ?? _vehiclePlate;
            _vehicleBrand = data['vehicleBrand'] ?? profile['vehicleBrand'] ?? _vehicleBrand;
            _rating = (data['rating'] as num?)?.toDouble() ?? (profile['rating'] as num?)?.toDouble() ?? _rating;
            _totalTrips = (data['totalTrips'] as num?)?.toInt() ?? (profile['totalTrips'] as num?)?.toInt() ?? _totalTrips;
            _todayEarnings = (data['todayEarnings'] as num?)?.toInt() ?? _todayEarnings;
            _isActive = data['isActive'] ?? true;
            if (data['isOnline'] is bool) {
              _isWorking = data['isOnline'] as bool;
            }
          });
          if (!_didInitialPresenceSync) {
            _didInitialPresenceSync = true;
            _syncPresence();
          }
        }
      });

      // 2. Listen Firestore: wallets/{uid}
      _walletSub = FirebaseFirestore.instance.collection('wallets').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists && mounted) {
          final data = doc.data() ?? {};
          setState(() {
            _walletBalance = (data['balance'] as num?)?.toInt() ?? _walletBalance;
          });
        }
      });
    }
  }

  Future<void> _ensureKtpDocumentExists(String uid) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('documents').doc('ktp');
      final doc = await docRef.get();
      if (!doc.exists) {
        await _docService.uploadKtpDriverUmum(
          uid: uid,
          nik: '1271012345670001',
          fileName: 'scaled_IMG_0226.jpg',
        );
      }
    } catch (_) {}
  }

  Future<void> _updateOnlineStatus(bool val) async {
    // Hanya blokir jika akun dinonaktifkan/suspend oleh Admin
    if (val && !_isActive) {
      _showVerificationWarningDialog();
      return;
    }

    setState(() => _isWorking = val);
    await _syncPresence();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'isOnline': val,
          'lastSeenAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  void _showVerificationWarningDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Akun Belum Siap Narik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Sesuai ketentuan keamanan GasKampus, Mitra Driver Umum wajib mengunggah KTP, SIM C, dan STNK serta telah disetujui Admin sebelum dapat mengaktifkan status Online.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _navIndex = 4); // Buka Profil
            },
            child: const Text('Cek Dokumen KTP', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Simulasi Penawaran Order Masuk 15 Detik (README Bagian 7)
  void _showIncomingOrderPopup(Map<String, dynamic> order) {
    _orderTimer?.cancel();
    _countdownSeconds = 15;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            _orderTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
              if (_countdownSeconds > 1) {
                setDialogState(() => _countdownSeconds--);
              } else {
                timer.cancel();
                _orderTimer = null;
                Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Waktu penawaran order habis (15s). Dialihkan ke driver berikutnya.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            });

            final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
            final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

            return Dialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Timer Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.bolt, color: Colors.black87, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'ORDER MASUK TIER 3',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$_countdownSeconds dtk',
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _countdownSeconds / 15.0,
                        backgroundColor: Colors.grey[200],
                        color: _countdownSeconds < 5 ? Colors.redAccent : kPrimary,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Customer Info
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.black87, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['name'] ?? 'Mahasiswa GasKampus',
                                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${order['desc'] ?? 'Pelanggan Kampus'} · ${order['payment'] ?? 'GasPay'}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          order['price'] ?? 'Rp 15.000',
                          style: const TextStyle(color: kPrimary, fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Route box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.radio_button_checked, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order['from'] ?? 'Stasiun Medan',
                                  style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 7),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                height: 12,
                                child: VerticalDivider(color: Colors.grey, thickness: 1.5),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order['to'] ?? 'Gedung C - Zona B (Fakultas Teknik USU)',
                                  style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Builder(
                            builder: (_) {
                              final metrics = MapRouteService.estimateMetricsFromDevice(
                                _driverGps,
                                order['from'] ?? 'Stasiun Medan',
                                fallbackZone: order['zone'],
                              );
                              final distKm = (metrics['distanceKm'] as double).toStringAsFixed(1);
                              final eta = metrics['etaMinutes'] as int;
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: kPrimary.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Jarak ke penumpang: $distKm km (~$eta mnt) dari lokasi Anda',
                                  style: TextStyle(
                                    color: isDark ? kPrimary : kBackgroundDark,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action buttons (Tolak vs Terima)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              _orderTimer?.cancel();
                              _orderTimer = null;
                              Navigator.pop(ctx);
                            },
                            child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              _orderTimer?.cancel();
                              _orderTimer = null;
                              Navigator.pop(ctx);

                              final user = FirebaseAuth.instance.currentUser;
                              final driverId = user?.uid ?? 'driveru_demo';

                              // Kunci order di Firestore (README Bagian 7)
                              await _tripService.acceptOrder(
                                orderId: order['orderId'] ?? 'order_live_01',
                                driverId: driverId,
                                matchTier: 3,
                              );

                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DriverUmumNavigationScreen(
                                    orderId: order['orderId'] ?? 'order_live_01',
                                    passengerName: order['name'] ?? 'Andi Pratama',
                                    passengerRole: order['desc'] ?? 'Mahasiswa · Fak. Teknik USU',
                                    fareAmount: order['fareAmount'] ?? 15000,
                                    pickupAddress: order['from'] ?? 'Stasiun Medan',
                                    dropoffAddress: order['to'] ?? 'Gedung C - Zona B (Fakultas Teknik USU)',
                                    paymentMethod: order['payment'] ?? 'GasPay',
                                    zone: order['zone'] ?? 'Zona B',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Terima Order (15s)', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _orderTimer?.cancel();
      _orderTimer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? kBackgroundDark : kBackgroundLight;

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: DriverIncomingOrderListener(
        isOnline: _isWorking,
        driverName: _driverName,
        driverRole: 'driver_umum',
        vehicleBrand: _vehicleBrand,
        vehiclePlate: _vehiclePlate,
        driverPosition: _driverGps,
        onOrderAccepted: () {
          if (mounted) setState(() => _navIndex = 0);
        },
        child: _buildBodyContent(isDark),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
      floatingActionButton: _navIndex == 0
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kPrimary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: InkWell(
                onTap: () => _showHotspotRadarModal(isDark),
                borderRadius: BorderRadius.circular(14),
                child: const Center(
                  child: Icon(Icons.map_rounded, color: kPrimary, size: 28),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBodyContent(bool isDark) {
    if (_navIndex == 1) {
      return DriverUmumOrdersScreen(
        onBack: () => setState(() => _navIndex = 0),
      );
    }

    if (_navIndex == 2) {
      return DriverUmumJadwalScreen(
        onBack: () => setState(() => _navIndex = 0),
      );
    }

    if (_navIndex == 3) {
      return WalletScreen(
        onBack: () => setState(() => _navIndex = 0),
      );
    }

    if (_navIndex == 4) {
      return DriverUmumProfileScreen(
        onBack: () => setState(() => _navIndex = 0),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            if (_isLeaderboardExpanded) _buildLeaderboardSection(isDark),
            DriverRideOrdersSection(
              isOnline: _isWorking,
              driverName: _driverName,
              driverRole: 'driver_umum',
              vehicleBrand: _vehicleBrand,
              vehiclePlate: _vehiclePlate,
              driverPosition: _driverGps,
            ),
            DriverFoodOrdersSection(driverName: _driverName),
            _buildEarningsCard(isDark),
            _buildScheduleShiftCard(isDark),
            _buildOrdersSection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334110) : const Color(0xFFE2E8F0);
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(color: kPrimary, width: 2),
                          ),
                          child: _photoUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    _photoUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: Colors.black87,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: Colors.black87,
                                    size: 26,
                                  ),
                                ),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: kPrimary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.check, size: 10, color: Colors.black, weight: 700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _driverName,
                                style: TextStyle(color: textColorPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kPrimary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'TIER 3 · MITRA UMUM',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.two_wheeler, size: 14, color: textColorSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '$_vehiclePlate · $_vehicleBrand',
                                  style: TextStyle(color: textColorSecondary, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLeaderboardExpanded = !_isLeaderboardExpanded;
                      });
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _isLeaderboardExpanded ? kPrimary.withValues(alpha: 0.2) : cardBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Icon(Icons.emoji_events_outlined, color: _isLeaderboardExpanded ? kPrimary : textColorSecondary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Icon(Icons.notifications_outlined, color: textColorSecondary, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Availability Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.electric_bolt, color: kPrimary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status Pekerjaan',
                            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          _isWorking ? 'Mode: Siap Narik' : 'Mode: Istirahat',
                          style: TextStyle(
                            color: _isWorking ? kPrimary : textColorPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _isWorking,
                  onChanged: (val) => _updateOnlineStatus(val),
                  activeThumbColor: kPrimary,
                  activeTrackColor: kPrimary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Live Device GPS Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  _isRealGps ? Icons.gps_fixed : Icons.location_searching,
                  color: _isRealGps ? Colors.green : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverAddress,
                        style: TextStyle(
                          color: textColorPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_driverGps.latitude.toStringAsFixed(4)}, ${_driverGps.longitude.toStringAsFixed(4)}',
                        style: TextStyle(color: textColorSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _isRealGps
                        ? Colors.green.withValues(alpha: 0.14)
                        : kPrimary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _isRealGps ? 'GPS ASLI' : 'SIMULASI MEDAN',
                    style: TextStyle(
                      color: _isRealGps ? Colors.green[700] : Colors.black87,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _initDeviceGps,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.refresh_rounded, color: kPrimary, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _navIndex = 3), // Dompet
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                bottom: -30,
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SALDO DOMPET GASPAY',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          'Rp',
                          style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatNumber(_walletBalance),
                          style: const TextStyle(
                            color: kPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up, color: kPrimary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Hari ini: +Rp ${_formatNumber(_todayEarnings)}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.moped, color: kPrimary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '$_totalTrips Trip',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Rekomendasi Jam Sibuk Narik Kampus untuk Driver Umum (README Poin 4)
  Widget _buildScheduleShiftCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334110) : const Color(0xFFE2E8F0);
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: kPrimary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rekomendasi Jam Sibuk Kampus',
                        style: TextStyle(color: textColorPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _navIndex = 2), // Jadwal
                child: const Text('Lihat Shift', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : kBackgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('NEXT', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('11:30',
                          style: TextStyle(color: textColorPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shift Siang · Jam Istirahat & Pindah Kelas',
                          style: TextStyle(color: textColorPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.location_city, size: 14, color: Colors.grey),
                              SizedBox(width: 4),
                              Text('Fak. Teknik & Perpustakaan USU', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.timer, size: 14, color: Colors.orange),
                              SizedBox(width: 4),
                              Text('Mulai dlm 30m',
                                  style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOrdersSection(bool isDark) {
    if (_activeOrders.isEmpty) return const SizedBox.shrink();

    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: kPrimary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Orderan Aktif (Tier 3)',
                        style: TextStyle(color: textColorPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_activeOrders.isNotEmpty) {
                        _showIncomingOrderPopup(_activeOrders.first);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.play_arrow_rounded, color: Colors.black87, size: 14),
                          SizedBox(width: 2),
                          Text('Tes Order 15s', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => setState(() => _navIndex = 1),
                    child: const Text('Riwayat', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_activeOrders.length, (index) {
            final order = _activeOrders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOrderCard(
                isDark: isDark,
                name: order['name'],
                desc: order['desc'] ?? 'Pelanggan Kampus',
                price: order['price'],
                from: order['from'],
                to: order['to'],
                isPrimary: order['isPrimary'],
                onView: () {
                  _showIncomingOrderPopup(order);
                },
                onDelete: () {
                  setState(() {
                    _activeOrders.removeAt(index);
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderCard({
    required bool isDark,
    required String name,
    required String desc,
    required String price,
    required String from,
    required String to,
    required bool isPrimary,
    required VoidCallback onView,
    required VoidCallback onDelete,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334110) : const Color(0xFFE2E8F0);
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: kPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(color: textColorPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  price,
                  style: const TextStyle(color: kPrimary, fontSize: 14, fontWeight: FontWeight.w900),
                ),
                Builder(
                  builder: (_) {
                    final metrics = MapRouteService.estimateMetricsFromDevice(_driverGps, from);
                    final km = (metrics['distanceKm'] as double).toStringAsFixed(1);
                    final eta = metrics['etaMinutes'] as int;
                    return Text(
                      'Jemput: $km km (~$eta mnt) · $from',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildActionCircle(
            icon: Icons.remove_red_eye_rounded,
            color: kPrimary,
            onTap: onView,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _buildActionCircle(
            icon: Icons.close_rounded,
            color: Colors.redAccent,
            onTap: onDelete,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color,
          size: icon == Icons.close_rounded ? 26 : 24,
          weight: 900,
        ),
      ),
    );
  }

  Widget _buildLeaderboardSection(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF334110) : const Color(0xFFE2E8F0);
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Row(
              children: const [
                Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 16),
                SizedBox(width: 8),
                Text(
                  'Leaderboard Driver Hari Ini',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLeaderboardRow(1, 'Agus Prabowo', 'Rp 340.000', true, textColorPrimary),
            const Divider(height: 16),
            _buildLeaderboardRow(2, 'Rizky Pratama', 'Rp 285.000', false, textColorPrimary),
            const Divider(height: 16),
            _buildLeaderboardRow(3, 'Budi Santoso', 'Rp 210.000', false, textColorPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow(int rank, String name, String amount, bool isMe, Color textColor) {
    return Row(
      children: [
        Container(
          width: 24,
          alignment: Alignment.center,
          child: Text(
            rank.toString(),
            style: TextStyle(
              color: rank == 1 ? Colors.amber : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name + (isMe ? ' (Anda)' : ''),
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            color: kPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey[100]!)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.grid_view_rounded, 'Home', 0, isDark, _navIndex == 0),
            _buildNavItem(Icons.moped, 'Orders', 1, isDark, _navIndex == 1),
            _buildNavItem(Icons.calendar_today, 'Jadwal', 2, isDark, _navIndex == 2),
            _buildNavItem(Icons.account_balance_wallet, 'Dompet', 3, isDark, _navIndex == 3),
            _buildNavItem(Icons.person_outline, 'Profil', 4, isDark, _navIndex == 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark, bool isActive) {
    final activeColor = kPrimary;
    final inactiveColor = isDark ? Colors.grey[500] : Colors.grey[400];
    final color = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _navIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Opacity(
            opacity: isActive ? 1.0 : 0.4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? (isDark ? Colors.white : Colors.black) : color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHotspotRadarModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      builder: (ctx) => _HotspotRadarSheet(isDark: isDark),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }
}

class _HotspotRadarSheet extends StatefulWidget {
  final bool isDark;
  const _HotspotRadarSheet({required this.isDark});

  @override
  State<_HotspotRadarSheet> createState() => _HotspotRadarSheetState();
}

class _HotspotRadarSheetState extends State<_HotspotRadarSheet> {
  final MapController _radarMapController = MapController();
  int _selectedIndex = 0;
  bool _isMapReady = false;

  // Hotspot penjemputan statis — nama area, bukan zona.
  static const _hotspots = [
    {'title': 'Pintu 1 USU & Jl. Dr. Mansyur', 'orders': 8, 'wait': 5, 'lat': 3.5658, 'lng': 98.6565, 'color': 0xFFC0F637},
    {'title': 'Fak. Teknik & Fasilkom-TI USU', 'orders': 12, 'wait': 3, 'lat': 3.5608, 'lng': 98.6542, 'color': 0xFF38BDF8},
    {'title': 'Perpustakaan & Pintu 4 USU', 'orders': 6, 'wait': 4, 'lat': 3.5595, 'lng': 98.6598, 'color': 0xFFFB923C},
    {'title': 'FMIPA & Teknik Elektro USU', 'orders': 10, 'wait': 3, 'lat': 3.5607, 'lng': 98.6545, 'color': 0xFFA78BFA},
    {'title': 'Vokasi & Fak. Pertanian USU', 'orders': 5, 'wait': 6, 'lat': 3.5577, 'lng': 98.6545, 'color': 0xFF34D399},
    {'title': 'FISIP & Fak. Ekonomi Bisnis USU', 'orders': 15, 'wait': 2, 'lat': 3.5582, 'lng': 98.6577, 'color': 0xFFF472B6},
  ];

  @override
  void dispose() {
    _radarMapController.dispose();
    super.dispose();
  }

  void _focusHotspot(int index) {
    final h = _hotspots[index];
    setState(() => _selectedIndex = index);
    if (_isMapReady) {
      _radarMapController.move(LatLng(h['lat'] as double, h['lng'] as double), 15.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapStyle = widget.isDark ? GasMapStyle.dark : GasMapStyle.street;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: const [
                      Icon(Icons.radar, color: kPrimary, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Radar Hotspot Penjemputan',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Text(
              'Peta live area kumpul mahasiswa & permintaan order tinggi:',
              style: TextStyle(color: Colors.grey, fontSize: 12.5),
            ),
            const SizedBox(height: 12),

            // Peta Hotspot Kampus
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: GasKampusLiveMap(
                  mapController: _radarMapController,
                  mapStyle: mapStyle,
                  initialCenter: MapRouteService.defaultKampusCenter,
                  initialZoom: 14.3,
                  onMapReady: () => _isMapReady = true,
                  markers: List.generate(_hotspots.length, (i) {
                    final h = _hotspots[i];
                    final isSelected = i == _selectedIndex;
                    final color = Color(h['color'] as int);
                    return Marker(
                      point: LatLng(h['lat'] as double, h['lng'] as double),
                      width: 68,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _focusHotspot(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? kPrimary : const Color(0xFF1D2210),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? Colors.black : color,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${h['orders']} Order',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: isSelected ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 210),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _hotspots.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final h = _hotspots[index];
                  final isSelected = index == _selectedIndex;
                  final color = Color(h['color'] as int);
                  return InkWell(
                    onTap: () => _focusHotspot(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? kPrimary.withValues(alpha: 0.14)
                            : (widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? kPrimary
                              : (widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.near_me, color: color, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h['title'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${h['orders']} Order menunggu · Estimasi ${h['wait']}m',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: 'Navigasi ke ${h['title']}',
                            onPressed: () {
                              MapRouteService.openGoogleMapsNavigation(
                                destination: LatLng(h['lat'] as double, h['lng'] as double),
                              );
                            },
                            icon: const Icon(Icons.directions_rounded, color: kPrimary, size: 20),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
