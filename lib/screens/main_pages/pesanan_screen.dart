import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/map_route_service.dart';
import 'service_order_screen.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kSecondaryGreen = Color(0xFF68cd5c);
const Color kBgDark = Color(0xFF1D2210);
const Color kBgLight = Color(0xFFF7F8F5);

TextStyle _body(Color c, double sz, FontWeight w, {double? ls, double? h}) =>
    TextStyle(
      color: c,
      fontSize: sz,
      fontWeight: w,
      letterSpacing: ls,
      height: h,
    );

class OrderItem {
  final String driverName;
  final String driverPhoto;
  final String serviceType;
  final String dateLabel;
  final String from;
  final String to;
  final String price;
  final String status;

  const OrderItem({
    required this.driverName,
    required this.driverPhoto,
    required this.serviceType,
    required this.dateLabel,
    required this.from,
    required this.to,
    required this.price,
    required this.status,
  });
}

final List<OrderItem> _allOrders = [
  const OrderItem(
    driverName: 'Siti Aminah',
    driverPhoto:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
    serviceType: 'Goride',
    dateLabel: 'Hari ini, 09:12',
    from: 'Asrama Mahasiswa USU',
    to: 'Gedung Biro Rektor USU',
    price: 'Rp 10.000',
    status: 'proses',
  ),
  const OrderItem(
    driverName: 'Budi Santoso',
    driverPhoto:
        'https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
    serviceType: 'Goride',
    dateLabel: 'Kemarin, 10:30',
    from: 'Pintu 1 USU (Jl. Dr. Mansyur)',
    to: 'Kantin Vokasi USU',
    price: 'Rp 12.000',
    status: 'selesai',
  ),
  const OrderItem(
    driverName: 'Andi Wijaya',
    driverPhoto:
        'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
    serviceType: 'Gocar',
    dateLabel: '2 hari lalu, 15:45',
    from: 'Fakultas Teknik USU',
    to: 'Stasiun Medan',
    price: 'Rp 25.000',
    status: 'selesai',
  ),
];

class PesananScreen extends StatefulWidget {
  /// Naikkan nilainya dari parent untuk langsung membuka Riwayat Pesanan.
  final int openHistorySignal;

  /// Naikkan nilainya dari parent untuk membuka Halaman Pesanan (Antar).
  final int openOrderSignal;
  final VoidCallback onBackToHome;

