import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'driver_umum_active_trip_screen.dart';
import '../../../services/trip_service.dart';
import '../../../services/map_route_service.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kCampusDark = Color(0xFF1D2210);

class DriverUmumNavigationScreen extends StatefulWidget {
  final String orderId;
  final String passengerName;
  final String passengerRole;
  final int fareAmount;
  final String pickupAddress;
  final String dropoffAddress;
  final String paymentMethod;
  final String zone;

  const DriverUmumNavigationScreen({
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
  State<DriverUmumNavigationScreen> createState() =>
      _DriverUmumNavigationScreenState();
}

class _DriverUmumNavigationScreenState extends State<DriverUmumNavigationScreen>
    with SingleTickerProviderStateMixin {
  final TripService _tripService = TripService();
  final MapController _mapController = MapController();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late final LatLng _pickupLatLng;
  late final LatLng _dropoffLatLng;
  LatLng _driverLatLng = MapRouteService.lastKnownDriverGps?.position ??
      MapRouteService.defaultDriverSpawn;
  LatLng _lastRoutedGps = MapRouteService.defaultDriverSpawn;
  double _driverHeading = 0.0;
  String _driverCurrentStreet = 'Mendeteksi jalan...';

  GasMapStyle _mapStyle = GasMapStyle.street;
  List<LatLng> _pickupRoutePoints = [];
  List<LatLng> _tripPreviewPoints = [];
  List<LatLng> _simulationPath = [];
  int _simulationIndex = 0;

  double _distanceKm = 1.4;
  int _etaMinutes = 4;
  bool _hasArrived = false;
  bool _isLoadingRoute = true;
  bool _isMapReady = false;
  bool _isSimulating = false;
  bool _isRealDeviceGps =
      MapRouteService.lastKnownDriverGps?.isRealDeviceGps ?? false;

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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initNavigationMap();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _gpsSub?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initNavigationMap() async {
    final gps = await MapRouteService.getCurrentDriverPosition();

    if (!mounted) return;
    setState(() {
      _driverLatLng = gps.position;
      _lastRoutedGps = gps.position;
      _driverHeading = gps.heading != 0.0
          ? gps.heading
          : MapRouteService.calculateBearingDegrees(_driverLatLng, _pickupLatLng);
      _isRealDeviceGps = gps.isRealDeviceGps;
    });

    await Future.wait([
      _loadRoutes(),
      _updateCurrentStreet(gps.position),
    ]);
    _startGpsListener();
    _syncDriverLocationThrottled();
  }

  Future<void> _updateCurrentStreet(LatLng pos) async {
    final street = await MapRouteService.reverseGeocodePosition(pos);
    if (!mounted) return;
    setState(() => _driverCurrentStreet = street);
  }

  Future<void> _recenterToDeviceGps() async {
    setState(() => _isLoadingRoute = true);
    final gps = await MapRouteService.getCurrentDriverPosition();
    if (!mounted) return;

    setState(() {
      _isSimulating = false;
      _driverLatLng = gps.position;
      _lastRoutedGps = gps.position;
      _isRealDeviceGps = gps.isRealDeviceGps;
      _driverHeading = gps.heading != 0.0
          ? gps.heading
          : MapRouteService.calculateBearingDegrees(gps.position, _pickupLatLng);
    });
    _simulationTimer?.cancel();

    await Future.wait([
      _loadRoutes(),
      _updateCurrentStreet(gps.position),
    ]);
    _fitRouteBounds();
  }

  Future<void> _loadRoutes() async {
    final results = await Future.wait([
      MapRouteService.fetchRoadRoute(_driverLatLng, _pickupLatLng),
      MapRouteService.fetchRoadRoute(_pickupLatLng, _dropoffLatLng),
    ]);

    if (!mounted) return;
    final toPickup = results[0];
    final toDropoff = results[1];

    setState(() {
      _pickupRoutePoints = toPickup.points;
      _tripPreviewPoints = toDropoff.points;
      _simulationPath = MapRouteService.densifyRoutePoints(toPickup.points);
      _simulationIndex = 0;
      _distanceKm = toPickup.distanceKm;
      _etaMinutes = toPickup.durationMinutes;
      _isLoadingRoute = false;
    });

    if (_isMapReady) {
      _fitRouteBounds();
    }
  }

  void _startGpsListener() {
    _gpsSub = MapRouteService.watchDriverPosition().listen((gps) async {
      if (!mounted || _isSimulating) return;

      final distMeters = MapRouteService.distanceInMeters(
        gps.position,
        _pickupLatLng,
      );
      final newHeading = gps.heading != 0.0
          ? gps.heading
          : MapRouteService.calculateBearingDegrees(_driverLatLng, gps.position);

      final movedSinceRoute = MapRouteService.distanceInMeters(
        _lastRoutedGps,
        gps.position,
      );

      setState(() {
        _driverLatLng = gps.position;
        _driverHeading = newHeading;
        _isRealDeviceGps = true;
        _distanceKm = distMeters / 1000.0;
        _etaMinutes = math.max(1, ((_distanceKm / 24.0) * 60.0).ceil());
      });

      _syncDriverLocationThrottled();

      if (movedSinceRoute > 20) {
        _lastRoutedGps = gps.position;
        final route = await MapRouteService.fetchRoadRoute(
          gps.position,
          _pickupLatLng,
        );
        if (!mounted) return;
        setState(() {
          _pickupRoutePoints = route.points;
          _simulationPath = MapRouteService.densifyRoutePoints(route.points);
          _distanceKm = route.distanceKm;
          _etaMinutes = route.durationMinutes;
        });
        _updateCurrentStreet(gps.position);
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
        const SnackBar(content: Text('Rute belum siap untuk disimulasikan.')),
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
          _distanceKm = 0.0;
          _etaMinutes = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulasi motor telah sampai di titik jemput!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final current = _simulationPath[_simulationIndex];
      final next = _simulationPath[_simulationIndex + 1];
      final bearing = MapRouteService.calculateBearingDegrees(current, next);
      final remainingMeters =
          MapRouteService.distanceInMeters(next, _pickupLatLng);
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
          _driverLatLng,
          _pickupLatLng,
          ..._pickupRoutePoints,
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
      destination: _pickupLatLng,
    );
    if (!mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak dapat membuka Google Maps eksternal untuk: ${widget.pickupAddress}',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      _mapStyle == GasMapStyle.street
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    );

    final remainingRoute = _isSimulating && _simulationIndex > 0
        ? _simulationPath.sublist(
            math.min(_simulationIndex, _simulationPath.length - 1),
          )
        : _pickupRoutePoints;

    return Scaffold(
      backgroundColor: kCampusDark,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
          // 1. Peta Asli Interaktif (OpenStreetMap / CartoDB / Esri)
          Positioned.fill(
            child: GasKampusLiveMap(
              mapController: _mapController,
              mapStyle: _mapStyle,
              initialCenter: _pickupLatLng,
              initialZoom: 14.8,
              onMapReady: () {
                _isMapReady = true;
                _fitRouteBounds();
              },
              polylines: [
                if (_tripPreviewPoints.length >= 2)
                  Polyline(
                    points: _tripPreviewPoints,
                    color: Colors.blueGrey.withValues(alpha: 0.7),
                    strokeWidth: 4.0,
                    pattern: StrokePattern.dashed(segments: const [10, 7]),
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
                  point: _dropoffLatLng,
                  label: 'Tujuan · ${widget.zone}',
                  color: Colors.deepOrange,
                  icon: Icons.flag_rounded,
                ),
                MapRouteService.buildPlacePinMarker(
                  point: _pickupLatLng,
                  label: 'Jemput Penumpang',
                  color: const Color(0xFF16A34A),
                  icon: Icons.person_pin_circle_rounded,
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
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
                                  Icon(
                                    _hasArrived
                                        ? Icons.check_circle
                                        : Icons.navigation,
                                    color: _hasArrived
                                        ? Colors.green
                                        : Colors.blueAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _hasArrived
                                          ? 'Sampai di Titik Jemput'
                                          : 'Menjemput · ${_distanceKm.toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isRealDeviceGps
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : kPrimary.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _isRealDeviceGps ? 'GPS' : 'LIVE',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: kCampusDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTopNavButton(
                          icon: Icons.directions_rounded,
                          onTap: _openGoogleMaps,
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

          // 3. Kontrol Mengambang + Bottom Sheet Info Card
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
                    onFitRoute: _recenterToDeviceGps,
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
                _buildBottomInfoCard(context),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInfoCard(BuildContext context) {
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

          // Route details
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
                  Icons.turn_right,
                  color: Colors.black87,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Titik Jemput Mahasiswa',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '· ${_distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.pickupAddress,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Posisi Anda: $_driverCurrentStreet',
                      style: const TextStyle(
                        color: Colors.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tujuan: ${widget.dropoffAddress} (${widget.zone})',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _hasArrived || _etaMinutes == 0
                        ? 'Sampai'
                        : '$_etaMinutes min',
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

          // Passenger Info & Chat/Call/GMaps
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
                            '${widget.passengerRole} · ${widget.paymentMethod}',
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
                          content: Text('Membuka chat dengan mahasiswa...'),
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

          // Action Button
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
              onPressed: () async {
                if (!_hasArrived) {
                  await _tripService.updateTripStatus(
                    orderId: widget.orderId,
                    status: 'arrived',
                  );
                  if (!context.mounted) return;
                  setState(() => _hasArrived = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Status: Driver sudah sampai di titik jemput (notifikasi dikirim ke mahasiswa).',
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  _simulationTimer?.cancel();
                  await _tripService.updateTripStatus(
                    orderId: widget.orderId,
                    status: 'onTrip',
                  );
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DriverUmumActiveTripScreen(
                        orderId: widget.orderId,
                        passengerName: widget.passengerName,
                        passengerRole: widget.passengerRole,
                        fareAmount: widget.fareAmount,
                        pickupAddress: widget.pickupAddress,
                        dropoffAddress: widget.dropoffAddress,
                        paymentMethod: widget.paymentMethod,
                        zone: widget.zone,
                      ),
                    ),
                  );
                }
              },
              child: Text(
                _hasArrived
                    ? 'Konfirmasi Penumpang Naik & Mulai Perjalanan'
                    : 'Saya Sudah Sampai di Titik Jemput',
                style: const TextStyle(
                  fontSize: 13.5,
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
