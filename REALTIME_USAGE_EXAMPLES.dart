// ============================================================================
// SUPABASE REALTIME SERVICE - USAGE EXAMPLES
// ============================================================================
// This file contains practical examples of how to use SupabaseRealtimeService
// in your Flutter screens
// ============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:get_it/get_it.dart';

// Import your service
import 'lib/core/services/supabase_realtime_service.dart';
import 'lib/core/models/chat_message_model.dart';

final getIt = GetIt.instance;

// ============================================================================
// EXAMPLE 1: CHAT SCREEN WITH REAL-TIME MESSAGES
// ============================================================================

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const ChatScreen({
    Key? key,
    required this.roomId,
    required this.roomName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final realtimeService = getIt<SupabaseRealtimeService>();
  final messageController = TextEditingController();
  
  List<ChatMessageModel> messages = [];
  Map<String, bool> typingUsers = {};
  
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Initialize realtime service
    realtimeService.initialize(userId);

    // Listen for new messages (Postgres Changes)
    _messageSubscription = realtimeService
        .streamMessages(widget.roomId)
        .listen((newMessages) {
          setState(() {
            messages = newMessages;
          });
          
          // Mark messages as read
          realtimeService.markAllMessagesAsRead(widget.roomId);
        });

    // Listen for typing indicators (Broadcast)
    _typingSubscription = realtimeService
        .onTypingIndicator(widget.roomId)
        .listen((event) {
          setState(() {
            typingUsers[event['user_id']] = event['is_typing'];
          });

          // Auto-clear typing indicator after 3 seconds
          Future.delayed(Duration(seconds: 3), () {
            setState(() {
              typingUsers.remove(event['user_id']);
            });
          });
        });
  }

  void _sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    try {
      // Send message (will automatically update via stream)
      await realtimeService.sendMessage(
        roomId: widget.roomId,
        message: text,
        type: 'text',
      );

      messageController.clear();
      
      // Stop typing indicator
      realtimeService.sendTypingIndicator(widget.roomId, false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _onTextChanged(String text) {
    // Send typing indicator
    realtimeService.sendTypingIndicator(widget.roomId, true);

    // Cancel previous timer
    _typingTimer?.cancel();

    // Stop typing indicator after 2 seconds of no typing
    _typingTimer = Timer(Duration(seconds: 2), () {
      realtimeService.sendTypingIndicator(widget.roomId, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomName),
            if (typingUsers.values.any((isTyping) => isTyping))
              Text(
                'typing...',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index];
                final isMe = message.senderId == 
                    Supabase.instance.client.auth.currentUser?.id;

                return _buildMessageBubble(message, isMe);
              },
            ),
          ),

          // Input area
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    onChanged: _onTextChanged,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.senderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    messageController.dispose();
    super.dispose();
  }
}

// ============================================================================
// EXAMPLE 2: LIVE LOCATION TRACKING (RIDER SIDE)
// ============================================================================

class RiderDeliveryScreen extends StatefulWidget {
  final String orderId;

  const RiderDeliveryScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<RiderDeliveryScreen> createState() => _RiderDeliveryScreenState();
}

class _RiderDeliveryScreenState extends State<RiderDeliveryScreen> {
  final realtimeService = getIt<SupabaseRealtimeService>();
  Timer? _locationTimer;
  bool isSharingLocation = false;

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      realtimeService.initialize(userId);
    }
  }

  void _startSharingLocation() {
    setState(() {
      isSharingLocation = true;
    });

    // Send location every 3 seconds
    _locationTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      // Get current GPS location (using geolocator package)
      // final position = await Geolocator.getCurrentPosition();
      
      // For demo, using fake coordinates
      final latitude = 37.7749 + (DateTime.now().second * 0.0001);
      final longitude = -122.4194 + (DateTime.now().second * 0.0001);

      // Broadcast location (ephemeral - not stored in DB)
      realtimeService.sendLocationUpdate(
        orderId: widget.orderId,
        latitude: latitude,
        longitude: longitude,
        heading: 45.0,
        speed: 15.5,
      );

      print('Sent location: $latitude, $longitude');
    });
  }

  void _stopSharingLocation() async {
    _locationTimer?.cancel();
    await realtimeService.stopLocationUpdates();
    
    setState(() {
      isSharingLocation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery in Progress'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isSharingLocation
                  ? 'Sharing your location...'
                  : 'Location sharing stopped',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSharingLocation 
                  ? _stopSharingLocation 
                  : _startSharingLocation,
              child: Text(
                isSharingLocation ? 'Stop Sharing' : 'Start Sharing Location',
              ),
            ),
            if (isSharingLocation)
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Customer can see your location in real-time',
                  style: TextStyle(color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopSharingLocation();
    super.dispose();
  }
}

// ============================================================================
// EXAMPLE 3: LIVE LOCATION TRACKING (CUSTOMER SIDE)
// ============================================================================

class CustomerTrackingScreen extends StatefulWidget {
  final String orderId;

  const CustomerTrackingScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen> {
  final realtimeService = getIt<SupabaseRealtimeService>();
  StreamSubscription? _locationSubscription;
  
  double? riderLatitude;
  double? riderLongitude;
  String? lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  void _initializeTracking() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    realtimeService.initialize(userId);

    // Listen for rider location updates (Broadcast)
    _locationSubscription = realtimeService
        .onLocationUpdate(widget.orderId)
        .listen((location) {
          setState(() {
            riderLatitude = location['latitude'];
            riderLongitude = location['longitude'];
            lastUpdateTime = DateTime.now().toString().substring(11, 19);
          });

          print('Rider location: $riderLatitude, $riderLongitude');
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Your Order'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            if (riderLatitude != null && riderLongitude != null) ...[
              Text(
                'Rider Location:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Lat: ${riderLatitude!.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Lng: ${riderLongitude!.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Last update: $lastUpdateTime',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🟢 Live tracking active',
                  style: TextStyle(color: Colors.green[800]),
                ),
              ),
            ] else ...[
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Waiting for rider location...'),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}

// ============================================================================
// EXAMPLE 4: VENDOR DASHBOARD - STREAMING NEW ORDERS
// ============================================================================

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({Key? key}) : super(key: key);

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  final realtimeService = getIt<SupabaseRealtimeService>();
  StreamSubscription? _ordersSubscription;
  
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    _initializeOrders();
  }

  void _initializeOrders() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    realtimeService.initialize(userId);

    // Stream orders for this vendor
    _ordersSubscription = realtimeService
        .streamOrders(vendorId: userId, status: 'pending')
        .listen((newOrders) {
          setState(() {
            orders = newOrders;
          });

          // Show notification for new orders
          if (newOrders.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('New order received!')),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Orders (${orders.length})'),
      ),
      body: orders.isEmpty
          ? Center(child: Text('No pending orders'))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return ListTile(
                  leading: Icon(Icons.shopping_bag),
                  title: Text('Order #${order['order_number']}'),
                  subtitle: Text('${order['total_amount']} - ${order['status']}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Accept order logic
                    },
                    child: Text('Accept'),
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}

// ============================================================================
// EXAMPLE 5: CUSTOMER - STREAMING ORDER STATUS
// ============================================================================

class CustomerOrderStatusScreen extends StatefulWidget {
  final String orderId;

  const CustomerOrderStatusScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<CustomerOrderStatusScreen> createState() => _CustomerOrderStatusScreenState();
}

class _CustomerOrderStatusScreenState extends State<CustomerOrderStatusScreen> {
  final realtimeService = getIt<SupabaseRealtimeService>();
  StreamSubscription? _statusSubscription;
  
  String orderStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _initializeStatus();
  }

  void _initializeStatus() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    realtimeService.initialize(userId);

    // Stream order status changes
    _statusSubscription = realtimeService
        .streamOrderStatus(widget.orderId)
        .listen((order) {
          if (order.isNotEmpty) {
            final newStatus = order['status'] as String;
            
            if (newStatus != orderStatus) {
              setState(() {
                orderStatus = newStatus;
              });

              // Show notification
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Order status: $newStatus')),
              );
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Status'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusIndicator(orderStatus),
            SizedBox(height: 20),
            Text(
              _getStatusMessage(orderStatus),
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    final statusSteps = ['pending', 'accepted', 'preparing', 'ready', 'picked_up', 'delivered'];
    final currentIndex = statusSteps.indexOf(status);

    return Column(
      children: statusSteps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = index <= currentIndex;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: isActive ? Colors.green : Colors.grey,
              size: 32,
            ),
            SizedBox(width: 8),
            Text(
              step.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                color: isActive ? Colors.green : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Waiting for vendor to accept...';
      case 'accepted':
        return 'Vendor is preparing your order';
      case 'preparing':
        return 'Your order is being prepared';
      case 'ready':
        return 'Order is ready for pickup!';
      case 'picked_up':
        return 'Rider is on the way!';
      case 'delivered':
        return 'Order delivered! Enjoy!';
      default:
        return 'Unknown status';
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}

// ============================================================================
// NOTES:
// ============================================================================

/*
IMPORTANT PATTERNS:

1. ALWAYS initialize the service with user ID:
   realtimeService.initialize(userId);

2. ALWAYS cancel subscriptions in dispose():
   _subscription?.cancel();

3. For CHAT: Use streamMessages() - auto-updates from database
4. For TYPING: Use sendTypingIndicator() + onTypingIndicator() - broadcast
5. For LOCATION: Use sendLocationUpdate() + onLocationUpdate() - broadcast
6. For ORDERS: Use streamOrders() or streamOrderStatus() - auto-updates

7. Database operations (INSERT/UPDATE) automatically trigger realtime updates
8. No need to manually emit events - Supabase handles it all!

MIGRATION CHECKLIST:
- [x] Remove Socket.io code
- [x] Use SupabaseRealtimeService
- [x] Initialize service with user ID
- [x] Use .stream() for database tables
- [x] Use broadcast for ephemeral events
- [x] Cancel subscriptions on dispose
*/
