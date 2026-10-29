/// Model jadwal kuliah driver mahasiswa.
/// Firestore collection: `users/{uid}/schedules`
class ScheduleModel {
  final String scheduleId;
  final String userId;
  final String courseName;
  final String courseType; // regular, praktikum
  final String room;
  final String building;
  final int dayOfWeek; // 1=Senin, 2=Selasa, ..., 7=Minggu
  final String startTime; // format "HH:mm" (contoh: "10:00")
  final String endTime; // format "HH:mm" (contoh: "12:00")
  final DateTime createdAt;

  const ScheduleModel({
    required this.scheduleId,
    required this.userId,
    required this.courseName,
    this.courseType = 'regular',
    required this.room,
    required this.building,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
  });

  factory ScheduleModel.fromMap(Map<String, dynamic> data, String docId) {
    return ScheduleModel(
      scheduleId: docId,
      userId: data['userId'] ?? '',
      courseName: data['courseName'] ?? '',
      courseType: data['courseType'] ?? 'regular',
      room: data['room'] ?? '',
      building: data['building'] ?? '',
      dayOfWeek: data['dayOfWeek'] ?? 1,
      startTime: data['startTime'] ?? '00:00',
      endTime: data['endTime'] ?? '00:00',
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt']
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseName': courseName,
      'courseType': courseType,
      'room': room,
      'building': building,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ScheduleModel copyWith({
    String? scheduleId,
    String? userId,
    String? courseName,
    String? courseType,
    String? room,
    String? building,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    DateTime? createdAt,
  }) {
    return ScheduleModel(
      scheduleId: scheduleId ?? this.scheduleId,
      userId: userId ?? this.userId,
      courseName: courseName ?? this.courseName,
      courseType: courseType ?? this.courseType,
      room: room ?? this.room,
      building: building ?? this.building,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Nama hari dari dayOfWeek
  String get dayName {
    const days = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) return days[dayOfWeek];
    return '-';
  }

  /// Nama hari singkat
  String get dayNameShort {
    const days = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) return days[dayOfWeek];
    return '-';
  }

  /// Format waktu tampil (contoh: "10:00 - 12:00")
  String get formattedTime => '$startTime - $endTime';

  /// Format lokasi lengkap (contoh: "Gedung A, R.302")
  String get formattedLocation => '$building, $room';

  /// Apakah jadwal ini praktikum
  bool get isPraktikum => courseType == 'praktikum';

  /// Cek apakah jadwal sedang berlangsung saat ini
  bool get isOngoing {
    final now = DateTime.now();
    final currentDay = now.weekday; // 1=Monday ... 7=Sunday
    if (currentDay != dayOfWeek) return false;

    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    if (startParts.length != 2 || endParts.length != 2) return false;

    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    final nowMinutes = now.hour * 60 + now.minute;

    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  @override
  String toString() =>
      'ScheduleModel(id: $scheduleId, course: $courseName, day: $dayName, time: $formattedTime)';
}

