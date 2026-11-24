/// Model item menu makanan/minuman milik merchant.
class MerchantMenuItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String category;
  final String imageData; // URL, data:image base64, atau kosong
  final bool isAvailable;

  const MerchantMenuItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.category = 'Makanan Berat',
    this.imageData = '',
    this.isAvailable = true,
  });

  factory MerchantMenuItem.fromMap(Map<String, dynamic> data, {String? id}) {
    return MerchantMenuItem(
      id: (id ?? data['id'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      price: (data['price'] as num?)?.toInt() ?? 0,
      category: (data['category'] ?? 'Makanan Berat').toString(),
      imageData: (data['imageData'] ?? '').toString(),
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageData': imageData,
      'isAvailable': isAvailable,
    };
  }

  MerchantMenuItem copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    String? category,
    String? imageData,
    bool? isAvailable,
  }) {
    return MerchantMenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageData: imageData ?? this.imageData,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

/// Model toko makanan (Merchant) pada koleksi Firestore `merchants/{id}`.
class MerchantModel {
  final String id;
  final String ownerUid;
  final String name;
  final String ownerName;
  final String phone;
  final String category;
  final String address;
  final double latitude;
  final double longitude;
  final String bannerData; // URL gambar atau data:image;base64,...
  final String bannerHeadline;
  final String bannerTheme; // 'lime' | 'orange' | 'emerald' | 'berry' | 'dark'
  final bool isOpen;
  final bool isClaimed;
  final String registeredBy;
  final double rating;
  final int totalOrders;
  final List<MerchantMenuItem> menus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MerchantModel({
    required this.id,
    required this.ownerUid,
    required this.name,
    this.ownerName = '',
    this.phone = '',
    this.category = 'Aneka Masakan',
    required this.address,
    this.latitude = 3.5625,
    this.longitude = 98.6565,
    this.bannerData = '',
    this.bannerHeadline = '',
    this.bannerTheme = 'lime',
    this.isOpen = true,
    this.isClaimed = true,
    this.registeredBy = 'self',
    this.rating = 4.9,
    this.totalOrders = 0,
    this.menus = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory MerchantModel.fromMap(Map<String, dynamic> data, String docId) {
    final rawMenus = data['menus'];
    final parsedMenus = <MerchantMenuItem>[];
    if (rawMenus is List) {
      for (var i = 0; i < rawMenus.length; i++) {
        final item = rawMenus[i];
        if (item is Map) {
          parsedMenus.add(
            MerchantMenuItem.fromMap(
              Map<String, dynamic>.from(item),
              id: (item['id'] ?? 'menu_$i').toString(),
            ),
          );
        }
      }
    }

    final ownerUid = (data['ownerUid'] ?? docId).toString();
    final bool isClaimed = data['isClaimed'] ?? (ownerUid != 'unclaimed' && ownerUid.isNotEmpty);

    return MerchantModel(
      id: docId,
      ownerUid: ownerUid,
      name: (data['name'] ?? 'Toko Makanan').toString(),
      ownerName: (data['ownerName'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      category: (data['category'] ?? 'Aneka Masakan').toString(),
      address: (data['address'] ?? 'Area Kampus USU, Medan').toString(),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 3.5625,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 98.6565,
      bannerData: (data['bannerData'] ?? '').toString(),
      bannerHeadline: (data['bannerHeadline'] ?? '').toString(),
      bannerTheme: (data['bannerTheme'] ?? 'lime').toString(),
      isOpen: data['isOpen'] ?? true,
      isClaimed: isClaimed,
      registeredBy: (data['registeredBy'] ?? (isClaimed ? 'self' : 'admin')).toString(),
      rating: (data['rating'] as num?)?.toDouble() ?? 4.9,
      totalOrders: (data['totalOrders'] as num?)?.toInt() ?? 0,
      menus: parsedMenus,
      createdAt:
          DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(data['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'name': name,
      'ownerName': ownerName,
      'phone': phone,
      'category': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'bannerData': bannerData,
      'bannerHeadline': bannerHeadline,
      'bannerTheme': bannerTheme,
      'isOpen': isOpen,
      'isClaimed': isClaimed,
      'registeredBy': registeredBy,
      'rating': rating,
      'totalOrders': totalOrders,
      'menus': menus.map((m) => m.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MerchantModel copyWith({
    String? id,
    String? ownerUid,
    String? name,
    String? ownerName,
    String? phone,
    String? category,
    String? address,
    double? latitude,
    double? longitude,
    String? bannerData,
    String? bannerHeadline,
    String? bannerTheme,
    bool? isOpen,
    bool? isClaimed,
    String? registeredBy,
    double? rating,
    int? totalOrders,
    List<MerchantMenuItem>? menus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MerchantModel(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      category: category ?? this.category,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bannerData: bannerData ?? this.bannerData,
      bannerHeadline: bannerHeadline ?? this.bannerHeadline,
      bannerTheme: bannerTheme ?? this.bannerTheme,
      isOpen: isOpen ?? this.isOpen,
      isClaimed: isClaimed ?? this.isClaimed,
      registeredBy: registeredBy ?? this.registeredBy,
      rating: rating ?? this.rating,
      totalOrders: totalOrders ?? this.totalOrders,
      menus: menus ?? this.menus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
