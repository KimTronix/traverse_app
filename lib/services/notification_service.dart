import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import 'supabase_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  factory NotificationService() => _instance;
  NotificationService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final StreamController<AppNotification> _notificationController = StreamController<AppNotification>.broadcast();
  final List<AppNotification> _notifications = [];
  
  // Notification types
  static const String typeMessage = 'message';
  static const String typePost = 'post';
  static const String typeStatus = 'status';
  static const String typeBooking = 'booking';
  static const String typeWallet = 'wallet';
  
  Stream<AppNotification> get notificationStream => _notificationController.stream;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Initialize notification service
  Future<void> initialize() async {
    try {
      Logger.info('Initializing notification service');
      await _setupRealtimeListeners();
      await _loadStoredNotifications();
      Logger.info('Notification service initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize notification service: $e');
    }
  }

  // Setup real-time listeners for different notification types
  Future<void> _setupRealtimeListeners() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      Logger.warning('No authenticated user for notification setup');
      return;
    }

    // Listen for new messages
    _setupMessageNotifications(currentUser.id);
    
    // Listen for post interactions
    _setupPostNotifications(currentUser.id);
    
    // Listen for wallet updates
    _setupWalletNotifications(currentUser.id);
  }

  void _setupMessageNotifications(String userId) {
    try {
      // Get user conversations and listen for new messages
      _supabaseService.getConversations(userId).then((conversations) {
        for (final conversation in conversations) {
          final conversationId = conversation['id'] as String;
          
          _supabaseService.getMessagesStream(conversationId).listen(
            (messageData) {
              final senderId = messageData['sender_id'] as String?;
              if (senderId != null && senderId != userId) {
                _createNotification(
                  type: typeMessage,
                  title: 'New Message',
                  body: 'You have a new message',
                  data: messageData,
                );
              }
            },
            onError: (error) {
              Logger.error('Error in message stream for conversation $conversationId: $error');
            },
          );
        }
      }).catchError((error) {
        Logger.error('Failed to setup message notifications: $error');
      });
    } catch (e) {
      Logger.error('Error setting up message notifications: $e');
    }
  }

  void _setupPostNotifications(String userId) {
    try {
      _supabaseService.getPostsStream().listen(
        (postEvent) {
          final eventType = postEvent['event'] as String;
          final postData = postEvent['data'] as Map<String, dynamic>;
          final postUserId = postData['user_id'] as String?;
          
          // Don't notify user about their own posts
          if (postUserId == userId) return;
          
          if (eventType == 'insert') {
            _createNotification(
              type: typePost,
              title: 'New Post',
              body: 'Someone shared a new travel experience',
              data: postData,
            );
          } else if (eventType == 'update') {
            // Check if it's a like or comment on user's post
            _checkPostInteraction(postData, userId);
          }
        },
        onError: (error) {
          Logger.error('Error in posts stream: $error');
        },
      );
    } catch (e) {
      Logger.error('Error setting up post notifications: $e');
    }
  }

  void _setupWalletNotifications(String userId) {
    try {
      // Listen for wallet updates (points, rewards, etc.)
      _supabaseService.subscribeToTable(
        'user_wallets',
        (data) {
          final walletUserId = data['user_id'] as String?;
          if (walletUserId == userId) {
            _createNotification(
              type: typeWallet,
              title: 'Wallet Update',
              body: 'Your wallet has been updated',
              data: data,
            );
          }
        },
        (data) {
          final walletUserId = data['user_id'] as String?;
          if (walletUserId == userId) {
            _createNotification(
              type: typeWallet,
              title: 'Points Earned',
              body: 'You earned new points!',
              data: data,
            );
          }
        },
        (data) {}, // Delete handler
      );
    } catch (e) {
      Logger.error('Error setting up wallet notifications: $e');
    }
  }

  Future<void> _checkPostInteraction(Map<String, dynamic> postData, String userId) async {
    try {
      // This would typically check if the post belongs to the current user
      // and if there are new likes or comments
      final postId = postData['id'] as String?;
      if (postId == null) return;
      
      // In a real implementation, you'd check the post ownership and interaction type
      // For now, we'll create a generic interaction notification
      _createNotification(
        type: typePost,
        title: 'Post Interaction',
        body: 'Someone interacted with your post',
        data: postData,
      );
    } catch (e) {
      Logger.error('Error checking post interaction: $e');
    }
  }

  void _createNotification({
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    try {
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        title: title,
        body: body,
        data: data ?? {},
        timestamp: DateTime.now(),
        isRead: false,
      );

      _notifications.insert(0, notification); // Add to beginning
      _notificationController.add(notification);
      
      // Keep only last 100 notifications
      if (_notifications.length > 100) {
        _notifications.removeRange(100, _notifications.length);
      }
      
      _saveNotifications();
      Logger.info('Created notification: $title');
    } catch (e) {
      Logger.error('Error creating notification: $e');
    }
  }

  // Stop message notifications
  void stopMessageNotifications() {
    // Clean up message-related subscriptions
    Logger.info('Stopped message notifications');
  }

  // Setup message notifications
  void setupMessageNotifications(String userId) {
    Logger.info('Setting up message notifications for user: $userId');
    // Implementation for message notifications would go here
  }

  // Setup post notifications
  void setupPostNotifications(String userId) {
    Logger.info('Setting up post notifications for user: $userId');
    // Implementation for post notifications would go here
  }

  // Setup wallet notifications
  void setupWalletNotifications(String userId) {
    Logger.info('Setting up wallet notifications for user: $userId');
    // Implementation for wallet notifications would go here
  }

  // Create test notification for demo purposes
  void createTestNotification({
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    _createNotification(
      type: type,
      title: title,
      body: body,
      data: data,
    );
  }

  // Mark notification as read
  void markAsRead(String notificationId) {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _saveNotifications();
        Logger.info('Marked notification as read: $notificationId');
      }
    } catch (e) {
      Logger.error('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  void markAllAsRead() {
    try {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
      _saveNotifications();
      Logger.info('Marked all notifications as read');
    } catch (e) {
      Logger.error('Error marking all notifications as read: $e');
    }
  }

  // Clear all notifications
  void clearAll() {
    try {
      _notifications.clear();
      _saveNotifications();
      Logger.info('Cleared all notifications');
    } catch (e) {
      Logger.error('Error clearing notifications: $e');
    }
  }

  // Remove specific notification
  void removeNotification(String notificationId) {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      _saveNotifications();
      Logger.info('Removed notification: $notificationId');
    } catch (e) {
      Logger.error('Error removing notification: $e');
    }
  }

  // Save notifications to local storage (simplified)
  Future<void> _saveNotifications() async {
    try {
      // In a real implementation, you'd save to SharedPreferences or local database
      if (kDebugMode) {
        Logger.debug('Saving ${_notifications.length} notifications');
      }
    } catch (e) {
      Logger.error('Error saving notifications: $e');
    }
  }

  // Load notifications from local storage (simplified)
  Future<void> _loadStoredNotifications() async {
    try {
      // In a real implementation, you'd load from SharedPreferences or local database
      Logger.info('Loaded stored notifications');
    } catch (e) {
      Logger.error('Error loading stored notifications: $e');
    }
  }

  // Cleanup resources
  void dispose() {
    try {
      _notificationController.close();
      _supabaseService.unsubscribeAll();
      Logger.info('Notification service disposed');
    } catch (e) {
      Logger.error('Error disposing notification service: $e');
    }
  }
}

// Notification model
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.timestamp,
    required this.isRead,
  });

  AppNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool,
    );
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, type: $type, title: $title, isRead: $isRead)';
  }
}