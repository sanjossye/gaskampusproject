import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'driver_umum_trip_complete_screen.dart';
import '../../../services/trip_service.dart';
import '../../../services/map_route_service.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kCampusDark = Color(0xFF1D2210);

class DriverUmumActiveTripScreen extends StatefulWidget {
  final String orderId;
  final String passengerName;
  final String passengerRole;
  final int fareAmount;
  final String pickupAddress;
  final String dropoffAddress;
  final String paymentMethod;
  final String zone;

  const DriverUmumActiveTripScreen({
    super.key,
    this.orderId = 'order_live_01',
    this.passengerName = 'Andi Pratama',
    this.passengerRole = 'Mahasiswa · Fak. Teknik USU',
    this.fareAmount = 15000,
    this.pickupAddress = 'Stasiun Medan',
    this.dropoffAddress = 'Gedung C - Zona B (Fakultas Teknik USU)',
    this.paymentMethod = 'GasPay',
    this.zone = 'Zona B',
  });

  @override
  State<DriverUmumActiveTripScreen> createState() =>
      _DriverUmumActiveTripScreenState();
}

class _DriverUmumActiveTripScreenState extends State<DriverUmumActiveTripScreen>
    with SingleTickerProviderStateMixin {
  final TripService _tripService = TripService();
  final MapController _mapController = MapController();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late final LatLng _pickupLatLng;
  late final LatLng _dropoffLatLng;
  late LatLng _driverLatLng;
  late LatLng _lastRoutedGps;
  double _driverHeading = 0.0;

  GasMapStyle _mapStyle = GasMapStyle.street;
  List<LatLng> _tripRoutePoints = [];
  List<LatLng> _simulationPath = [];
  int _simulationIndex = 0;

  double _totalDistanceKm = 3.2;
  double _remainingDistanceKm = 3.2;
  int _etaMinutes = 8;
  double _tripProgress = 0.0;

  bool _isCompleting = false;
  bool _isLoadingRoute = true;
  bool _isMapReady = false;
  bool _isSimulating = false;
  bool _isRealDeviceGps = false;

  Timer? _simulationTimer;
  StreamSubscription<DriverGpsResult>? _gpsSub;
  DateTime _lastFirestoreSync = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _pickupLatLng = MapRouteService.resolveCoordinate(widget.pickupAddress);
    _dropoffLatLng = MapRouteService.resolveCoordinate(
      widget.dropoffAddress,
      fallbackZone: widget.zone,
    );
    _driverLatLng = _pickupLatLng;
    _lastRoutedGps = _pickupLatLng;
    _driverHeading = MapRouteService.calculateBearingDegrees(
      _pickupLatLng,
      _dropoffLatLng,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initActiveTripMap();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _gpsSub?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initActiveTripMap() async {
    final gps = await MapRouteService.getCurrentDriverPosition(
      campusFallback: _pickupLatLng,
    );
    if (!mounted) return;

    if (gps.isRealDeviceGps) {
      setState(() {
        _driverLatLng = gps.position;
        _lastRoutedGps = gps.position;
        _isRealDeviceGps = true;
      });
    }

    final route = await MapRouteService.fetchRoadRoute(
      _driverLatLng,
      _dropoffLatLng,
    );
    if (!mounted) return;

    setState(() {
      _tripRoutePoints = route.points;
      _simulationPath = MapRouteService.densifyRoutePoints(route.points);
      _simulationIndex = 0;
      _totalDistanceKm = math.max(0.1, route.distanceKm);
      _remainingDistanceKm = route.distanceKm;
      _etaMinutes = route.durationMinutes;
      _tripProgress = 0.0;
      _isLoadingRoute = false;
    });

    if (_isMapReady) {
      _fitRouteBounds();
    }

    _startGpsListener();
    _syncDriverLocationThrottled();
  }

  void _startGpsListener() {
    _gpsSub = MapRouteService.watchDriverPosition().listen((gps) async {
      if (!mounted || _isSimulating) return;

      final distMeters = MapRouteService.distanceInMeters(
        gps.position,
        _dropoffLatLng,
      );
      final remKm = distMeters / 1000.0;
      final progress = (1.0 - (remKm / _totalDistanceKm)).clamp(0.0, 1.0);
      final newHeading = gps.heading != 0.0
          ? gps.heading
          : MapRouteService.calculateBearingDegrees(
              _driverLatLng,
              gps.position,
            );
      final movedSinceRoute = MapRouteService.distanceInMeters(
        _lastRoutedGps,
        gps.position,
      );

      setState(() {
        _driverLatLng = gps.position;
        _driverHeading = newHeading;
        _isRealDeviceGps = true;
        _remainingDistanceKm = remKm;
        _tripProgress = progress;
        _etaMinutes = remKm <= 0.05
            ? 0
            : math.max(1, ((remKm / 24.0) * 60.0).ceil());
      });

      _syncDriverLocationThrottled();

      if (movedSinceRoute > 20) {
        _lastRoutedGps = gps.position;
        final route = await MapRouteService.fetchRoadRoute(
          gps.position,
          _dropoffLatLng,
        );
        if (!mounted) return;
        setState(() {
          _tripRoutePoints = route.points;
          _simulationPath = MapRouteService.densifyRoutePoints(route.points);
          _remainingDistanceKm = route.distanceKm;
          _etaMinutes = route.durationMinutes;
          _tripProgress =
              (1.0 - (route.distanceKm / _totalDistanceKm)).clamp(0.0, 1.0);
        });
      }
    });
  }

  void _syncDriverLocationThrottled() {
    final now = DateTime.now();
    if (now.difference(_lastFirestoreSync).inSeconds < 4) return;
    _lastFirestoreSync = now;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'driveru_demo';
    MapRouteService.syncDriverLocation(
      driverId: uid,
      position: _driverLatLng,
      heading: _driverHeading,
      activeOrderId: widget.orderId,
    );
  }

  void _toggleSimulation() {
    if (_isSimulating) {
      _simulationTimer?.cancel();
      setState(() => _isSimulating = false);
      return;
    }

    if (_simulationPath.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rute tujuan belum tersedia.')),
      );
      return;
    }

    if (_simulationIndex >= _simulationPath.length - 1) {
      _simulationIndex = 0;
    }

    setState(() => _isSimulating = true);

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      if (_simulationIndex >= _simulationPath.length - 1) {
        _simulationTimer?.cancel();
        setState(() {
          _isSimulating = false;
          _remainingDistanceKm = 0.0;
          _etaMinutes = 0;
          _tripProgress = 1.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Telah tiba di ${widget.dropoffAddress}!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final current = _simulationPath[_simulationIndex];
      final next = _simulationPath[_simulationIndex + 1];
      final bearing = MapRouteService.calculateBearingDegrees(current, next);
      final progress =
          ((_simulationIndex + 1) / (_simulationPath.length - 1)).clamp(
            0.0,
            1.0,
          );
      final remKm = math.max(0.0, _totalDistanceKm * (1.0 - progress));
      final remEta = remKm <= 0.05
          ? 0
          : math.max(1, ((remKm / 24.0) * 60.0).ceil());

      setState(() {
        _simulationIndex++;
        _driverLatLng = next;
        _driverHeading = bearing;
        _remainingDistanceKm = remKm;
        _etaMinutes = remEta;
        _tripProgress = progress;
      });

      if (_isMapReady) {
        final targetZoom = math.max(_mapController.camera.zoom, 15.2);
        _mapController.move(next, targetZoom);
      }
      _syncDriverLocationThrottled();
    });
  }

  void _fitRouteBounds() {
    if (!_isMapReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isMapReady) return;
      try {
        final allPoints = <LatLng>[
          _pickupLatLng,
          _driverLatLng,
          _dropoffLatLng,
          ..._tripRoutePoints,
        ];
        if (allPoints.length < 2) {
          _mapController.move(_driverLatLng, 15.0);
          return;
        }

        final bounds = LatLngBounds.fromPoints(allPoints);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.fromLTRB(48, 100, 64, 260),
            maxZoom: 16.5,
          ),
        );
      } catch (_) {}
    });
  }

  void _cycleMapStyle() {
    const styles = GasMapStyle.values;
    final nextIdx = (styles.indexOf(_mapStyle) + 1) % styles.length;
    setState(() => _mapStyle = styles[nextIdx]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tema peta: ${styles[nextIdx].label}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openGoogleMaps() async {
    final launched = await MapRouteService.openGoogleMapsNavigation(
      origin: _driverLatLng,
      destination: _dropoffLatLng,
    );
    if (!mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak dapat membuka Google Maps eksternal menuju: ${widget.dropoffAddress}',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSosDialog() {
    final coordText =
        '${_driverLatLng.latitude.toStringAsFixed(5)}, ${_driverLatLng.longitude.toStringAsFixed(5)}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tombol Darurat (SOS)',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gunakan jika terjadi ancaman keamanan, kecelakaan, atau kondisi darurat di area kampus.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Koordinat Live: $coordText',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Telepon Satpam Kampus USU: 061-8211633',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const Text(
              '• Layanan Darurat Polisi: 110',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const Text(
              '• Lapor Insiden Langsung ke Admin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Sinyal SOS & koordinat ($coordText) dikirim ke Pos Satpam Kampus!',
                  ),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Kirim Sinyal Darurat',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCompleteTrip() async {
    _simulationTimer?.cancel();
    setState(() {
      _isCompleting = true;
      _isSimulating = false;
    });
    final user = FirebaseAuth.instance.currentUser;
    final driverId = user?.uid ?? 'driveru_demo';

    try {
      final result = await _tripService.completeTripAndProcessFinancials(
        orderId: widget.orderId,
        driverId: driverId,
        fareAmount: widget.fareAmount,
        paymentMethod: widget.paymentMethod,
      );

      if (!mounted) return;

      final bool isCash = result['isCash'] as bool;
      final int commission = result['commission'] as int;
      final int netEarnings = result['netEarnings'] as int;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCash
                ? 'Trip Selesai! Terima Tunai Rp ${widget.fareAmount}. Komisi 15% (Rp $commission) dipotong dari saldo GasPay.'
                : 'Trip Selesai! Pendapatan bersih Rp $netEarnings telah masuk ke saldo GasPay kamu.',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverUmumTripCompleteScreen(
            orderId: widget.orderId,
            passengerName: widget.passengerName,
            passengerRole: widget.passengerRole,
            fareAmount: widget.fareAmount,
            dropoffAddress: widget.dropoffAddress,
            paymentMethod: widget.paymentMethod,
            zone: widget.zone,
            commission: commission,
            netEarnings: netEarnings,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyelesaikan trip: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      _mapStyle == GasMapStyle.street
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    );

    final hasSimStep = _isSimulating &&
        _simulationPath.length >= 2 &&
        _simulationIndex > 0;
    final completedRoute = hasSimStep
        ? _simulationPath.sublist(
            0,
            math.min(_simulationIndex + 1, _simulationPath.length),
          )
        : <LatLng>[];
    final remainingRoute = hasSimStep
        ? _simulationPath.sublist(
            math.min(_simulationIndex, _simulationPath.length - 1),
          )
        : _tripRoutePoints;

    return Scaffold(
      backgroundColor: kCampusDark,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
          // 1. Peta Interaktif Asli (OpenStreetMap / CartoDB / Esri)
          Positioned.fill(
            child: GasKampusLiveMap(
              mapController: _mapController,
              mapStyle: _mapStyle,
              initialCenter: _dropoffLatLng,
              initialZoom: 14.5,
              onMapReady: () {
                _isMapReady = true;
                _fitRouteBounds();
              },
              polylines: [
                if (completedRoute.length >= 2)
                  Polyline(
                    points: completedRoute,
                    color: Colors.grey.withValues(alpha: 0.7),
                    strokeWidth: 5.0,
                  ),
                if (remainingRoute.length >= 2)
                  Polyline(
                    points: remainingRoute,
                    color: kPrimary,
                    strokeWidth: 6.5,
                    borderStrokeWidth: 2.2,
                    borderColor: kCampusDark,
                  ),
              ],
              markers: [
                MapRouteService.buildPlacePinMarker(
                  point: _pickupLatLng,
                  label: 'Titik Jemput',
                  color: Colors.blueGrey,
                  icon: Icons.radio_button_checked,
                ),
                MapRouteService.buildPlacePinMarker(
                  point: _dropoffLatLng,
                  label: 'Tujuan · ${widget.zone}',
                  color: Colors.redAccent,
                  icon: Icons.location_on,
                ),
                MapRouteService.buildDriverMotorMarker(
                  point: _driverLatLng,
                  headingDegrees: _driverHeading,
                  pulseAnimation: _pulseAnimation,
                ),
              ],
            ),
          ),

          // 2. Top Navigation Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTopNavButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.two_wheeler,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      'Mengantar · ${_remainingDistanceKm.toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_isRealDeviceGps) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.gps_fixed,
                                      size: 12,
                                      color: Colors.green,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _showSosDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.warning,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'SOS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildTopNavButton(
                              icon: Icons.directions_rounded,
                              onTap: _openGoogleMaps,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_isLoadingRoute)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            minHeight: 3,
                            color: kPrimary,
                            backgroundColor: Colors.black26,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Map Controls + Bottom Info Sheet
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
                    onFitRoute: _fitRouteBounds,
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
                _buildBottomInfoSheet(),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInfoSheet() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Progress bar perjalanan
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _tripProgress,
                    minHeight: 5,
                    backgroundColor: Colors.grey[200],
                    color: kPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(_tripProgress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Destination and ETA
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.black87,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Menuju Tujuan (${widget.zone}) · ${_remainingDistanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.dropoffAddress,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tarif: Rp ${widget.fareAmount} · ${widget.paymentMethod}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _etaMinutes == 0 ? 'Tiba' : '$_etaMinutes min',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'ESTIMASI',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 22),

          // Passenger Info & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.black87,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.passengerName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.passengerRole,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                  _buildCircleAction(
                    icon: Icons.near_me_outlined,
                    onTap: _openGoogleMaps,
                  ),
                  const SizedBox(width: 6),
                  _buildCircleAction(
                    icon: Icons.chat_bubble_outline,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Membuka chat penumpang...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildCircleAction(
                    icon: Icons.phone_outlined,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Menghubungi telepon penumpang...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Selesaikan Perjalanan Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.black,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isCompleting ? null : _handleCompleteTrip,
              child: _isCompleting
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'Selesaikan Perjalanan (Tiba di Tujuan)',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 21),
      ),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(icon, color: Colors.black87, size: 17),
      ),
    );
  }
}
