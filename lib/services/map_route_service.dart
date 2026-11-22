import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gas_kampusapp/services/seed_services.dart';
import 'package:gas_kampusapp/services/zone_service.dart';

enum GasMapStyle {
  street('Jalan', Icons.map_outlined),
  dark('Terrain', Icons.terrain_outlined),
  satellite('Satelit', Icons.satellite_alt_outlined);

  final String label;
  final IconData icon;
  const GasMapStyle(this.label, this.icon);

  String get urlTemplate {
    switch (this) {
      case GasMapStyle.street:
        return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
      case GasMapStyle.dark:
        return 'https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
      case GasMapStyle.satellite:
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
    }
  }
}

// ── Value objects dikembalikan oleh MapRouteService ──────────────────────────

/// Hasil rute jalan (dari OSRM atau fallback lokal).
class RoadRouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final bool isRealRoad;

  const RoadRouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.isRealRoad,
  });
}

/// Hasil GPS driver — posisi + heading + flag apakah GPS perangkat nyata.
class DriverGpsResult {
  final LatLng position;
  final double heading;
  final bool isRealDeviceGps;

  const DriverGpsResult({
    required this.position,
    this.heading = 0.0,
    this.isRealDeviceGps = false,
  });
}

/// Service Geospatial, Routing Jalan Raya (OSRM), Geofencing Kampus, dan Live GPS
class MapRouteService {
  /// Pusat Kampus USU Padang Bulan, Medan
  static const LatLng defaultKampusCenter = LatLng(3.5625, 98.6562);
  /// Koordinat default dari posisi sensor laptop saat ini di Medan
  static const LatLng defaultDriverSpawn = LatLng(3.555454, 98.657995);
  static const Distance _distanceCalc = Distance();

  /// Kamus Koordinat Asli Lokasi Kampus USU & Kota Medan
  static final Map<String, LatLng> _knownLocations = {
    'stasiun medan': const LatLng(3.5912, 98.6775),
    'merdeka walk': const LatLng(3.5904, 98.6766),
    'plaza medan fair': const LatLng(3.5914, 98.6615),
    'sun plaza': const LatLng(3.5835, 98.6716),
    'sun plaza medan': const LatLng(3.5835, 98.6716),
    'centre point': const LatLng(3.5916, 98.6801),
    'mall centre point medan': const LatLng(3.5916, 98.6801),
    'manhattan times square': const LatLng(3.5786, 98.6258),
    'ringroad city walks': const LatLng(3.5698, 98.6264),
    'taman setia budi indah (tasbi)': const LatLng(3.5562, 98.6345),
    'tasbi medan': const LatLng(3.5562, 98.6345),
    'gedung c - zona b (fakultas teknik usu)': const LatLng(3.5612, 98.6540),
    'fakultas teknik usu': const LatLng(3.5612, 98.6540),
    'fakultas teknik usu, pintu 2': const LatLng(3.5618, 98.6534),
    'gedung fakultas teknik usu': const LatLng(3.5612, 98.6540),
    'fakultas teknik': const LatLng(3.5612, 98.6540),
    'zona b': const LatLng(3.5612, 98.6540),
    'fasilkom-ti usu': const LatLng(3.5620, 98.6592),
    'fakultas ilmu komputer usu': const LatLng(3.5620, 98.6592),
    'biro rektor - zona a (rektorat usu)': const LatLng(3.5655, 98.6565),
    'biro rektor usu': const LatLng(3.5655, 98.6565),
    'gedung biro rektor usu': const LatLng(3.5655, 98.6565),
    'gedung rektorat usu': const LatLng(3.5655, 98.6565),
    'rektorat': const LatLng(3.5655, 98.6565),
    'zona a': const LatLng(3.5655, 98.6565),
    'auditorium usu': const LatLng(3.5642, 98.6572),
    'perpustakaan pusat usu': const LatLng(3.5635, 98.6580),
    'perpus pusat': const LatLng(3.5635, 98.6580),
    'zona c': const LatLng(3.5635, 98.6580),
    'vokasi usu': const LatLng(3.5592, 98.6552),
    'kantin vokasi usu': const LatLng(3.5592, 98.6552),
    'kantin fib usu': const LatLng(3.5604, 98.6586),
    'pintu 1 usu': const LatLng(3.5675, 98.6566),
    'gerbang utama usu (pintu 1)': const LatLng(3.5675, 98.6566),
    'pintu 4 usu': const LatLng(3.5588, 98.6602),
    'gerbang pintu 4 usu': const LatLng(3.5588, 98.6602),
    'asrama mahasiswa usu': const LatLng(3.5575, 98.6585),
    'stadion mini usu': const LatLng(3.5608, 98.6568),
    'rs usu': const LatLng(3.5618, 98.6505),
    'kosan sumber': const LatLng(3.5502, 98.6488),
    'padang bulan medan': const LatLng(3.5502, 98.6488),
    'jl. dr. mansyur medan': const LatLng(3.5565, 98.6522),
    'zona d': const LatLng(3.5502, 98.6488),
    // Alias order lama agar tetap terpetakan di Medan
    'stasiun depok baru': const LatLng(3.5912, 98.6775),
    'margo city mall': const LatLng(3.5914, 98.6615),
    'margo city': const LatLng(3.5914, 98.6615),
    'margonda residence': const LatLng(3.5562, 98.6345),
    'balairung': const LatLng(3.5655, 98.6565),
    'stasiun pondok cina': const LatLng(3.5675, 98.6566),
    'gerbatama': const LatLng(3.5675, 98.6566),
    'stasiun ui': const LatLng(3.5588, 98.6602),
    'kosan ciseke': const LatLng(3.5502, 98.6488),
    'dmall depok': const LatLng(3.5786, 98.6258),
    'itc depok': const LatLng(3.5835, 98.6716),
    'pesona square': const LatLng(3.5916, 98.6801),
  };

