/// Tipe notifikasi.
enum NotificationType {
  order,
  promo,
  system,
  chat,
}

/// Model notifikasi.
/// Firestore collection: `users/{uid}/notifications`
class NotificationModel {
  final String notifId;
  final String userId;
  final String title;
  final String subtitle;
  final NotificationType type;
  final String? icon;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.notifId,
    required this.userId,
    required this.title,
    required this.subtitle,
    required this.type,
    this.icon,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, String docId) {
    return NotificationModel(
      notifId: docId,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      type: _parseType(data['type']),
      icon: data['icon'],
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt']
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'subtitle': subtitle,
      'type': type.name,
      'icon': icon,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? notifId,
    String? userId,
    String? title,
    String? subtitle,
    NotificationType? type,
    String? icon,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      notifId: notifId ?? this.notifId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Tandai notifikasi sebagai sudah dibaca
  NotificationModel markAsRead() => copyWith(isRead: true);

  /// Format waktu relatif (contoh: "5 menit lalu", "2 jam lalu")
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  static NotificationType _parseType(String? value) {
    switch (value) {
      case 'order':
        return NotificationType.order;
      case 'promo':
        return NotificationType.promo;
      case 'system':
        return NotificationType.system;
      case 'chat':
        return NotificationType.chat;
      default:
        return NotificationType.system;
    }
  }

  @override
  String toString() =>
      'NotificationModel(id: $notifId, title: $title, isRead: $isRead)';
}