  const PesananScreen({
    super.key,
    this.openHistorySignal = 0,
    this.openOrderSignal = 0,
    required this.onBackToHome,
  });

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen>
    with SingleTickerProviderStateMixin {
  int _mainStep = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.openHistorySignal > 0 &&
        widget.openHistorySignal > widget.openOrderSignal) {
      _mainStep = 2;
    } else {
      _mainStep = 0;
    }
  }

  @override
  void didUpdateWidget(covariant PesananScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openOrderSignal != oldWidget.openOrderSignal) {
      setState(() => _mainStep = 0);
    } else if (widget.openHistorySignal != oldWidget.openHistorySignal) {
      setState(() => _mainStep = 2);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_mainStep) {
      case 0:
        return _FindDriverScreen(
          onFindDriver: () => setState(() => _mainStep = 1),
          onShowHistory: () => setState(() => _mainStep = 2),
        );
      case 1:
        return _ActiveOrderScreen(
          onBack: () => setState(() => _mainStep = 0),
          onShowHistory: () => setState(() => _mainStep = 2),
        );
      case 2:
        return _RiwayatScreen(
          tabController: _tabController,
          onBack: () => setState(() => _mainStep = 0),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _FindDriverScreen extends StatefulWidget {
  final VoidCallback onFindDriver;
  final VoidCallback onShowHistory;

  const _FindDriverScreen({
    required this.onFindDriver,
    required this.onShowHistory,
  });

  @override
  State<_FindDriverScreen> createState() => _FindDriverScreenState();
}

class _FindDriverScreenState extends State<_FindDriverScreen> {
  int _selectedService = 0;
  int _selectedPayment = 0;
  final TextEditingController _pickupController = TextEditingController(
    text: 'Mendeteksi lokasi perangkat...',
  );
  final TextEditingController _destinationController = TextEditingController();

  LatLng _devicePos = MapRouteService.lastKnownDriverGps?.position ??
      MapRouteService.defaultKampusCenter;
  bool _isRealGps = MapRouteService.lastKnownDriverGps?.isRealDeviceGps ?? false;

  @override
  void initState() {
    super.initState();
    _destinationController.addListener(_onDestChanged);
    _detectDevicePickup();
  }

  void _onDestChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _detectDevicePickup() async {
    final gps = await MapRouteService.getCurrentDriverPosition(
      campusFallback: MapRouteService.defaultKampusCenter,
    );
    if (!mounted) return;
    setState(() {
      _devicePos = gps.position;
      _isRealGps = gps.isRealDeviceGps;
    });

    final street = await MapRouteService.reverseGeocodePosition(gps.position);
    if (!mounted) return;
    if (_pickupController.text == 'Mendeteksi lokasi perangkat...') {
      _pickupController.text = street;
    }
  }

  @override
  void dispose() {
    _destinationController.removeListener(_onDestChanged);
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _handleFindDriver() async {
    final rawPickup = _pickupController.text.trim();
    final pickup = (rawPickup.isEmpty ||
            rawPickup == 'Mendeteksi lokasi perangkat...')
        ? 'Lokasi Perangkat (${_devicePos.latitude.toStringAsFixed(4)}, ${_devicePos.longitude.toStringAsFixed(4)})'
        : rawPickup;
    final dest = _destinationController.text.trim().isEmpty
        ? 'Gedung Biro Rektor USU'
        : _destinationController.text.trim();
    final svcLabel = _services[_selectedService]['label'] as String;
    final fareStr = _services[_selectedService]['fare'] as String;
    final now = DateTime.now();
    String docId = 'ride_${now.millisecondsSinceEpoch}';

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final docRef = await FirebaseFirestore.instance
            .collection('orders')
            .add({
              'passengerId': uid,
              'driverId': null,
              'serviceType': 'antar',
              'status': 'pending',
              'items': 'Layanan Antar ($svcLabel)',
              'originAddress': pickup,
              'destinationAddress': dest,
              'note': '',
              'fareAmount': _selectedService == 1 ? 20000 : 10000,
              'paymentMethod': 'wallet',
              'createdAt': now.toIso8601String(),
            })
            .timeout(const Duration(seconds: 6));
        docId = docRef.id;
      }
    } catch (_) {}

    SessionOrderStore.addOrder(
      LocalOrderRecord(
        id: docId,
        serviceType: 'antar',
        items: 'Layanan Antar ($svcLabel)',
        originAddress: pickup,
        destinationAddress: dest,
        note: '',
        status: 'pending',
        price: fareStr,
        createdAt: now,
      ),
    );

    if (mounted) {
      widget.onFindDriver();
    }
  }

  static const _services = [
    {
      'label': 'Goride',
      'icon': Icons.motorcycle_rounded,
      'fare': 'Rp 10.000',
      'time': '3-5',
    },
    {
      'label': 'Gocar',
      'icon': Icons.directions_car_rounded,
      'fare': 'Rp 20.000',
      'time': '5-7',
    },
    {
      'label': 'Lainnya',
      'icon': Icons.more_horiz_rounded,
      'fare': 'Rp 10.000',
      'time': '3-5',
    },
  ];

  static const _paymentMethods = [
    {
      'label': 'Gopay Wallet',
      'sub': 'Rp 45.500',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF2B6CB0),
    },
    {
      'label': 'QRIS',
      'sub': 'Scan & Pay',
      'icon': Icons.qr_code_scanner_rounded,
      'color': Color(0xFF7C3AED),
    },
    {
      'label': 'Tunai',
      'sub': 'Bayar di tempat',
      'icon': Icons.payments_rounded,
      'color': Color(0xFF059669),
    },
  ];

  void _showPaymentSheet(
    BuildContext context,
    bool isDark,
    Color textColorPrimary,
    Color textColorSecondary,
    Color cardBg,
    Color borderColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModal) => Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(ctx).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Text(
                  'Metode Pembayaran',
                  style: _body(textColorPrimary, 18, FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pilih cara kamu membayar perjalanan',
                  style: _body(textColorSecondary, 13, FontWeight.normal),
                ),
                const SizedBox(height: 20),
                ...List.generate(_paymentMethods.length, (i) {
                  final pm = _paymentMethods[i];
                  final isSelected = _selectedPayment == i;
                  final accentColor = pm['color'] as Color;

                  return GestureDetector(
                    onTap: () {
                      setModal(() {});
                      setState(() => _selectedPayment = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withOpacity(isDark ? 0.18 : 0.08)
                            : (isDark
                                  ? const Color(0xFF232A18)
                                  : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? accentColor : borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              pm['icon'] as IconData,
                              color: accentColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pm['label'] as String,
                                  style: _body(
                                    textColorPrimary,
                                    15,
                                    FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pm['sub'] as String,
                                  style: _body(
                                    textColorSecondary,
                                    12,
                                    FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? accentColor
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? accentColor : borderColor,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 13,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Konfirmasi',
                      textAlign: TextAlign.center,
                      style: _body(
                        const Color(0xFF0F172A),
                        16,
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLainnyaSheet(
    BuildContext context,
    bool isDark,
    Color textColorPrimary,
    Color textColorSecondary,
    Color cardBg,
    Color borderColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              'Opsi Lainnya',
              style: _body(textColorPrimary, 18, FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Fitur tambahan untuk perjalananmu',
              style: _body(textColorSecondary, 13, FontWeight.normal),
            ),
            const SizedBox(height: 20),
            _lainnyaItem(
              icon: Icons.note_alt_outlined,
              iconColor: const Color(0xFF2B6CB0),
              title: 'Catatan untuk Driver',
              subtitle: 'Tambahkan instruksi khusus',
              isDark: isDark,
              textColorPrimary: textColorPrimary,
              textColorSecondary: textColorSecondary,
              borderColor: borderColor,
            ),
            const SizedBox(height: 10),
            _lainnyaItem(
              icon: Icons.discount_outlined,
              iconColor: const Color(0xFFE53E3E),
              title: 'Gunakan Voucher',
              subtitle: 'Hemat lebih banyak',
              isDark: isDark,
              textColorPrimary: textColorPrimary,
              textColorSecondary: textColorSecondary,
              borderColor: borderColor,
            ),
            const SizedBox(height: 10),
            _lainnyaItem(
              icon: Icons.group_outlined,
              iconColor: const Color(0xFF7C3AED),
              title: 'Pesan untuk Orang Lain',
              subtitle: 'Kirim pesanan ke kontak',
              isDark: isDark,
              textColorPrimary: textColorPrimary,
              textColorSecondary: textColorSecondary,
              borderColor: borderColor,
            ),
            const SizedBox(height: 10),
            _lainnyaItem(
              icon: Icons.schedule_rounded,
              iconColor: const Color(0xFF059669),
              title: 'Jadwalkan Perjalanan',
              subtitle: 'Atur waktu penjemputan',
              isDark: isDark,
              textColorPrimary: textColorPrimary,
              textColorSecondary: textColorSecondary,
              borderColor: borderColor,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _lainnyaItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color textColorPrimary,
    required Color textColorSecondary,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232A18) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _body(textColorPrimary, 14, FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: _body(textColorSecondary, 12, FontWeight.normal),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: textColorSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kBgDark : kBgLight;
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark
        ? Colors.white70
        : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF181E10) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1A2210) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2A3518)
        : const Color(0xFFE2E8F0);

    final svc = _services[_selectedService];
    final pm = _paymentMethods[_selectedPayment];
    final pmColor = pm['color'] as Color;

    return Container(
      color: bg,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 24),
                        Expanded(
                          child: Text(
                            'Pesan Antar',
                            textAlign: TextAlign.center,
                            style: _body(textColorPrimary, 18, FontWeight.bold),
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onShowHistory,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  color: textColorPrimary,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Riwayat',
                                  style: _body(
                                    textColorPrimary,
                                    12,
                                    FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOKASI JEMPUT (PICKUP)',
                          style: _body(
                            textColorSecondary,
                            12,
                            FontWeight.w600,
                            ls: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _locationField(
                          icon: Icons.my_location,
                          iconColor: kPrimary,
                          hint: 'Lokasi jemput saat ini',
                          controller: _pickupController,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          textColorPrimary: textColorPrimary,
                          textColorSecondary: textColorSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'TUJUAN PENGANTARAN (DESTINATION)',
                          style: _body(
                            textColorSecondary,
                            12,
                            FontWeight.w600,
                            ls: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _locationField(
                          icon: Icons.location_on_outlined,
                          iconColor: textColorSecondary,
                          hint: 'Mau diantar ke mana? (mis. Biro Rektor USU)',
                          controller: _destinationController,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          textColorPrimary: textColorPrimary,
                          textColorSecondary: textColorSecondary,
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (_) {
                            final destText = _destinationController.text.trim().isEmpty
                                ? 'Gedung Biro Rektor USU'
                                : _destinationController.text.trim();
                            final metrics = MapRouteService.estimateMetricsFromDevice(
                              _devicePos,
                              destText,
                            );
                            final km = (metrics['distanceKm'] as double).toStringAsFixed(1);
                            final eta = metrics['etaMinutes'] as int;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: kPrimary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isRealGps ? Icons.gps_fixed : Icons.route_rounded,
                                    size: 14,
                                    color: isDark ? kPrimary : kBgDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Estimasi jarak: $km km (~$eta mnt) dari lokasi perangkat',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? kPrimary : kBgDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        _historyItem(
                          Icons.history,
                          'Gedung Fakultas Teknik USU',
                          textColorSecondary,
                          isDark,
                          onTap: () => setState(
                            () => _destinationController.text =
                                'Gedung Fakultas Teknik USU',
                          ),
                        ),
                        _historyItem(
                          Icons.history,
                          'Asrama Mahasiswa USU Padang Bulan',
                          textColorSecondary,
                          isDark,
                          onTap: () => setState(
                            () => _destinationController.text =
                                'Asrama Mahasiswa USU Padang Bulan',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: List.generate(_services.length, (i) {
                    final s = _services[i];
                    final isSel = _selectedService == i;
                    final isLainnya = i == _services.length - 1;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (isLainnya) {
                            _showLainnyaSheet(
                              context,
                              isDark,
                              textColorPrimary,
                              textColorSecondary,
                              cardBg,
                              borderColor,
                            );
                          } else {
                            setState(() => _selectedService = i);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(
                            right: i < _services.length - 1 ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSel
                                ? kPrimary
                                : (isDark
                                      ? const Color(0xFF232A18)
                                      : const Color(0xFFF1F5F0)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSel ? Colors.transparent : borderColor,
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: kPrimary.withOpacity(0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                s['icon'] as IconData,
                                size: 26,
                                color: isSel
                                    ? const Color(0xFF0F172A)
                                    : (isDark
                                          ? Colors.white54
                                          : Colors.black38),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                s['label'] as String,
                                style: _body(
                                  isSel
                                      ? const Color(0xFF0F172A)
                                      : (isDark
                                            ? Colors.white54
                                            : Colors.black38),
                                  11,
                                  isSel ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // ── Fare + Time strip ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payments_outlined, color: kPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        svc['fare'] as String,
                        style: _body(textColorPrimary, 16, FontWeight.bold),
                      ),
                      Container(
                        width: 1,
                        height: 18,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: borderColor,
                      ),
                      Icon(
                        Icons.schedule_rounded,
                        color: textColorSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${svc['time']} mnt',
                        style: _body(textColorSecondary, 13, FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFF6B35),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Cepat!',
                        style: _body(
                          const Color(0xFFFF6B35),
                          12,
                          FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Payment selector row ──
                GestureDetector(
                  onTap: () => _showPaymentSheet(
                    context,
                    isDark,
                    textColorPrimary,
                    textColorSecondary,
                    cardBg,
                    borderColor,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: pmColor.withOpacity(isDark ? 0.12 : 0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: pmColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: pmColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            pm['icon'] as IconData,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pm['label'] as String,
                              style: _body(
                                textColorPrimary,
                                13,
                                FontWeight.bold,
                              ),
                            ),
                            Text(
                              pm['sub'] as String,
                              style: _body(
                                textColorSecondary,
                                11,
                                FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: pmColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Ganti',
                                style: _body(pmColor, 11, FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: pmColor,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: _handleFindDriver,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF0F172A),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cari Driver',
                          style: _body(
                            const Color(0xFF0F172A),
                            17,
                            FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationField({
    required IconData icon,
    required Color iconColor,
    required String hint,
    required TextEditingController controller,
    required Color inputBg,
    required Color borderColor,
    required Color textColorPrimary,
    required Color textColorSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: _body(textColorSecondary, 14, FontWeight.w500),
              ),
              style: _body(textColorPrimary, 14, FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyItem(
    IconData icon,
    String text,
    Color color,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 12),
            Text(
              text,
              style: _body(
                isDark ? Colors.white70 : Colors.black87,
                14,
                FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveOrderScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onShowHistory;

  const _ActiveOrderScreen({required this.onBack, required this.onShowHistory});

  @override
  State<_ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<_ActiveOrderScreen> {
  final MapController _mapController = MapController();
  late LatLng _pickupLatLng;
  late final LatLng _dropoffLatLng;
  List<LatLng> _routePoints = [];
  bool _isMapReady = false;
  double _distanceKm = 0.8;
  int _etaMinutes = 3;

  @override
  void initState() {
    super.initState();
    _pickupLatLng = MapRouteService.lastKnownDriverGps?.position ??
        MapRouteService.resolveCoordinate('Fakultas Teknik USU');
    _dropoffLatLng = MapRouteService.resolveCoordinate('Gedung Biro Rektor USU');
    _initUserLocationAndRoute();
  }

  Future<void> _initUserLocationAndRoute() async {
    final gps = await MapRouteService.getCurrentDriverPosition(
      campusFallback: MapRouteService.resolveCoordinate('Fakultas Teknik USU'),
    );
    if (!mounted) return;
    setState(() => _pickupLatLng = gps.position);
    await _loadRoute();
  }

  Future<void> _loadRoute() async {
    final res = await MapRouteService.fetchRoadRoute(_pickupLatLng, _dropoffLatLng);
    if (!mounted) return;
    setState(() {
      _routePoints = res.points;
      _distanceKm = res.distanceKm;
      _etaMinutes = res.durationMinutes;
    });
    _fitBounds();
  }

  void _fitBounds() {
    if (!_isMapReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isMapReady) return;
      try {
        final bounds = LatLngBounds.fromPoints([
          _pickupLatLng,
          _dropoffLatLng,
          ..._routePoints,
        ]);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.fromLTRB(48, 110, 64, 310),
            maxZoom: 16.8,
          ),
        );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark
        ? Colors.white70
        : const Color(0xFF64748B);
    final cardColor = isDark ? const Color(0xFF181E10) : Colors.white;
    final driverPoint = _routePoints.length > 2
        ? _routePoints[_routePoints.length ~/ 3]
        : _pickupLatLng;

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GasKampusLiveMap(
                mapController: _mapController,
                mapStyle: isDark ? GasMapStyle.dark : GasMapStyle.street,
                initialCenter: MapRouteService.defaultKampusCenter,
                initialZoom: 15.6,
                onMapReady: () {
                  _isMapReady = true;
                  _fitBounds();
                },
                polylines: [
                  if (_routePoints.length >= 2)
                    Polyline(
                      points: _routePoints,
                      color: kPrimary,
                      strokeWidth: 6.0,
                      borderStrokeWidth: 2.0,
                      borderColor: kBgDark,
                    ),
                ],
                markers: [
                  MapRouteService.buildPlacePinMarker(
                    point: _pickupLatLng,
                    label: 'Lokasi Anda',
                    color: kSecondaryGreen,
                    icon: Icons.my_location_rounded,
                  ),
                  MapRouteService.buildPlacePinMarker(
                    point: _dropoffLatLng,
                    label: 'Biro Rektor USU',
                    color: Colors.redAccent,
                    icon: Icons.location_on,
                  ),
                  Marker(
                    point: driverPoint,
                    width: 44,
                    height: 44,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.motorcycle_rounded,
                        color: Colors.black87,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 16,
                  16,
                  16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark ? Colors.black : Colors.white).withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _floatingIcon(
                      Icons.arrow_back_rounded,
                      isDark,
                      onTap: widget.onBack,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF181E10) : Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'GasKampus · Medan',
                        style: _body(textColorPrimary, 14, FontWeight.bold),
                      ),
                    ),
                    _floatingIcon(
                      Icons.receipt_long_rounded,
                      isDark,
                      onTap: widget.onShowHistory,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height * 0.3,
              child: Column(
                children: [
                  _floatingIcon(
                    Icons.add_rounded,
                    isDark,
                    onTap: () {
                      if (!_isMapReady) return;
                      _mapController.move(
                        _mapController.camera.center,
                        math.min(19.0, _mapController.camera.zoom + 1.0),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _floatingIcon(
                    Icons.remove_rounded,
                    isDark,
                    onTap: () {
                      if (!_isMapReady) return;
                      _mapController.move(
                        _mapController.camera.center,
                        math.max(11.0, _mapController.camera.zoom - 1.0),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _floatingIcon(
                    Icons.my_location_rounded,
                    isDark,
                    iconColor: kPrimary,
                    onTap: _fitBounds,
                  ),
                ],
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white30 : Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Driver sedang menuju lokasimu',
                                    style: _body(
                                      textColorPrimary,
                                      18,
                                      FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jarak ke tujuan: ${_distanceKm.toStringAsFixed(1)} km dari lokasimu',
                                    style: _body(
                                      textColorSecondary,
                                      13,
                                      FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '$_etaMinutes Menit',
                                style: _body(
                                  textColorPrimary,
                                  14,
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF232A18)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 56,
                                height: 56,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: cardColor,
                                          width: 2,
                                        ),
                                        image: const DecorationImage(
                                          image: NetworkImage(
                                            'https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Budi Santoso',
                                          style: _body(
                                            textColorPrimary,
                                            16,
                                            FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.circle,
                                          size: 4,
                                          color: textColorSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '4.9',
                                          style: _body(
                                            textColorPrimary,
                                            14,
                                            FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'BK 1234 GKS',
                                      style: TextStyle(
                                        color: textColorSecondary,
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  _actionBtn(
                                    Icons.call_outlined,
                                    kSecondaryGreen,
                                    isDark,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(99),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.share_location_rounded,
                                  color: Colors.black87,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bagikan Lokasi',
                                  style: _body(
                                    Colors.black87,
                                    16,
                                    FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 16,
                        ),
                      ],
                    ),
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

  Widget _floatingIcon(
    IconData icon,
    bool isDark, {
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181E10) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color:
              iconColor ?? (isDark ? Colors.white70 : const Color(0xFF334155)),
          size: 24,
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(isDark ? 0.3 : 0.2)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _RiwayatScreen extends StatefulWidget {
  final TabController tabController;
  final VoidCallback onBack;

  const _RiwayatScreen({required this.tabController, required this.onBack});

  @override
  State<_RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<_RiwayatScreen> {
  int _selectedTab = 0;

  List<OrderItem> get _filteredOrders {
    switch (_selectedTab) {
      case 1:
        return _allOrders.where((o) => o.status == 'proses').toList();
      case 2:
        return _allOrders.where((o) => o.status == 'selesai').toList();
      default:
        return _allOrders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark
        ? Colors.white70
        : const Color(0xFF64748B);
    final bg = isDark ? kBgDark : kBgLight;
    final cardBg = isDark ? const Color(0xFF1A2210) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2A3518)
        : const Color(0xFFE2E8F0);

    return Container(
      color: bg,
      child: Column(
        children: [
          Container(
            color: isDark
                ? kBgDark.withOpacity(0.95)
                : Colors.white.withOpacity(0.9),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onBack,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF232A18)
                                : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: textColorPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Riwayat Pesanan',
                          textAlign: TextAlign.center,
                          style: _body(textColorPrimary, 18, FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Row(
                  children: [
                    for (int i = 0; i < 3; i++)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = i),
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 12, top: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedTab == i
                                      ? kPrimary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              ['Semua', 'Proses', 'Selesai'][i],
                              textAlign: TextAlign.center,
                              style: _body(
                                _selectedTab == i
                                    ? textColorPrimary
                                    : textColorSecondary,
                                14,
                                _selectedTab == i
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Divider(height: 1, thickness: 1, color: borderColor),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseAuth.instance.currentUser == null
                  ? null
                  : FirebaseFirestore.instance
                        .collection('orders')
                        .where(
                          'passengerId',
                          isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                        )
                        .snapshots(),
              builder: (context, snapshot) {
                final seenIds = <String>{};
                final serviceOrders = <_ServiceOrderData>[];

                // 1. Pesanan dari Firestore
                if (snapshot.hasData) {
                  for (final doc in snapshot.data!.docs) {
                    final data = doc.data();
                    final item = _ServiceOrderData.fromMap(doc.id, data);
                    seenIds.add(doc.id);
                    final isDone =
                        item.status == 'completed' ||
                        item.status == 'cancelled';
                    if (_selectedTab == 1 && isDone) continue;
                    if (_selectedTab == 2 && !isDone) continue;
                    serviceOrders.add(item);
                  }
                }

                // 2. Pesanan dari sesi lokal (SessionOrderStore) yang belum ada di snapshot
                for (final loc in SessionOrderStore.orders) {
                  if (seenIds.contains(loc.id)) continue;
                  final item = _ServiceOrderData(
                    id: loc.id,
                    serviceType: loc.serviceType,
                    items: loc.items,
                    originAddress: loc.originAddress,
                    destinationAddress: loc.destinationAddress,
                    note: loc.note,
                    status: loc.status,
                    createdAt: loc.createdAt,
                  );
                  final isDone =
                      item.status == 'completed' || item.status == 'cancelled';
                  if (_selectedTab == 1 && isDone) continue;
                  if (_selectedTab == 2 && !isDone) continue;
                  serviceOrders.add(item);
                }

                serviceOrders.sort(
                  (a, b) => b.createdAt.compareTo(a.createdAt),
                );

                final staticOrders = _filteredOrders;
                final total = serviceOrders.length + staticOrders.length;

                if (total == 0) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: textColorSecondary.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada pesanan',
                          style: _body(textColorSecondary, 16, FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: total,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index < serviceOrders.length) {
                      return _ServiceOrderCard(
                        order: serviceOrders[index],
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColorPrimary: textColorPrimary,
                        textColorSecondary: textColorSecondary,
                      );
                    }

                    final order = staticOrders[index - serviceOrders.length];
                    return _OrderCard(
                      order: order,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textColorPrimary: textColorPrimary,
                      textColorSecondary: textColorSecondary,
                      isDark: isDark,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderItem order;
  final Color cardBg;
  final Color borderColor;
  final Color textColorPrimary;
  final Color textColorSecondary;
  final bool isDark;

  const _OrderCard({
    required this.order,
    required this.cardBg,
    required this.borderColor,
    required this.textColorPrimary,
    required this.textColorSecondary,
    required this.isDark,
  });

  bool get isProses => order.status == 'proses';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isProses ? kPrimary : borderColor,
          width: isProses ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isProses
                ? kPrimary.withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kPrimary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        order.driverPhoto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.driverName,
                        style: _body(textColorPrimary, 14, FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order.serviceType} • ${order.dateLabel}',
                        style: _body(textColorSecondary, 12, FontWeight.normal),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isProses
                      ? kPrimary.withOpacity(0.2)
                      : kSecondaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  isProses ? 'Proses' : 'Selesai',
                  style: _body(
                    isProses ? textColorPrimary : kSecondaryGreen,
                    12,
                    FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 2),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: kPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 16,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white38 : Colors.black26,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.from,
                      style: _body(textColorSecondary, 12, FontWeight.normal),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.to,
                      style: _body(textColorSecondary, 12, FontWeight.normal),
                    ),
                  ],
                ),
              ),
              Text(
                order.price,
                style: _body(textColorPrimary, 14, FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 14),
          if (isProses)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.black87,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                icon: const Icon(Icons.location_on_rounded, size: 18),
                label: Text(
                  'Lacak Driver',
                  style: _body(Colors.black87, 14, FontWeight.bold),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColorPrimary,
                  side: const BorderSide(color: kPrimary, width: 2),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: Icon(
                  Icons.replay_rounded,
                  size: 18,
                  color: textColorPrimary,
                ),
                label: Text(
                  'Pesan Lagi',
                  style: _body(textColorPrimary, 14, FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Data pesanan layanan Makan / Titip dari koleksi Firestore `orders`.
class _ServiceOrderData {
  final String id;
  final String serviceType;
  final String items;
  final String originAddress;
  final String destinationAddress;
  final String note;
  final String status;
  final DateTime createdAt;

  const _ServiceOrderData({
    required this.id,
    required this.serviceType,
    required this.items,
    required this.originAddress,
    required this.destinationAddress,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  factory _ServiceOrderData.fromMap(String id, Map<String, dynamic> data) {
    return _ServiceOrderData(
      id: id,
      serviceType: (data['serviceType'] ?? '').toString(),
      items: (data['items'] ?? '').toString(),
      originAddress: (data['originAddress'] ?? '').toString(),
      destinationAddress: (data['destinationAddress'] ?? '').toString(),
      note: (data['note'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      createdAt:
          DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get isMakan => serviceType == 'makan';
  bool get isTitip => serviceType == 'titip';
  bool get isAntar => serviceType == 'antar';

  String get title {
    if (isMakan) return 'Pesanan Makan';
    if (isTitip) return 'Titip Barang';
    return 'Pesan Antar';
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'accepted':
        return 'Diterima';
      case 'onPickup':
        return 'Dijemput';
      case 'onTrip':
        return 'Diantar';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Batal';
      default:
        return status;
    }
  }

  String get dateLabel {
    final d = createdAt;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} • $hh:$mm';
  }
}

class _ServiceOrderCard extends StatelessWidget {
  final _ServiceOrderData order;
  final Color cardBg;
  final Color borderColor;
  final Color textColorPrimary;
  final Color textColorSecondary;

  const _ServiceOrderCard({
    required this.order,
    required this.cardBg,
    required this.borderColor,
    required this.textColorPrimary,
    required this.textColorSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final accent = order.isMakan
        ? const Color(0xFFFF9F43)
        : (order.isTitip ? const Color(0xFF54A0FF) : kPrimary);
    final isFinished =
        order.status == 'completed' || order.status == 'cancelled';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isFinished ? borderColor : accent,
          width: isFinished ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  order.isMakan
                      ? Icons.restaurant_rounded
                      : (order.isTitip
                            ? Icons.shopping_bag_rounded
                            : Icons.motorcycle_rounded),
                  color: order.isAntar ? textColorPrimary : accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.title,
                      style: _body(textColorPrimary, 14, FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.dateLabel,
                      style: _body(textColorSecondary, 12, FontWeight.normal),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isFinished
                      ? kSecondaryGreen.withOpacity(0.12)
                      : accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  order.statusLabel,
                  style: _body(
                    isFinished ? kSecondaryGreen : textColorPrimary,
                    12,
                    FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (order.items.isNotEmpty)
            _detailRow(
              order.isMakan
                  ? Icons.restaurant_menu_rounded
                  : (order.isTitip
                        ? Icons.inventory_2_outlined
                        : Icons.two_wheeler_rounded),
              order.isMakan
                  ? 'Makanan dipesan'
                  : (order.isTitip ? 'Barang dititip' : 'Layanan'),
              order.items,
            ),
          if (order.originAddress.isNotEmpty) ...[
            const SizedBox(height: 8),
            _detailRow(
              order.isMakan
                  ? Icons.storefront_outlined
                  : Icons.my_location_rounded,
              order.isMakan
                  ? 'Alamat warung / kantin'
                  : (order.isTitip ? 'Dari alamat' : 'Lokasi jemput'),
              order.originAddress,
            ),
          ],
          if (order.destinationAddress.isNotEmpty) ...[
            const SizedBox(height: 8),
            _detailRow(
              Icons.location_on_outlined,
              order.isMakan ? 'Alamat pengantaran' : 'Alamat tujuan',
              order.destinationAddress,
            ),
          ],
          if (order.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            _detailRow(Icons.sticky_note_2_outlined, 'Catatan', order.note),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: textColorSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: _body(textColorSecondary, 12, FontWeight.normal, h: 1.4),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: _body(textColorSecondary, 12, FontWeight.w600),
                ),
                TextSpan(
                  text: value,
                  style: _body(textColorPrimary, 12, FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
