import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_app/main.dart';

class ChatPage extends StatefulWidget {
  final String peerId;
  const ChatPage({super.key, required this.peerId, required productImage, required String price, required productName, required productId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  StreamSubscription? _subscription;

  String? _peerName;

  @override
  void initState() {
    super.initState();
    _fetchPeerName();
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

  /// Realtime listener
  void _setupRealtimeSubscription() {
    final userId = supabase.auth.currentUser!.id;

_subscription = supabase
    .from('tbl_chat')
    .stream(primaryKey: ['id'])
    .order('created_at', ascending: true)
    .listen((data) {
  final filtered = data.where((msg) =>
      (msg['sender_id'] == userId &&
          msg['receiver_id'] == widget.peerId) ||
      (msg['sender_id'] == widget.peerId &&
          msg['receiver_id'] == userId)).toList();

      setState(() => _messages = filtered);

      /// auto scroll
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      });
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

    await supabase.from('tbl_chat').insert(message);
    _messageController.clear();
  }

  String _formatTime(String createdAt) {
    final dt = DateTime.parse(createdAt).toLocal();
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  void dispose() {
    _subscription?.cancel();
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
                    constraints:
                        BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.green : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['chat_message'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(msg['created_at']),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.black54,
                          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    icon: const Icon(Icons.send, color: Colors.white),
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
