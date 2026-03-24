import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  final String peerId;

  const ChatPage({
    super.key,
    required this.peerId,
    required productImage,
    required String price,
    required productName,
    required productId,
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

  @override
  void initState() {
    super.initState();
    _fetchPeerName();
    _loadMessages();
    _setupRealtimeSubscription();
    _markMessagesAsRead();
  }

  /// Fetch receiver name
  Future<void> _fetchPeerName() async {
    try {
      final response = await supabase
          .from('tbl_user')
          .select('user_name')
          .eq('user_id', widget.peerId)
          .single();

      setState(() {
        _peerName = response['user_name'] ?? 'User';
      });
    } catch (_) {
      _peerName = 'User';
    }
  }

  /// Load previous chat history once
  Future<void> _loadMessages() async {
    final userId = supabase.auth.currentUser!.id;

    final data = await supabase
        .from('tbl_chat')
        .select()
        .or(
            'and(sender_id.eq.$userId,receiver_id.eq.${widget.peerId}),and(sender_id.eq.${widget.peerId},receiver_id.eq.$userId)')
        .order('created_at', ascending: true);

    setState(() => _messages = List<Map<String, dynamic>>.from(data));

    _scrollToBottom();
  }

  /// Mark messages as read
  Future<void> _markMessagesAsRead() async {
    final userId = supabase.auth.currentUser!.id;

    await supabase
        .from('tbl_chat')
        .update({'chat_read': true})
        .eq('receiver_id', userId)
        .eq('sender_id', widget.peerId)
        .eq('chat_read', false);
  }

  /// Realtime listener ONLY for new messages
  void _setupRealtimeSubscription() {
    final userId = supabase.auth.currentUser!.id;

    _channel = supabase.channel('chat_channel');

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

  /// Smooth scroll
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

  /// Send message
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userId = supabase.auth.currentUser!.id;

    final message = {
      'sender_id': userId,
      'receiver_id': widget.peerId,
      'chat_message': text,
      'chat_read': false,
      'created_at': DateTime.now().toIso8601String(),
    };

    /// show instantly
    setState(() => _messages.add(message));
    _scrollToBottom();

    _messageController.clear();

    /// insert into DB
    await supabase.from('tbl_chat').insert(message);
  }

  String _formatTime(String createdAt) {
    final dt = DateTime.parse(createdAt).toLocal();
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F7F2),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(_peerName ?? "Chat"),
      ),
      body: Column(
        children: [
          /// CHAT LIST
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['sender_id'] == userId;

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    padding: const EdgeInsets.all(10),
                    constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.green : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['chat_message'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            color: isMe ? Colors.white : Colors.black,
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
                                color: isMe
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            if (isMe) const SizedBox(width: 4),
                            if (isMe)
                              Icon(
                                msg['chat_read'] == true
                                    ? Icons.done_all
                                    : Icons.done,
                                size: 14,
                                color: msg['chat_read'] == true
                                    ? Colors.blue
                                    : Colors.white70,
                              )
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// MESSAGE INPUT
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message",
                      filled: true,
                      fillColor: const Color(0xFFF2F2F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: IconButton(
                    icon:
                        const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
