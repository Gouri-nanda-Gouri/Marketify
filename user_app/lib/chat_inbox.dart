import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_app/main.dart';
import 'package:user_app/theme.dart';
import 'package:user_app/widgets/custom_app_bar.dart';
import 'package:user_app/widgets/custom_card.dart';
import 'chat_page.dart';

class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({super.key});

  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage> {
  List<Map<String, dynamic>> _chatList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final data = await supabase.rpc(
        'get_chat_list',
        params: {'p_user': userId},
      );

      setState(() {
        _chatList = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading chats: $e");
      setState(() => _loading = false);
    }
  }

  String _formatTime(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      if (dt.day == DateTime.now().day && dt.month == DateTime.now().month && dt.year == DateTime.now().year) {
        return DateFormat('hh:mm a').format(dt);
      }
      return DateFormat('MMM dd').format(dt);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(title: 'Messages', showBackButton: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _chatList.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding, vertical: 16),
                  itemCount: _chatList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final chat = _chatList[index];

                    return CustomCard(
                      padding: const EdgeInsets.all(4),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: Text(
                            (chat['peer_name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          chat['peer_name'] ?? 'User',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          chat['last_message'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        trailing: Text(
                          _formatTime(chat['created_at']),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                peerId: chat['peer_id'],
                              ),
                            ),
                          ).then((_) => _loadChats());
                        },
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.forum_outlined, size: 64, color: AppTheme.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text("No messages yet", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            "When you contact sellers, your messages will appear here",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}