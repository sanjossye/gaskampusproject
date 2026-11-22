
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';

// ── Data model ──────────────────────────────────────────────────────────────

/// Zona kampus. Sumber kebenaran: Firestore `zones/{id}`.
class CampusZone {
  final String id;       // "A", "B", ..., "F"
  final String name;     // "Zona A"
  final List<LatLng> polygon;
  final List<String> places;

  const CampusZone({
    required this.id,
    required this.name,
    required this.polygon,
    required this.places,
  });

  factory CampusZone.fromMap(Map<String, dynamic> m, String docId) {
    final rawPoly = m['polygon'];
    final poly = <LatLng>[];
    if (rawPoly is List) {
      for (final p in rawPoly) {
        if (p is Map) {
          final lat = p['lat'];
          final lng = p['lng'];
          if (lat is num && lng is num) {
            poly.add(LatLng(lat.toDouble(), lng.toDouble()));
          }
        }
      }
    }

    final rawPlaces = m['places'];
    final places = <String>[];
    if (rawPlaces is List) {
      for (final item in rawPlaces) {
        if (item != null) places.add(item.toString());
      }
    }

    final rawName = m['name'];
    return CampusZone(
      id: docId,
      name: (rawName is String && rawName.trim().isNotEmpty) ? rawName : 'Zona $docId',
      polygon: poly,
      places: places,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'polygon': polygon.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        'places': places,
      };
}

// ── Default config constants ────────────────────────────────────────────────

/// Tier-1 promo multiplier (0.70 = 30% diskon).
const double kDefaultTier1Multiplier = 0.70;

/// Maks selisih menit antara estimasi tiba dan jam mulai kelas driver.
const int kDefaultMaxScheduleGapMinutes = 30;

/// Maks detour (km) agar lolos tier 1.
const double kDefaultMaxDetourKm = 1.0;

// ── Kode Fakultas & Jurusan Tetap ───────────────────────────────────────────

/// Nama lengkap resmi per kode fakultas (untuk ditampilkan di UI).
const Map<String, String> kFacultyNames = {
  'FK': 'Fakultas Kedokteran',
  'FKG': 'Fakultas Kedokteran Gigi',
  'FASILKOMTI': 'Fakultas Ilmu Komputer dan Teknologi Informasi',
  'FIB': 'Fakultas Ilmu Budaya',
  'FT': 'Fakultas Teknik',
  'PSIKOLOGI': 'Fakultas Psikologi',
  'FMIPA': 'Fakultas Matematika dan Ilmu Pengetahuan Alam',
  'VOKASI': 'Fakultas Vokasi',
  'FP': 'Fakultas Pertanian',
  'FISIP': 'Fakultas Ilmu Sosial dan Ilmu Politik',
  'FEB': 'Fakultas Ekonomi dan Bisnis',
  'MKN': 'Magister Kenotariatan',
  'MM': 'Magister Manajemen',
  'POLMED': 'Politeknik Negeri Medan',
};

/// Nama lengkap jurusan Fakultas Teknik per kode jurusan.
const Map<String, String> kTeknikMajorNames = {
  'ARSITEKTUR': 'Teknik Arsitektur',
  'SIPIL': 'Teknik Sipil',
  'KIMIA': 'Teknik Kimia',
  'LINGKUNGAN': 'Teknik Lingkungan',
  'ELEKTRO': 'Teknik Elektro',
  'MESIN': 'Teknik Mesin',
  'INDUSTRI': 'Teknik Industri',
};

/// Pemetaan kode fakultas (non-FT) ke ID Zona (A–F).
const Map<String, String> _facultyCodeToZone = {
  // Zona A
  'FK': 'A',
  'FKG': 'A',
  'FASILKOMTI': 'A',
  'FIB': 'A',
  // Zona B
  'PSIKOLOGI': 'B',
  'MKN': 'B',
  'MM': 'B',
  // Zona C
  'POLMED': 'C',
  // Zona D
  'FMIPA': 'D',
  // Zona E
  'VOKASI': 'E',
  'FP': 'E',
  // Zona F
  'FISIP': 'F',
  'FEB': 'F',
};

/// Pemetaan kode jurusan Teknik (FT) ke ID Zona (B atau D).
const Map<String, String> _teknikMajorCodeToZone = {
  // Zona B
  'ARSITEKTUR': 'B',
  'SIPIL': 'B',
  'KIMIA': 'B',
  'LINGKUNGAN': 'B',
  // Zona D
  'ELEKTRO': 'D',
  'MESIN': 'D',
  'INDUSTRI': 'D',
};

/// Tabel alias EXACT (lowercase) → kode fakultas tetap.
const Map<String, String> _facultyAliases = {
  // FK
  'fk': 'FK',
  'fakultas kedokteran': 'FK',
  'fakultas kedokteran (fk)': 'FK',
  'kedokteran': 'FK',
  // FKG
  'fkg': 'FKG',
  'fakultas kedokteran gigi': 'FKG',
  'fakultas kedokteran gigi (fkg)': 'FKG',
  'kedokteran gigi': 'FKG',
  // FASILKOMTI
  'fasilkomti': 'FASILKOMTI',
  'fasilkom-ti': 'FASILKOMTI',
  'fasilkom ti': 'FASILKOMTI',
  'fasilkom': 'FASILKOMTI',
  'fakultas ilmu komputer': 'FASILKOMTI',
  'fakultas ilmu komputer dan teknologi informasi': 'FASILKOMTI',
  'fakultas ilmu komputer dan teknologi informasi (fasilkom-ti)': 'FASILKOMTI',
  // FIB
  'fib': 'FIB',
  'fakultas ilmu budaya': 'FIB',
  'fakultas ilmu budaya (fib)': 'FIB',
  'ilmu budaya': 'FIB',
  // FT
  'ft': 'FT',
  'fakultas teknik': 'FT',
  'fakultas teknik (ft)': 'FT',
  'teknik': 'FT',
  // PSIKOLOGI
  'psikologi': 'PSIKOLOGI',
  'fpsi': 'PSIKOLOGI',
  'fakultas psikologi': 'PSIKOLOGI',
  'fakultas psikologi (fpsi)': 'PSIKOLOGI',
  // FMIPA
  'fmipa': 'FMIPA',
  'mipa': 'FMIPA',
  'fakultas mipa': 'FMIPA',
  'fakultas matematika dan ilmu pengetahuan alam': 'FMIPA',
  'fakultas matematika dan ilmu pengetahuan alam (fmipa)': 'FMIPA',
  // VOKASI
  'vokasi': 'VOKASI',
  'fv': 'VOKASI',
  'fakultas vokasi': 'VOKASI',
  'fakultas vokasi (fv)': 'VOKASI',
  // FP
  'fp': 'FP',
  'pertanian': 'FP',
  'fakultas pertanian': 'FP',
  'fakultas pertanian (fp)': 'FP',
  // FISIP
  'fisip': 'FISIP',
  'fakultas ilmu sosial dan ilmu politik': 'FISIP',
  'fakultas ilmu sosial dan ilmu politik (fisip)': 'FISIP',
  'ilmu sosial dan ilmu politik': 'FISIP',
  // FEB
  'feb': 'FEB',
  'fe': 'FEB',
  'fakultas ekonomi': 'FEB',
  'fakultas ekonomi dan bisnis': 'FEB',
  'fakultas ekonomi dan bisnis (feb)': 'FEB',
  'ekonomi dan bisnis': 'FEB',
  // MKN
  'mkn': 'MKN',
  'magister kenotariatan': 'MKN',
  // MM
  'mm': 'MM',
  'magister manajemen': 'MM',
  // POLMED
  'polmed': 'POLMED',
  'politeknik negeri medan': 'POLMED',
};

/// Tabel alias EXACT (lowercase) → kode jurusan Teknik tetap.
const Map<String, String> _teknikMajorAliases = {
  'arsitektur': 'ARSITEKTUR',
  'teknik arsitektur': 'ARSITEKTUR',
  'sipil': 'SIPIL',
  'teknik sipil': 'SIPIL',
  'kimia': 'KIMIA',
  'teknik kimia': 'KIMIA',
  'lingkungan': 'LINGKUNGAN',
  'teknik lingkungan': 'LINGKUNGAN',
  'elektro': 'ELEKTRO',
  'teknik elektro': 'ELEKTRO',
  'mesin': 'MESIN',
  'teknik mesin': 'MESIN',
  'industri': 'INDUSTRI',
  'teknik industri': 'INDUSTRI',
};

/// Normalisasi input fakultas (kode, singkatan, atau nama lengkap) ke kode tetap.
/// Pencocokan EXACT setelah trim & lowercase (TIDAK memakai contains).
String? normalizeFaculty(String? raw) {
  if (raw == null) return null;
  final key = raw.trim().toLowerCase();
  if (key.isEmpty) return null;
  return _facultyAliases[key];
}

/// Normalisasi input jurusan Fakultas Teknik ke kode jurusan tetap.
/// Pencocokan EXACT setelah trim & lowercase (TIDAK memakai contains).
String? normalizeTeknikMajor(String? raw) {
  if (raw == null) return null;
  final key = raw.trim().toLowerCase();
  if (key.isEmpty) return null;
  return _teknikMajorAliases[key];
}

/// Konversi kode/teks fakultas dari Firestore menjadi nama lengkap untuk tampilan UI.
String facultyDisplayName(String? raw, {String? fallback}) {
  if (raw == null || raw.trim().isEmpty) return fallback ?? 'Fakultas';
  final code = normalizeFaculty(raw);
  if (code != null && kFacultyNames.containsKey(code)) {
    return kFacultyNames[code]!;
  }
  return raw.trim();
}

// ── Places → Zona mapping (untuk field `places` di Firestore `zones/{id}`) ─

const Map<String, String> _placeToZone = {
  // A
  'Fakultas Kedokteran': 'A',
  'Sekretariat BEM': 'A',
  'Gelanggang Mahasiswa': 'A',
  'Fakultas Ilmu Komputer dan Teknologi Informasi': 'A',
  'Fakultas Ilmu Budaya': 'A',
  'Fakultas Kedokteran Gigi': 'A',
  'Gedung Pancasila': 'A',
  // B
  'Teknik Arsitektur': 'B',
  'Teknik Sipil': 'B',
  'Aula Teknik': 'B',
  'Teknik Kimia': 'B',
  'Teknik Lingkungan': 'B',
  'Perpustakaan USU': 'B',
  'Fakultas Psikologi': 'B',
  'Magister Kenotariatan': 'B',
  'Magister Manajemen': 'B',
  // C
  'Politeknik Negeri Medan': 'C',
  // D
  'Teknik Elektro': 'D',
  'Teknik Mesin': 'D',
  'Teknik Industri': 'D',
  'FMIPA': 'D',
  // E
  'Fakultas Vokasi': 'E',
  'Fakultas Pertanian': 'E',
  // F
  'FISIP': 'F',
  'Fakultas Ekonomi dan Bisnis': 'F',
  'FEB': 'F',
};

/// Places list per zona, untuk disimpan ke Firestore.
Map<String, List<String>> get placesPerZone {
  final result = <String, List<String>>{};
  for (final e in _placeToZone.entries) {
    result.putIfAbsent(e.value, () => []).add(e.key);
  }
  return result;
}

// ── Pure functions ──────────────────────────────────────────────────────────

/// Point-in-polygon via ray casting. Murni, tanpa I/O.
bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
  if (polygon.length < 3) return false;
  bool inside = false;
  final n = polygon.length;
  for (int i = 0, j = n - 1; i < n; j = i++) {
    final yi = polygon[i].latitude;
    final xi = polygon[i].longitude;
    final yj = polygon[j].latitude;
    final xj = polygon[j].longitude;
    if (((yi > point.latitude) != (yj > point.latitude)) &&
        (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
  }
  return inside;
}

/// Jarak haversine dalam km.
double haversineKm(LatLng a, LatLng b) {
  const r = 6371.0;
  final dLat = _rad(b.latitude - a.latitude);
  final dLon = _rad(b.longitude - a.longitude);
  final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(a.latitude)) *
          math.cos(_rad(b.latitude)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
}

double _rad(double deg) => deg * math.pi / 180.0;

/// Jarak minimum dari titik ke sisi polygon (meter).
double _minDistToPolygonEdgeMeters(LatLng point, List<LatLng> polygon) {
  double minDist = double.infinity;
  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final d = _pointToSegmentDistKm(point, polygon[j], polygon[i]);
    if (d < minDist) minDist = d;
  }
  return minDist * 1000.0;
}

double _pointToSegmentDistKm(LatLng p, LatLng a, LatLng b) {
  final ap = haversineKm(a, p);
  final ab = haversineKm(a, b);
  final bp = haversineKm(b, p);
  if (ab < 0.0001) return ap;
  // Proyeksi skalar
  final t = ((ap * ap) + (ab * ab) - (bp * bp)) / (2 * ab);
  if (t <= 0) return ap;
  if (t >= ab) return bp;
  // Jarak tegak lurus (aproksimasi)
  final h2 = (ap * ap) - (t * t);
  return h2 > 0 ? math.sqrt(h2) : 0;
}

/// Tentukan zona dari koordinat. Return null jika di luar kampus.
/// Urutan pengecekan: A → F. Jika di perbatasan, ambil pertama yang cocok.
/// Jika tidak masuk zona mana pun tapi ≤ 30 m dari tepi, pakai zona itu.
String? zoneOfPoint(LatLng point, List<CampusZone> zones) {
  // Exact match
  for (final z in zones) {
    if (_pointInPolygon(point, z.polygon)) return z.id;
  }
  // Toleransi 30 meter
  String? nearest;
  double nearestDist = double.infinity;
  for (final z in zones) {
    final d = _minDistToPolygonEdgeMeters(point, z.polygon);
    if (d < nearestDist) {
      nearestDist = d;
      nearest = z.id;
    }
  }
  if (nearestDist <= 30.0 && nearest != null) return nearest;
  return null;
}

/// Tentukan zona dari profil user (fakultas + jurusan opsional) berbasis kode tetap.
/// Jika kode fakultas == 'FT', zona ditentukan dari kode jurusan Teknik (wajib ada).
String? zoneOfUser(String? fakultas, String? jurusan) {
  final code = normalizeFaculty(fakultas);
  if (code == null) return null;

  if (code == 'FT') {
    final majorCode = normalizeTeknikMajor(jurusan);
    if (majorCode == null) return null;
    return _teknikMajorCodeToZone[majorCode];
  }

  return _facultyCodeToZone[code];
}

/// Data dispatch config — dibaca dari Firestore `config/dispatch`.
class DispatchConfig {
  final int maxScheduleGapMinutes;
  final double maxDetourKm;

