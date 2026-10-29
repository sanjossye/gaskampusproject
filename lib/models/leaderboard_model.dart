/// Model leaderboard driver.
/// Firestore collection: `leaderboard`
class LeaderboardModel {
  final String id;
  final String driverId;
  final String? driverName;
  final String? driverPhotoUrl;
  final int totalEarnings;
  final int totalTrips;
  final double avgRating;
  final String period; // weekly, monthly
  final int rank;
  final DateTime periodStart;
  final DateTime periodEnd;

  const LeaderboardModel({
    required this.id,
    required this.driverId,
    this.driverName,
    this.driverPhotoUrl,
    required this.totalEarnings,
    required this.totalTrips,
    this.avgRating = 0.0,
    required this.period,
    required this.rank,
    required this.periodStart,
    required this.periodEnd,
  });

  factory LeaderboardModel.fromMap(Map<String, dynamic> data, String docId) {
    return LeaderboardModel(
      id: docId,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'],
      driverPhotoUrl: data['driverPhotoUrl'],
      totalEarnings: data['totalEarnings'] ?? 0,
      totalTrips: data['totalTrips'] ?? 0,
      avgRating: (data['avgRating'] ?? 0).toDouble(),
      period: data['period'] ?? 'weekly',
      rank: data['rank'] ?? 0,
      periodStart: data['periodStart'] is DateTime
          ? data['periodStart']
          : DateTime.tryParse(data['periodStart']?.toString() ?? '') ?? DateTime.now(),
      periodEnd: data['periodEnd'] is DateTime
          ? data['periodEnd']
          : DateTime.tryParse(data['periodEnd']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'driverPhotoUrl': driverPhotoUrl,
      'totalEarnings': totalEarnings,
      'totalTrips': totalTrips,
      'avgRating': avgRating,
      'period': period,
      'rank': rank,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
    };
  }

  LeaderboardModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? driverPhotoUrl,
    int? totalEarnings,
    int? totalTrips,
    double? avgRating,
    String? period,
    int? rank,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    return LeaderboardModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalTrips: totalTrips ?? this.totalTrips,
      avgRating: avgRating ?? this.avgRating,
      period: period ?? this.period,
      rank: rank ?? this.rank,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
    );
  }

  /// Format total pendapatan ke Rupiah (contoh: "Rp 1.150.000")
  String get formattedEarnings {
    final formatted = totalEarnings.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  /// Apakah rank #1
  bool get isTopDriver => rank == 1;

  /// Emoji medali berdasarkan rank
  String get rankBadge {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  /// Label periode (contoh: "Mingguan" atau "Bulanan")
  String get periodLabel {
    switch (period) {
      case 'weekly':
        return 'Mingguan';
      case 'monthly':
        return 'Bulanan';
      default:
        return period;
    }
  }

  @override
  String toString() =>
      'LeaderboardModel(rank: $rank, driver: $driverName, earnings: $formattedEarnings)';
}

