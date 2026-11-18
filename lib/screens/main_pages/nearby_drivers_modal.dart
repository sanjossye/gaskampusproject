import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/map_route_service.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kPrimaryDeep = Color(0xFF8DBF1A);
const Color kTextOnPrimary = Color(0xFF1D2210);
const Color kCardDark = Color(0xFF1C2414);
const Color kBorderDark = Color(0xFF2A3518);
const Color kBorderLight = Color(0xFFE5EAD7);

void showNearbyDriversModal(
  BuildContext context, {
  ValueChanged<Map<String, dynamic>>? onOrderWithDriver,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _NearbyDriversSheet(onOrderWithDriver: onOrderWithDriver),
  );
}

class _NearbyDriversSheet extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onOrderWithDriver;

  const _NearbyDriversSheet({this.onOrderWithDriver});

  @override
  State<_NearbyDriversSheet> createState() => _NearbyDriversSheetState();
}

class _NearbyDriversSheetState extends State<_NearbyDriversSheet>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _radarCtrl;
  bool _isSearching = true;
  bool _isMapReady = false;
  String _searchStatusText = 'Mendeteksi sinyal GPS mahasiswa di Medan...';
  Timer? _statusTimer;
  Timer? _completeTimer;

  GasMapStyle _mapStyle = GasMapStyle.street;
  LatLng _studentPos =
      MapRouteService.lastKnownDriverGps?.position ??
      MapRouteService.defaultKampusCenter;
  bool _isRealGps =
      MapRouteService.lastKnownDriverGps?.isRealDeviceGps ?? false;
  String _studentStreet = 'Area Kampus USU Medan';

  int _selectedDriverIndex = 0;
  List<LatLng> _selectedDriverRoute = [];

  final List<Map<String, dynamic>> _drivers = [
    {
      'name': 'Budi Santoso',
      'role': 'Driver Mahasiswa · FMIPA USU',
      'bike': 'Honda Vario 125',
      'plat': 'BK 1234 GKS',
      'rating': '4.9',
      'trips': '120 trip',
      'zone': 'Zona B · Fak. Teknik & Fasilkom USU',
      'locationName': 'Fakultas Teknik USU',
      'latLng': const LatLng(3.5612, 98.6540),
      'color': const Color(0xFFC0F637),
    },
    {
      'name': 'Siti Aminah',
      'role': 'Driver Mahasiswa · FEB USU',
      'bike': 'Yamaha Fazzio',
      'plat': 'BK 4567 KMP',
      'rating': '5.0',
      'trips': '98 trip',
      'zone': 'Zona A · Biro Rektor & Pintu 1 USU',
      'locationName': 'Biro Rektor USU',
      'latLng': const LatLng(3.5655, 98.6565),
      'color': const Color(0xFF54A0FF),
    },
    {
      'name': 'Agus Prabowo',
      'role': 'Driver Umum · Mitra Reguler',
      'bike': 'Honda Beat',
      'plat': 'BK 5678 UMM',
      'rating': '4.8',
      'trips': '512 trip',
      'zone': 'Zona C · Perpus Pusat & Pintu 4 USU',
      'locationName': 'Perpustakaan Pusat USU',
      'latLng': const LatLng(3.5635, 98.6580),
      'color': const Color(0xFFFF9F43),
    },
    {
      'name': 'Rizky Pratama',
      'role': 'Driver Umum · Mitra Reguler',
      'bike': 'Honda Beat Street',
      'plat': 'BK 9012 UMM',
      'rating': '4.8',
      'trips': '310 trip',
      'zone': 'Zona D · Padang Bulan & Dr. Mansyur',
      'locationName': 'Jl. Dr. Mansyur Medan',
      'latLng': const LatLng(3.5565, 98.6522),
      'color': const Color(0xFFA78BFA),
    },
  ];

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _initStudentGps();
    _startSearchProcess();
  }

  Future<void> _initStudentGps() async {
    final gps = await MapRouteService.getCurrentDriverPosition(
      campusFallback: MapRouteService.defaultKampusCenter,
    );
    if (!mounted) return;
    setState(() {
      _studentPos = gps.position;
      _isRealGps = gps.isRealDeviceGps;
    });
    final addr = await MapRouteService.reverseGeocodePosition(gps.position);
    if (!mounted) return;
    setState(() => _studentStreet = addr);
    _loadRouteFromSelectedDriver();
  }

  Future<void> _loadRouteFromSelectedDriver() async {
    final drvPos = _drivers[_selectedDriverIndex]['latLng'] as LatLng;
    final route = await MapRouteService.fetchRoadRoute(drvPos, _studentPos);
    if (!mounted) return;
    setState(() {
      _selectedDriverRoute = route.points;
    });
    _fitMapToDriverAndStudent();
  }

  void _fitMapToDriverAndStudent() {
    if (!_isMapReady) return;
    final drvPos = _drivers[_selectedDriverIndex]['latLng'] as LatLng;
    try {
      final bounds = LatLngBounds.fromPoints([
        _studentPos,
        drvPos,
        ..._selectedDriverRoute,
      ]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(42),
          maxZoom: 16.2,
        ),
      );
    } catch (_) {
      _mapController.move(_studentPos, 15.0);
    }
  }

  void _selectDriver(int index) {
    setState(() => _selectedDriverIndex = index);
    _loadRouteFromSelectedDriver();
  }

  void _cycleMapStyle() {
    const styles = GasMapStyle.values;
    final nextIdx = (styles.indexOf(_mapStyle) + 1) % styles.length;
    setState(() => _mapStyle = styles[nextIdx]);
  }

  void _startSearchProcess() {
    setState(() {
      _isSearching = true;
      _searchStatusText = 'Mendeteksi sinyal GPS mahasiswa di Medan...';
    });

    _statusTimer?.cancel();
    _completeTimer?.cancel();

    _statusTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _searchStatusText =
              'Memindai driver aktif di Zona A, B, C, dan D Kampus USU...';
        });
      }
    });

    _completeTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        _loadRouteFromSelectedDriver();
      }
    });
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _statusTimer?.cancel();
    _completeTimer?.cancel();
    _mapController.dispose();
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
        maxHeight: MediaQuery.of(context).size.height * 0.90,
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
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.radar_rounded,
                          color: kPrimaryDeep,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Peta Radar Driver Kampus',
                              style: TextStyle(
                                color: tp,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Lokasi: $_studentStreet',
                              style: TextStyle(color: ts, fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, color: tp, size: 18),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(color: border, height: 1),

          // Main Animated Body
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _isSearching
                  ? _buildRadarAnimation(tp, ts, isDark)
                  : _buildLiveMapAndDriversList(
                      tp,
                      ts,
                      cardBg,
                      border,
                      isDark,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarAnimation(Color tp, Color ts, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: AnimatedBuilder(
              animation: _radarCtrl,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildPulseRing(
                      scale: (_radarCtrl.value + 0.66) % 1.0,
                      maxSize: 180,
                    ),
                    _buildPulseRing(
                      scale: (_radarCtrl.value + 0.33) % 1.0,
                      maxSize: 180,
                    ),
                    _buildPulseRing(scale: _radarCtrl.value, maxSize: 180),
                    Container(
                      width: 64,
                      height: 64,
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
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Memindai Peta Kampus USU Medan...',
            style: TextStyle(
              color: tp,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchStatusText,
            textAlign: TextAlign.center,
            style: TextStyle(color: ts, fontSize: 13),
          ),
          const SizedBox(height: 18),
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

  Widget _buildLiveMapAndDriversList(
    Color tp,
    Color ts,
    Color cardBg,
    Color border,
    bool isDark,
  ) {
    return ListView(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        // ── Live Google Maps Canvas ──────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 235,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GasKampusLiveMap(
                    mapController: _mapController,
                    mapStyle: _mapStyle,
                    initialCenter: _studentPos,
                    initialZoom: 15.0,
                    onMapReady: () {
                      _isMapReady = true;
                      _fitMapToDriverAndStudent();
                    },
                    polylines: [
                      if (_selectedDriverRoute.length >= 2)
                        Polyline(
                          points: _selectedDriverRoute,
                          color: kPrimary,
                          strokeWidth: 5.5,
                          borderStrokeWidth: 2.0,
                          borderColor: const Color(0xFF1D2210),
                        ),
                    ],
                    markers: [
                      // Marker Lokasi Mahasiswa
                      MapRouteService.buildPlacePinMarker(
                        point: _studentPos,
                        label: 'Lokasi Kamu',
                        color: const Color(0xFF16A34A),
                        icon: Icons.person_pin_circle_rounded,
                      ),
                      // Marker Semua Driver Aktif di Sekitar Kampus
                      ...List.generate(_drivers.length, (i) {
                        final drv = _drivers[i];
                        final drvPos = drv['latLng'] as LatLng;
                        final isSelected = i == _selectedDriverIndex;
                        return Marker(
                          point: drvPos,
                          width: 110,
                          height: 62,
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTap: () => _selectDriver(i),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? kPrimary
                                        : const Color(0xFF1D2210),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.black
                                          : kPrimary,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    drv['name'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  width: isSelected ? 34 : 28,
                                  height: isSelected ? 34 : 28,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? kPrimary
                                        : const Color(0xFF1D2210),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black38,
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.two_wheeler_rounded,
                                    size: isSelected ? 18 : 15,
                                    color: isSelected
                                        ? Colors.black
                                        : kPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Badge GPS Status di Kiri Atas Peta
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D2210).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: kPrimary.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isRealGps ? Icons.gps_fixed : Icons.location_on,
                          color: kPrimary,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isRealGps ? 'GPS Live Aktif' : 'Peta Kampus USU Medan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tombol Kontrol Peta di Kanan Atas Peta
                Positioned(
                  top: 10,
                  right: 10,
                  child: Column(
                    children: [
                      _mapMiniBtn(
                        icon: _mapStyle.icon,
                        tooltip: 'Ganti Tema Peta (${_mapStyle.label})',
                        onTap: _cycleMapStyle,
                      ),
                      const SizedBox(height: 6),
                      _mapMiniBtn(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Paskan Rute ke Lokasi Kamu',
                        onTap: _fitMapToDriverAndStudent,
                      ),
                      const SizedBox(height: 6),
                      _mapMiniBtn(
                        icon: Icons.directions_rounded,
                        tooltip: 'Buka di Google Maps',
                        onTap: () {
                          final drvPos =
                              _drivers[_selectedDriverIndex]['latLng']
                                  as LatLng;
                          MapRouteService.openGoogleMapsNavigation(
                            origin: drvPos,
                            destination: _studentPos,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Info Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: isDark ? 0.14 : 0.22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kPrimary.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: kPrimaryDeep,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ketuk driver untuk melihat rute jemput langsung di peta.',
                  style: TextStyle(
                    color: tp,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _startSearchProcess,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 15,
                  color: kPrimaryDeep,
                ),
                label: const Text(
                  'Scan Ulang',
                  style: TextStyle(
                    color: kPrimaryDeep,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Daftar Driver Terdekat
        ...List.generate(_drivers.length, (i) {
          final d = _drivers[i];
          final isSelected = i == _selectedDriverIndex;
          final metrics = MapRouteService.estimateMetricsFromDevice(
            _studentPos,
            d['locationName'] as String,
          );
          final km = (metrics['distanceKm'] as double).toStringAsFixed(1);
          final eta = metrics['etaMinutes'] as int;

          return GestureDetector(
            onTap: () => _selectDriver(i),
            child: _buildDriverCard(
              driver: d,
              distanceLabel: '$km km',
              etaLabel: '~$eta mnt',
              isSelected: isSelected,
              tp: tp,
              ts: ts,
              cardBg: cardBg,
              border: border,
              isDark: isDark,
            ),
          );
        }),
      ],
    );
  }

  Widget _mapMiniBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.94),
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 17, color: Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverCard({
    required Map<String, dynamic> driver,
    required String distanceLabel,
    required String etaLabel,
    required bool isSelected,
    required Color tp,
    required Color ts,
    required Color cardBg,
    required Color border,
    required bool isDark,
  }) {
    final Color badgeColor = driver['color'] as Color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected
            ? kPrimary.withValues(alpha: isDark ? 0.14 : 0.18)
            : cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? kPrimary : border,
          width: isSelected ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(Icons.person_rounded, color: tp, size: 24),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ED573),
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBg, width: 2),
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        driver['name'] as String,
                        style: TextStyle(
                          color: tp,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
                        color: kPrimary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: kPrimaryDeep,
                            size: 11,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            driver['rating'] as String,
                            style: TextStyle(
                              color: tp,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  driver['role'] as String,
                  style: TextStyle(
                    color: ts,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${driver['bike']} · ${driver['plat']}',
                  style: TextStyle(
                    color: tp.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
                distanceLabel,
                style: TextStyle(
                  color: tp,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                etaLabel,
                style: const TextStyle(
                  color: kPrimaryDeep,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  if (widget.onOrderWithDriver != null) {
                    widget.onOrderWithDriver!(driver);
                  }
                },
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Pesan',
                    style: TextStyle(
                      color: kTextOnPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