  const DispatchConfig({
    this.maxScheduleGapMinutes = kDefaultMaxScheduleGapMinutes,
    this.maxDetourKm = kDefaultMaxDetourKm,
  });

  factory DispatchConfig.fromMap(Map<String, dynamic> m) => DispatchConfig(
        maxScheduleGapMinutes: (m['maxScheduleGapMinutes'] as num?)?.toInt() ?? kDefaultMaxScheduleGapMinutes,
        maxDetourKm: (m['maxDetourKm'] as num?)?.toDouble() ?? kDefaultMaxDetourKm,
      );
}

/// Data jadwal sederhana yang dibutuhkan evaluateTier (supaya fungsi murni).
class ScheduleInfo {
  final int startHour;
  final int startMinute;

  const ScheduleInfo({required this.startHour, required this.startMinute});
}

/// Tentukan tier order. Fungsi MURNI — tanpa Firestore.
///
/// Return 1 (promo searah), 2 (driver kampus biasa), atau 3 (driver umum).
/// Syarat tier 1 (semua harus terpenuhi):
///   1. driverRole == 'driver_kampus' && driverIsOnline
///   2. Destination masuk zona kampus
///   3. Driver punya zona yang sama (dari profil: facultas + jurusan)
///   4. Selisih jam kelas ≤ config.maxScheduleGapMinutes
///   5. Detour ≤ config.maxDetourKm (haversine)
///   6. Estimasi tiba tidak bikin driver telat kelas
int evaluateTier({
  required String driverRole,
  required bool driverIsOnline,
  required String? driverFacultas,
  required String? driverJurusan,
  required List<ScheduleInfo> driverSchedulesToday,
  required LatLng pickup,
  required LatLng destination,
  required LatLng driverPosition,
  required DateTime now,
  required List<CampusZone> zones,
  DispatchConfig config = const DispatchConfig(),
}) {
  // Driver umum selalu tier 3
  if (driverRole != 'driver_kampus') return 3;
  if (!driverIsOnline) return 2;

  // Syarat 2: destination harus dalam zona kampus
  final destZone = zoneOfPoint(destination, zones);
  if (destZone == null) return 2;

  // Syarat 3: zona driver (dari profil) harus sama dengan zona tujuan
  final driverZone = zoneOfUser(driverFacultas, driverJurusan);
  if (driverZone != destZone) return 2;

  // Syarat 5: detour check (haversine)
  // detour = (driver→pickup + pickup→destination) - driver→destination
  final driverToPickup = haversineKm(driverPosition, pickup);
  final pickupToDest = haversineKm(pickup, destination);
  final driverToDest = haversineKm(driverPosition, destination);
  final detour = (driverToPickup + pickupToDest) - driverToDest;
  if (detour > config.maxDetourKm) return 2;

  // Estimasi waktu tiba (asumsi 25 km/h motor kota)
  final totalDistKm = driverToPickup + pickupToDest;
  final etaMinutes = (totalDistKm / 25.0 * 60.0).ceil();
  final etaTime = now.add(Duration(minutes: etaMinutes));

  // Syarat 4 & 6: cek terhadap jadwal hari ini
  bool anyMatch = false;
  for (final s in driverSchedulesToday) {
    final classStart = DateTime(now.year, now.month, now.day, s.startHour, s.startMinute);

    // Selisih menit antara jam kelas dan estimasi tiba
    final gapMinutes = classStart.difference(etaTime).inMinutes;

    // Syarat 4: selisih ≤ maxScheduleGapMinutes (kelas harus di depan, bukan sudah lewat)
    if (gapMinutes < 0 || gapMinutes > config.maxScheduleGapMinutes) continue;

    // Syarat 6: estimasi tiba tidak bikin telat (tiba sebelum kelas mulai)
    if (etaTime.isAfter(classStart)) continue;

    anyMatch = true;
    break;
  }

  return anyMatch ? 1 : 2;
}

/// Konversi array koordinat GeoJSON `[[lng, lat], ...]` ke `List<LatLng>` (`LatLng(lat, lng)`).
/// Fungsi murni (tanpa rootBundle) agar bisa diuji langsung di unit test.
List<LatLng> parseCoordinates(List<dynamic> raw) {
  return raw.map<LatLng>((c) {
    final pair = c as List<dynamic>;
    // GeoJSON = [lng, lat] → LatLng(lat, lng)
    return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
  }).toList();
}

// ── I/O layer ───────────────────────────────────────────────────────────────

class ZoneService {
  static List<CampusZone>? _cache;
  static DispatchConfig _dispatchConfig = const DispatchConfig();

