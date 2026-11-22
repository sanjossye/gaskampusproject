import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/map_route_service.dart';
import '../../services/fare_pricing_service.dart';
import '../../services/wallet_service.dart';
import 'service_order_screen.dart';
import 'topup_modal.dart';

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
    serviceType: 'GasRide',
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
    serviceType: 'GasRide',
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
    serviceType: 'GasCar',
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
  final String? initialDestination;
  final VoidCallback onBackToHome;

  const PesananScreen({
    super.key,
    this.openHistorySignal = 0,
    this.openOrderSignal = 0,
    this.initialDestination,
    required this.onBackToHome,
  });

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen>
    with SingleTickerProviderStateMixin {
  int _mainStep = 0;
  late TabController _tabController;

  String _activePickupAddress = 'Lokasi Saya Saat Ini';
  String _activeDestinationAddress = 'Gedung Biro Rektor USU';
  String _activeServiceLabel = 'GasRide';
  String _activeFareLabel = 'Rp 5.000';
  LatLng? _activePickupLatLng;
  LatLng? _activeDestinationLatLng;

  @override
  void initState() {
    super.initState();
    FarePricingService.init();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialDestination != null &&
        widget.initialDestination!.trim().isNotEmpty) {
      _activeDestinationAddress = widget.initialDestination!.trim();
    }
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
    if (widget.initialDestination != oldWidget.initialDestination &&
        widget.initialDestination != null &&
        widget.initialDestination!.trim().isNotEmpty) {
      _activeDestinationAddress = widget.initialDestination!.trim();
    }
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
          initialDestination: widget.initialDestination,
          onFindDriver: (pickup, dest, svc, fare, pickupPos, destPos) {
            setState(() {
              _activePickupAddress = pickup;
              _activeDestinationAddress = dest;
              _activeServiceLabel = svc;
              _activeFareLabel = fare;
              _activePickupLatLng = pickupPos;
              _activeDestinationLatLng = destPos;
              _mainStep = 1;
            });
          },
          onShowHistory: () => setState(() => _mainStep = 2),
        );
      case 1:
        return _ActiveOrderScreen(
          pickupAddress: _activePickupAddress,
          destinationAddress: _activeDestinationAddress,
          serviceLabel: _activeServiceLabel,
          fareLabel: _activeFareLabel,
          initialPickupLatLng: _activePickupLatLng,
          initialDropoffLatLng: _activeDestinationLatLng,
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
  final String? initialDestination;
  final void Function(
    String pickup,
    String destination,
    String serviceLabel,
    String fareLabel,
    LatLng pickupPos,
    LatLng destPos,
  ) onFindDriver;
  final VoidCallback onShowHistory;

  const _FindDriverScreen({
    this.initialDestination,
    required this.onFindDriver,
    required this.onShowHistory,
  });

  @override
  State<_FindDriverScreen> createState() => _FindDriverScreenState();
}

class _FindDriverScreenState extends State<_FindDriverScreen> {
  int _selectedService = 0;
  int _selectedPayment = 0;
  int _walletBalance = 0;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _walletSub;
  StreamSubscription<DriverGpsResult>? _gpsLiveSub;

  final TextEditingController _pickupController = TextEditingController(
    text: 'Mendeteksi lokasi perangkat...',
  );
  final TextEditingController _destinationController = TextEditingController();

  LatLng _devicePos = MapRouteService.lastKnownDriverGps?.position ??
      MapRouteService.defaultKampusCenter;
  LatLng _pickupPos = MapRouteService.lastKnownDriverGps?.position ??
      MapRouteService.defaultKampusCenter;
  String _detectedPickupAddress = '';
  LatLng _destPos = MapRouteService.resolveCoordinate('Gedung Biro Rektor USU');
  LatLng? _customTappedDestPos;
  String _customTappedDestAddress = '';
  double _routeDistanceKm = 1.0;
  int _routeEtaMinutes = 3;
  bool _isRealGps = MapRouteService.lastKnownDriverGps?.isRealDeviceGps ?? false;
  Timer? _routeDebounce;

  static const List<String> _campusQuickLocations = [
    'Biro Rektor USU (Zona A)',
    'Fakultas Teknik USU (Zona B)',
    'Fasilkom-TI USU',
    'Perpustakaan Pusat USU (Zona C)',
    'Pintu 1 USU',
    'Asrama Mahasiswa USU',
    'Kosan Sumber (Zona D)',
    'Stasiun Medan',
    'Plaza Medan Fair',
  ];

  @override
  void initState() {
    super.initState();
    FarePricingService.init();
    FarePricingService.versionNotifier.addListener(_onFareUpdated);
    _listenWalletBalance();
    if (widget.initialDestination != null &&
        widget.initialDestination!.trim().isNotEmpty) {
      _destinationController.text = widget.initialDestination!.trim();
    }
    _destinationController.addListener(_onDestChanged);
    _pickupController.addListener(_onDestChanged);
    _detectDevicePickup(forceResetPickup: true);
    _startLiveGpsListener();
  }

