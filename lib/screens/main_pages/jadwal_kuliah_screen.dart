import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kPrimaryDeep = Color(0xFF8DBF1A);
const Color kBgDark = Color(0xFF0E1009);
const Color kBgLight = Color(0xFFF5F7F0);
const Color kCardDark = Color(0xFF1C2414);
const Color kCardLight = Color(0xFFFFFFFF);
const Color kBorderDark = Color(0xFF2A3518);
const Color kBorderLight = Color(0xFFE8EDE0);
const Color kTextOnPrimary = Color(0xFF0A0F02);

const List<String> kScheduleDayNames = [
  '',
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
];

class CourseScheduleItem {
  final String id;
  final String courseName;
  final String room;
  final String building;
  final int dayOfWeek; // 1 = Senin .. 5 = Jumat
  final String startTime; // HH:mm
  final String endTime; // HH:mm

  const CourseScheduleItem({
    required this.id,
    required this.courseName,
    required this.room,
    this.building = '',
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  String get dayName =>
      (dayOfWeek >= 1 && dayOfWeek <= 5) ? kScheduleDayNames[dayOfWeek] : 'Senin';

  String get locationLabel {
    if (room.trim().isNotEmpty && building.trim().isNotEmpty) {
      return '$building · $room';
    }
    if (room.trim().isNotEmpty) return room.trim();
    if (building.trim().isNotEmpty) return building.trim();
    return 'Gedung Perkuliahan USU';
  }

  Map<String, dynamic> toMap({String? userId}) {
    final map = <String, dynamic>{
      'courseName': courseName,
      'courseType': 'regular',
      'room': room,
      'building': building,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'createdAt': DateTime.now().toIso8601String(),
    };
    if (userId != null) {
      map['userId'] = userId;
    }
    return map;
  }

  factory CourseScheduleItem.fromMap(String id, Map<String, dynamic> map) {
    final rawDay = map['dayOfWeek'];
    int parsedDay = 1;
    if (rawDay is num) {
      parsedDay = rawDay.toInt().clamp(1, 5);
    } else if (rawDay is String) {
      parsedDay = int.tryParse(rawDay)?.clamp(1, 5) ?? 1;
    }
    return CourseScheduleItem(
      id: id,
      courseName: (map['courseName'] ?? 'Mata Kuliah').toString(),
      room: (map['room'] ?? '').toString(),
      building: (map['building'] ?? '').toString(),
      dayOfWeek: parsedDay,
      startTime: (map['startTime'] ?? '08:00').toString(),
      endTime: (map['endTime'] ?? '10:00').toString(),
    );
  }
}

/// Penyimpanan sesi lokal jadwal kuliah agar jadwal yang baru diisi saat
/// registrasi atau ditambah di aplikasi langsung tampil seketika (real-time + offline-safe).
class StudentScheduleStore {
  static final ValueNotifier<List<CourseScheduleItem>> schedulesNotifier =
      ValueNotifier<List<CourseScheduleItem>>([]);

  static List<CourseScheduleItem> get items => schedulesNotifier.value;

  static void setSchedules(List<CourseScheduleItem> list) {
    final sorted = List<CourseScheduleItem>.from(list)
      ..sort((a, b) {
        final cmpDay = a.dayOfWeek.compareTo(b.dayOfWeek);
        if (cmpDay != 0) return cmpDay;
        return a.startTime.compareTo(b.startTime);
      });
    schedulesNotifier.value = sorted;
  }

  static void addSchedule(CourseScheduleItem item) {
    final updated = [...schedulesNotifier.value, item];
    setSchedules(updated);
  }

  static void removeSchedule(String id) {
    final updated =
        schedulesNotifier.value.where((e) => e.id != id).toList();
    setSchedules(updated);
  }
}

/// Dialog tambah / edit jadwal kuliah untuk Mahasiswa.
class AddStudentScheduleDialog extends StatefulWidget {
  final int initialDay;

  const AddStudentScheduleDialog({super.key, this.initialDay = 1});

  @override
  State<AddStudentScheduleDialog> createState() =>
      _AddStudentScheduleDialogState();
}

class _AddStudentScheduleDialogState extends State<AddStudentScheduleDialog> {
  final _nameCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  late int _selectedDay;
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay.clamp(1, 5);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
      _error = null;
    });
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama mata kuliah wajib diisi.');
      return;
    }
    final startMin = _start.hour * 60 + _start.minute;
    final endMin = _end.hour * 60 + _end.minute;
    if (endMin <= startMin) {
      setState(() => _error = 'Jam selesai harus setelah jam mulai.');
      return;
    }

    final item = CourseScheduleItem(
      id: 'sched_${DateTime.now().millisecondsSinceEpoch}',
      courseName: name,
      room: _roomCtrl.text.trim().isEmpty
          ? 'Fakultas USU'
          : _roomCtrl.text.trim(),
      dayOfWeek: _selectedDay,
      startTime: _fmt(_start),
      endTime: _fmt(_end),
    );
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2210) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0F172A);
    final ts = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF0F1405) : const Color(0xFFF1F5F9);
    final border = isDark ? const Color(0xFF334110) : const Color(0xFFE2E8F0);

    return AlertDialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        'Tambah Jadwal Kuliah',
        style: TextStyle(color: tp, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hari Perkuliahan',
              style: TextStyle(
                color: ts,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(5, (idx) {
                final d = idx + 1;
                final sel = _selectedDay == d;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? kPrimary : inputBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? kPrimary : border),
                    ),
                    child: Text(
                      kScheduleDayNames[d],
                      style: TextStyle(
                        color: sel ? kTextOnPrimary : tp,
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: tp, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nama Mata Kuliah (mis. Kalkulus II)',
                hintStyle: TextStyle(color: ts.withValues(alpha: 0.6)),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jam Mulai',
                            style: TextStyle(color: ts, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmt(_start),
                            style: TextStyle(
                              color: tp,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jam Selesai',
                            style: TextStyle(color: ts, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmt(_end),
                            style: TextStyle(
                              color: tp,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roomCtrl,
              style: TextStyle(color: tp, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ruang / Gedung (mis. Gedung C Fasilkom USU)',
                hintStyle: TextStyle(color: ts.withValues(alpha: 0.6)),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal', style: TextStyle(color: ts)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: kTextOnPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _save,
          child: const Text(
            'Simpan Jadwal',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// Widget Section Jadwal Kuliah untuk ditampilkan langsung di Beranda Mahasiswa
class MahasiswaScheduleSection extends StatefulWidget {
  final ValueChanged<String>? onOrderRideToClass;
  final VoidCallback? onOpenFullSchedule;

  const MahasiswaScheduleSection({
    super.key,
    this.onOrderRideToClass,
    this.onOpenFullSchedule,
  });

  @override
  State<MahasiswaScheduleSection> createState() =>
      _MahasiswaScheduleSectionState();
}

class _MahasiswaScheduleSectionState extends State<MahasiswaScheduleSection> {
  /// 0 = Semua Hari, 1 = Senin .. 5 = Jumat
  int _selectedDayFilter = 0;

  @override
  void initState() {
    super.initState();
    _syncUserDocSchedules();
  }

  Future<void> _syncUserDocSchedules() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data != null && data['jadwalKuliah'] is List) {
        final rawList = data['jadwalKuliah'] as List;
        final parsed = <CourseScheduleItem>[];
        for (int i = 0; i < rawList.length; i++) {
          final item = rawList[i];
          if (item is Map<String, dynamic>) {
            parsed.add(CourseScheduleItem.fromMap('doc_$i', item));
          } else if (item is Map) {
            parsed.add(
              CourseScheduleItem.fromMap(
                'doc_$i',
                Map<String, dynamic>.from(item),
              ),
            );
          }
        }
        if (parsed.isNotEmpty) {
          StudentScheduleStore.setSchedules([
            ...StudentScheduleStore.items,
            ...parsed,
          ]);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tp = isDark ? Colors.white : const Color(0xFF0F1A02);
    final ts = isDark ? const Color(0xFF8A9E70) : const Color(0xFF6B7A5A);
    final cardBg = isDark ? kCardDark : kCardLight;
    final border = isDark ? kBorderDark : kBorderLight;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: uid != null
          ? FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('schedules')
                .snapshots()
          : null,
      builder: (context, snapshot) {
        return ValueListenableBuilder<List<CourseScheduleItem>>(
          valueListenable: StudentScheduleStore.schedulesNotifier,
          builder: (context, localItems, _) {
            final merged = _mergeSchedules(snapshot.data?.docs, localItems);

            final filtered = _selectedDayFilter == 0
                ? merged
                : merged
                      .where((s) => s.dayOfWeek == _selectedDayFilter)
                      .toList();

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: kPrimaryDeep,
                            size: 20,
                          ),
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
                                      'Jadwal Kuliah Kamu',
                                      style: TextStyle(
                                        color: tp,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kPrimary,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      '${merged.length} Matkul',
                                      style: const TextStyle(
                                        color: kTextOnPrimary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Data jadwal Senin – Jumat dari pendaftaran akunmu',
                                style: TextStyle(color: ts, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: widget.onOpenFullSchedule,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Kelola',
                              style: TextStyle(
                                color: kPrimaryDeep,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Day Filter Pills (Semua, Senin .. Jumat)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: List.generate(6, (idx) {
                          final isSelected = _selectedDayFilter == idx;
                          final label = idx == 0
                              ? 'Semua Hari'
                              : kScheduleDayNames[idx];
                          final count = idx == 0
                              ? merged.length
                              : merged.where((s) => s.dayOfWeek == idx).length;

                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedDayFilter = idx),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? kPrimary
                                    : (isDark
                                          ? const Color(0xFF141A0C)
                                          : const Color(0xFFF3F6EC)),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: isSelected ? kPrimary : border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected ? kTextOnPrimary : tp,
                                      fontSize: 11.5,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  if (count > 0) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? kTextOnPrimary.withValues(
                                                alpha: 0.15,
                                              )
                                            : kPrimary.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          color: isSelected
                                              ? kTextOnPrimary
                                              : tp,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (filtered.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF141A0C)
                              : const Color(0xFFF8FAF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_note_rounded,
                              color: ts.withValues(alpha: 0.6),
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _selectedDayFilter == 0
                                  ? 'Belum ada jadwal kuliah yang tersimpan.'
                                  : 'Tidak ada jadwal kuliah pada hari ${kScheduleDayNames[_selectedDayFilter]}.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: ts,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: widget.onOpenFullSchedule,
                              borderRadius: BorderRadius.circular(99),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimary,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Text(
                                  '+ Tambah Jadwal Kuliah',
                                  style: TextStyle(
                                    color: kTextOnPrimary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...filtered.take(4).map((course) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF141A0C)
                                : const Color(0xFFF8FAF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      course.dayName.substring(0, 3).toUpperCase(),
                                      style: const TextStyle(
                                        color: kPrimaryDeep,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      course.startTime,
                                      style: TextStyle(
                                        color: tp,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.courseName,
                                      style: TextStyle(
                                        color: tp,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 12,
                                          color: ts,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${course.startTime} - ${course.endTime}',
                                          style: TextStyle(
                                            color: ts,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 12,
                                          color: ts,
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            course.locationLabel,
                                            style: TextStyle(
                                              color: ts,
                                              fontSize: 11,
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
                              if (widget.onOrderRideToClass != null) ...[
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: 'Pesan Antar ke ${course.locationLabel}',
                                  child: InkWell(
                                    onTap: () => widget.onOrderRideToClass!(
                                      course.locationLabel,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kPrimary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.motorcycle_rounded,
                                            size: 14,
                                            color: kTextOnPrimary,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Gas',
                                            style: TextStyle(
                                              color: kTextOnPrimary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),

                    if (filtered.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Center(
                          child: TextButton(
                            onPressed: widget.onOpenFullSchedule,
                            child: Text(
                              'Lihat Semua ${filtered.length} Jadwal Kuliah →',
                              style: const TextStyle(
                                color: kPrimaryDeep,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
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
  }
}

List<CourseScheduleItem> _mergeSchedules(
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? firestoreDocs,
  List<CourseScheduleItem> localItems,
) {
  final result = <CourseScheduleItem>[];
  final seenKeys = <String>{};

  if (firestoreDocs != null) {
    for (final doc in firestoreDocs) {
      final item = CourseScheduleItem.fromMap(doc.id, doc.data());
      final key =
          '${item.dayOfWeek}_${item.courseName.toLowerCase()}_${item.startTime}';
      if (seenKeys.add(key)) {
        result.add(item);
      }
    }
  }

  for (final item in localItems) {
    final key =
        '${item.dayOfWeek}_${item.courseName.toLowerCase()}_${item.startTime}';
    if (seenKeys.add(key)) {
      result.add(item);
    }
  }

  // Fallback contoh jadwal apabila akun demo belum memiliki dokumen jadwal
  if (result.isEmpty && FirebaseAuth.instance.currentUser == null) {
    return const [
      CourseScheduleItem(
        id: 'demo_1',
        courseName: 'Algoritma & Struktur Data',
        room: 'Gedung C Fasilkom-TI USU',
        dayOfWeek: 1,
        startTime: '08:00',
        endTime: '10:30',
      ),
      CourseScheduleItem(
        id: 'demo_2',
        courseName: 'Kalkulus Lanjut',
        room: 'Fakultas Teknik USU',
        dayOfWeek: 2,
        startTime: '10:00',
        endTime: '12:00',
      ),
      CourseScheduleItem(
        id: 'demo_3',
        courseName: 'Rekayasa Perangkat Lunak',
        room: 'Lab Komputer Fasilkom-TI USU',
        dayOfWeek: 4,
        startTime: '13:30',
        endTime: '15:30',
      ),
    ];
  }

  result.sort((a, b) {
    final cmpDay = a.dayOfWeek.compareTo(b.dayOfWeek);
    if (cmpDay != 0) return cmpDay;
    return a.startTime.compareTo(b.startTime);
  });

  return result;
}

/// Halaman Penuh Jadwal Kuliah Mahasiswa (Senin s/d Jumat)
class JadwalKuliahScreen extends StatefulWidget {
  final ValueChanged<String>? onOrderRideToClass;

  const JadwalKuliahScreen({super.key, this.onOrderRideToClass});

  @override
  State<JadwalKuliahScreen> createState() => _JadwalKuliahScreenState();
}

class _JadwalKuliahScreenState extends State<JadwalKuliahScreen> {
  int _selectedDay = 0; // 0 = Semua Hari, 1..5 = Senin..Jumat

  Future<void> _handleAddSchedule() async {
    final added = await showDialog<CourseScheduleItem>(
      context: context,
      builder: (_) => AddStudentScheduleDialog(
        initialDay: _selectedDay == 0 ? 1 : _selectedDay,
      ),
    );
    if (added == null) return;

    StudentScheduleStore.addSchedule(added);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('schedules')
            .add(added.toMap(userId: uid));
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'hasSchedule': true,
        });
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jadwal "${added.courseName}" (${added.dayName}) berhasil ditambahkan!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleDeleteSchedule(CourseScheduleItem item) async {
    StudentScheduleStore.removeSchedule(item.id);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && !item.id.startsWith('sched_')) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('schedules')
            .doc(item.id)
            .delete();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kBgDark : kBgLight;
    final tp = isDark ? Colors.white : const Color(0xFF0F1A02);
    final ts = isDark ? const Color(0xFF8A9E70) : const Color(0xFF6B7A5A);
    final cardBg = isDark ? kCardDark : kCardLight;
    final border = isDark ? kBorderDark : kBorderLight;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: tp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Jadwal Kuliah Mahasiswa',
          style: TextStyle(
            color: tp,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _handleAddSchedule,
              style: TextButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: kTextOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Tambah',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: uid != null
            ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('schedules')
                  .snapshots()
            : null,
        builder: (context, snapshot) {
          return ValueListenableBuilder<List<CourseScheduleItem>>(
            valueListenable: StudentScheduleStore.schedulesNotifier,
            builder: (context, localItems, _) {
              final allSchedules = _mergeSchedules(
                snapshot.data?.docs,
                localItems,
              );

              final daysToShow = _selectedDay == 0
                  ? [1, 2, 3, 4, 5]
                  : [_selectedDay];

              return Column(
                children: [
                  // Filter Hari
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: List.generate(6, (idx) {
                          final sel = _selectedDay == idx;
                          final label = idx == 0
                              ? 'Semua (Sen–Jum)'
                              : kScheduleDayNames[idx];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDay = idx),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: sel ? kPrimary : cardBg,
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: sel ? kPrimary : border,
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: sel ? kTextOnPrimary : tp,
                                  fontSize: 12.5,
                                  fontWeight: sel
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      itemCount: daysToShow.length,
                      itemBuilder: (context, index) {
                        final day = daysToShow[index];
                        final dayCourses = allSchedules
                            .where((s) => s.dayOfWeek == day)
                            .toList();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: kPrimary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        kScheduleDayNames[day],
                                        style: TextStyle(
                                          color: tp,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${dayCourses.length} Mata Kuliah',
                                    style: TextStyle(
                                      color: ts,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (dayCourses.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'Tidak ada jadwal kuliah di hari ${kScheduleDayNames[day]}.',
                                    style: TextStyle(color: ts, fontSize: 12.5),
                                  ),
                                )
                              else
                                ...dayCourses.map((course) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF141A0C)
                                          : const Color(0xFFF8FAF4),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: border),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                course.courseName,
                                                style: TextStyle(
                                                  color: tp,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${course.startTime} - ${course.endTime}  •  ${course.locationLabel}',
                                                style: TextStyle(
                                                  color: ts,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (widget.onOrderRideToClass != null)
                                          IconButton(
                                            tooltip:
                                                'Pesan Antar ke ${course.locationLabel}',
                                            onPressed: () {
                                              Navigator.pop(context);
                                              widget.onOrderRideToClass!(
                                                course.locationLabel,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.motorcycle_rounded,
                                              color: kPrimaryDeep,
                                              size: 20,
                                            ),
                                          ),
                                        IconButton(
                                          tooltip: 'Hapus Jadwal',
                                          onPressed: () =>
                                              _handleDeleteSchedule(course),
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