  /// Mencocokkan nama alamat/lokasi atau zona dengan koordinat peta nyata
  static LatLng resolveCoordinate(String address, {String? fallbackZone}) {
    final normalized = address.toLowerCase().trim();

    if (_knownLocations.containsKey(normalized)) {
      return _knownLocations[normalized]!;
    }

    for (final entry in _knownLocations.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    if (fallbackZone != null) {
      final zoneKey = fallbackZone.toLowerCase().trim();
      for (final entry in _knownLocations.entries) {
        if (zoneKey.contains(entry.key) || entry.key.contains(zoneKey)) {
          return entry.value;
        }
      }
    }

    return defaultKampusCenter;
  }

  /// Polygon Geofencing dipindahkan ke ZoneService — lihat lib/services/zone_service.dart

  /// Mencari koordinat alamat secara online (Photon Geocoder) jika tidak ada di kamus lokal
  static Future<LatLng> searchOrResolveCoordinate(
    String address, {
    LatLng? nearPos,
    String? fallbackZone,
  }) async {
    final normalized = address.toLowerCase().trim();
    if (normalized.isEmpty) return nearPos ?? defaultKampusCenter;

    if (_knownLocations.containsKey(normalized)) {
      return _knownLocations[normalized]!;
    }
    for (final entry in _knownLocations.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    final ref = nearPos ?? lastKnownDriverGps?.position ?? defaultKampusCenter;
    try {
      final q = Uri.encodeComponent('$address Medan');
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?q=$q&lat=${ref.latitude}&lon=${ref.longitude}&limit=1',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>?;
        if (features != null && features.isNotEmpty) {
          final geom =
              (features.first as Map<String, dynamic>)['geometry']
                  as Map<String, dynamic>?;
          final coords = geom?['coordinates'] as List<dynamic>?;
          if (coords != null && coords.length >= 2) {
            final lng = (coords[0] as num).toDouble();
            final lat = (coords[1] as num).toDouble();
            if (_isInsideIndonesia(lat, lng)) {
              return LatLng(lat, lng);
            }
          }
        }
      }
    } catch (_) {}

    return resolveCoordinate(address, fallbackZone: fallbackZone);
  }

  /// Mendapatkan rute jalan asli via OSRM (OpenStreetMap Routing Machine)
  static Future<RoadRouteResult> fetchRoadRoute(LatLng start, LatLng end) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = decoded['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes.first as Map<String, dynamic>;
          final geometry = firstRoute['geometry'] as Map<String, dynamic>;
          final coords = geometry['coordinates'] as List<dynamic>;

          final points = coords.map((pt) {
            final pair = pt as List<dynamic>;
            return LatLng(
              (pair[1] as num).toDouble(),
              (pair[0] as num).toDouble(),
            );
          }).toList();

          if (points.length >= 2) {
            final distMeters = (firstRoute['distance'] as num).toDouble();
            final distKm = distMeters / 1000.0;
            final durationSec = (firstRoute['duration'] as num).toDouble();
            final mins = math.max(1, (durationSec / 60.0).ceil());
            return RoadRouteResult(
              points: points,
              distanceKm: distKm,
              durationMinutes: mins,
              isRealRoad: true,
            );
          }
        }
      }
    } catch (_) {
      // Fallback ke multi-point lokal bila offline / timeout
    }

    return _buildFallbackRoute(start, end);
  }

  static RoadRouteResult _buildFallbackRoute(LatLng start, LatLng end) {
    final totalMeters = _distanceCalc.as(LengthUnit.Meter, start, end);
    final distKm = math.max(0.2, (totalMeters * 1.3) / 1000.0);
    final mins = math.max(1, ((distKm / 24.0) * 60.0).ceil());

    // Jalur grid multi-belokan realistis mengikuti orientasi jalan Medan bila OSRM offline
    final dLat = end.latitude - start.latitude;
    final dLng = end.longitude - start.longitude;
    final p1 = LatLng(start.latitude + dLat * 0.35, start.longitude + dLng * 0.05);
    final p2 = LatLng(start.latitude + dLat * 0.38, start.longitude + dLng * 0.52);
    final p3 = LatLng(start.latitude + dLat * 0.78, start.longitude + dLng * 0.58);
    final p4 = LatLng(start.latitude + dLat * 0.82, start.longitude + dLng * 0.94);

    return RoadRouteResult(
      points: [start, p1, p2, p3, p4, end],
      distanceKm: distKm,
      durationMinutes: mins,
      isRealRoad: false,
    );
  }

  /// Cache posisi GPS perangkat terakhir di memori
  static DriverGpsResult? lastKnownDriverGps;

  /// Label nama tempat ramah untuk fallback offline reverse-geocoding terdekat
  static const List<MapEntry<String, LatLng>> _landmarkEntries = [
    MapEntry('Stasiun Medan', LatLng(3.5912, 98.6775)),
    MapEntry('Plaza Medan Fair', LatLng(3.5914, 98.6615)),
    MapEntry('Sun Plaza Medan', LatLng(3.5835, 98.6716)),
    MapEntry('Pintu 1 USU', LatLng(3.5675, 98.6566)),
    MapEntry('Biro Rektor USU', LatLng(3.5655, 98.6565)),
    MapEntry('Perpustakaan Pusat USU', LatLng(3.5635, 98.6580)),
    MapEntry('Fakultas Teknik USU', LatLng(3.5612, 98.6540)),
    MapEntry('Fasilkom-TI USU', LatLng(3.5620, 98.6592)),
    MapEntry('Vokasi USU', LatLng(3.5592, 98.6552)),
    MapEntry('Asrama Mahasiswa USU', LatLng(3.5575, 98.6585)),
    MapEntry('Kosan Sumber / Dr. Mansyur', LatLng(3.5502, 98.6488)),
    MapEntry('Tasbi Medan', LatLng(3.5562, 98.6345)),
  ];

  /// Membaca sensor lokasi laptop Windows melalui bridge lokal (`10.0.2.2:18923` di emulator)
  static Future<DriverGpsResult?> _fetchLaptopBridgeGps() async {
    if (kIsWeb) return null;
    final host = defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';
    final uri = Uri.parse('http://$host:18923/location');
    try {
      final res = await http.get(uri).timeout(const Duration(milliseconds: 1200));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null && _isInsideIndonesia(lat, lng)) {
          return DriverGpsResult(
            position: LatLng(lat, lng),
            isRealDeviceGps: true,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fallback geolokasi berbasis IP jaringan bila GPS perangkat belum aktif
  static Future<LatLng?> _fetchNetworkIpLocation() async {
    try {
      final res = await http
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null && _isInsideIndonesia(lat, lng)) {
          return LatLng(lat, lng);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Mendapatkan posisi GPS live:
  /// 1) Bridge sensor laptop Windows (`GeoCoordinateWatcher` via `10.0.2.2:18923`)
  /// 2) GPS asli perangkat (`Geolocator`, termasuk injeksi `adb emu geo fix`)
  /// 3) Geolokasi IP jaringan (jika di Indonesia)
  /// 4) Fallback Medan
  static Future<DriverGpsResult> getCurrentDriverPosition({
    LatLng? campusFallback,
  }) async {
    final fallback = campusFallback ?? defaultDriverSpawn;

    // 1. Cek bridge sensor laptop Windows (untuk emulator)
    final bridgeGps = await _fetchLaptopBridgeGps();
    if (bridgeGps != null) {
      lastKnownDriverGps = bridgeGps;
      return bridgeGps;
    }

    // 2. Cek hardware GPS Android / HP asli / Browser Geolocation (Web)
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          Position? pos;
          try {
            pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 7),
              ),
            );
          } catch (_) {
            try {
              pos = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.low,
                  timeLimit: Duration(seconds: 5),
                ),
              );
            } catch (_) {
              if (!kIsWeb) {
                pos = await Geolocator.getLastKnownPosition();
              }
            }
          }

          if (pos != null && _isInsideIndonesia(pos.latitude, pos.longitude)) {
            final res = DriverGpsResult(
              position: LatLng(pos.latitude, pos.longitude),
              heading: pos.heading,
              isRealDeviceGps: true,
            );
            lastKnownDriverGps = res;
            return res;
          }
        }
      }
    } catch (_) {}

    // 3. Fallback geolokasi jaringan/IP Indonesia
    final ipPos = await _fetchNetworkIpLocation();
    if (ipPos != null) {
      final res = DriverGpsResult(position: ipPos, isRealDeviceGps: true);
      lastKnownDriverGps = res;
      return res;
    }

    final res = DriverGpsResult(position: fallback, isRealDeviceGps: false);
    lastKnownDriverGps = res;
    return res;
  }

  /// Cek apakah koordinat berada di wilayah Indonesia (hindari default emulator Googleplex USA 37.42,-122.08)
  static bool _isInsideIndonesia(double lat, double lng) {
    return lat >= -11.0 && lat <= 6.5 && lng >= 95.0 && lng <= 141.5;
  }

  /// Stream GPS real-time gabungan sensor laptop bridge + Geolocator perangkat
  static Stream<DriverGpsResult> watchDriverPosition() {
    final controller = StreamController<DriverGpsResult>();
    StreamSubscription<Position>? geoSub;
    Timer? bridgeTimer;
    LatLng? lastEmitted;

    void emitIfValid(DriverGpsResult res) {
      if (controller.isClosed) return;
      if (lastEmitted == null ||
          distanceInMeters(lastEmitted!, res.position) >= 5.0) {
        lastEmitted = res.position;
        lastKnownDriverGps = res;
        controller.add(res);
      }
    }

    controller.onListen = () async {
      // Polling bridge laptop tiap 5 detik jika laptop berpindah tempat
      bridgeTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        final bridge = await _fetchLaptopBridgeGps();
        if (bridge != null) {
          emitIfValid(bridge);
        }
      });

      try {
        final permission = await Geolocator.checkPermission();
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          geoSub = Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 8,
            ),
          ).listen((pos) {
            if (_isInsideIndonesia(pos.latitude, pos.longitude)) {
              emitIfValid(
                DriverGpsResult(
                  position: LatLng(pos.latitude, pos.longitude),
                  heading: pos.heading,
                  isRealDeviceGps: true,
                ),
              );
            }
          }, onError: (_) {});
        }
      } catch (_) {}
    };

    controller.onCancel = () async {
      bridgeTimer?.cancel();
      await geoSub?.cancel();
      await controller.close();
    };

    return controller.stream;
  }

  /// Reverse-geocode koordinat GPS ke nama jalan/kelurahan asli (Photon + BigDataCloud + Fallback)
  static Future<String> reverseGeocodePosition(LatLng pos) async {
    // 1. Photon Komoot Reverse Geocoder (cepat & tidak terblokir)
    try {
      final photonUri = Uri.parse(
        'https://photon.komoot.io/reverse?lon=${pos.longitude}&lat=${pos.latitude}',
      );
      final res = await http.get(photonUri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>?;
        if (features != null && features.isNotEmpty) {
          final props =
              (features.first as Map<String, dynamic>)['properties']
                  as Map<String, dynamic>? ??
              {};
          final street = (props['street'] ?? props['name'] ?? '')
              .toString()
              .trim();
          final area = (props['district'] ??
                  props['locality'] ??
                  props['city'] ??
                  '')
              .toString()
              .trim();
          if (street.isNotEmpty && area.isNotEmpty && street != area) {
            return '$street, $area';
          }
          if (street.isNotEmpty) return street;
          if (area.isNotEmpty) return area;
        }
      }
    } catch (_) {}

    // 2. BigDataCloud Free Reverse Geocoder
    try {
      final bdcUri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client'
        '?latitude=${pos.latitude}&longitude=${pos.longitude}&localityLanguage=id',
      );
      final res = await http.get(bdcUri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final locality = (data['locality'] ?? '').toString().trim();
        final city = (data['city'] ?? data['principalSubdivision'] ?? '')
            .toString()
            .trim();
        if (locality.isNotEmpty && city.isNotEmpty && locality != city) {
          return '$locality, $city';
        }
        if (locality.isNotEmpty) return locality;
        if (city.isNotEmpty) return city;
      }
    } catch (_) {}

    // 3. Fallback ke landmark Medan terdekat jika sepenuhnya offline
    String nearestName = 'Kampus USU Medan';
    double minDistMeters = double.infinity;
    for (final entry in _landmarkEntries) {
      final d = distanceInMeters(pos, entry.value);
      if (d < minDistMeters) {
        minDistMeters = d;
        nearestName = entry.key;
      }
    }
    final distKm = minDistMeters / 1000.0;
    return 'Dekat $nearestName (${distKm.toStringAsFixed(1)} km)';
  }

  /// Menghitung estimasi jarak jalan (km) dan ETA (menit) dari posisi perangkat ke alamat jemput/tujuan
  static Map<String, dynamic> estimateMetricsFromDevice(
    LatLng devicePos,
    String targetAddress, {
    String? fallbackZone,
  }) {
    final targetLatLng = resolveCoordinate(
      targetAddress,
      fallbackZone: fallbackZone,
    );
    final rawMeters = distanceInMeters(devicePos, targetLatLng);
    final estimatedKm = math.max(0.1, (rawMeters * 1.25) / 1000.0);
    final etaMinutes = math.max(1, ((estimatedKm / 24.0) * 60.0).ceil());
    return {
      'distanceKm': estimatedKm,
      'etaMinutes': etaMinutes,
      'targetLatLng': targetLatLng,
    };
  }

  /// Hitung jarak meter antar dua koordinat
  static double distanceInMeters(LatLng a, LatLng b) {
    return _distanceCalc.as(LengthUnit.Meter, a, b);
  }

  /// Memecah segmen polyline yang panjang menjadi titik-titik rapat untuk animasi motor halus
  static List<LatLng> densifyRoutePoints(
    List<LatLng> points, {
    double maxSegmentMeters = 35.0,
  }) {
    if (points.length < 2) return points;
    final result = <LatLng>[points.first];
    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final dist = distanceInMeters(a, b);
      if (dist > maxSegmentMeters) {
        final steps = (dist / maxSegmentMeters).ceil();
        for (int s = 1; s < steps; s++) {
          final t = s / steps;
          result.add(
            LatLng(
              a.latitude + (b.latitude - a.latitude) * t,
              a.longitude + (b.longitude - a.longitude) * t,
            ),
          );
        }
      }
      result.add(b);
    }
    return result;
  }

  /// Hitung sudut arah kompas (derajat 0-360) dari titik A ke B
  static double calculateBearingDegrees(LatLng from, LatLng to) {
    final lat1 = from.latitudeInRad;
    final lon1 = from.longitudeInRad;
    final lat2 = to.latitudeInRad;
    final lon2 = to.longitudeInRad;

    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final brng = math.atan2(y, x);
    return (brng * 180.0 / math.pi + 360.0) % 360.0;
  }

  /// Sync posisi terkini driver ke Cloud Firestore (`driver_locations/{driverId}`)
  static Future<void> syncDriverLocation({
    required String driverId,
    required LatLng position,
    required double heading,
    String? activeOrderId,
    bool isOnline = true,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('driver_locations')
          .doc(driverId)
          .set({
        'driverId': driverId,
        'role': 'driver_umum',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'heading': heading,
        'isOnline': isOnline,
        'activeOrderId': activeOrderId,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Buka aplikasi Google Maps Turn-by-Turn bawaan HP atau browser fallback
  static Future<bool> openGoogleMapsNavigation({
    required LatLng destination,
    LatLng? origin,
  }) async {
    final navUri = Uri.parse(
      'google.navigation:q=${destination.latitude},${destination.longitude}&mode=d',
    );
    final geoUri = Uri.parse(
      'geo:${destination.latitude},${destination.longitude}'
      '?q=${destination.latitude},${destination.longitude}',
    );
    final webUri = Uri.parse(
      origin != null
          ? 'https://www.google.com/maps/dir/?api=1'
              '&origin=${origin.latitude},${origin.longitude}'
              '&destination=${destination.latitude},${destination.longitude}'
              '&travelmode=two-wheeler'
          : 'https://www.google.com/maps/search/?api=1'
              '&query=${destination.latitude},${destination.longitude}',
    );

    try {
      if (await canLaunchUrl(navUri)) {
        return await launchUrl(navUri, mode: LaunchMode.externalApplication);
      }
      if (await canLaunchUrl(geoUri)) {
        return await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Zona polygon layer dipindahkan ke ZoneService — tidak ditampilkan ke UI.

  /// Marker animasi motor driver dengan rotasi arah perjalanan (heading)
  static Marker buildDriverMotorMarker({
    required LatLng point,
    required double headingDegrees,
    required Animation<double> pulseAnimation,
  }) {
    return Marker(
      point: point,
      width: 60,
      height: 60,
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44 * pulseAnimation.value,
                height: 44 * pulseAnimation.value,
                decoration: BoxDecoration(
                  color: const Color(0xFFC0F637).withValues(alpha: 0.28),
                  shape: BoxShape.circle,
                ),
              ),
              Transform.rotate(
                angle: headingDegrees * (math.pi / 180.0),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2210),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFC0F637), width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Color(0xFFC0F637),
                    size: 20,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Marker titik Jemput (Pickup) atau Tujuan (Dropoff) beserta label badge
  static Marker buildPlacePinMarker({
    required LatLng point,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Marker(
      point: point,
      width: 130,
      height: 68,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1D2210),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 1.2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}

/// Saklar boolean untuk menampilkan/menyembunyikan overlay debug Zona A–F di peta.
/// Ubah ke `true` saat ingin mengecek polygon Zona A–F & tap koordinat di mode debug.
const bool kEnableZoneDebugOverlay = false;

/// Canvas peta interaktif asli berbasis Google Maps Tiles (Jalan / Terrain / Satelit)
class GasKampusLiveMap extends StatefulWidget {
  final MapController mapController;
  final GasMapStyle mapStyle;
  final LatLng initialCenter;
  final double initialZoom;
  final List<Polyline> polylines;
  final List<Marker> markers;
  final VoidCallback? onMapReady;
  final void Function(TapPosition tapPosition, LatLng point)? onTap;

  const GasKampusLiveMap({
    super.key,
    required this.mapController,
    required this.mapStyle,
    required this.initialCenter,
    this.initialZoom = 14.5,
    this.polylines = const [],
    this.markers = const [],
    this.onMapReady,
    this.onTap,
  });

  @override
  State<GasKampusLiveMap> createState() => _GasKampusLiveMapState();
}

class _GasKampusLiveMapState extends State<GasKampusLiveMap> {
  late final NetworkTileProvider _tileProvider;
  List<CampusZone> _debugZones = const [];
  bool _debugShowZones = true;

  @override
  void initState() {
    super.initState();
    _tileProvider = NetworkTileProvider(silenceExceptions: true);
    if (kDebugMode && kEnableZoneDebugOverlay) {
      _loadDebugZones();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (kDebugMode && kEnableZoneDebugOverlay) {
      _loadDebugZones();
    }
  }

  Future<void> _loadDebugZones() async {
    if (!(kDebugMode && kEnableZoneDebugOverlay)) return;
    var zones = await ZoneService.loadZones();
    if (zones.isEmpty) {
      // Jika koleksi `zones` di Firestore belum pernah di-seed, seed ke Firestore
      // terlebih dahulu lalu baca ulang dari Firestore via ZoneService.loadZones().
      try {
        await SeedService().seedZones();
        ZoneService.clearCache();
        zones = await ZoneService.loadZones();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _debugZones = zones);
  }

  Color _debugZoneColor(String id) {
    switch (id) {
      case 'A':
        return const Color(0xFFEF4444); // Merah
      case 'B':
        return const Color(0xFF3B82F6); // Biru
      case 'C':
        return const Color(0xFF10B981); // Hijau
      case 'D':
        return const Color(0xFFF59E0B); // Amber
      case 'E':
        return const Color(0xFF8B5CF6); // Ungu
      case 'F':
        return const Color(0xFFEC4899); // Pink
      default:
        return const Color(0xFF06B6D4);
    }
  }

  LatLng _polygonCenter(List<LatLng> pts) {
    double lat = 0;
    double lng = 0;
    for (final p in pts) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / pts.length, lng / pts.length);
  }

  void _handleDebugTap(TapPosition tapPosition, LatLng point) {
    if (!(kDebugMode && kEnableZoneDebugOverlay)) return;
    final matched = zoneOfPoint(point, _debugZones);
    final coordText =
        '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    final resultText = matched != null ? 'Zona $matched' : 'di luar kampus';
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('DEBUG: $coordText → $resultText'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final map = FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
        minZoom: 11.0,
        maxZoom: 19.0,
        onMapReady: widget.onMapReady,
        onTap: (widget.onTap != null || (kDebugMode && kEnableZoneDebugOverlay))
            ? (tapPos, point) {
                widget.onTap?.call(tapPos, point);
                if (kDebugMode && kEnableZoneDebugOverlay) {
                  _handleDebugTap(tapPos, point);
                }
              }
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: widget.mapStyle.urlTemplate,
          tileProvider: _tileProvider,
          userAgentPackageName: 'com.gaskampus.app',
          maxNativeZoom: 19,
        ),
        if (kDebugMode && kEnableZoneDebugOverlay && _debugShowZones && _debugZones.isNotEmpty)
          PolygonLayer(
            polygons: _debugZones.map((z) {
              final c = _debugZoneColor(z.id);
              return Polygon(
                points: z.polygon,
                color: c.withValues(alpha: 0.22),
                borderColor: c,
                borderStrokeWidth: 2.5,
              );
            }).toList(),
          ),
        if (widget.polylines.isNotEmpty)
          PolylineLayer(polylines: widget.polylines),
        if (kDebugMode && kEnableZoneDebugOverlay && _debugShowZones && _debugZones.isNotEmpty)
          MarkerLayer(
            markers: _debugZones.map((z) {
              final c = _debugZoneColor(z.id);
              return Marker(
                point: _polygonCenter(z.polygon),
                width: 30,
                height: 30,
                child: IgnorePointer(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.90),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      z.id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        if (widget.markers.isNotEmpty)
          MarkerLayer(markers: widget.markers),
      ],
    );

    if (!(kDebugMode && kEnableZoneDebugOverlay)) return map;

    return Stack(
      children: [
        Positioned.fill(child: map),
        Positioned(
          top: 96,
          left: 12,
          child: Material(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(99),
            elevation: 4,
            child: InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: () {
                setState(() => _debugShowZones = !_debugShowZones);
                if (_debugShowZones && _debugZones.isEmpty) {
                  ZoneService.clearCache();
                  _loadDebugZones();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  'DEBUG: Zona ${_debugShowZones ? 'ON' : 'OFF'}',
                  style: TextStyle(
                    color: _debugShowZones
                        ? const Color(0xFFC0F637)
                        : Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tombol kontrol mengambang untuk peta navigasi (Simulasi, Recenter, Zoom, Tema Peta)
class GasKampusMapControls extends StatelessWidget {
  final GasMapStyle currentStyle;
  final bool isSimulating;
  final VoidCallback onToggleSimulation;
  final VoidCallback onCycleStyle;
  final VoidCallback onFitRoute;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const GasKampusMapControls({
    super.key,
    required this.currentStyle,
    required this.isSimulating,
    required this.onToggleSimulation,
    required this.onCycleStyle,
    required this.onFitRoute,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Toggle Simulasi Jalan (sangat berguna di Emulator atau Demo)
        Material(
          color: isSimulating ? const Color(0xFFC0F637) : const Color(0xFF1D2210),
          borderRadius: BorderRadius.circular(20),
          elevation: 4,
          child: InkWell(
            onTap: onToggleSimulation,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSimulating ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 16,
                    color: isSimulating ? Colors.black : const Color(0xFFC0F637),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSimulating ? 'Jeda Simulasi' : 'Simulasi Motor',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSimulating ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Theme Peta (Jalan / Gelap / Satelit)
        _controlButton(
          icon: currentStyle.icon,
          tooltip: 'Tema: ${currentStyle.label}',
          onTap: onCycleStyle,
        ),
        const SizedBox(height: 6),

        // Recenter / Fit Rute
        _controlButton(
          icon: Icons.my_location_rounded,
          tooltip: 'Paskan Rute di Layar',
          onTap: onFitRoute,
        ),
        const SizedBox(height: 6),

        // Zoom In & Zoom Out
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onZoomIn,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: const SizedBox(
                  width: 40,
                  height: 36,
                  child: Icon(Icons.add_rounded, size: 20, color: Colors.black87),
                ),
              ),
              Container(width: 24, height: 1, color: Colors.grey[300]),
              InkWell(
                onTap: onZoomOut,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                child: const SizedBox(
                  width: 40,
                  height: 36,
                  child: Icon(Icons.remove_rounded, size: 20, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.95),
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
