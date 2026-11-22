// ignore_for_file: avoid_print
// Unit test zone_service.dart — tidak butuh Firebase.
// Jalankan: flutter test test/zone_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:gas_kampusapp/services/zone_service.dart';

// ── Polygon dari geojson.json (LatLng = dibalik dari [lng, lat]) ──────────

// Zona C: lng 98.6529–98.6560, lat 3.5624–3.5673
final _zoneC = CampusZone(
  id: 'C',
  name: 'Zona C',
  polygon: [
    LatLng(3.5673665, 98.6531956), LatLng(3.5673426, 98.6545242),
    LatLng(3.5673259, 98.6559246), LatLng(3.5649374, 98.6559619),
    LatLng(3.5637421, 98.6559947), LatLng(3.5631496, 98.6560138),
    LatLng(3.5631254, 98.6560154), LatLng(3.5631043, 98.6560167),
    LatLng(3.5630628, 98.6560192), LatLng(3.5629793, 98.6560242),
    LatLng(3.5628132, 98.6560346), LatLng(3.5625503, 98.6560407),
    LatLng(3.5624433, 98.6529815), LatLng(3.5636815, 98.6530155),
    LatLng(3.5649076, 98.6530772), LatLng(3.5661359, 98.6531455),
    LatLng(3.5673665, 98.6531956),
  ],
  places: [],
);

// Zona B: lng 98.6559–98.6584, lat 3.5590–3.5673
final _zoneB = CampusZone(
  id: 'B',
  name: 'Zona B',
  polygon: [
    LatLng(3.5673255, 98.6559258), LatLng(3.5673094, 98.6583943),
    LatLng(3.5590835, 98.6582996), LatLng(3.5590794, 98.6577316),
    LatLng(3.5590664, 98.6572609), LatLng(3.5590612, 98.6568742),
    LatLng(3.5590571, 98.6565044), LatLng(3.5590544, 98.6563129),
    LatLng(3.5590543, 98.6562199), LatLng(3.5590556, 98.6561736),
    LatLng(3.5590578, 98.6561283), LatLng(3.559158, 98.6561272),
    LatLng(3.5592079, 98.6561266), LatLng(3.5592579, 98.6561252),
    LatLng(3.5594583, 98.6561203), LatLng(3.5598618, 98.6561047),
    LatLng(3.5606662, 98.6560795), LatLng(3.5611995, 98.6560685),
    LatLng(3.5622671, 98.6560495), LatLng(3.5625271, 98.6560429),
    LatLng(3.562663, 98.6560405), LatLng(3.5627313, 98.6560381),
    LatLng(3.5627679, 98.656037), LatLng(3.5628097, 98.6560359),
    LatLng(3.563328, 98.656012), LatLng(3.5643885, 98.6559812),
    LatLng(3.5651245, 98.6559612), LatLng(3.5658565, 98.6559493),
    LatLng(3.5665915, 98.655937), LatLng(3.5669577, 98.6559323),
    LatLng(3.5671421, 98.6559284), LatLng(3.5672348, 98.6559272),
    LatLng(3.5672807, 98.6559263), LatLng(3.5673255, 98.6559258),
  ],
  places: [],
);

// Zona A: lng 98.6584–98.6604, lat 3.5591–3.5673
final _zoneA = CampusZone(
  id: 'A',
  name: 'Zona A',
  polygon: [
    LatLng(3.5673086, 98.6584052), LatLng(3.567327, 98.660191),
    LatLng(3.5655674, 98.6602556), LatLng(3.5637661, 98.6603281),
    LatLng(3.5591098, 98.6603938), LatLng(3.5590885, 98.6583084),
    LatLng(3.5673086, 98.6584052),
  ],
  places: [],
);

// Zona D: lng 98.6529–98.6561, lat 3.5590–3.5625
final _zoneD = CampusZone(
  id: 'D',
  name: 'Zona D',
  polygon: [
    LatLng(3.5624423, 98.6529822), LatLng(3.5624661, 98.6537838),
    LatLng(3.5624937, 98.6545497), LatLng(3.5625494, 98.6560407),
    LatLng(3.5607708, 98.6560747), LatLng(3.5598811, 98.6561032),
    LatLng(3.5596232, 98.6561128), LatLng(3.5594923, 98.656119),
    LatLng(3.5594191, 98.6561211), LatLng(3.5593594, 98.6561225),
    LatLng(3.5591736, 98.6561267), LatLng(3.5591527, 98.6561268),
    LatLng(3.5591317, 98.656127), LatLng(3.5591117, 98.6561272),
    LatLng(3.5590911, 98.6561271), LatLng(3.5590717, 98.6561274),
    LatLng(3.5590505, 98.6561272), LatLng(3.5590101, 98.6561277),
    LatLng(3.5590242, 98.6545306), LatLng(3.5590272, 98.6528959),
    LatLng(3.5624423, 98.6529822),
  ],
  places: [],
);

