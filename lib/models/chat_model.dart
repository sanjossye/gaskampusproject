/// Tipe pesan dalam chat.
enum MessageType {
  text,
  image,
  location,
}

/// Model ruang chat antara passenger dan driver.
/// Firestore collection: `chat_rooms`
class ChatRoomModel {
  final String roomId;
  final String passengerId;
  final String driverId;
  final String? orderId;
  final String? lastMessage;
  final DateTime lastMessageAt;

  const ChatRoomModel({
    required this.roomId,
    required this.passengerId,
    required this.driverId,
    this.orderId,
    this.lastMessage,
    required this.lastMessageAt,
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> data, String docId) {
    return ChatRoomModel(
      roomId: docId,
      passengerId: data['passengerId'] ?? '',
      driverId: data['driverId'] ?? '',
      orderId: data['orderId'],
      lastMessage: data['lastMessage'],
      lastMessageAt: data['lastMessageAt'] is DateTime
          ? data['lastMessageAt']
          : DateTime.tryParse(data['lastMessageAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'passengerId': passengerId,
      'driverId': driverId,
      'orderId': orderId,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt.toIso8601String(),
    };
  }

  ChatRoomModel copyWith({
    String? roomId,
    String? passengerId,
    String? driverId,
    String? orderId,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) {
    return ChatRoomModel(
      roomId: roomId ?? this.roomId,
      passengerId: passengerId ?? this.passengerId,
      driverId: driverId ?? this.driverId,
      orderId: orderId ?? this.orderId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  @override
  String toString() => 'ChatRoomModel(roomId: $roomId, orderId: $orderId)';
}

/// Model pesan individual dalam chat room.
/// Firestore collection: `chat_rooms/{roomId}/messages`
class MessageModel {
  final String messageId;
  final String roomId;
  final String senderId;
  final String text;
  final MessageType type;
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.text,
    this.type = MessageType.text,
    this.isRead = false,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> data, String docId) {
    return MessageModel(
      messageId: docId,
      roomId: data['roomId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      type: _parseType(data['type']),
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt']
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? messageId,
    String? roomId,
    String? senderId,
    String? text,
    MessageType? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Tandai pesan sebagai sudah dibaca
  MessageModel markAsRead() => copyWith(isRead: true);

  /// Cek apakah pesan dikirim oleh user tertentu
  bool isSentBy(String userId) => senderId == userId;

  /// Format waktu tampil (contoh: "14:30")
  String get formattedTime {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static MessageType _parseType(String? value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'location':
        return MessageType.location;
      default:
        return MessageType.text;
    }
  }

  @override
  String toString() =>
      'MessageModel(id: $messageId, sender: $senderId, type: ${type.name})';
}

