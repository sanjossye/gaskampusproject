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
import '../../widgets/gas_faces.dart';
import '../payment_success_screen.dart';
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
  final DateTime createdAt;

  const OrderItem({
    required this.driverName,
    required this.driverPhoto,
    required this.serviceType,
    required this.dateLabel,
    required this.from,
    required this.to,
    required this.price,
    required this.status,
    required this.createdAt,
  });
}

final List<OrderItem> _allOrders = [
  OrderItem(
    driverName: 'Siti Aminah',
    driverPhoto:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
    serviceType: 'GasRide',
    dateLabel: 'Hari ini, 09:12',
    from: 'Asrama Mahasiswa USU',
    to: 'Gedung Biro Rektor USU',
    price: 'Rp 10.000',
    status: 'proses',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  OrderItem(
    driverName: 'Budi Santoso',
    driverPhoto:
        'https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
    serviceType: 'GasRide',
    dateLabel: 'Kemarin, 10:30',
    from: 'Pintu 1 USU (Jl. Dr. Mansyur)',
    to: 'Kantin Vokasi USU',
    price: 'Rp 12.000',
    status: 'selesai',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  OrderItem(
    driverName: 'Andi Wijaya',
    driverPhoto:
        'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
    serviceType: 'GasCar',
    dateLabel: '2 hari lalu, 15:45',
    from: 'Fakultas Teknik USU',
    to: 'Stasiun Medan',
    price: 'Rp 25.000',
    status: 'selesai',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
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
  int _activeFareAmount = 5000;
  String _activePaymentMethod = 'GasPay';
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
          onFindDriver: (
            pickup,
            dest,
            svc,
            fare,
            fareAmount,
            paymentMethod,
            pickupPos,
            destPos,
          ) {
            setState(() {
              _activePickupAddress = pickup;
              _activeDestinationAddress = dest;
              _activeServiceLabel = svc;
              _activeFareLabel = fare;
              _activeFareAmount = fareAmount;
              _activePaymentMethod = paymentMethod;
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
          fareAmount: _activeFareAmount,
          paymentMethod: _activePaymentMethod,
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
    int fareAmount,
    String paymentMethod,
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

  // State untuk Opsi Lainnya (Catatan, Voucher, Penumpang Lain, Jadwal)
  String _driverNote = '';
  String? _selectedVoucherTitle;
  int _voucherDiscount = 0;
  String? _otherPassengerInfo;
  String? _scheduledTimeLabel;

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

    // Hitung tarif resmi dinamis sesuai ketetapan Admin (dikurangi voucher jika aktif)
    final int baseFare = _selectedService == 1
        ? FarePricingService.calculateCarFare(_routeDistanceKm)
        : FarePricingService.calculateMotorFare(_routeDistanceKm);
    final int dynamicFare = math.max(1000, baseFare - _voucherDiscount);
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

    final List<String> noteParts = [];
    if (_driverNote.trim().isNotEmpty) {
      noteParts.add('Catatan: ${_driverNote.trim()}');
    }
    if (_selectedVoucherTitle != null) {
      noteParts.add('Voucher: $_selectedVoucherTitle (-Rp ${WalletService.formatRupiah(_voucherDiscount)})');
    }
    if (_otherPassengerInfo != null && _otherPassengerInfo!.trim().isNotEmpty) {
      noteParts.add('Penumpang: ${_otherPassengerInfo!.trim()}');
    }
    if (_scheduledTimeLabel != null && _scheduledTimeLabel!.trim().isNotEmpty) {
      noteParts.add('Jadwal: ${_scheduledTimeLabel!.trim()}');
    }
    final String combinedNote = noteParts.join(' • ');

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
              'note': combinedNote,
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
        note: combinedNote,
        status: 'pending',
        price: fareStr,
        createdAt: now,
      ),
    );
    AppNotificationStore.add(
      title: 'Mencari driver ($svcLabel)',
      message: 'Pesananmu dari $pickup ke $dest ($fareStr) sedang dicarikan driver.',
      icon: Icons.search_rounded,
      color: const Color(0xFF64748B),
    );

    if (mounted) {
      widget.onFindDriver(
        pickup,
        dest,
        svcLabel,
        fareStr,
        dynamicFare,
        paymentCode,
        _pickupPos,
        _destPos,
      );
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
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(sheetCtx).padding.bottom + 24,
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
                subtitle: _driverNote.isNotEmpty
                    ? _driverNote
                    : 'Tambahkan instruksi khusus',
                isActive: _driverNote.isNotEmpty,
                isDark: isDark,
                textColorPrimary: textColorPrimary,
                textColorSecondary: textColorSecondary,
                borderColor: borderColor,
                onTap: () => _openNoteDialog(
                  sheetCtx,
                  setSheet,
                  isDark,
                  textColorPrimary,
                  textColorSecondary,
                  cardBg,
                  borderColor,
                ),
              ),
              const SizedBox(height: 10),
              _lainnyaItem(
                icon: Icons.discount_outlined,
                iconColor: const Color(0xFFE53E3E),
                title: 'Gunakan Voucher',
                subtitle: _selectedVoucherTitle != null
                    ? '$_selectedVoucherTitle (-Rp ${WalletService.formatRupiah(_voucherDiscount)})'
                    : 'Hemat lebih banyak',
                isActive: _selectedVoucherTitle != null,
                isDark: isDark,
                textColorPrimary: textColorPrimary,
                textColorSecondary: textColorSecondary,
                borderColor: borderColor,
                onTap: () => _openVoucherSheet(
                  sheetCtx,
                  setSheet,
                  isDark,
                  textColorPrimary,
                  textColorSecondary,
                  cardBg,
                  borderColor,
                ),
              ),
              const SizedBox(height: 10),
              _lainnyaItem(
                icon: Icons.group_outlined,
                iconColor: const Color(0xFF7C3AED),
                title: 'Pesan untuk Orang Lain',
                subtitle: _otherPassengerInfo != null
                    ? 'Penumpang: $_otherPassengerInfo'
                    : 'Kirim pesanan ke kontak',
                isActive: _otherPassengerInfo != null,
                isDark: isDark,
                textColorPrimary: textColorPrimary,
                textColorSecondary: textColorSecondary,
                borderColor: borderColor,
                onTap: () => _openOtherPassengerDialog(
                  sheetCtx,
                  setSheet,
                  isDark,
                  textColorPrimary,
                  textColorSecondary,
                  cardBg,
                  borderColor,
                ),
              ),
              const SizedBox(height: 10),
              _lainnyaItem(
                icon: Icons.schedule_rounded,
                iconColor: const Color(0xFF059669),
                title: 'Jadwalkan Perjalanan',
                subtitle: _scheduledTimeLabel != null
                    ? 'Penjemputan: $_scheduledTimeLabel'
                    : 'Atur waktu penjemputan',
                isActive: _scheduledTimeLabel != null,
                isDark: isDark,
                textColorPrimary: textColorPrimary,
                textColorSecondary: textColorSecondary,
                borderColor: borderColor,
                onTap: () => _openScheduleSheet(
                  sheetCtx,
                  setSheet,
                  isDark,
                  textColorPrimary,
                  textColorSecondary,
                  cardBg,
                  borderColor,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _openNoteDialog(
    BuildContext sheetCtx,
    StateSetter setSheet,
    bool isDark,
    Color tp,
    Color ts,
    Color cardBg,
    Color borderColor,
  ) {
    final noteCtrl = TextEditingController(text: _driverNote);
    const quickNotes = [
      'Tunggu di depan gerbang utama',
      'Saya pakai jaket/kemeja hijau',
      'Titik jemput sesuai pin peta',
      'Hubungi saya jika sudah dekat',
    ];

    showDialog(
      context: sheetCtx,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Catatan untuk Driver',
          style: _body(tp, 17, FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                style: _body(tp, 14, FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Contoh: Tunggu di dekat pos satpam...',
                  hintStyle: _body(ts, 13, FontWeight.normal),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF232A18)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pilih Cepat:',
                style: _body(ts, 11.5, FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: quickNotes.map((qn) {
                  return InkWell(
                    onTap: () => noteCtrl.text = qn,
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        qn,
                        style: _body(tp, 11, FontWeight.w600),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          if (_driverNote.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() => _driverNote = '');
                setSheet(() {});
                Navigator.pop(dlgCtx);
              },
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text('Batal', style: TextStyle(color: ts)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            onPressed: () {
              setState(() => _driverNote = noteCtrl.text.trim());
              setSheet(() {});
              Navigator.pop(dlgCtx);
            },
            child: const Text(
              'Simpan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openVoucherSheet(
    BuildContext sheetCtx,
    StateSetter setSheet,
    bool isDark,
    Color tp,
    Color ts,
    Color cardBg,
    Color borderColor,
  ) {
    const vouchers = [
      {
        'title': 'Kampus Hemat USU',
        'code': 'KAMPUSHEMAT',
        'discount': 2000,
        'desc': 'Potongan Rp 2.000 untuk perjalanan area Kampus USU',
      },
      {
        'title': 'Promo GasRide Mahasiswa',
        'code': 'GASRIDE3K',
        'discount': 3000,
        'desc': 'Potongan langsung Rp 3.000 khusus mahasiswa aktif',
      },
      {
        'title': 'Voucher Perpustakaan & Fakultas',
        'code': 'PERPUSUSU',
        'discount': 2500,
        'desc': 'Hemat Rp 2.500 antar jemput gedung fakultas',
      },
    ];

    showDialog(
      context: sheetCtx,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Pilih Voucher Promo',
          style: _body(tp, 17, FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...vouchers.map((v) {
                final title = v['title'] as String;
                final disc = v['discount'] as int;
                final desc = v['desc'] as String;
                final isSelected = _selectedVoucherTitle == title;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedVoucherTitle = title;
                      _voucherDiscount = disc;
                    });
                    setSheet(() {});
                    Navigator.pop(dlgCtx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? kPrimary.withValues(alpha: 0.22)
                          : (isDark
                                ? const Color(0xFF232A18)
                                : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? kPrimary : borderColor,
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_offer_rounded,
                          color: Color(0xFFE53E3E),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$title (-Rp ${WalletService.formatRupiah(disc)})',
                                style: _body(tp, 13, FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                desc,
                                style: _body(ts, 11, FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: kSecondaryGreen,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          if (_selectedVoucherTitle != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedVoucherTitle = null;
                  _voucherDiscount = 0;
                });
                setSheet(() {});
                Navigator.pop(dlgCtx);
              },
              child: const Text(
                'Lepas Voucher',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text('Tutup', style: TextStyle(color: ts)),
          ),
        ],
      ),
    );
  }

  void _openOtherPassengerDialog(
    BuildContext sheetCtx,
    StateSetter setSheet,
    bool isDark,
    Color tp,
    Color ts,
    Color cardBg,
    Color borderColor,
  ) {
    final nameCtrl = TextEditingController(text: _otherPassengerInfo ?? '');
    showDialog(
      context: sheetCtx,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Pesan untuk Orang Lain',
          style: _body(tp, 17, FontWeight.bold),
        ),
        content: TextField(
          controller: nameCtrl,
          style: _body(tp, 14, FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Nama & No. HP teman (mis: Rina - 0812xxx)',
            hintStyle: _body(ts, 13, FontWeight.normal),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF232A18)
                : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
          ),
        ),
        actions: [
          if (_otherPassengerInfo != null)
            TextButton(
              onPressed: () {
                setState(() => _otherPassengerInfo = null);
                setSheet(() {});
                Navigator.pop(dlgCtx);
              },
              child: const Text(
                'Untuk Saya Sendiri',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text('Batal', style: TextStyle(color: ts)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            onPressed: () {
              final val = nameCtrl.text.trim();
              setState(() => _otherPassengerInfo = val.isEmpty ? null : val);
              setSheet(() {});
              Navigator.pop(dlgCtx);
            },
            child: const Text(
              'Simpan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openScheduleSheet(
    BuildContext sheetCtx,
    StateSetter setSheet,
    bool isDark,
    Color tp,
    Color ts,
    Color cardBg,
    Color borderColor,
  ) {
    const scheduleOptions = [
      'Sekarang (Langsung Dijemput)',
      '15 Menit Lagi',
      '30 Menit Lagi',
      '1 Jam Lagi',
      'Selesai Kelas Sore (16:00 WIB)',
    ];

    showDialog(
      context: sheetCtx,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Jadwalkan Perjalanan',
          style: _body(tp, 17, FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...scheduleOptions.map((opt) {
              final isNow = opt.startsWith('Sekarang');
              final isSelected =
                  (isNow && _scheduledTimeLabel == null) ||
                  (_scheduledTimeLabel == opt);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.access_time_rounded,
                  color: isSelected ? kSecondaryGreen : ts,
                  size: 20,
                ),
                title: Text(
                  opt,
                  style: _body(
                    tp,
                    13.5,
                    isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: kSecondaryGreen,
                        size: 18,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _scheduledTimeLabel = isNow ? null : opt;
                  });
                  setSheet(() {});
                  Navigator.pop(dlgCtx);
                },
              );
            }),
            const Divider(),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.edit_calendar_rounded,
                color: Color(0xFF059669),
                size: 20,
              ),
              title: Text(
                'Pilih Jam Penjemputan Manual...',
                style: _body(const Color(0xFF059669), 13.5, FontWeight.bold),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: dlgCtx,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null && mounted) {
                  final hh = picked.hour.toString().padLeft(2, '0');
                  final mm = picked.minute.toString().padLeft(2, '0');
                  setState(() {
                    _scheduledTimeLabel = 'Pukul $hh:$mm WIB';
                  });
                  setSheet(() {});
                  if (dlgCtx.mounted) Navigator.pop(dlgCtx);
                }
              },
            ),
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
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive
              ? iconColor.withValues(alpha: isDark ? 0.16 : 0.08)
              : (isDark ? const Color(0xFF232A18) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? iconColor : borderColor,
            width: isActive ? 1.5 : 1.0,
          ),
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
                    style: _body(
                      isActive ? iconColor : textColorSecondary,
                      12,
                      isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              isActive
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: isActive ? iconColor : textColorSecondary,
              size: 20,
            ),
          ],
        ),
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
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
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
                                    13,
                                    FontWeight.w600,
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
                          iconColor: kSecondaryGreen,
                          hint: 'Pilih titik pengantaran...',
                          controller: _destinationController,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          textColorPrimary: textColorPrimary,
                          textColorSecondary: textColorSecondary,
                          onTapMapPicker: () =>
                              _openMapLocationPicker(isPickup: false),
                        ),
                        const SizedBox(height: 16),

                        // Pilihan Cepat Lokasi Kampus USU & Medan (Slide ke Samping)
                        Text(
                          'PILIH CEPAT TITIK KAMPUS USU & MEDAN',
                          style: _body(
                            textColorSecondary,
                            11,
                            FontWeight.w700,
                            ls: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _campusQuickLocations.map((loc) {
                              final isCurrent =
                                  _destinationController.text.trim() == loc;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
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
                                      horizontal: 13,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCurrent ? kPrimary : inputBg,
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color:
                                            isCurrent ? kPrimary : borderColor,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.place_rounded,
                                          size: 14,
                                          color: isCurrent
                                              ? Colors.black
                                              : kSecondaryGreen,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          loc,
                                          style: TextStyle(
                                            color: isCurrent
                                                ? Colors.black
                                                : textColorPrimary,
                                            fontSize: 12,
                                            fontWeight: isCurrent
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        if (_driverNote.isNotEmpty ||
                            _selectedVoucherTitle != null ||
                            _otherPassengerInfo != null ||
                            _scheduledTimeLabel != null) ...[
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                if (_selectedVoucherTitle != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      '🏷️ $_selectedVoucherTitle (-Rp ${WalletService.formatRupiah(_voucherDiscount)})',
                                      style: _body(
                                        kSecondaryGreen,
                                        12,
                                        FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (_scheduledTimeLabel != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      '🕒 $_scheduledTimeLabel',
                                      style: _body(
                                        textColorPrimary,
                                        12,
                                        FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (_driverNote.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      '📝 $_driverNote',
                                      style: _body(
                                        textColorSecondary,
                                        12,
                                        FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if (_otherPassengerInfo != null)
                                  Text(
                                    '👤 $_otherPassengerInfo',
                                    style: _body(
                                      textColorSecondary,
                                      12,
                                      FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
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

                // ── Harga & Jarak (Simpel tanpa cover box & tanpa teks Tarif Admin) ──
                ValueListenableBuilder<int>(
                  valueListenable: FarePricingService.versionNotifier,
                  builder: (context, _, _) {
                    final int baseFare = _selectedService == 1
                        ? FarePricingService.calculateCarFare(_routeDistanceKm)
                        : FarePricingService.calculateMotorFare(_routeDistanceKm);
                    final int finalFare =
                        math.max(1000, baseFare - _voucherDiscount);
                    final String displayFare =
                        FarePricingService.formatRupiah(finalFare);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                displayFare,
                                style: _body(
                                  textColorPrimary,
                                  18,
                                  FontWeight.bold,
                                ),
                              ),
                              if (_voucherDiscount > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  FarePricingService.formatRupiah(baseFare),
                                  style: TextStyle(
                                    color: textColorSecondary,
                                    fontSize: 13,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${_routeDistanceKm.toStringAsFixed(1)} km · ~$_routeEtaMinutes mnt',
                            style: _body(
                              textColorSecondary,
                              13,
                              FontWeight.w600,
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
            Icon(
              Icons.map_outlined,
              size: 20,
              color: textColorSecondary,
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color kPickerBg = isDark ? kBgDark : kBgLight;
    final Color kPickerSurface = isDark ? const Color(0xFF1C2414) : Colors.white;
    final Color kPickerBorder = isDark
        ? const Color(0xFF2A3518)
        : const Color(0xFFE8EDE0);
    const Color kPickerAccent = kPrimary; // 0xFFC0F637 (Palet Utama GasKampus)
    const Color kPickerAccentDeep = Color(0xFF8DBF1A);
    const Color kPickerOnAccent = Color(0xFF0A0F02);
    final Color kPickerTextPrimary = isDark
        ? Colors.white
        : const Color(0xFF0F1A02);
    final Color kPickerTextSecondary = isDark
        ? const Color(0xFF8A9E70)
        : const Color(0xFF6B7A5A);

    return Scaffold(
      backgroundColor: kPickerBg,
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
                // Marker Titik Terpilih (Sesuai Palet Utama GasKampus kPrimary)
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
                          color: kPickerAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: kPickerOnAccent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.circle,
                            color: kPickerOnAccent,
                            size: 11,
                          ),
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: kPickerOnAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Top Search Bar (Sesuai Palet Aplikasi) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: kPickerSurface,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: kPickerBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: kPickerTextPrimary,
                          size: 19,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                            color: kPickerTextPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                          onTap: () => setState(() => _showSuggestions = true),
                          onChanged: (_) =>
                              setState(() => _showSuggestions = true),
                          onSubmitted: _onSearchSubmitted,
                          decoration: InputDecoration(
                            hintText: widget.isPickup
                                ? 'Masukkan alamat untuk penjemputan...'
                                : 'Masukkan alamat untuk pengantaran...',
                            hintStyle: TextStyle(
                              color: kPickerTextSecondary,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: kPickerTextSecondary,
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
                            color: kPickerAccentDeep,
                            size: 21,
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
                      color: kPickerSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kPickerBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
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
                            backgroundColor: kPickerAccent,
                            child: Icon(
                              Icons.my_location_rounded,
                              color: kPickerOnAccent,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            'Gunakan Lokasi Saya Saat Ini (GPS)',
                            style: TextStyle(
                              color: kPickerTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: Text(
                            'Deteksi otomatis posisi perangkat saat ini',
                            style: TextStyle(
                              color: kPickerTextSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            _useCurrentDeviceGps();
                          },
                        ),
                        Divider(color: kPickerBorder, height: 1),
                        ...filteredPresets.map((item) {
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.place_rounded,
                              color: kPickerAccentDeep,
                              size: 20,
                            ),
                            title: Text(
                              item['title'] as String,
                              style: TextStyle(
                                color: kPickerTextPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              item['sub'] as String,
                              style: TextStyle(
                                color: kPickerTextSecondary,
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
            bottom: 225,
            child: Column(
              children: [
                _roundControlBtn(
                  icon: Icons.add_rounded,
                  surfaceColor: kPickerSurface,
                  borderColor: kPickerBorder,
                  iconColor: kPickerTextPrimary,
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
                  surfaceColor: kPickerSurface,
                  borderColor: kPickerBorder,
                  iconColor: kPickerTextPrimary,
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
                  surfaceColor: kPickerSurface,
                  borderColor: kPickerBorder,
                  iconColor: kPickerAccentDeep,
                  onTap: _useCurrentDeviceGps,
                ),
              ],
            ),
          ),

          // ── 4. Bottom Sheet Card (Simpel tanpa cover box di dalam & Palet GasKampus) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                22,
                20,
                22,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: kPickerSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border(
                  top: BorderSide(color: kPickerBorder, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
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
                        style: TextStyle(
                          color: kPickerTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: _useCurrentDeviceGps,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.my_location_rounded,
                              size: 15,
                              color: kPickerAccentDeep,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Lokasi Saat Ini',
                              style: TextStyle(
                                color: kPickerAccentDeep,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: kPickerAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isPickup
                              ? Icons.my_location_rounded
                              : Icons.flag_rounded,
                          color: kPickerOnAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _isGeocoding
                            ? Text(
                                'Mendeteksi nama jalan...',
                                style: TextStyle(
                                  color: kPickerTextSecondary,
                                  fontSize: 15,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _placeTitle,
                                    style: TextStyle(
                                      color: kPickerTextPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _streetSubtitle,
                                    style: TextStyle(
                                      color: kPickerTextSecondary,
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
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
                        backgroundColor: kPickerAccent,
                        foregroundColor: kPickerOnAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      child: const Text(
                        'Selesai',
                        style: TextStyle(
                          fontSize: 16,
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
    required Color surfaceColor,
    required Color borderColor,
    required Color iconColor,
  }) {
    return Material(
      color: surfaceColor,
      shape: CircleBorder(
        side: BorderSide(color: borderColor, width: 1),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: iconColor, size: 21),
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
  final int fareAmount;
  final String paymentMethod;
  final LatLng? initialPickupLatLng;
  final LatLng? initialDropoffLatLng;
  final VoidCallback onBack;
  final VoidCallback onShowHistory;

  const _ActiveOrderScreen({
    this.pickupAddress = 'Fakultas Teknik USU',
    this.destinationAddress = 'Gedung Biro Rektor USU',
    this.serviceLabel = 'GasRide',
    this.fareLabel = 'Rp 5.000',
    this.fareAmount = 5000,
    this.paymentMethod = 'GasPay',
    this.initialPickupLatLng,
    this.initialDropoffLatLng,
    required this.onBack,
    required this.onShowHistory,
  });

  @override
  State<_ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

enum _RidePhase { searching, found, otw, pickupArrived, onTrip, arrived }

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

  // Fase pesanan: mencari driver -> ditemukan -> OTW -> tiba di jemput -> antar -> selesai
  _RidePhase _phase = _RidePhase.searching;
  List<LatLng> _otwPath = [];
  int _otwIndex = 0;
  double _tripDistanceKm = 0.8;
  int _tripEtaMinutes = 3;
  Timer? _phaseTimer;
  Timer? _otwTimer;

  bool _isMapReady = false;
  bool _isSimulating = false;
  bool _hasArrived = false;
  bool _hasDeductedGasPay = false;
  int? _remainingWalletBalance;
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
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.25).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    _initUserLocationAndRoute();
    // Fase 1: animasi menunggu driver ditemukan
    _phaseTimer = Timer(const Duration(milliseconds: 4500), _onDriverFound);
  }

  String get _phaseTitle {
    switch (_phase) {
      case _RidePhase.searching:
        return 'Mencari driver terdekat...';
      case _RidePhase.found:
        return 'Driver ditemukan!';
      case _RidePhase.otw:
        return 'Driver sedang menuju lokasimu';
      case _RidePhase.pickupArrived:
        return 'Driver sudah tiba di lokasi jemput';
      case _RidePhase.onTrip:
        return 'Driver sedang mengantar ke tujuan';
      case _RidePhase.arrived:
        return 'Perjalanan telah selesai!';
    }
  }

  String get _etaChipLabel {
    switch (_phase) {
      case _RidePhase.searching:
        return 'Mencari';
      case _RidePhase.pickupArrived:
      case _RidePhase.arrived:
        return 'Tiba';
      default:
        return '$_etaMinutes Menit';
    }
  }

  String get _topPillLabel {
    switch (_phase) {
      case _RidePhase.searching:
        return 'Mencari driver...';
      case _RidePhase.found:
        return 'Driver ditemukan';
      case _RidePhase.otw:
        return 'Driver OTW · ${_distanceKm.toStringAsFixed(1)} km';
      case _RidePhase.pickupArrived:
        return 'Driver sudah tiba';
      case _RidePhase.onTrip:
        return '${widget.serviceLabel} · ${_distanceKm.toStringAsFixed(1)} km';
      case _RidePhase.arrived:
        return 'Sampai di Tujuan';
    }
  }

  List<LatLng> get _activePolyline {
    switch (_phase) {
      case _RidePhase.searching:
        return const [];
      case _RidePhase.found:
      case _RidePhase.otw:
        if (_otwPath.length < 2) return const [];
        return _otwPath.sublist(math.min(_otwIndex, _otwPath.length - 1));
      case _RidePhase.pickupArrived:
        return _routePoints;
      case _RidePhase.onTrip:
      case _RidePhase.arrived:
        return _isSimulating && _simulationIndex > 0
            ? _simulationPath.sublist(
                math.min(_simulationIndex, _simulationPath.length - 1),
              )
            : _routePoints;
    }
  }

  /// Fase 2: driver ditemukan -> munculkan pop up "driver OTW".
  Future<void> _onDriverFound() async {
    if (!mounted) return;
    // Titik awal driver sekitar 700 m dari lokasi penjemputan.
    final start = LatLng(
      _pickupLatLng.latitude + 0.0045,
      _pickupLatLng.longitude - 0.0032,
    );
    final res = await MapRouteService.fetchRoadRoute(start, _pickupLatLng);
    if (!mounted) return;
    final dense = MapRouteService.densifyRoutePoints(res.points);
    final path = dense.length >= 2 ? dense : [start, _pickupLatLng];
    setState(() {
      _otwPath = path;
      _otwIndex = 0;
      _driverLatLng = path.first;
      _driverHeading = MapRouteService.calculateBearingDegrees(
        path.first,
        path[1],
      );
      _distanceKm = res.distanceKm;
      _etaMinutes = res.durationMinutes;
      _phase = _RidePhase.found;
    });
    _fitBounds();
    AppNotificationStore.add(
      title: 'Driver ditemukan',
      message: 'Budi Santoso (BK 1234 GKS) sedang OTW ke ${widget.pickupAddress}.',
      icon: Icons.two_wheeler_rounded,
      color: const Color(0xFF64748B),
    );
    await _showDriverOtwBottomSheet();
    if (!mounted) return;
    _startOtwPhase();
  }

  Future<void> _showDriverOtwBottomSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1A2210) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0F172A);
    final ts = isDark ? Colors.white70 : const Color(0xFF64748B);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        // Tutup otomatis agar fase OTW langsung berjalan
        Timer(const Duration(milliseconds: 3800), () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            14,
            24,
            MediaQuery.of(ctx).padding.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
              const SizedBox(height: 22),
              const Icon(
                Icons.two_wheeler_rounded,
                color: kSecondaryGreen,
                size: 52,
              ),
              const SizedBox(height: 12),
              Text(
                'Driver Ditemukan!',
                textAlign: TextAlign.center,
                style: _body(tp, 20, FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Tunggu sebentar ya, driver lagi OTW ke lokasi penjemputan kamu.',
                textAlign: TextAlign.center,
                style: _body(ts, 14, FontWeight.w500, h: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.person_rounded, color: tp, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budi Santoso',
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
                  Text(
                    widget.fareLabel,
                    style: _body(tp, 15, FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Fase 3: driver bergerak menuju titik jemput.
  void _startOtwPhase() {
    setState(() => _phase = _RidePhase.otw);
    _fitBounds();
    _otwTimer?.cancel();
    _otwTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (!mounted) return;
      if (_otwIndex >= _otwPath.length - 1) {
        _otwTimer?.cancel();
        setState(() {
          _phase = _RidePhase.pickupArrived;
          _driverLatLng = _pickupLatLng;
          _distanceKm = 0.0;
          _etaMinutes = 0;
        });
        AppNotificationStore.add(
          title: 'Driver sudah tiba',
          message: 'Driver menunggu di ${widget.pickupAddress}.',
          icon: Icons.location_on_rounded,
          color: const Color(0xFF64748B),
        );
        _phaseTimer = Timer(const Duration(milliseconds: 2200), _beginTrip);
        return;
      }

      final step = math.min(2, _otwPath.length - 1 - _otwIndex);
      final current = _otwPath[_otwIndex];
      final next = _otwPath[_otwIndex + step];
      final remainingKm = math.max(
        0.0,
        MapRouteService.distanceInMeters(next, _pickupLatLng) / 1000.0,
      );
      final remainingEta = remainingKm <= 0.05
          ? 0
          : math.max(1, ((remainingKm / 24.0) * 60.0).ceil());

      setState(() {
        _otwIndex += step;
        _driverLatLng = next;
        _driverHeading = MapRouteService.calculateBearingDegrees(current, next);
        _distanceKm = remainingKm;
        _etaMinutes = remainingEta;
      });

      if (_isMapReady) {
        _mapController.move(next, math.max(_mapController.camera.zoom, 15.4));
      }
    });
  }

  /// Fase 4: setelah driver sampai di titik jemput, simulasi antar baru aktif.
  void _beginTrip() {
    if (!mounted) return;
    if (_simulationPath.length < 2) {
      _phaseTimer = Timer(const Duration(milliseconds: 800), _beginTrip);
      return;
    }
    setState(() {
      _phase = _RidePhase.onTrip;
      _simulationIndex = 0;
      _driverLatLng = _simulationPath.first;
      _driverHeading = MapRouteService.calculateBearingDegrees(
        _simulationPath.first,
        _simulationPath[1],
      );
      _distanceKm = _tripDistanceKm;
      _etaMinutes = _tripEtaMinutes;
    });
    _fitBounds();
    _toggleSimulation();
  }

  void _onManualSimulationToggle() {
    if (_phase == _RidePhase.onTrip) _toggleSimulation();
  }

  Widget _buildSearchingPanel(Color tp, Color ts) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 150,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, _) {
              Widget ring(double offset) {
                final t = (_pulseController.value + offset) % 1.0;
                return Container(
                  width: 40 + 110 * t,
                  height: 40 + 110 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kSecondaryGreen.withValues(alpha: (1 - t) * 0.7),
                      width: 2,
                    ),
                  ),
                );
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  ring(0.0),
                  ring(0.33),
                  ring(0.66),
                  const GasMoodFace(mood: GasMood.happy, size: 46),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Mencari driver terdekat...',
          style: _body(tp, 17, FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Radar menjangkau driver kampus yang aktif di sekitar ${widget.pickupAddress}',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _body(ts, 12.5, FontWeight.w500, h: 1.35),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: widget.onBack,
          child: Text(
            'Batalkan pesanan',
            style: _body(Colors.redAccent, 13, FontWeight.bold),
          ),
        ),
      ],
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

    setState(() {
      _routePoints = res.points;
      _simulationPath = densified;
      _simulationIndex = 0;
      _tripDistanceKm = res.distanceKm;
      _tripEtaMinutes = res.durationMinutes;
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
          _phase = _RidePhase.arrived;
          _distanceKm = 0.0;
          _etaMinutes = 0;
        });
        _handleArrivalAndShowPopup();
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

  Future<void> _handleArrivalAndShowPopup() async {
    // Jika metode pembayaran GasPay, potong otomatis dari saldo wallet user
    if (widget.paymentMethod == 'GasPay' && !_hasDeductedGasPay) {
      _hasDeductedGasPay = true;
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null && widget.fareAmount > 0) {
          final db = FirebaseFirestore.instance;
          final walletRef = db.collection('wallets').doc(uid);
          final txRef = walletRef.collection('transactions').doc();
          final now = DateTime.now().toIso8601String();

          final newBal = await db.runTransaction<int>((tx) async {
            final snap = await tx.get(walletRef);
            final currentBal = (snap.data()?['balance'] as num?)?.toInt() ?? 0;
            final updatedBal = math.max(0, currentBal - widget.fareAmount);
            tx.set(
              walletRef,
              {'userId': uid, 'balance': updatedBal, 'updatedAt': now},
              SetOptions(merge: true),
            );
            tx.set(txRef, {
              'transactionId': txRef.id,
              'walletId': uid,
              'type': 'payment',
              'amount': widget.fareAmount,
              'description':
                  'Pembayaran ${widget.serviceLabel} ke ${widget.destinationAddress}',
              'createdAt': now,
            });
            return updatedBal;
          });
          if (mounted) setState(() => _remainingWalletBalance = newBal);
        }
      } catch (_) {}
    }

    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1A2210) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0F172A);
    final ts = isDark ? Colors.white70 : const Color(0xFF64748B);
    final borderCol = isDark ? const Color(0xFF2A3518) : const Color(0xFFE2E8F0);

    // Rating bersifat opsional (3 wajah logo GasKampus, tanpa teks)
    GasMood? selectedMood;
    final ratingNoteCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialog) {
            return Dialog(
              backgroundColor: dialogBg,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: kSecondaryGreen,
                      size: 46,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Anda Telah Diantar Sampai ke Tujuan!',
                      textAlign: TextAlign.center,
                      style: _body(tp, 18, FontWeight.bold, h: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.pickupAddress} → ${widget.destinationAddress}',
                      textAlign: TextAlign.center,
                      style: _body(ts, 12.5, FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    if (widget.paymentMethod == 'QRIS') ...[
                      Text(
                        'Scan QRIS di bawah ini untuk membayar:',
                        textAlign: TextAlign.center,
                        style: _body(ts, 12.5, FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      _buildQrisCodeBox(widget.fareLabel),
                      const SizedBox(height: 10),
                      Text(
                        'Total Tagihan: ${widget.fareLabel}',
                        style: _body(tp, 16, FontWeight.bold),
                      ),
                    ] else if (widget.paymentMethod == 'GasPay') ...[
                      Text(
                        'Terpotong otomatis dari saldo GasPay',
                        textAlign: TextAlign.center,
                        style: _body(ts, 13, FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '- ${widget.fareLabel}',
                        style: _body(tp, 24, FontWeight.bold),
                      ),
                      if (_remainingWalletBalance != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Sisa saldo: Rp ${WalletService.formatRupiah(_remainingWalletBalance!)}',
                          style: _body(ts, 12, FontWeight.w500),
                        ),
                      ],
                    ] else ...[
                      Text(
                        'Bayarlah ke driver sesuai harga:',
                        textAlign: TextAlign.center,
                        style: _body(ts, 13, FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.fareLabel,
                        style: _body(tp, 26, FontWeight.bold),
                      ),
                    ],

                    const SizedBox(height: 18),
                    Divider(color: borderCol, height: 1),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: GasMood.values.map((m) {
                        final isSelected = selectedMood == m;
                        return GestureDetector(
                          onTap: () => setDialog(
                            () => selectedMood = isSelected ? null : m,
                          ),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedScale(
                            scale: isSelected ? 1.18 : 0.94,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutBack,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: GasMoodFace(
                                mood: m,
                                size: 58,
                                active: selectedMood == null || isSelected,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (selectedMood != null) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: ratingNoteCtrl,
                        maxLines: 2,
                        style: _body(tp, 13, FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Catatan untuk driver (opsional)',
                          hintStyle: _body(ts, 12.5, FontWeight.normal),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderCol),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderCol),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: kSecondaryGreen,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dlgCtx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: const Color(0xFF0F172A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        child: const Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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
      },
    );

    // Dialog ditutup (lewat tombol Selesai maupun ketuk di luar kotak).
    // Rating hanya disimpan bila pengguna memilih.
    if (selectedMood != null) {
      _saveDriverRating(selectedMood!.name, ratingNoteCtrl.text.trim());
    }

    if (!mounted) return;
    _openPaymentSuccess();
  }

  Future<void> _saveDriverRating(String moodId, String note) async {
    try {
      await FirebaseFirestore.instance
          .collection('driver_ratings')
          .add({
            'passengerId': FirebaseAuth.instance.currentUser?.uid,
            'driverName': 'Budi Santoso',
            'mood': moodId,
            'note': note,
            'serviceLabel': widget.serviceLabel,
            'fareLabel': widget.fareLabel,
            'paymentMethod': widget.paymentMethod,
            'createdAt': DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  void _openPaymentSuccess() {
    final method = widget.paymentMethod;
    AppNotificationStore.add(
      title: 'Pembayaran berhasil',
      message:
          '${widget.serviceLabel} ke ${widget.destinationAddress} • ${widget.fareLabel} via $method',
      icon: Icons.receipt_long_rounded,
      color: const Color(0xFF64748B),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PaymentSuccessScreen(
          receiverName: 'GasKampus ${widget.serviceLabel}',
          receiverSub: 'Driver Budi Santoso • BK 1234 GKS',
          amountLabel: widget.fareLabel,
          details: [
            MapEntry(
              'Metode',
              method == 'Tunai' ? 'Tunai ke driver' : method,
            ),
            MapEntry('Dari', widget.pickupAddress),
            MapEntry('Tujuan', widget.destinationAddress),
            if (method == 'GasPay' && _remainingWalletBalance != null)
              MapEntry(
                'Sisa saldo',
                'Rp ${WalletService.formatRupiah(_remainingWalletBalance!)}',
              ),
          ],
          onDone: widget.onShowHistory,
        ),
      ),
    );
  }

  Widget _buildQrisCodeBox(String fareLabel) {
    // Representasi matriks QR Code 11x11 yang rapi & realistis untuk pembayaran QRIS
    const List<List<int>> qrMatrix = [
      [1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1],
      [1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1],
      [1, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1],
      [0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0],
      [1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1],
      [0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1],
      [1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0],
      [0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 1],
      [1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0],
      [1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1],
      [1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1],
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'QRIS · GASKAMPUS USU',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 154,
            height: 154,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: qrMatrix.map((row) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: row.map((cell) {
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: cell == 1
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'NMID: ID1026000USU • $fareLabel',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
    _phaseTimer?.cancel();
    _otwTimer?.cancel();
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

    final remainingRoute = _activePolyline;

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
                  if (_phase == _RidePhase.searching)
                    Marker(
                      point: _pickupLatLng,
                      width: 240,
                      height: 240,
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, _) {
                            Widget ring(double offset) {
                              final t = (_pulseController.value + offset) % 1.0;
                              return Container(
                                width: 40 + 190 * t,
                                height: 40 + 190 * t,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kSecondaryGreen.withValues(
                                    alpha: (1 - t) * 0.16,
                                  ),
                                  border: Border.all(
                                    color: kSecondaryGreen.withValues(
                                      alpha: (1 - t) * 0.7,
                                    ),
                                    width: 2,
                                  ),
                                ),
                              );
                            }

                            return Stack(
                              alignment: Alignment.center,
                              children: [ring(0.0), ring(0.5)],
                            );
                          },
                        ),
                      ),
                    ),
                  if (_phase != _RidePhase.searching)
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
                                  _topPillLabel,
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
                      onToggleSimulation: _onManualSimulationToggle,
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
                          child: _phase == _RidePhase.searching
                              ? _buildSearchingPanel(
                                  textColorPrimary,
                                  textColorSecondary,
                                )
                              : Column(
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
                                          _phaseTitle,
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
                                      _etaChipLabel,
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
                                      onTap: _phase == _RidePhase.onTrip
                                          ? _toggleSimulation
                                          : null,
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
                                              _phase == _RidePhase.onTrip
                                                  ? (_isSimulating
                                                        ? 'Jeda Perjalanan'
                                                        : 'Lanjutkan Perjalanan')
                                                  : (_phase == _RidePhase.arrived
                                                        ? 'Perjalanan Selesai'
                                                        : (_phase ==
                                                                  _RidePhase
                                                                      .pickupArrived
                                                              ? 'Driver Tiba, Berangkat...'
                                                              : 'Driver Menuju Lokasimu...')),
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
  bool _isDeletingAll = false;

  @override
  void initState() {
    super.initState();
    _runOneMonthAutoCleanup();
  }

  /// Algoritma otomatis: hapus pesanan yang berusia >= 1 bulan (30 hari)
  /// dari memori lokal maupun database Firestore agar tidak memberatkan database.
  Future<void> _runOneMonthAutoCleanup() async {
    _allOrders.removeWhere(
      (o) => SessionOrderStore.isOlderThanOneMonth(o.createdAt),
    );
    final purgedCount =
        await SessionOrderStore.purgeOlderThanOneMonthDatabase();
    if (mounted) {
      setState(() {});
      if (purgedCount > 0) {
        AppNotificationStore.add(
          title: 'Pembersihan Otomatis Riwayat (1 Bulan)',
          message:
              '$purgedCount riwayat pesanan berusia > 1 bulan telah dihapus otomatis dari database.',
          icon: Icons.auto_delete_rounded,
          color: const Color(0xFF64748B),
        );
      }
    }
  }

  Future<void> _confirmAndDeleteAllHistory(
    BuildContext context,
    Color cardBg,
    Color tp,
    Color ts,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Hapus Semua Riwayat?',
          style: _body(tp, 17, FontWeight.bold),
        ),
        content: Text(
          'Seluruh riwayat pesanan Anda akan dihapus permanen dari aplikasi dan database.',
          style: _body(ts, 13.5, FontWeight.normal, h: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: Text('Batal', style: TextStyle(color: ts)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: const Text(
              'Hapus Semua',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isDeletingAll = true);
    _allOrders.clear();
    await SessionOrderStore.deleteAllUserOrdersFromDatabase();
    AppNotificationStore.add(
      title: 'Riwayat Pesanan Dihapus',
      message: 'Seluruh riwayat pesanan telah dibersihkan dari database.',
      icon: Icons.delete_sweep_rounded,
      color: Colors.redAccent,
    );
    if (mounted) {
      setState(() => _isDeletingAll = false);
    }
  }

  List<OrderItem> get _filteredOrders {
    _allOrders.removeWhere(
      (o) => SessionOrderStore.isOlderThanOneMonth(o.createdAt),
    );
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
                      GestureDetector(
                        onTap: _isDeletingAll
                            ? null
                            : () => _confirmAndDeleteAllHistory(
                                context,
                                cardBg,
                                textColorPrimary,
                                textColorSecondary,
                              ),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.delete_sweep_rounded,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Hapus Semua',
                                style: _body(
                                  Colors.redAccent,
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

                // 1. Pesanan dari Firestore (otomatis hapus jika berusia >= 1 bulan / 30 hari)
                if (snapshot.hasData) {
                  for (final doc in snapshot.data!.docs) {
                    final data = doc.data();
                    final item = _ServiceOrderData.fromMap(doc.id, data);
                    if (SessionOrderStore.isOlderThanOneMonth(item.createdAt)) {
                      doc.reference.delete().catchError((_) {});
                      continue;
                    }
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
                SessionOrderStore.purgeOlderThanOneMonthLocal();
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
