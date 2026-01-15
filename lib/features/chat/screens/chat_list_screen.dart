import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_router.dart';
import '../../auth/providers/auth_provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
    _subscribeToChats();
  }

  Future<void> _loadChatRooms() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('chat_rooms')
          .select()
          .contains('participant_ids', [userId])
          .order('updated_at', ascending: false);

      // Load participant details for each room
      final rooms = <Map<String, dynamic>>[];
      for (final room in response) {
        final participantIds = List<String>.from(room['participant_ids'] ?? []);
        final otherUserId = participantIds.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          final userResponse = await Supabase.instance.client
              .from('users')
              .select('id, full_name, profile_image_url, role')
              .eq('id', otherUserId)
              .maybeSingle();

          rooms.add({
            ...room,
            'other_user': userResponse,
          });
        }
      }

      if (mounted) {
        setState(() {
          _chatRooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToChats() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    Supabase.instance.client
        .channel('chat_rooms_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_rooms',
          callback: (payload) {
            _loadChatRooms();
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadChatRooms,
                  child: ListView.builder(
                    itemCount: _chatRooms.length,
                    itemBuilder: (context, index) {
                      return _buildChatRoomTile(_chatRooms[index]);
                    },
                  ),
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
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with a vendor or rider',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomTile(Map<String, dynamic> room) {
    final otherUser = room['other_user'] as Map<String, dynamic>?;
    final lastMessage = room['last_message'] as String?;
    final updatedAt = room['updated_at'] != null
        ? DateTime.parse(room['updated_at'])
        : DateTime.now();
    final unreadCount = room['unread_count'] as int? ?? 0;

    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
        backgroundImage: otherUser?['profile_image_url'] != null
            ? NetworkImage(otherUser!['profile_image_url'])
            : null,
        child: otherUser?['profile_image_url'] == null
            ? Text(
                (otherUser?['full_name'] as String?)?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherUser?['full_name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            _formatTime(updatedAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMessage ?? 'No messages yet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.chatRoom,
          arguments: {
            'roomId': room['id'],
            'otherUserId': otherUser?['id'],
            'otherUserName': otherUser?['full_name'],
          },
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${time.day}/${time.month}';
    }

    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Now';
  }
}
