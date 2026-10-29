/// Model data user untuk semua role (mahasiswa, driver_kampus, driver_umum, admin).
/// Firestore collection: `users`
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? nim;
  final String? phone;
  final String? photoUrl;
  final String role; // mahasiswa, driver_kampus, driver_umum, admin
  final String? facultas;
  final bool isVerified;
  final bool isActive;
  final double rating;
  final int totalTrips;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.nim,
    this.phone,
    this.photoUrl,
    required this.role,
    this.facultas,
    this.isVerified = false,
    this.isActive = true,
    this.rating = 0.0,
    this.totalTrips = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String docId) {
    return UserModel(
      uid: docId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      nim: data['nim'],
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'mahasiswa',
      facultas: data['facultas'],
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      rating: (data['rating'] ?? 0).toDouble(),
      totalTrips: data['totalTrips'] ?? 0,
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt']
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: data['updatedAt'] is DateTime
          ? data['updatedAt']
          : DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'nim': nim,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role,
      'facultas': facultas,
      'isVerified': isVerified,
      'isActive': isActive,
      'rating': rating,
      'totalTrips': totalTrips,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? nim,
    String? phone,
    String? photoUrl,
    String? role,
    String? facultas,
    bool? isVerified,
    bool? isActive,
    double? rating,
    int? totalTrips,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      nim: nim ?? this.nim,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      facultas: facultas ?? this.facultas,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Cek apakah user adalah driver (kampus atau umum)
  bool get isDriver => role == 'driver_kampus' || role == 'driver_umum';

  /// Cek apakah user adalah admin
  bool get isAdmin => role == 'admin';

  /// Cek apakah user adalah mahasiswa (passenger)
  bool get isMahasiswa => role == 'mahasiswa';

  @override
  String toString() => 'UserModel(uid: $uid, name: $name, role: $role)';
}

/// Profil tambahan khusus driver.
/// Firestore collection: `users/{uid}/driver_profile` (subcollection)
class DriverProfileModel {
  final String uid;
  final String vehicleType; // motor, mobil
  final String vehiclePlate;
  final String vehicleBrand;
  final String? simNumber;
  final String? stnkNumber;
  final String? ktmNumber;
  final bool isOnline;
  final double? currentLatitude;
  final double? currentLongitude;
  final String status; // available, on_trip, offline
  final DateTime memberSince;

  const DriverProfileModel({
    required this.uid,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.vehicleBrand,
    this.simNumber,
    this.stnkNumber,
    this.ktmNumber,
    this.isOnline = false,
    this.currentLatitude,
    this.currentLongitude,
    this.status = 'offline',
    required this.memberSince,
  });

  factory DriverProfileModel.fromMap(Map<String, dynamic> data, String docId) {
    return DriverProfileModel(
      uid: docId,
      vehicleType: data['vehicleType'] ?? 'motor',
      vehiclePlate: data['vehiclePlate'] ?? '',
      vehicleBrand: data['vehicleBrand'] ?? '',
      simNumber: data['simNumber'],
      stnkNumber: data['stnkNumber'],
      ktmNumber: data['ktmNumber'],
      isOnline: data['isOnline'] ?? false,
      currentLatitude: (data['currentLatitude'] as num?)?.toDouble(),
      currentLongitude: (data['currentLongitude'] as num?)?.toDouble(),
      status: data['status'] ?? 'offline',
      memberSince: data['memberSince'] is DateTime
          ? data['memberSince']
          : DateTime.tryParse(data['memberSince']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleType': vehicleType,
      'vehiclePlate': vehiclePlate,
      'vehicleBrand': vehicleBrand,
      'simNumber': simNumber,
      'stnkNumber': stnkNumber,
      'ktmNumber': ktmNumber,
      'isOnline': isOnline,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'status': status,
      'memberSince': memberSince.toIso8601String(),
    };
  }

  DriverProfileModel copyWith({
    String? uid,
    String? vehicleType,
    String? vehiclePlate,
    String? vehicleBrand,
    String? simNumber,
    String? stnkNumber,
    String? ktmNumber,
    bool? isOnline,
    double? currentLatitude,
    double? currentLongitude,
    String? status,
    DateTime? memberSince,
  }) {
    return DriverProfileModel(
      uid: uid ?? this.uid,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      simNumber: simNumber ?? this.simNumber,
      stnkNumber: stnkNumber ?? this.stnkNumber,
      ktmNumber: ktmNumber ?? this.ktmNumber,
      isOnline: isOnline ?? this.isOnline,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      status: status ?? this.status,
      memberSince: memberSince ?? this.memberSince,
    );
  }

  @override
  String toString() =>
      'DriverProfileModel(uid: $uid, plate: $vehiclePlate, status: $status)';
}

