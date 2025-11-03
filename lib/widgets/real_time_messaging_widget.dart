import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../utils/logger.dart';

class RealTimeMessagingWidget extends StatefulWidget {
  final String userId;
  final String conversationId;

  const RealTimeMessagingWidget({
    super.key,
    required this.userId,
    required this.conversationId,
  });

  @override
  State<RealTimeMessagingWidget> createState() => _RealTimeMessagingWidgetState();
}

class _RealTimeMessagingWidgetState extends State<RealTimeMessagingWidget> {
  final NotificationService _notificationService = NotificationService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupRealTimeFeatures();
    _loadMessages();
  }

  void _setupRealTimeFeatures() {
    // Setup message notifications
    _notificationService.setupMessageNotifications(widget.userId);
    
    // Listen to real-time messages
    _supabaseService.getMessagesStream(widget.conversationId).listen(
      (messageData) {
        if (mounted) {
          setState(() {
            _messages.insert(0, messageData);
          });
        }
      },
      onError: (error) {
        Logger.error('Error in message stream: $error');
      },
    );

    // Listen to notifications
    _notificationService.notificationStream.listen(
      (notification) {
        if (mounted && notification.type == 'message') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${notification.title}: ${notification.body}'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await _supabaseService.getMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages.reversed);
        });
      }
    } catch (e) {
      Logger.error('Failed to load messages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    try {
      await _supabaseService.sendMessage(
        conversationId: widget.conversationId,
        senderId: widget.userId,
        message: messageText,
      );
      
      _messageController.clear();
    } catch (e) {
      Logger.error('Failed to send message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _notificationService.stopMessageNotifications();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Messaging'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          // Notification status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            color: Colors.green.shade100,
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Real-time notifications enabled',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ],
            ),
          ),
          
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet. Start a conversation!',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMyMessage = message['sender_id'] == widget.userId;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: Row(
                              mainAxisAlignment: isMyMessage
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: isMyMessage
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message['message'] ?? '',
                                        style: TextStyle(
                                          color: isMyMessage
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTimestamp(message['created_at']),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isMyMessage
                                              ? Colors.white70
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final dateTime = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return '';
    }
  }
}