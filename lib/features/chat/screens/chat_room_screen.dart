import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/models/chat_message_model.dart';

class ChatRoomScreen extends StatefulWidget {
  final String? roomId;
  final String? otherUserId;
  final String? otherUserName;

  const ChatRoomScreen({
    super.key,
    this.roomId,
    this.otherUserId,
    this.otherUserName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _roomId;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _roomId = widget.roomId;
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    // If no room ID, create or find existing room
    if (_roomId == null && widget.otherUserId != null) {
      _roomId = await _findOrCreateRoom(userId, widget.otherUserId!);
    }

    if (_roomId != null) {
      await _loadMessages();
      _subscribeToMessages();
    }
  }

  Future<String?> _findOrCreateRoom(String userId, String otherUserId) async {
    try {
      // Check if room exists
      final existingRooms = await Supabase.instance.client
          .from('chat_rooms')
          .select()
          .contains('participant_ids', [userId])
          .contains('participant_ids', [otherUserId]);

      if (existingRooms.isNotEmpty) {
        return existingRooms.first['id'] as String;
      }

      // Create new room
      final newRoom = await Supabase.instance.client
          .from('chat_rooms')
          .insert({
            'participant_ids': [userId, otherUserId],
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return newRoom['id'] as String;
    } catch (e) {
      debugPrint('Error creating room: $e');
      return null;
    }
  }

  Future<void> _loadMessages() async {
    if (_roomId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('chat_messages')
          .select('*, sender:users!chat_messages_sender_id_fkey(id, full_name, profile_image_url)')
          .eq('room_id', _roomId!)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages = (response as List)
              .map((m) => ChatMessageModel.fromJson(m))
              .toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToMessages() {
    if (_roomId == null) return;

    _channel = Supabase.instance.client
        .channel('messages_$_roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: _roomId,
          ),
          callback: (payload) {
            _onNewMessage(payload.newRecord);
          },
        )
        .subscribe();
  }

  void _onNewMessage(Map<String, dynamic> record) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    
    // Load full message with sender info
    try {
      final response = await Supabase.instance.client
          .from('chat_messages')
          .select('*, sender:users!chat_messages_sender_id_fkey(id, full_name, profile_image_url)')
          .eq('id', record['id'])
          .single();

      final message = ChatMessageModel.fromJson(response);
      
      // Avoid duplicates
      if (!_messages.any((m) => m.id == message.id)) {
        if (mounted) {
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error loading new message: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _roomId == null) return;

    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await Supabase.instance.client.from('chat_messages').insert({
        'room_id': _roomId,
        'sender_id': userId,
        'content': text,
        'message_type': 'text',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update room's last message and timestamp
      await Supabase.instance.client
          .from('chat_rooms')
          .update({
            'last_message': text,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _roomId!);

      setState(() => _isSending = false);
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
              child: Text(
                (widget.otherUserName ?? '?').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName ?? 'Chat',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // TODO: Implement call
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId == userId;
                          final showAvatar = index == 0 ||
                              _messages[index - 1].senderId != message.senderId;

                          return _buildMessageBubble(message, isMe, showAvatar);
                        },
                      ),
          ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Start the conversation',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to ${widget.otherUserName ?? 'get started'}',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMe, bool showAvatar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                (message.senderName ?? '?').substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
            )
          else if (!isMe)
            const SizedBox(width: 32),
          
          const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryGreen : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          if (isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
              child: const Icon(Icons.person, size: 16, color: AppTheme.primaryGreen),
            )
          else if (isMe)
            const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 8, 16, MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            color: Colors.grey[600],
            onPressed: () {
              // TODO: Attach file
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.primaryGreen,
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final isToday = time.day == now.day &&
        time.month == now.month &&
        time.year == now.year;

    if (isToday) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