// Zona F: lng 98.6561–98.6606, lat 3.5563–3.5591
final _zoneF = CampusZone(
  id: 'F',
  name: 'Zona F',
  polygon: [
    LatLng(3.5590507, 98.6563055), LatLng(3.5591093, 98.6603924),
    LatLng(3.5563153, 98.6605977), LatLng(3.5563303, 98.6583645),
    LatLng(3.5563359, 98.6561182), LatLng(3.5565943, 98.6561207),
    LatLng(3.5568447, 98.6561209), LatLng(3.5573122, 98.656123),
    LatLng(3.5582586, 98.6561272), LatLng(3.5584915, 98.6561278),
    LatLng(3.5587261, 98.6561292), LatLng(3.5590087, 98.6561277),
    LatLng(3.5590343, 98.6561276), LatLng(3.5590573, 98.6561277),
    LatLng(3.5590561, 98.6561477), LatLng(3.5590546, 98.6561741),
    LatLng(3.5590528, 98.6562073), LatLng(3.5590527, 98.6562556),
    LatLng(3.5590507, 98.6563055),
  ],
  places: [],
);

// Zona E: lng 98.6529–98.6561, lat 3.5563–3.5590
final _zoneE = CampusZone(
  id: 'E',
  name: 'Zona E',
  polygon: [
    LatLng(3.5590245, 98.6528968), LatLng(3.5590238, 98.6537035),
    LatLng(3.559024, 98.6541052), LatLng(3.5590238, 98.6543255),
    LatLng(3.5590229, 98.6545216), LatLng(3.5590197, 98.6549208),
    LatLng(3.5590179, 98.6551203), LatLng(3.5590163, 98.6553201),
    LatLng(3.5590127, 98.6557253), LatLng(3.5590092, 98.6561274),
    LatLng(3.5563184683094136, 98.6561261),
    LatLng(3.5563184683094136, 98.6528968),
    LatLng(3.5590245, 98.6528968),
  ],
  places: [],
);

final _allZones = [_zoneA, _zoneB, _zoneC, _zoneD, _zoneE, _zoneF];

