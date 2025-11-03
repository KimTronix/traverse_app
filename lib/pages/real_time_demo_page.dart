import 'package:flutter/material.dart';
import '../widgets/real_time_messaging_widget.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

class RealTimeDemoPage extends StatefulWidget {
  const RealTimeDemoPage({super.key});

  @override
  State<RealTimeDemoPage> createState() => _RealTimeDemoPageState();
}

class _RealTimeDemoPageState extends State<RealTimeDemoPage> {
  final NotificationService _notificationService = NotificationService.instance;
  final List<AppNotification> _notifications = [];
  bool _isConnected = false;
  String _connectionStatus = 'Checking connection...';

  // Demo user and conversation IDs
  final String _demoUserId = 'demo-user-123';
  final String _demoConversationId = 'demo-conversation-456';

  @override
  void initState() {
    super.initState();
    _setupDemo();
  }

  Future<void> _setupDemo() async {
    // Check connection status
    await _checkConnection();
    
    // Setup notifications
    _setupNotifications();
    
    // Setup real-time features
    _setupRealTimeFeatures();
  }

  Future<void> _checkConnection() async {
    try {
      final isConnected = await SupabaseService.testConnection();
      setState(() {
        _isConnected = isConnected;
        _connectionStatus = isConnected 
            ? 'Connected to Supabase' 
            : 'Connection failed';
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Connection error: $e';
      });
    }
  }

  void _setupNotifications() {
    // Listen to all notifications
    _notificationService.notificationStream.listen(
      (notification) {
        if (mounted) {
          setState(() {
            _notifications.insert(0, notification);
          });
        }
      },
    );
  }

  void _setupRealTimeFeatures() {
    // Setup various real-time listeners
    _notificationService.setupMessageNotifications(_demoUserId);
    _notificationService.setupPostNotifications(_demoUserId);
    _notificationService.setupWalletNotifications(_demoUserId);
  }

  Future<void> _simulateNotification(String type) async {
    switch (type) {
      case 'message':
        _notificationService.createTestNotification(
          type: 'message',
          title: 'New Message',
          body: 'You have received a new message from John',
          data: {'sender': 'John', 'conversation_id': _demoConversationId},
        );
        break;
      case 'post':
        _notificationService.createTestNotification(
          type: 'post',
          title: 'New Post',
          body: 'Someone liked your travel post!',
          data: {'post_id': 'post-123', 'action': 'like'},
        );
        break;
      case 'wallet':
        _notificationService.createTestNotification(
          type: 'wallet',
          title: 'Payment Received',
          body: 'You received \$25.00 for your travel guide',
          data: {'amount': 25.00, 'currency': 'USD'},
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Features Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkConnection,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.check_circle : Icons.error,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Connection Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _connectionStatus,
                      style: TextStyle(
                        color: _isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Real-Time Features Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Real-Time Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Messaging Demo Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isConnected ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RealTimeMessagingWidget(
                                userId: _demoUserId,
                                conversationId: _demoConversationId,
                              ),
                            ),
                          );
                        } : null,
                        icon: const Icon(Icons.message),
                        label: const Text('Open Real-Time Messaging'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Notification Simulation Buttons
                    const Text(
                      'Simulate Notifications:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _simulateNotification('message'),
                            child: const Text('Message'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _simulateNotification('post'),
                            child: const Text('Post'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _simulateNotification('wallet'),
                            child: const Text('Wallet'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notifications List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_notifications.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _notifications.clear();
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (_notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No notifications yet.\nTry simulating some above!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _notifications.length > 5 ? 5 : _notifications.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getNotificationColor(notification.type),
                              child: Icon(
                                _getNotificationIcon(notification.type),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              notification.title,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification.body),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(notification.timestamp),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'message':
        return Colors.blue;
      case 'post':
        return Colors.green;
      case 'wallet':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'post':
        return Icons.favorite;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _notificationService.stopMessageNotifications();
    super.dispose();
  }
}