class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String? senderImageUrl;
  final String message;
  final String type; // text, image, location, system
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.message,
    this.type = 'text',
    this.metadata,
    this.isRead = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String,
      senderImageUrl: json['sender_image_url'] as String?,
      message: json['message'] as String,
      type: json['type'] as String? ?? 'text',
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_image_url': senderImageUrl,
      'message': message,
      'type': type,
      'metadata': metadata,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class ChatRoom {
  final String id;
  final String name;
  final String type; // direct, vendor_room, rider_room
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.metadata,
    required this.createdAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      participantIds: List<String>.from(json['participant_ids'] ?? []),
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'participant_ids': participantIds,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
