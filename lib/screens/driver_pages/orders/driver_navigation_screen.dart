import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'driver_active_trip_screen.dart';
import '../../../services/map_route_service.dart';

const Color kGojekGreen = Color(0xFF68CD5C);
const Color kGojekNeon = Color(0xFFC1F637);
const Color kCampusDark = Color(0xFF1A1A1A);

class DriverNavigationScreen extends StatefulWidget {
  const DriverNavigationScreen({super.key});

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late LatLng _driverLatLng;
  late LatLng _lastRoutedGps;
  late final LatLng _pickupLatLng;
  late final LatLng _dropoffLatLng;

  List<LatLng> _routePoints = [];
  List<LatLng> _previewPoints = [];
  bool _isMapReady = false;
  double _distanceKm = 0.9;
  int _etaMinutes = 3;
  StreamSubscription<DriverGpsResult>? _gpsSub;

  @override
  void initState() {
    super.initState();
    _driverLatLng = MapRouteService.lastKnownDriverGps?.position ??
        MapRouteService.resolveCoordinate('Pintu 1 USU');
    _lastRoutedGps = _driverLatLng;
    _pickupLatLng = MapRouteService.resolveCoordinate('Fakultas Teknik USU');
    _dropoffLatLng = MapRouteService.resolveCoordinate('Perpustakaan Pusat USU');

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initDeviceAndRoute();
  }

  Future<void> _initDeviceAndRoute() async {
    final gps = await MapRouteService.getCurrentDriverPosition(
      campusFallback: MapRouteService.resolveCoordinate('Pintu 1 USU'),
    );
    if (!mounted) return;
    setState(() {
      _driverLatLng = gps.position;
      _lastRoutedGps = gps.position;
    });
    await _loadMedanRoute();

    _gpsSub = MapRouteService.watchDriverPosition().listen((liveGps) async {
      if (!mounted) return;
      final moved = MapRouteService.distanceInMeters(_lastRoutedGps, liveGps.position);
      final distKm = MapRouteService.distanceInMeters(liveGps.position, _pickupLatLng) / 1000.0;
      setState(() {
        _driverLatLng = liveGps.position;
        _distanceKm = distKm;
        _etaMinutes = (distKm / 24.0 * 60.0).ceil().clamp(1, 999);
      });
      if (moved > 20) {
        _lastRoutedGps = liveGps.position;
        await _loadMedanRoute();
      }
    });
  }

  Future<void> _loadMedanRoute() async {
    final results = await Future.wait([
      MapRouteService.fetchRoadRoute(_driverLatLng, _pickupLatLng),
      MapRouteService.fetchRoadRoute(_pickupLatLng, _dropoffLatLng),
    ]);
    if (!mounted) return;

    setState(() {
      _routePoints = results[0].points;
      _previewPoints = results[1].points;
      _distanceKm = results[0].distanceKm;
      _etaMinutes = results[0].durationMinutes;
    });
    _fitRouteBounds();
  }

  void _fitRouteBounds() {
    if (!_isMapReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isMapReady) return;
      try {
        final bounds = LatLngBounds.fromPoints([
          _driverLatLng,
          _pickupLatLng,
          ..._routePoints,
        ]);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.fromLTRB(48, 100, 48, 280),
            maxZoom: 16.8,
          ),
        );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Peta Interaktif Asli Kampus USU Medan
            Positioned.fill(
              child: GasKampusLiveMap(
                mapController: _mapController,
                mapStyle: GasMapStyle.street,
                initialCenter: _pickupLatLng,
                initialZoom: 15.6,
                onMapReady: () {
                  _isMapReady = true;
                  _fitRouteBounds();
                },
                polylines: [
                  if (_previewPoints.length >= 2)
                    Polyline(
                      points: _previewPoints,
                      color: Colors.blueGrey.withValues(alpha: 0.65),
                      strokeWidth: 4.0,
                      pattern: StrokePattern.dashed(segments: const [10, 7]),
                    ),
                  if (_routePoints.length >= 2)
                    Polyline(
                      points: _routePoints,
                      color: kGojekNeon,
                      strokeWidth: 6.5,
                      borderStrokeWidth: 2.0,
                      borderColor: kCampusDark,
                    ),
                ],
                markers: [
                  MapRouteService.buildPlacePinMarker(
                    point: _dropoffLatLng,
                    label: 'Perpustakaan Pusat USU',
                    color: Colors.deepOrange,
                    icon: Icons.flag_rounded,
                  ),
                  MapRouteService.buildPlacePinMarker(
                    point: _pickupLatLng,
                    label: 'Jemput · Fak. Teknik USU',
                    color: kGojekGreen,
                    icon: Icons.person_pin_circle_rounded,
                  ),
                  MapRouteService.buildDriverMotorMarker(
                    point: _driverLatLng,
                    headingDegrees: MapRouteService.calculateBearingDegrees(
                      _driverLatLng,
                      _pickupLatLng,
                    ),
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
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTopNavButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: kCampusDark,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _pulseAnimation.value > 1.0 ? 1.0 : 0.5,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: kGojekNeon,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Menjemput · ${_distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildTopNavButton(
                        icon: Icons.directions_rounded,
                        onTap: () => MapRouteService.openGoogleMapsNavigation(
                          origin: _driverLatLng,
                          destination: _pickupLatLng,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Bottom Panel
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: kGojekGreen,
                                        width: 2,
                                      ),
                                      image: const DecorationImage(
                                        image: NetworkImage(
                                          'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=200&q=80',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -4,
                                    right: -4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.star,
                                            color: Colors.black,
                                            size: 8,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            '4.9',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Andi Pratama',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.location_on,
                                          color: kGojekGreen,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Fakultas Teknik USU, Medan',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$_etaMinutes min',
                              style: const TextStyle(
                                color: kGojekGreen,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'ESTIMATED ARRIVAL',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.phone_outlined,
                            label: 'Call',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Anda sudah sampai di titik jemput.'),
                            ),
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DriverActiveTripScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGojekNeon,
                          foregroundColor: kCampusDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: kGojekNeon.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Saya Sudah Sampai',
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 24),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kGojekGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kGojekGreen, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: kGojekGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