void main() {
  // ── zoneOfPoint ────────────────────────────────────────────────────────────

  group('zoneOfPoint — titik dalam zona', () {
    // Titik manual dipilih agar pasti di dalam polygon (bukan centroid)

    test('titik di Zona A (tengah)', () {
      // A: lat ~3.5630, lng ~3.5591 → pakai titik aman dalam bounding box
      final p = LatLng(3.5630, 98.6590);
      expect(zoneOfPoint(p, _allZones), 'A');
    });

    test('titik di Zona B', () {
      final p = LatLng(3.5630, 98.6570);
      expect(zoneOfPoint(p, _allZones), 'B');
    });

    test('titik di Zona C', () {
      final p = LatLng(3.5650, 98.6545);
      expect(zoneOfPoint(p, _allZones), 'C');
    });

    test('titik di Zona D', () {
      final p = LatLng(3.5610, 98.6545);
      expect(zoneOfPoint(p, _allZones), 'D');
    });

    test('titik di Zona E', () {
      final p = LatLng(3.5575, 98.6545);
      expect(zoneOfPoint(p, _allZones), 'E');
    });

    test('titik di Zona F', () {
      final p = LatLng(3.5575, 98.6580);
      expect(zoneOfPoint(p, _allZones), 'F');
    });
  });

  group('zoneOfPoint — titik di luar kampus', () {
    test('Stasiun Medan → null', () {
      final p = LatLng(3.5912, 98.6775); // jauh dari USU
      expect(zoneOfPoint(p, _allZones), isNull);
    });
  });

  group('parseCoordinates — GeoJSON [lng, lat] harus dibalik', () {
    test('koordinat mentah [98.6531956, 3.5673665] → LatLng(3.5673665, 98.6531956)', () {
      final raw = [
        [98.6531956, 3.5673665],
      ];
      final parsed = parseCoordinates(raw);
      expect(parsed, hasLength(1));
      expect(parsed.first.latitude, closeTo(3.5673665, 0.0000001));
      expect(parsed.first.longitude, closeTo(98.6531956, 0.0000001));
    });
  });

  // ── CampusZone round-trip & malformed data ─────────────────────────────

  group('CampusZone toMap() / fromMap() round-trip & ketahanan data rusak', () {
    test('round-trip zone → toMap() → fromMap() menghasilkan data yang sama', () {
      final original = CampusZone(
        id: 'A',
        name: 'Zona A',
        polygon: _zoneA.polygon,
        places: const ['Fakultas Kedokteran', 'Fasilkom-TI'],
      );
      final map = original.toMap();
      final restored = CampusZone.fromMap(map, 'A');

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.polygon.length, original.polygon.length);
      expect(restored.polygon.first.latitude, closeTo(original.polygon.first.latitude, 0.0000001));
      expect(restored.polygon.first.longitude, closeTo(original.polygon.first.longitude, 0.0000001));
      expect(restored.places, original.places);
    });

    test('fromMap() dengan data rusak (polygon kosong / field hilang / tipe salah) tidak crash', () {
      final emptyDoc = CampusZone.fromMap(<String, dynamic>{}, 'X');
      expect(emptyDoc.id, 'X');
      expect(emptyDoc.name, 'Zona X');
      expect(emptyDoc.polygon, isEmpty);
      expect(emptyDoc.places, isEmpty);
      // Zona dengan polygon kosong harus aman dilewati oleh zoneOfPoint
      expect(zoneOfPoint(const LatLng(3.5630, 98.6590), [emptyDoc]), isNull);

      final corruptedDoc = CampusZone.fromMap(<String, dynamic>{
        'name': 12345,
        'polygon': [
          {'lat': 'bukan_angka', 'lng': null},
          'bukan_map',
          {'lat': 3.5630, 'lng': 98.6590},
        ],
        'places': 'bukan_list',
      }, 'Y');
      expect(corruptedDoc.id, 'Y');
      expect(corruptedDoc.name, 'Zona Y');
      expect(corruptedDoc.polygon, hasLength(1));
      expect(corruptedDoc.places, isEmpty);
    });
  });

  // ── normalizeFaculty & zoneOfUser ──────────────────────────────────────

  group('normalizeFaculty & zoneOfUser', () {
    test('Politeknik Negeri Medan → POLMED (bukan FT)', () {
      expect(normalizeFaculty('Politeknik Negeri Medan'), 'POLMED');
      expect(zoneOfUser('Politeknik Negeri Medan', null), 'C');
    });
    test('Fakultas Ilmu Sosial dan Ilmu Politik → FISIP', () {
      expect(normalizeFaculty('Fakultas Ilmu Sosial dan Ilmu Politik'), 'FISIP');
      expect(zoneOfUser('Fakultas Ilmu Sosial dan Ilmu Politik', null), 'F');
    });
    test('fasilkom-ti → FASILKOMTI', () {
      expect(normalizeFaculty('fasilkom-ti'), 'FASILKOMTI');
      expect(zoneOfUser('fasilkom-ti', null), 'A');
    });
    test('  FMIPA  → FMIPA', () {
      expect(normalizeFaculty('  FMIPA '), 'FMIPA');
      expect(zoneOfUser('  FMIPA ', null), 'D');
    });
    test('FT + Teknik Sipil → B', () {
      expect(zoneOfUser('FT', 'Teknik Sipil'), 'B');
      expect(zoneOfUser('Fakultas Teknik', 'SIPIL'), 'B');
    });
    test('FISIP → F', () => expect(zoneOfUser('FISIP', null), 'F'));
    test('FMIPA → D', () => expect(zoneOfUser('FMIPA', null), 'D'));
    test('FEB → F', () => expect(zoneOfUser('FEB', null), 'F'));
    test('Teknik + Teknik Elektro → D', () => expect(zoneOfUser('Fakultas Teknik', 'Teknik Elektro'), 'D'));
    test('Teknik + Teknik Kimia → B', () => expect(zoneOfUser('Fakultas Teknik', 'Teknik Kimia'), 'B'));
    test('Teknik + jurusan null → null', () => expect(zoneOfUser('Fakultas Teknik', null), isNull));
    test('teks acak / tidak dikenal → null', () {
      expect(normalizeFaculty('Hukum'), isNull);
      expect(normalizeFaculty('Teknik Informatika Liar'), isNull);
      expect(zoneOfUser('Hukum', null), isNull);
    });
  });

  // ── evaluateTier ───────────────────────────────────────────────────────

  group('evaluateTier', () {
    final now = DateTime(2024, 11, 20, 7, 30); // 07:30 pagi

    // Driver mahasiswa di Zona D (FMIPA), punya kelas 08:00
    final schedules = [
      ScheduleInfo(startHour: 8, startMinute: 0),
    ];

    // Posisi: driver berangkat dari kos (3.5450, 98.6450), jemput penumpang searah di (3.5540, 98.6490),
    // lalu menuju Zona D (3.5610, 98.6545) -> detour ~0.01 km <= 1.0 km.
    final driverPos = LatLng(3.5450, 98.6450);
    final pickup = LatLng(3.5540, 98.6490); // searah di jalur menuju kampus (di luar zona kampus)
    final destZoneD = LatLng(3.5610, 98.6545); // dalam Zona D

    test('lolos tier 1 — semua syarat terpenuhi', () {
      final tier = evaluateTier(
        driverRole: 'driver_kampus',
        driverIsOnline: true,
        driverFacultas: 'FMIPA',
        driverJurusan: null,
        driverSchedulesToday: schedules,
        pickup: pickup,
        destination: destZoneD,
        driverPosition: driverPos,
        now: now,
        zones: _allZones,
      );
      expect(tier, 1);
    });

    test('tier 2 — driver_kampus tapi beda zona (destination di Zona A)', () {
      final destZoneA = LatLng(3.5630, 98.6590);
      final tier = evaluateTier(
        driverRole: 'driver_kampus',
        driverIsOnline: true,
        driverFacultas: 'FMIPA',
        driverJurusan: null,
        driverSchedulesToday: schedules, // zona D, destination A
        pickup: pickup,
        destination: destZoneA,
        driverPosition: driverPos,
        now: now,
        zones: _allZones,
      );
      expect(tier, 2);
    });

    test('tier 2 — selisih waktu > 30 menit', () {
      // "now" = 05:00 pagi, kelas 08:00 → gap 180 menit > 30
      final nowEarly = DateTime(2024, 11, 20, 5, 0);
      final tier = evaluateTier(
        driverRole: 'driver_kampus',
        driverIsOnline: true,
        driverFacultas: 'FMIPA',
        driverJurusan: null,
        driverSchedulesToday: schedules,
        pickup: pickup,
        destination: destZoneD,
        driverPosition: driverPos,
        now: nowEarly,
        zones: _allZones,
      );
      expect(tier, 2);
    });

    test('tier 2 — detour > 1 km', () {
      // Pickup sangat jauh untuk memaksa detour besar
      final farPickup = LatLng(3.5200, 98.6000);
      final tier = evaluateTier(
        driverRole: 'driver_kampus',
        driverIsOnline: true,
        driverFacultas: 'FMIPA',
        driverJurusan: null,
        driverSchedulesToday: schedules,
        pickup: farPickup,
        destination: destZoneD,
        driverPosition: driverPos,
        now: now,
        zones: _allZones,
      );
      expect(tier, 2);
    });

    test('tier 3 — driver_umum selalu 3', () {
      final tier = evaluateTier(
        driverRole: 'driver_umum',
        driverIsOnline: true,
        driverFacultas: 'FMIPA',
        driverJurusan: null,
        driverSchedulesToday: schedules,
        pickup: pickup,
        destination: destZoneD,
        driverPosition: driverPos,
        now: now,
        zones: _allZones,
      );
      expect(tier, 3);
    });
  });

  // ── haversineKm ────────────────────────────────────────────────────────────

  group('haversineKm sanity', () {
    test('jarak ke diri sendiri = 0', () {
      final p = LatLng(3.5612, 98.6540);
      expect(haversineKm(p, p), closeTo(0.0, 0.0001));
    });

    test('jarak Fasilkom-TI ke Fak.Teknik USU ≈ 0.3 km', () {
      final a = LatLng(3.5620, 98.6592);
      final b = LatLng(3.5612, 98.6540);
      expect(haversineKm(a, b), lessThan(1.0));
      expect(haversineKm(a, b), greaterThan(0.1));
    });
  });
}