  static DispatchConfig get dispatchConfig => _dispatchConfig;

  /// Baca zona dari Firestore, cache di memori. Panggil sekali per sesi.
  static Future<List<CampusZone>> loadZones() async {
    if (_cache != null) return _cache!;
    try {
      final snap = await FirebaseFirestore.instance.collection('zones').get();
      if (snap.docs.isNotEmpty) {
        _cache = snap.docs
            .map((d) => CampusZone.fromMap(d.data(), d.id))
            .where((z) => z.polygon.length >= 3)
            .toList();
        // Urutkan A → F
        _cache!.sort((a, b) => a.id.compareTo(b.id));
        return _cache!;
      }
    } catch (_) {}
    // Fallback: kosong (seed belum dijalankan)
    return [];
  }

  /// Load dispatch config dari Firestore (opsional).
  static Future<void> loadDispatchConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('config').doc('dispatch').get();
      if (doc.exists && doc.data() != null) {
        _dispatchConfig = DispatchConfig.fromMap(doc.data()!);
      }
    } catch (_) {}
  }

  /// Parse GeoJSON asset ke list CampusZone (untuk seed).
  static Future<List<CampusZone>> parseGeoJsonAsset() async {
    final raw = await rootBundle.loadString('assets/zones/usu_zones.geojson');
    final geojson = jsonDecode(raw) as Map<String, dynamic>;
    final features = geojson['features'] as List<dynamic>;
    final places = placesPerZone;
    final zones = <CampusZone>[];

    for (final f in features) {
      final props = f['properties'] as Map<String, dynamic>;
      // Ambil ID huruf dari key: "Zona A" → "A"
      final key = props.keys.first; // e.g. "Zona A"
      final id = key.replaceFirst('Zona ', '');

      final coords = (f['geometry']['coordinates'] as List).first as List;
      final polygon = parseCoordinates(coords);

      zones.add(CampusZone(
        id: id,
        name: 'Zona $id',
        polygon: polygon,
        places: places[id] ?? [],
      ));
    }

    zones.sort((a, b) => a.id.compareTo(b.id));
    return zones;
  }

  /// Reset cache (untuk testing).
  static void clearCache() => _cache = null;
}
