import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/config/app_config.dart';
import '../../../core/models/chat_message_model.dart';

class ChatService {
  IO.Socket? _socket;
  String? _currentUserId;
  String? _currentRoomId;
  
  bool get isConnected => _socket?.connected ?? false;

  // Initialize Socket.io connection
  void connect(String userId) {
    _currentUserId = userId;
    
    _socket = IO.io(
      AppConfig.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setExtraHeaders({'user_id': userId})
          .build(),
    );

    _socket!.onConnect((_) {
      print('Socket connected');
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });

    _socket!.onError((error) {
      print('Socket error: $error');
    });
  }

  // Disconnect socket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentUserId = null;
    _currentRoomId = null;
  }

  // Join a chat room
  void joinRoom(String roomId) {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }

    _currentRoomId = roomId;
    _socket!.emit('join_room', {'room_id': roomId, 'user_id': _currentUserId});
  }

  // Leave a chat room
  void leaveRoom(String roomId) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit('leave_room', {'room_id': roomId, 'user_id': _currentUserId});
    if (_currentRoomId == roomId) {
      _currentRoomId = null;
    }
  }

  // Send a message
  void sendMessage({
    required String roomId,
    required String message,
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }

    final messageData = {
      'room_id': roomId,
      'sender_id': _currentUserId,
      'message': message,
      'type': type,
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    };

    _socket!.emit('send_message', messageData);
  }

  // Listen for incoming messages
  void onMessageReceived(Function(ChatMessageModel) callback) {
    if (_socket == null) return;

    _socket!.on('new_message', (data) {
      final message = ChatMessageModel.fromJson(data as Map<String, dynamic>);
      callback(message);
    });
  }

  // Send typing indicator
  void sendTypingIndicator(String roomId, bool isTyping) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit('typing', {
      'room_id': roomId,
      'user_id': _currentUserId,
      'is_typing': isTyping,
    });
  }

  // Listen for typing indicators
  void onTypingIndicator(Function(String userId, bool isTyping) callback) {
    if (_socket == null) return;

    _socket!.on('user_typing', (data) {
      final userId = data['user_id'] as String;
      final isTyping = data['is_typing'] as bool;
      
      // Don't show typing indicator for current user
      if (userId != _currentUserId) {
        callback(userId, isTyping);
      }
    });
  }

  // Mark message as read
  void markMessageAsRead(String messageId, String roomId) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit('mark_read', {
      'message_id': messageId,
      'room_id': roomId,
      'user_id': _currentUserId,
    });
  }

  // Listen for message read receipts
  void onMessageRead(Function(String messageId) callback) {
    if (_socket == null) return;

    _socket!.on('message_read', (data) {
      final messageId = data['message_id'] as String;
      callback(messageId);
    });
  }

  // Join global rooms (for vendors and riders)
  void joinGlobalRoom(String roomType) {
    // roomType: 'vendors' or 'riders'
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit('join_global_room', {
      'room_type': roomType,
      'user_id': _currentUserId,
    });
  }
}
