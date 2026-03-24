import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/theme.dart';
import 'package:user_app/widgets/custom_app_bar.dart';

class ChatPage extends StatefulWidget {
  final String peerId;
  final String? productImage;
  final String? price;
  final String? productName;
  final String? productId;

  const ChatPage({
    super.key,
    required this.peerId,
    this.productImage,
    this.price,
    this.productName,
    this.productId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  RealtimeChannel? _channel;
  String? _peerName;
  String? _peerPhoto;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPeerDetails();
    _loadMessages();
    _setupRealtimeSubscription();
  }

  Future<void> _fetchPeerDetails() async {
    try {
      final response = await supabase
          .from('tbl_user')
          .select('user_name, user_photo')
          .eq('id', widget.peerId)
          .single();

      setState(() {
        _peerName = response['user_name'];
        _peerPhoto = response['user_photo'];
      });
    } catch (e) {
      debugPrint("Error fetching peer details: $e");
    }
  }

  Future<void> _loadMessages() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final data = await supabase
          .from('tbl_chat')
          .select()
          .or(
              'and(sender_id.eq.$userId,receiver_id.eq.${widget.peerId}),and(sender_id.eq.${widget.peerId},receiver_id.eq.$userId)')
          .order('created_at', ascending: true);

      setState(() {
        _messages = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });

      _scrollToBottom();
      _markMessagesAsRead();
    } catch (e) {
      debugPrint("Error loading messages: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      await supabase
          .from('tbl_chat')
          .update({'chat_read': true})
          .eq('receiver_id', userId)
          .eq('sender_id', widget.peerId)
          .eq('chat_read', false);
    } catch (e) {
      // Ignore
    }
  }

  void _setupRealtimeSubscription() {
    final userId = supabase.auth.currentUser!.id;

    _channel = supabase.channel('chat_realtime');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'tbl_chat',
          callback: (payload) {
            final msg = payload.newRecord;

            final isThisChat =
                (msg['sender_id'] == userId &&
                        msg['receiver_id'] == widget.peerId) ||
                    (msg['sender_id'] == widget.peerId &&
                        msg['receiver_id'] == userId);

            if (isThisChat) {
              setState(() => _messages.add(msg));
              _scrollToBottom();
              _markMessagesAsRead();
            }
          },
        )
        .subscribe();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    if (text.isEmpty) return;
    _messageController.clear();

    try {
      final userId = supabase.auth.currentUser!.id;

      final message = {
        'sender_id': userId,
        'receiver_id': widget.peerId,
        'chat_message': text,
        'chat_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'product_id': widget.productId,
      };

      await supabase.from('tbl_chat').insert(message);
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: _peerPhoto != null && _peerPhoto!.isNotEmpty
                        ? NetworkImage(_peerPhoto!)
                        : null,
                    backgroundColor: Colors.transparent,
                    onBackgroundImageError: (_, __) {},
                    child: _peerPhoto == null || _peerPhoto!.isEmpty
                        ? Text(
                            (_peerName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _peerName ?? 'Chat',
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding, vertical: 24),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['sender_id'] == userId;
                          
                          // Check if we should show date header
                          bool showDate = true;
                          if (index > 0) {
                            final currentMsgDate = DateTime.parse(msg['created_at']).toLocal();
                            final prevMsgDate = DateTime.parse(_messages[index - 1]['created_at']).toLocal();
                            
                            showDate = currentMsgDate.day != prevMsgDate.day || 
                                       currentMsgDate.month != prevMsgDate.month ||
                                       currentMsgDate.year != prevMsgDate.year;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDate) _buildDateHeader(msg['created_at']),
                              Align(
                                alignment:
                                    isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppTheme.primary : AppTheme.card,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 20),
                                    ),
                                    boxShadow: isMe
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.04),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            )
                                          ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        msg['chat_message'] ?? '',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: isMe ? Colors.white : AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatTime(msg['created_at']),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isMe ? Colors.white70 : AppTheme.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (isMe) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              msg['chat_read'] == true ? Icons.done_all : Icons.check,
                                              size: 14,
                                              color: msg['chat_read'] == true 
                                                  ? Colors.amber 
                                                  : Colors.white70,
                                            )
                                          ]
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          _messageInput(),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      String text;
      
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        text = "Today";
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        text = "Yesterday";
      } else {
        text = DateFormat('MMM dd, yyyy').format(date);
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.divider.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox();
    }
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
            child: Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text("Say Hello!", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            "Start the conversation with ${_peerName ?? 'them'}",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _messageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.padding,
        right: AppTheme.padding,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.divider),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 50,
            width: 50,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              onPressed: _sendMessage,
            ),
          )
        ],
      ),
    );
  }
}