  void _onFareUpdated() {
    if (mounted) setState(() {});
  }

  void _listenWalletBalance() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _walletSub = FirebaseFirestore.instance
        .collection('wallets')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
          if (!mounted) return;
          final bal = (doc.data()?['balance'] as num?)?.toInt() ?? 0;
          setState(() => _walletBalance = bal);
        });
  }

  void _startLiveGpsListener() {
    _gpsLiveSub?.cancel();
    _gpsLiveSub = MapRouteService.watchDriverPosition().listen((liveGps) {
      if (!mounted) return;
      final isUsingCurrentGps =
          _pickupController.text.trim().isEmpty ||
          _pickupController.text.trim() == 'Mendeteksi lokasi perangkat...' ||
          _pickupController.text.trim() == _detectedPickupAddress;
      setState(() {
        _devicePos = liveGps.position;
        _isRealGps = liveGps.isRealDeviceGps;
        if (isUsingCurrentGps) {
          _pickupPos = liveGps.position;
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant _FindDriverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDestination != oldWidget.initialDestination &&
        widget.initialDestination != null &&
        widget.initialDestination!.trim().isNotEmpty) {
      _destinationController.text = widget.initialDestination!.trim();
      _refreshPreviewRoute();
    }
  }

  void _onDestChanged() {
    if (!mounted) return;
    setState(() {});
    _routeDebounce?.cancel();
    _routeDebounce = Timer(
      const Duration(milliseconds: 350),
      _refreshPreviewRoute,
    );
  }

  Future<void> _detectDevicePickup({bool forceResetPickup = false}) async {
    final gps = await MapRouteService.getCurrentDriverPosition(
      campusFallback: MapRouteService.defaultKampusCenter,
    );
    if (!mounted) return;
    setState(() {
      _devicePos = gps.position;
      _pickupPos = gps.position;
      _isRealGps = gps.isRealDeviceGps;
    });

    final street = await MapRouteService.reverseGeocodePosition(gps.position);
    if (!mounted) return;
    _detectedPickupAddress = street;
    if (forceResetPickup ||
        _pickupController.text == 'Mendeteksi lokasi perangkat...' ||
        _pickupController.text.trim().isEmpty) {
      _pickupController.text = street;
    }
    await _refreshPreviewRoute();
  }

  Future<void> _openMapLocationPicker({required bool isPickup}) async {
    FocusScope.of(context).unfocus();
    final initialLatLng = isPickup ? _pickupPos : _destPos;
    final initialAddr = isPickup
        ? (_pickupController.text.trim() == 'Mendeteksi lokasi perangkat...'
              ? _detectedPickupAddress
              : _pickupController.text.trim())
        : _destinationController.text.trim();

    final result = await Navigator.push<_PickedLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => _LocationMapPickerScreen(
          isPickup: isPickup,
          initialPosition: initialLatLng,
          initialAddress: initialAddr,
          deviceGpsPosition: _devicePos,
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      if (isPickup) {
        _pickupPos = result.position;
        _detectedPickupAddress = result.address;
        _pickupController.text = result.address;
      } else {
        _customTappedDestPos = result.position;
        _customTappedDestAddress = result.address;
        _destPos = result.position;
        _destinationController.text = result.address;
      }
    });
    await _refreshPreviewRoute();
  }

  Future<void> _refreshPreviewRoute() async {
    final rawPickup = _pickupController.text.trim();
    LatLng pickupLatLng;
    if (rawPickup.isEmpty ||
        rawPickup == 'Mendeteksi lokasi perangkat...' ||
        rawPickup == _detectedPickupAddress) {
      pickupLatLng = _devicePos;
    } else {
      pickupLatLng = await MapRouteService.searchOrResolveCoordinate(
        rawPickup,
        nearPos: _devicePos,
      );
    }

    final destText = _destinationController.text.trim().isEmpty
        ? 'Gedung Biro Rektor USU'
        : _destinationController.text.trim();
    LatLng dropoffLatLng;
    if (_customTappedDestPos != null && destText == _customTappedDestAddress) {
      dropoffLatLng = _customTappedDestPos!;
    } else {
      dropoffLatLng = await MapRouteService.searchOrResolveCoordinate(
        destText,
        nearPos: pickupLatLng,
      );
    }

    final route = await MapRouteService.fetchRoadRoute(
      pickupLatLng,
      dropoffLatLng,
    );
    if (!mounted) return;
    setState(() {
      _pickupPos = pickupLatLng;
      _destPos = dropoffLatLng;
      _routeDistanceKm = route.distanceKm;
      _routeEtaMinutes = route.durationMinutes;
    });
  }

  @override
  void dispose() {
    FarePricingService.versionNotifier.removeListener(_onFareUpdated);
    _walletSub?.cancel();
    _gpsLiveSub?.cancel();
    _routeDebounce?.cancel();
    _destinationController.removeListener(_onDestChanged);
    _pickupController.removeListener(_onDestChanged);
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _handleFindDriver() async {
    final rawPickup = _pickupController.text.trim();
    final pickup = (rawPickup.isEmpty ||
            rawPickup == 'Mendeteksi lokasi perangkat...')
        ? (_detectedPickupAddress.isNotEmpty
            ? _detectedPickupAddress
            : 'Lokasi Saya Saat Ini (${_pickupPos.latitude.toStringAsFixed(4)}, ${_pickupPos.longitude.toStringAsFixed(4)})')
        : rawPickup;
    final dest = _destinationController.text.trim().isEmpty
        ? 'Gedung Biro Rektor USU'
        : _destinationController.text.trim();
    final svcLabel = _services[_selectedService]['label'] as String;

    // Hitung tarif resmi dinamis sesuai ketetapan Admin
    final int dynamicFare = _selectedService == 1
        ? FarePricingService.calculateCarFare(_routeDistanceKm)
        : FarePricingService.calculateMotorFare(_routeDistanceKm);
    final String fareStr = FarePricingService.formatRupiah(dynamicFare);

    // Validasi saldo jika memilih pembayaran GasPay
    if (_selectedPayment == 0 && _walletBalance < dynamicFare) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo GasPay kamu (Rp ${WalletService.formatRupiah(_walletBalance)}) belum cukup untuk tarif $fareStr. Silakan Top Up terlebih dahulu.',
          ),
          backgroundColor: Colors.redAccent,
          action: SnackBarAction(
            label: 'Top Up',
            textColor: kPrimary,
            onPressed: () => showTopUpModal(context),
          ),
        ),
      );
      return;
    }

    final now = DateTime.now();
    String docId = 'ride_${now.millisecondsSinceEpoch}';
    final paymentCode = _selectedPayment == 0
        ? 'GasPay'
        : (_selectedPayment == 1 ? 'QRIS' : 'Tunai');

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
              'fareAmount': dynamicFare,
              'distanceKm': _routeDistanceKm,
              'paymentMethod': paymentCode,
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
      widget.onFindDriver(pickup, dest, svcLabel, fareStr, _pickupPos, _destPos);
    }
  }

  static const _services = [
    {
      'label': 'GasRide',
      'icon': Icons.motorcycle_rounded,
      'time': '3-5',
    },
    {
      'label': 'GasCar',
      'icon': Icons.directions_car_rounded,
      'time': '5-7',
    },
    {
      'label': 'Lainnya',
      'icon': Icons.more_horiz_rounded,
      'time': '3-5',
    },
  ];

  List<Map<String, dynamic>> get _paymentMethods => [
    {
      'label': 'GasPay',
      'sub': 'Saldo: Rp ${WalletService.formatRupiah(_walletBalance)}',
      'icon': Icons.account_balance_wallet_rounded,
      'color': const Color(0xFF2B6CB0),
    },
    {
      'label': 'QRIS',
      'sub': 'Scan & Pay',
      'icon': Icons.qr_code_scanner_rounded,
      'color': const Color(0xFF7C3AED),
    },
    {
      'label': 'Tunai',
      'sub': 'Bayar di tempat',
      'icon': Icons.payments_rounded,
      'color': const Color(0xFF059669),
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
                          'LOKASI JEMPUT',
                          style: _body(
                            textColorSecondary,
                            11.5,
                            FontWeight.w700,
                            ls: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _locationField(
                          icon: Icons.my_location_rounded,
                          iconColor: kPrimary,
                          hint: 'Pilih lokasi penjemputan...',
                          controller: _pickupController,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          textColorPrimary: textColorPrimary,
                          textColorSecondary: textColorSecondary,
                          onTapMapPicker: () =>
                              _openMapLocationPicker(isPickup: true),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'TITIK PENGANTARAN',
                          style: _body(
                            textColorSecondary,
                            11.5,
                            FontWeight.w700,
                            ls: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _locationField(
                          icon: Icons.flag_rounded,
                          iconColor: Colors.deepOrange,
                          hint: 'Pilih titik pengantaran...',
                          controller: _destinationController,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          textColorPrimary: textColorPrimary,
                          textColorSecondary: textColorSecondary,
                          onTapMapPicker: () =>
                              _openMapLocationPicker(isPickup: false),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isRealGps
                                    ? Icons.gps_fixed
                                    : Icons.route_rounded,
                                size: 15,
                                color: isDark ? kPrimary : kBgDark,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Estimasi Jarak: ${_routeDistanceKm.toStringAsFixed(1)} km (~$_routeEtaMinutes mnt)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? kPrimary : kBgDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Pilihan Cepat Lokasi Kampus USU & Medan
                        Text(
                          'PILIH CEPAT TITIK KAMPUS USU & MEDAN',
                          style: _body(
                            textColorSecondary,
                            11,
                            FontWeight.w700,
                            ls: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _campusQuickLocations.map((loc) {
                            final isCurrent =
                                _destinationController.text.trim() == loc;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _customTappedDestPos = null;
                                  _customTappedDestAddress = '';
                                  _destinationController.text = loc;
                                });
                                _refreshPreviewRoute();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrent ? kPrimary : inputBg,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: isCurrent ? kPrimary : borderColor,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.place_rounded,
                                      size: 13,
                                      color: isCurrent
                                          ? Colors.black
                                          : kSecondaryGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      loc,
                                      style: TextStyle(
                                        color: isCurrent
                                            ? Colors.black
                                            : textColorPrimary,
                                        fontSize: 11.5,
                                        fontWeight: isCurrent
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
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

                // ── Fare + Time strip (Sinkron Tarif Admin Real-Time) ──
                ValueListenableBuilder<int>(
                  valueListenable: FarePricingService.versionNotifier,
                  builder: (context, _, _) {
                    final int dynamicFare = _selectedService == 1
                        ? FarePricingService.calculateCarFare(_routeDistanceKm)
                        : FarePricingService.calculateMotorFare(_routeDistanceKm);
                    final String displayFare =
                        FarePricingService.formatRupiah(dynamicFare);
                    final int oneKmRate =
                        FarePricingService.effectiveOneKmPrice;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            color: kPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            displayFare,
                            style: _body(textColorPrimary, 16, FontWeight.bold),
                          ),
                          Container(
                            width: 1,
                            height: 18,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            color: borderColor,
                          ),
                          Icon(
                            Icons.route_rounded,
                            color: textColorSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${_routeDistanceKm.toStringAsFixed(1)} km',
                            style: _body(
                              textColorSecondary,
                              12.5,
                              FontWeight.w600,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 18,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            color: borderColor,
                          ),
                          Expanded(
                            child: Text(
                              'Tarif Admin (1 km = ${FarePricingService.formatRupiah(oneKmRate)})',
                              style: _body(
                                kSecondaryGreen,
                                11.5,
                                FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
    required VoidCallback onTapMapPicker,
  }) {
    return GestureDetector(
      onTap: onTapMapPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
                readOnly: true,
                onTap: onTapMapPicker,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: _body(textColorSecondary, 14, FontWeight.w500),
                ),
                style: _body(textColorPrimary, 14, FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.map_outlined,
                    size: 14,
                    color: Color(0xFF0F172A),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Peta',
                    style: _body(
                      const Color(0xFF0F172A),
                      11,
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickedLocationResult {
  final LatLng position;
  final String address;
  const _PickedLocationResult({
    required this.position,
    required this.address,
  });
}

/// Layar Full-Screen Map Picker (sesuai gambar referensi user)
/// Muncul saat "Lokasi Jemput" atau "Titik Pengantaran" dipencet.
class _LocationMapPickerScreen extends StatefulWidget {
  final bool isPickup;
  final LatLng initialPosition;
  final String initialAddress;
  final LatLng deviceGpsPosition;

  const _LocationMapPickerScreen({
    required this.isPickup,
    required this.initialPosition,
    required this.initialAddress,
    required this.deviceGpsPosition,
  });

  @override
  State<_LocationMapPickerScreen> createState() =>
      _LocationMapPickerScreenState();
}

class _LocationMapPickerScreenState extends State<_LocationMapPickerScreen> {
  final MapController _mapController = MapController();
  late final TextEditingController _searchController;

  late LatLng _selectedPos;
  String _placeTitle = 'Memuat lokasi...';
  String _streetSubtitle = 'Kawasan Kampus USU, Padang Bulan, Medan';
  bool _isGeocoding = false;
  bool _showSuggestions = false;
  Timer? _geocodeDebounce;

  static const List<Map<String, dynamic>> _presetPlaces = [
    {
      'title': 'Fasilkom-TI & Fak. Kedokteran USU',
      'sub': 'Jl. Universitas No. 9, Kampus USU Medan',
      'pos': LatLng(3.5620, 98.6592),
    },
    {
      'title': 'Perpustakaan Pusat & Fak. Teknik USU',
      'sub': 'Jl. Perpustakaan No. 1, Kampus USU',
      'pos': LatLng(3.5635, 98.6580),
    },
    {
      'title': 'Politeknik Negeri Medan (Polmed)',
      'sub': 'Jl. Almamater No. 1, Kampus USU Medan',
      'pos': LatLng(3.5650, 98.6545),
    },
    {
      'title': 'FMIPA & Teknik Elektro/Mesin USU',
      'sub': 'Jl. Bioteknologi No. 1, Kampus USU',
      'pos': LatLng(3.5610, 98.6545),
    },
    {
      'title': 'Fakultas Vokasi & Pertanian USU',
      'sub': 'Jl. Prof. A. Sofian No. 3, Kampus USU',
      'pos': LatLng(3.5575, 98.6545),
    },
    {
      'title': 'FISIP & Fak. Ekonomi dan Bisnis USU',
      'sub': 'Jl. Dr. T. Mansur, Kampus USU Padang Bulan',
      'pos': LatLng(3.5575, 98.6580),
    },
    {
      'title': 'Biro Rektor & Gerbang Pintu 1 USU',
      'sub': 'Jl. Dr. T. Mansur No. 9, Padang Bulan, Medan',
      'pos': LatLng(3.5655, 98.6565),
    },
    {
      'title': 'Kosan Sumber & Jl. Berdikari',
      'sub': 'Jalan Berdikari, Padang Bulan, Medan',
      'pos': LatLng(3.5502, 98.6488),
    },
    {
      'title': 'Stasiun Medan',
      'sub': 'Jl. Stasiun Kereta Api, Kesawan, Medan Barat',
      'pos': LatLng(3.5912, 98.6775),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedPos = widget.initialPosition;
    _searchController = TextEditingController(text: widget.initialAddress);
    if (widget.initialAddress.trim().isNotEmpty) {
      _parseTitleAndSub(widget.initialAddress.trim());
    } else {
      _reverseGeocode(_selectedPos);
    }
  }

  void _parseTitleAndSub(String fullAddress) {
    final parts = fullAddress.split(',');
    if (parts.length >= 2) {
      _placeTitle = parts.first.trim();
      _streetSubtitle = parts.sublist(1).join(',').trim();
    } else {
      _placeTitle = fullAddress;
      _streetSubtitle =
          '${_selectedPos.latitude.toStringAsFixed(4)}, ${_selectedPos.longitude.toStringAsFixed(4)} · Padang Bulan, Medan';
    }
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _isGeocoding = true);
    final addr = await MapRouteService.reverseGeocodePosition(pos);
    if (!mounted) return;
    setState(() {
      _isGeocoding = false;
      _parseTitleAndSub(addr);
      _searchController.text = addr;
    });
  }

  void _moveSelectionTo(LatLng pos, {String? knownTitle, String? knownSub}) {
    setState(() {
      _selectedPos = pos;
      _showSuggestions = false;
      if (knownTitle != null) {
        _placeTitle = knownTitle;
        _streetSubtitle = knownSub ?? 'Padang Bulan, Medan';
        _searchController.text = knownTitle;
      }
    });
    try {
      _mapController.move(pos, 16.2);
    } catch (_) {}

    if (knownTitle == null) {
      _geocodeDebounce?.cancel();
      _geocodeDebounce = Timer(
        const Duration(milliseconds: 300),
        () => _reverseGeocode(pos),
      );
    }
  }

  Future<void> _useCurrentDeviceGps() async {
    setState(() => _isGeocoding = true);
    final gps = await MapRouteService.getCurrentDriverPosition(
      campusFallback: widget.deviceGpsPosition,
    );
    if (!mounted) return;
    _moveSelectionTo(gps.position);
  }

  Future<void> _onSearchSubmitted(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() {
      _isGeocoding = true;
      _showSuggestions = false;
    });
    final pos = await MapRouteService.searchOrResolveCoordinate(
      q,
      nearPos: _selectedPos,
    );
    if (!mounted) return;
    setState(() {
      _selectedPos = pos;
      _isGeocoding = false;
      _parseTitleAndSub(q);
    });
    try {
      _mapController.move(pos, 16.2);
    } catch (_) {}
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredPresets = query.isEmpty
        ? _presetPlaces
        : _presetPlaces.where((p) {
            final t = (p['title'] as String).toLowerCase();
            final s = (p['sub'] as String).toLowerCase();
            return t.contains(query) || s.contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF14181C),
      body: Stack(
        children: [
          // ── 1. Full-Screen Interactive Map ──
          Positioned.fill(
            child: GasKampusLiveMap(
              mapController: _mapController,
              mapStyle: GasMapStyle.street,
              initialCenter: _selectedPos,
              initialZoom: 16.0,
              onTap: (_, latLng) {
                FocusScope.of(context).unfocus();
                _moveSelectionTo(latLng);
              },
              markers: [
                // Marker Titik Terpilih (gaya Pin seperti gambar referensi)
                Marker(
                  point: _selectedPos,
                  width: 64,
                  height: 76,
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF67A3D9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Top Search Bar (Mirip Gambar Referensi) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF21262D).withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          onTap: () => setState(() => _showSuggestions = true),
                          onChanged: (_) =>
                              setState(() => _showSuggestions = true),
                          onSubmitted: _onSearchSubmitted,
                          decoration: InputDecoration(
                            hintText: widget.isPickup
                                ? 'Masukkan alamat untuk penjemputan...'
                                : 'Masukkan alamat untuk pengantaran...',
                            hintStyle: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14.5,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _showSuggestions = true;
                            });
                          },
                        )
                      else
                        IconButton(
                          icon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF67A3D9),
                            size: 22,
                          ),
                          onPressed: () =>
                              _onSearchSubmitted(_searchController.text),
                        ),
                    ],
                  ),
                ),

                // Daftar Saran Alamat Saat Mengetik / Memilih
                if (_showSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 230),
                    decoration: BoxDecoration(
                      color: const Color(0xFF21262D).withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      children: [
                        ListTile(
                          dense: true,
                          leading: const CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFF16A34A),
                            child: Icon(
                              Icons.my_location_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          title: const Text(
                            'Gunakan Lokasi Saya Saat Ini (GPS)',
                            style: TextStyle(
                              color: kPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: const Text(
                            'Deteksi otomatis posisi perangkat saat ini',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11.5,
                            ),
                          ),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            _useCurrentDeviceGps();
                          },
                        ),
                        const Divider(color: Colors.white12, height: 1),
                        ...filteredPresets.map((item) {
                          return ListTile(
                            dense: true,
                            leading: const CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(0xFF30363D),
                              child: Icon(
                                Icons.place_rounded,
                                color: Color(0xFF67A3D9),
                                size: 16,
                              ),
                            ),
                            title: Text(
                              item['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              item['sub'] as String,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              _moveSelectionTo(
                                item['pos'] as LatLng,
                                knownTitle: item['title'] as String,
                                knownSub: item['sub'] as String,
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── 3. Floating Right Buttons (+ , - , GPS) ──
          Positioned(
            right: 16,
            bottom: 245,
            child: Column(
              children: [
                _roundControlBtn(
                  icon: Icons.add_rounded,
                  onTap: () {
                    final z = (_mapController.camera.zoom + 1.0).clamp(
                      11.0,
                      19.0,
                    );
                    _mapController.move(_mapController.camera.center, z);
                  },
                ),
                const SizedBox(height: 10),
                _roundControlBtn(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    final z = (_mapController.camera.zoom - 1.0).clamp(
                      11.0,
                      19.0,
                    );
                    _mapController.move(_mapController.camera.center, z);
                  },
                ),
                const SizedBox(height: 10),
                _roundControlBtn(
                  icon: Icons.near_me_rounded,
                  iconColor: const Color(0xFF67A3D9),
                  onTap: _useCurrentDeviceGps,
                ),
              ],
            ),
          ),

          // ── 4. Bottom Sheet Card (Mirip Gambar Referensi: Judul + Alamat + Tombol Selesai) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                22,
                22,
                22,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF21262D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 20,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isPickup ? 'Lokasi Jemput' : 'Tujuan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _useCurrentDeviceGps,
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimary,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.my_location_rounded, size: 15),
                        label: const Text(
                          'Lokasi Saat Ini',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF67A3D9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isPickup
                              ? Icons.my_location_rounded
                              : Icons.flag_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _isGeocoding
                            ? const Text(
                                'Mendeteksi nama jalan...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _placeTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _streetSubtitle,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        final finalAddr = _placeTitle.trim().isNotEmpty
                            ? _placeTitle.trim()
                            : 'Titik Peta (${_selectedPos.latitude.toStringAsFixed(4)}, ${_selectedPos.longitude.toStringAsFixed(4)})';
                        Navigator.pop(
                          context,
                          _PickedLocationResult(
                            position: _selectedPos,
                            address: finalAddr,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFACC15),
                        foregroundColor: const Color(0xFF0F172A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      child: const Text(
                        'Selesai',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundControlBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white70,
  }) {
    return Material(
      color: const Color(0xFF2D333B).withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}

class _ActiveOrderScreen extends StatefulWidget {
  final String pickupAddress;
  final String destinationAddress;
  final String serviceLabel;
  final String fareLabel;
  final LatLng? initialPickupLatLng;
  final LatLng? initialDropoffLatLng;
  final VoidCallback onBack;
  final VoidCallback onShowHistory;

  const _ActiveOrderScreen({
    this.pickupAddress = 'Fakultas Teknik USU',
    this.destinationAddress = 'Gedung Biro Rektor USU',
    this.serviceLabel = 'GasRide',
    this.fareLabel = 'Rp 5.000',
    this.initialPickupLatLng,
    this.initialDropoffLatLng,
    required this.onBack,
    required this.onShowHistory,
  });

  @override
  State<_ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<_ActiveOrderScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late LatLng _pickupLatLng;
  late LatLng _dropoffLatLng;
  late LatLng _driverLatLng;
  double _driverHeading = 0.0;

  GasMapStyle _mapStyle = GasMapStyle.street;
  List<LatLng> _routePoints = [];
  List<LatLng> _simulationPath = [];
  int _simulationIndex = 0;

  bool _isMapReady = false;
  bool _isSimulating = false;
  bool _hasArrived = false;
  double _distanceKm = 0.8;
  int _etaMinutes = 3;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _pickupLatLng =
        widget.initialPickupLatLng ??
        MapRouteService.lastKnownDriverGps?.position ??
        MapRouteService.resolveCoordinate(widget.pickupAddress);
    _dropoffLatLng =
        widget.initialDropoffLatLng ??
        MapRouteService.resolveCoordinate(widget.destinationAddress);
    _driverLatLng = _pickupLatLng;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initUserLocationAndRoute();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showDriverOtwBottomSheet();
      }
    });
  }

  void _showDriverOtwBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1A2210) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0F172A);
    final ts = isDark ? Colors.white70 : const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(ctx).padding.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.two_wheeler_rounded,
                  color: Color(0xFF0F172A),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Driver Sudah Ditemukan!',
                textAlign: TextAlign.center,
                style: _body(tp, 20, FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Tunggu sebentar ya, driver lagi OTW ke lokasi penjemputan kamu!',
                textAlign: TextAlign.center,
                style: _body(ts, 14, FontWeight.w500, h: 1.4),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF232A18)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_rounded, color: tp, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budi Santoso • 4.9 ★',
                            style: _body(tp, 14.5, FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Honda Vario 125 • BK 1234 GKS',
                            style: _body(ts, 12, FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        widget.fareLabel,
                        style: _body(
                          const Color(0xFF0F172A),
                          12,
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (!_isSimulating) {
                      _toggleSimulation();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  child: const Text(
                    'Oke, Pantau Posisi Driver',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _initUserLocationAndRoute() async {
    if (widget.initialPickupLatLng == null) {
      final gps = await MapRouteService.getCurrentDriverPosition(
        campusFallback: MapRouteService.resolveCoordinate(widget.pickupAddress),
      );
      if (!mounted) return;
      _pickupLatLng = gps.position;
    }
    if (widget.initialDropoffLatLng == null) {
      final resolvedDest = await MapRouteService.searchOrResolveCoordinate(
        widget.destinationAddress,
        nearPos: _pickupLatLng,
      );
      if (!mounted) return;
      _dropoffLatLng = resolvedDest;
    }
    setState(() {});
    await _loadRoute();
  }

  Future<void> _loadRoute() async {
    final res = await MapRouteService.fetchRoadRoute(
      _pickupLatLng,
      _dropoffLatLng,
    );
    if (!mounted) return;
    final densified = MapRouteService.densifyRoutePoints(res.points);
    final startDriver = densified.isNotEmpty ? densified.first : _pickupLatLng;
    final nextPoint = densified.length > 1 ? densified[1] : _dropoffLatLng;

    setState(() {
      _routePoints = res.points;
      _simulationPath = densified;
      _simulationIndex = 0;
      _driverLatLng = startDriver;
      _driverHeading = MapRouteService.calculateBearingDegrees(
        startDriver,
        nextPoint,
      );
      _distanceKm = res.distanceKm;
      _etaMinutes = res.durationMinutes;
    });
    _fitBounds();
  }

  void _toggleSimulation() {
    if (_isSimulating) {
      _simulationTimer?.cancel();
      setState(() => _isSimulating = false);
      return;
    }

    if (_simulationPath.length < 2) return;
    if (_simulationIndex >= _simulationPath.length - 1) {
      _simulationIndex = 0;
      _hasArrived = false;
    }

    setState(() => _isSimulating = true);
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      if (_simulationIndex >= _simulationPath.length - 1) {
        _simulationTimer?.cancel();
        setState(() {
          _isSimulating = false;
          _hasArrived = true;
          _distanceKm = 0.0;
          _etaMinutes = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Driver telah tiba di tujuan: ${widget.destinationAddress}!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final current = _simulationPath[_simulationIndex];
      final next = _simulationPath[_simulationIndex + 1];
      final bearing = MapRouteService.calculateBearingDegrees(current, next);
      final remainingMeters = MapRouteService.distanceInMeters(
        next,
        _dropoffLatLng,
      );
      final remainingKm = math.max(0.0, remainingMeters / 1000.0);
      final remainingEta = remainingKm <= 0.05
          ? 0
          : math.max(1, ((remainingKm / 24.0) * 60.0).ceil());

      setState(() {
        _simulationIndex++;
        _driverLatLng = next;
        _driverHeading = bearing;
        _distanceKm = remainingKm;
        _etaMinutes = remainingEta;
      });

      if (_isMapReady) {
        final targetZoom = math.max(_mapController.camera.zoom, 15.4);
        _mapController.move(next, targetZoom);
      }
    });
  }

  void _cycleMapStyle() {
    const styles = GasMapStyle.values;
    final nextIdx = (styles.indexOf(_mapStyle) + 1) % styles.length;
    setState(() => _mapStyle = styles[nextIdx]);
  }

  void _fitBounds() {
    if (!_isMapReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isMapReady) return;
      try {
        final bounds = LatLngBounds.fromPoints([
          _pickupLatLng,
          _dropoffLatLng,
          _driverLatLng,
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
    _simulationTimer?.cancel();
    _pulseController.dispose();
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

    final remainingRoute = _isSimulating && _simulationIndex > 0
        ? _simulationPath.sublist(
            math.min(_simulationIndex, _simulationPath.length - 1),
          )
        : _routePoints;

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GasKampusLiveMap(
                mapController: _mapController,
                mapStyle: _mapStyle,
                initialCenter: _pickupLatLng,
                initialZoom: 15.4,
                onMapReady: () {
                  _isMapReady = true;
                  _fitBounds();
                },
                polylines: [
                  if (remainingRoute.length >= 2)
                    Polyline(
                      points: remainingRoute,
                      color: kPrimary,
                      strokeWidth: 6.0,
                      borderStrokeWidth: 2.0,
                      borderColor: kBgDark,
                    ),
                ],
                markers: [
                  MapRouteService.buildPlacePinMarker(
                    point: _pickupLatLng,
                    label: 'Jemput · ${widget.pickupAddress}',
                    color: kSecondaryGreen,
                    icon: Icons.person_pin_circle_rounded,
                  ),
                  MapRouteService.buildPlacePinMarker(
                    point: _dropoffLatLng,
                    label: 'Tujuan · ${widget.destinationAddress}',
                    color: Colors.redAccent,
                    icon: Icons.flag_rounded,
                  ),
                  MapRouteService.buildDriverMotorMarker(
                    point: _driverLatLng,
                    headingDegrees: _driverHeading,
                    pulseAnimation: _pulseAnimation,
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
                      (isDark ? Colors.black : Colors.white).withOpacity(0.82),
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
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF181E10)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _hasArrived
                                    ? Icons.check_circle_rounded
                                    : Icons.navigation_rounded,
                                color: _hasArrived ? Colors.green : kPrimary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _hasArrived
                                      ? 'Sampai di Tujuan'
                                      : '${widget.serviceLabel} · ${_distanceKm.toStringAsFixed(1)} km',
                                  style: _body(
                                    textColorPrimary,
                                    13,
                                    FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
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

            // Kontrol Peta + Bottom Sheet Info Card
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 12),
                    child: GasKampusMapControls(
                      currentStyle: _mapStyle,
                      isSimulating: _isSimulating,
                      onToggleSimulation: _toggleSimulation,
                      onCycleStyle: _cycleMapStyle,
                      onFitRoute: _fitBounds,
                      onZoomIn: () {
                        if (!_isMapReady) return;
                        _mapController.move(
                          _mapController.camera.center,
                          math.min(19.0, _mapController.camera.zoom + 1.0),
                        );
                      },
                      onZoomOut: () {
                        if (!_isMapReady) return;
                        _mapController.move(
                          _mapController.camera.center,
                          math.max(11.0, _mapController.camera.zoom - 1.0),
                        );
                      },
                    ),
                  ),
                  Container(
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
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _hasArrived
                                              ? 'Perjalanan telah selesai!'
                                              : (_isSimulating
                                                    ? 'Driver sedang mengantar ke tujuan'
                                                    : 'Driver sedang menuju lokasimu'),
                                          style: _body(
                                            textColorPrimary,
                                            17,
                                            FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${widget.pickupAddress} → ${widget.destinationAddress}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: _body(
                                            textColorSecondary,
                                            12.5,
                                            FontWeight.w500,
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
                                      _hasArrived
                                          ? 'Tiba'
                                          : '$_etaMinutes Menit',
                                      style: _body(
                                        textColorPrimary,
                                        13,
                                        FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF232A18)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 52,
                                      height: 52,
                                      child: Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: kPrimary.withOpacity(0.18),
                                              border: Border.all(
                                                color: cardColor,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.person_rounded,
                                                color: Colors.black87,
                                                size: 28,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Budi Santoso',
                                                style: _body(
                                                  textColorPrimary,
                                                  15,
                                                  FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '• 4.9',
                                                style: _body(
                                                  textColorPrimary,
                                                  13,
                                                  FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'BK 1234 GKS · ${widget.fareLabel}',
                                            style: TextStyle(
                                              color: textColorSecondary,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        MapRouteService
                                            .openGoogleMapsNavigation(
                                              origin: _pickupLatLng,
                                              destination: _dropoffLatLng,
                                            );
                                      },
                                      child: _actionBtn(
                                        Icons.directions_rounded,
                                        kSecondaryGreen,
                                        isDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: _toggleSimulation,
                                      borderRadius: BorderRadius.circular(99),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: kPrimary,
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _isSimulating
                                                  ? Icons.pause_rounded
                                                  : Icons.two_wheeler_rounded,
                                              color: Colors.black87,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _isSimulating
                                                  ? 'Jeda Simulasi Motor'
                                                  : 'Jalankan Simulasi Motor',
                                              style: _body(
                                                Colors.black87,
                                                14,
                                                FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).padding.bottom + 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    priceLabel: loc.price,
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
  final String priceLabel;
  final DateTime createdAt;

  const _ServiceOrderData({
    required this.id,
    required this.serviceType,
    required this.items,
    required this.originAddress,
    required this.destinationAddress,
    required this.note,
    required this.status,
    this.priceLabel = '',
    required this.createdAt,
  });

  factory _ServiceOrderData.fromMap(String id, Map<String, dynamic> data) {
    final fareNum = (data['fareAmount'] as num?)?.toInt();
    final distNum = (data['distanceKm'] as num?)?.toDouble() ?? 1.0;
    final computedFare =
        fareNum ?? FarePricingService.calculateMotorFare(distNum);
    return _ServiceOrderData(
      id: id,
      serviceType: (data['serviceType'] ?? '').toString(),
      items: (data['items'] ?? '').toString(),
      originAddress: (data['originAddress'] ?? '').toString(),
      destinationAddress: (data['destinationAddress'] ?? '').toString(),
      note: (data['note'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      priceLabel: FarePricingService.formatRupiah(computedFare),
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
          if (order.priceLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            _detailRow(Icons.payments_outlined, 'Tarif', order.priceLabel),
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
