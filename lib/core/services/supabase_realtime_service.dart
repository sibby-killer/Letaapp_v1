import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';

/// Supabase Realtime Service
/// Handles all real-time features using Supabase Realtime (Postgres Changes + Broadcast)
/// No Socket.io or external Node.js server required
class SupabaseRealtimeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Broadcast channels for ephemeral events
  RealtimeChannel? _typingChannel;
  RealtimeChannel? _locationChannel;
  
  // Stream subscriptions
  final Map<String, StreamSubscription> _messageSubscriptions = {};
  
  String? _currentUserId;
  String? _currentRoomId;

  /// Initialize the service with current user ID
  void initialize(String userId) {
    _currentUserId = userId;
  }

  /// Cleanup all channels and subscriptions
  Future<void> dispose() async {
    // Remove all channels
    if (_typingChannel != null) {
      await _supabase.removeChannel(_typingChannel!);
      _typingChannel = null;
    }
    
    if (_locationChannel != null) {
      await _supabase.removeChannel(_locationChannel!);
      _locationChannel = null;
    }

    // Cancel all message subscriptions
    for (var subscription in _messageSubscriptions.values) {
      await subscription.cancel();
    }
    _messageSubscriptions.clear();
    
    _currentUserId = null;
    _currentRoomId = null;
  }

  // ============================================================================
  // CHAT MESSAGES (Using Postgres Changes - Database Streaming)
  // ============================================================================

  /// Send a message by inserting into the messages table
  /// The UI will automatically update via the stream
  Future<void> sendMessage({
    required String roomId,
    required String message,
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not initialized. Call initialize() first.');
    }

    // Get sender name from users table
    final userResponse = await _supabase
        .from('users')
        .select('full_name, avatar_url')
        .eq('id', _currentUserId!)
        .single();

    // Insert message into database
    await _supabase.from('messages').insert({
      'room_id': roomId,
      'sender_id': _currentUserId,
      'sender_name': userResponse['full_name'] ?? 'Unknown',
      'sender_image_url': userResponse['avatar_url'],
      'message': message,
      'type': type,
      'metadata': metadata,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Note: We don't need to emit any events!
    // Supabase Realtime will automatically notify all listeners
  }

  /// Stream messages from a specific room
  /// Returns a Stream that emits new messages in real-time
  Stream<List<ChatMessageModel>> streamMessages(String roomId) {
    _currentRoomId = roomId;

    // Stream data from the messages table where room_id matches
    // The .stream() method automatically listens for INSERT, UPDATE, DELETE
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((data) {
          return data.map((json) => ChatMessageModel.fromJson(json)).toList();
        });
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    if (_currentUserId == null) return;

    await _supabase
        .from('messages')
        .update({'is_read': true})
        .eq('id', messageId);
  }

  /// Mark all messages in a room as read
  Future<void> markAllMessagesAsRead(String roomId) async {
    if (_currentUserId == null) return;

    await _supabase
        .from('messages')
        .update({'is_read': true})
        .eq('room_id', roomId)
        .neq('sender_id', _currentUserId!);
  }

  /// Get chat rooms for current user
  Future<List<ChatRoom>> getChatRooms() async {
    if (_currentUserId == null) {
      throw Exception('User not initialized. Call initialize() first.');
    }

    final response = await _supabase
        .from('chat_rooms')
        .select('*')
        .contains('participant_ids', [_currentUserId])
        .order('last_message_time', ascending: false);

    return (response as List)
        .map((json) => ChatRoom.fromJson(json))
        .toList();
  }

  /// Create a new chat room
  Future<String> createChatRoom({
    required String name,
    required String type,
    required List<String> participantIds,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _supabase.from('chat_rooms').insert({
      'name': name,
      'type': type,
      'participant_ids': participantIds,
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    }).select('id').single();

    return response['id'] as String;
  }

  // ============================================================================
  // TYPING INDICATORS (Using Broadcast Channels - Ephemeral)
  // ============================================================================

  /// Send typing indicator (ephemeral - not stored in database)
  /// Uses Supabase Broadcast for real-time, temporary events
  void sendTypingIndicator(String roomId, bool isTyping) {
    if (_currentUserId == null) return;

    // Create or reuse typing channel for this room
    _typingChannel ??= _supabase.channel('typing:$roomId');

    // Send broadcast message (ephemeral)
    _typingChannel!.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'user_id': _currentUserId,
        'room_id': roomId,
        'is_typing': isTyping,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Subscribe to the channel if not already subscribed
    if (_typingChannel!.socket.isConnected == false) {
      _typingChannel!.subscribe();
    }
  }

  /// Listen for typing indicators in a room
  /// Returns a Stream of (userId, isTyping) events
  Stream<Map<String, dynamic>> onTypingIndicator(String roomId) {
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    // Create channel for this room
    final channel = _supabase.channel('typing:$roomId');

    // Listen for broadcast messages
    channel.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final userId = payload['user_id'] as String?;
        
        // Don't show typing indicator for current user
        if (userId != null && userId != _currentUserId) {
          controller.add({
            'user_id': userId,
            'is_typing': payload['is_typing'] as bool? ?? false,
          });
        }
      },
    );

    // Subscribe to the channel
    channel.subscribe();

    // Cleanup when stream is canceled
    controller.onCancel = () async {
      await _supabase.removeChannel(channel);
    };

    return controller.stream;
  }

  // ============================================================================
  // LIVE LOCATION TRACKING (Using Broadcast Channels - Ephemeral)
  // ============================================================================

  /// Send live location update (ephemeral - not stored in database)
  /// Used by riders to broadcast their location to customers
  void sendLocationUpdate({
    required String orderId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) {
    if (_currentUserId == null) return;

    // Create or reuse location channel for this order
    _locationChannel ??= _supabase.channel('location:$orderId');

    // Send broadcast message (ephemeral)
    _locationChannel!.sendBroadcastMessage(
      event: 'location',
      payload: {
        'rider_id': _currentUserId,
        'order_id': orderId,
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Subscribe to the channel if not already subscribed
    if (_locationChannel!.socket.isConnected == false) {
      _locationChannel!.subscribe();
    }
  }

  /// Listen for live location updates for a specific order
  /// Returns a Stream of location data
  Stream<Map<String, dynamic>> onLocationUpdate(String orderId) {
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    // Create channel for this order
    final channel = _supabase.channel('location:$orderId');

    // Listen for broadcast messages
    channel.onBroadcast(
      event: 'location',
      callback: (payload) {
        controller.add({
          'rider_id': payload['rider_id'],
          'latitude': payload['latitude'],
          'longitude': payload['longitude'],
          'heading': payload['heading'],
          'speed': payload['speed'],
          'timestamp': payload['timestamp'],
        });
      },
    );

    // Subscribe to the channel
    channel.subscribe();

    // Cleanup when stream is canceled
    controller.onCancel = () async {
      await _supabase.removeChannel(channel);
    };

    return controller.stream;
  }

  /// Stop sending location updates
  Future<void> stopLocationUpdates() async {
    if (_locationChannel != null) {
      await _supabase.removeChannel(_locationChannel!);
      _locationChannel = null;
    }
  }

  // ============================================================================
  // ORDER STATUS UPDATES (Using Postgres Changes)
  // ============================================================================

  /// Stream order status changes
  /// Useful for customers to see when their order status changes in real-time
  Stream<Map<String, dynamic>> streamOrderStatus(String orderId) {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((data) {
          if (data.isEmpty) return {};
          return data.first;
        });
  }

  /// Stream all orders for a vendor/rider
  /// Useful for vendors and riders to see new orders in real-time
  Stream<List<Map<String, dynamic>>> streamOrders({
    String? vendorId,
    String? riderId,
    String? status,
  }) {
    // Build the base stream
    var streamBuilder = _supabase
        .from('orders')
        .stream(primaryKey: ['id']);

    // Apply filters using the filter map (Supabase 2.x compatible)
    // Note: Filters must be applied before .order()
    
    // Build initial query with filters
    var query = _supabase.from('orders').select();
    
    if (vendorId != null) {
      query = query.eq('vendor_id', vendorId);
    }

    if (riderId != null) {
      query = query.eq('rider_id', riderId);
    }

    if (status != null) {
      query = query.eq('status', status);
    }

    // For streaming with filters, we need to use the stream differently
    // Return a stream that applies filters
    return streamBuilder.map((data) {
      var filtered = data;
      
      if (vendorId != null) {
        filtered = filtered.where((order) => order['vendor_id'] == vendorId).toList();
      }
      
      if (riderId != null) {
        filtered = filtered.where((order) => order['rider_id'] == riderId).toList();
      }
      
      if (status != null) {
        filtered = filtered.where((order) => order['status'] == status).toList();
      }
      
      // Sort by created_at descending
      filtered.sort((a, b) {
        final aTime = DateTime.parse(a['created_at'] ?? DateTime.now().toIso8601String());
        final bTime = DateTime.parse(b['created_at'] ?? DateTime.now().toIso8601String());
        return bTime.compareTo(aTime);
      });
      
      return filtered;
    });
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Check if service is initialized
  bool get isInitialized => _currentUserId != null;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Get current room ID
  String? get currentRoomId => _currentRoomId;
}
