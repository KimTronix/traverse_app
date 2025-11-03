import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';
import '../config/supabase_config.dart';
import '../utils/constants.dart';
import '../models/wallet.dart';
import '../utils/logger.dart';
import 'cache_service.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();
  
  final CacheService _cacheService = CacheService.instance;
  
  SupabaseClient get client => Supabase.instance.client;
  
  // Connection status tracking
  bool _isConnected = true;
  Timer? _connectionTimer;
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }
  
  // Test database connection with retry logic
  static Future<bool> testConnection() async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        Logger.debug('Testing Supabase connection (attempt $attempt/$_maxRetries)...');
        
        await Supabase.instance.client
            .from('users')
            .select('id')
            .limit(1)
            .timeout(const Duration(seconds: 10));
        
        Logger.info('Database connection successful');
        return true;
      } catch (e) {
        Logger.warning('Connection attempt $attempt failed: $e');
        
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
        } else {
          Logger.error('Database connection failed after $_maxRetries attempts: $e');
          return false;
        }
      }
    }
    return false;
  }
  
  // Monitor connection status
  void startConnectionMonitoring() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      final wasConnected = _isConnected;
      _isConnected = await testConnection();
      
      if (wasConnected != _isConnected) {
        Logger.info('Connection status changed: ${_isConnected ? "Connected" : "Disconnected"}');
      }
    });
  }
  
  // Stop connection monitoring
  void stopConnectionMonitoring() {
    _connectionTimer?.cancel();
    _connectionTimer = null;
  }
  
  // Get connection status
  bool get isConnected => _isConnected;
  
  // Enhanced retry wrapper for database operations
  Future<T> _executeWithRetry<T>(Future<T> Function() operation, {
    T? fallback,
    String? operationName,
  }) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        return await operation().timeout(const Duration(seconds: 30));
      } catch (e) {
        Logger.warning('${operationName ?? "Operation"} attempt $attempt failed: $e');
        
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
        } else {
          Logger.error('${operationName ?? "Operation"} failed after $_maxRetries attempts: $e');
          if (fallback != null) {
            Logger.info('Using fallback data for ${operationName ?? "operation"}');
            return fallback;
          }
          rethrow;
        }
      }
    }
    throw Exception('Unexpected error in retry logic');
  }

  // User operations with enhanced error handling and caching
  Future<List<Map<String, dynamic>>> getUsers({bool useCache = true}) async {
    final cacheKey = CacheService.usersCacheKey();
    
    if (useCache) {
      final cachedUsers = await _cacheService.getCache<List<dynamic>>(cacheKey, duration: CacheService.shortCacheDuration);
      if (cachedUsers != null) {
        Logger.debug('Retrieved users from cache');
        return List<Map<String, dynamic>>.from(cachedUsers);
      }
    }
    
    final users = await _executeWithRetry(
      () async {
        final response = await client
            .from(SupabaseConfig.usersTable)
            .select()
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      },
      fallback: <Map<String, dynamic>>[],
      operationName: 'Get Users',
    );
    
    if (useCache && users.isNotEmpty) {
      await _cacheService.setCache(cacheKey, users, duration: CacheService.shortCacheDuration);
    }
    
    return users;
  }
  
  Future<Map<String, dynamic>?> getUserById(String userId, {bool useCache = true}) async {
    if (userId.isEmpty) {
      Logger.warning('getUserById called with empty userId');
      return null;
    }

    final cacheKey = CacheService.userCacheKey(userId);

    if (useCache) {
      final cachedUser = await _cacheService.getCache<Map<String, dynamic>>(cacheKey, duration: CacheService.defaultCacheDuration);
      if (cachedUser != null) {
        Logger.debug('Retrieved user $userId from cache');
        return cachedUser;
      }
    }

    final user = await _executeWithRetry(
      () async {
        final response = await client
            .from(SupabaseConfig.usersTable)
            .select()
            .eq('id', userId)
            .single();
        return response;
      },
      fallback: null,
      operationName: 'Get User by ID',
    );

    if (useCache && user != null) {
      await _cacheService.setCache(cacheKey, user, duration: CacheService.defaultCacheDuration);
    }

    return user;
  }

  // Search users by username or full name
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) {
      Logger.warning('searchUsers called with empty query');
      return [];
    }

    final users = await _executeWithRetry(
      () async {
        final response = await client
            .from(SupabaseConfig.usersTable)
            .select('id, username, full_name, email, avatar_url')
            .or('username.ilike.%$query%,full_name.ilike.%$query%,email.ilike.%$query%')
            .limit(20);
        return List<Map<String, dynamic>>.from(response);
      },
      fallback: <Map<String, dynamic>>[],
      operationName: 'Search Users',
    );

    return users;
  }

  // Get user by username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    if (username.isEmpty) {
      Logger.warning('getUserByUsername called with empty username');
      return null;
    }

    final user = await _executeWithRetry(
      () async {
        final response = await client
            .from(SupabaseConfig.usersTable)
            .select()
            .eq('username', username)
            .maybeSingle();
        return response;
      },
      fallback: null,
      operationName: 'Get User by Username',
    );

    return user;
  }
  
  Future<bool> insertUser(Map<String, dynamic> user) async {
    if (user.isEmpty) {
      Logger.warning('insertUser called with empty user data');
      return false;
    }
    
    try {
      final result = await _executeWithRetry(
        () async {
          await client.from(SupabaseConfig.usersTable).insert(user);
          return true;
        },
        fallback: false,
        operationName: 'Insert User',
      );
      
      // Invalidate users cache
      if (result) {
        await _cacheService.invalidateCache(CacheService.usersCacheKey());
      }
      
      return result;
    } catch (e) {
      Logger.error('Failed to insert user after retries: $e');
      return false;
    }
  }

  // Destination operations with enhanced error handling and caching
  Future<List<Map<String, dynamic>>> getDestinations({bool useCache = true}) async {
    final cacheKey = CacheService.destinationsCacheKey();
    
    if (useCache) {
      final cachedDestinations = await _cacheService.getCache<List<dynamic>>(cacheKey, duration: CacheService.defaultCacheDuration);
      if (cachedDestinations != null) {
        Logger.debug('Retrieved destinations from cache');
        return List<Map<String, dynamic>>.from(cachedDestinations);
      }
    }
    
    final destinations = await _executeWithRetry(
      () async {
        final response = await client
            .from(SupabaseConfig.destinationsTable)
            .select()
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      },
      fallback: AppConstants.sampleDestinations,
      operationName: 'Get Destinations',
    );
    
    if (useCache && destinations.isNotEmpty) {
      await _cacheService.setCache(cacheKey, destinations, duration: CacheService.defaultCacheDuration);
    }
    
    return destinations;
  }

  Future<Map<String, dynamic>?> getDestinationById(String destinationId, {bool useCache = true}) async {
    if (destinationId.isEmpty) {
      Logger.warning('getDestinationById called with empty destinationId');
      return null;
    }
    
    final cacheKey = CacheService.destinationCacheKey(destinationId);
    
    if (useCache) {
      final cachedDestination = await _cacheService.getCache<Map<String, dynamic>>(cacheKey, duration: CacheService.defaultCacheDuration);
      if (cachedDestination != null) {
        Logger.debug('Retrieved destination $destinationId from cache');
        return cachedDestination;
      }
    }
    
    final destination = await _executeWithRetry(
      () async {
        final response = await client
            .from(SupabaseConfig.destinationsTable)
            .select()
            .eq('id', destinationId)
            .single();
        return response;
      },
      fallback: null,
      operationName: 'Get Destination by ID',
    );
    
    if (useCache && destination != null) {
      await _cacheService.setCache(cacheKey, destination, duration: CacheService.defaultCacheDuration);
    }
    
    return destination;
  }
  
  Future<bool> insertDestination(Map<String, dynamic> destination) async {
    if (destination.isEmpty) {
      Logger.warning('insertDestination called with empty destination data');
      return false;
    }
    
    // Validate destination data
    if (!_validateDestinationData(destination)) {
      Logger.error('insertDestination: Invalid destination data');
      return false;
    }
    
    // Sanitize destination data
    final sanitizedDestination = _sanitizeUserData(destination);
    
    try {
      final result = await _executeWithRetry(
        () async {
          await client.from(SupabaseConfig.destinationsTable).insert(sanitizedDestination);
          return true;
        },
        fallback: false,
        operationName: 'Insert Destination',
      );
      
      // Invalidate destinations cache
      if (result) {
        await _cacheService.invalidateCache(CacheService.destinationsCacheKey());
      }
      
      return result;
    } catch (e) {
      Logger.error('Failed to insert destination after retries: $e');
      return false;
    }
  }
  
  // Post operations with enhanced error handling
  Future<List<Map<String, dynamic>>> getPosts() async {
    return await _executeWithRetry(
      () async {
        final response = await client
            .from(SupabaseConfig.postsTable)
            .select()
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      },
      fallback: AppConstants.samplePosts,
      operationName: 'Get Posts',
    );
  }
  
  Future<bool> insertPost(Map<String, dynamic> post) async {
    if (post.isEmpty) {
      Logger.warning('insertPost called with empty post data');
      return false;
    }
    
    // Validate post data
    if (!_validatePostData(post)) {
      Logger.error('insertPost: Invalid post data');
      return false;
    }
    
    // Sanitize post data
    final sanitizedPost = _sanitizeUserData(post);
    
    try {
      final result = await _executeWithRetry(
        () async {
          await client.from(SupabaseConfig.postsTable).insert(sanitizedPost);
          return true;
        },
        fallback: false,
        operationName: 'Insert Post',
      );
      
      // Invalidate posts cache
      if (result) {
        await _cacheService.invalidateCache('posts_cache');
      }
      
      return result;
    } catch (e) {
      Logger.error('Failed to insert post after retries: $e');
      return false;
    }
  }
  
  Future<bool> updatePost(String postId, Map<String, dynamic> updates) async {
    if (postId.isEmpty) {
      Logger.warning('updatePost called with empty postId');
      return false;
    }
    
    if (updates.isEmpty) {
      Logger.warning('updatePost called with empty updates');
      return true; // No updates needed
    }
    
    try {
      final result = await _executeWithRetry(
        () async {
          await client
              .from(SupabaseConfig.postsTable)
              .update(updates)
              .eq('id', postId);
          return true;
        },
        fallback: false,
        operationName: 'Update Post',
      );
      
      // Invalidate posts cache
      if (result) {
        await _cacheService.invalidateCache('posts_cache');
      }
      
      return result;
    } catch (e) {
      Logger.error('Failed to update post after retries: $e');
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    if (postId.isEmpty) {
      Logger.warning('deletePost called with empty postId');
      return false;
    }
    
    try {
      final result = await _executeWithRetry(
        () async {
          await client.from(SupabaseConfig.postsTable).delete().eq('id', postId);
          return true;
        },
        fallback: false,
        operationName: 'Delete Post',
      );
      
      // Invalidate posts cache
      if (result) {
        await _cacheService.invalidateCache('posts_cache');
      }
      
      return result;
    } catch (e) {
      Logger.error('Failed to delete post after retries: $e');
      return false;
    }
  }
  
  // Story operations
  Future<List<Map<String, dynamic>>> getStories() async {
    try {
      final response = await client
          .from(SupabaseConfig.storiesTable)
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching stories', e);
      // Fallback to sample data
      return AppConstants.sampleStories;
    }
  }
  
  Future<bool> insertStory(Map<String, dynamic> story) async {
    try {
      await client.from(SupabaseConfig.storiesTable).insert(story);
      return true;
    } catch (e) {
      Logger.error('Error inserting story', e);
      return false;
    }
  }
  
  // Booking operations
  Future<List<Map<String, dynamic>>> getBookings() async {
    try {
      final response = await client
          .from(SupabaseConfig.bookingsTable)
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching bookings', e);
      return [];
    }
  }
  
  Future<bool> insertBooking(Map<String, dynamic> booking) async {
    try {
      await client.from(SupabaseConfig.bookingsTable).insert(booking);
      return true;
    } catch (e) {
      Logger.error('Error inserting booking', e);
      return false;
    }
  }
  
  // User interaction operations
  Future<bool> insertUserInteraction(Map<String, dynamic> interaction) async {
    try {
      await client.from(SupabaseConfig.userInteractionsTable).insert(interaction);
      return true;
    } catch (e) {
      Logger.error('Error inserting user interaction', e);
      return false;
    }
  }
  
  Future<List<Map<String, dynamic>>> getUserInteractions(String userId) async {
    try {
      final response = await client
          .from(SupabaseConfig.userInteractionsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching user interactions', e);
      return [];
    }
  }
  
  // Message operations
  Future<List<Map<String, dynamic>>> getMessages(String conversationId, {bool useCache = true}) async {
    if (conversationId.isEmpty) {
      Logger.warning('getMessages called with empty conversationId');
      throw ArgumentError('Conversation ID cannot be empty');
    }

    final cacheKey = CacheService.messagesCacheKey(conversationId);
    
    if (useCache) {
      final cachedMessages = await _cacheService.getCache<List<dynamic>>(cacheKey, duration: CacheService.shortCacheDuration);
      if (cachedMessages != null) {
        Logger.debug('Retrieved messages for conversation $conversationId from cache');
        return List<Map<String, dynamic>>.from(cachedMessages);
      }
    }

    final messages = await _executeWithRetry(() async {
       Logger.debug('SupabaseService.getMessages called with conversationId: $conversationId');
       
       final response = await client
           .from('messages')
           .select('*')
           .eq('conversation_id', conversationId)
           .order('created_at', ascending: true);
       
       Logger.debug('Retrieved ${response.length} messages for conversation $conversationId');
       return List<Map<String, dynamic>>.from(response);
     }, fallback: <Map<String, dynamic>>[], operationName: 'Get Messages');
    
    if (useCache && messages.isNotEmpty) {
      await _cacheService.setCache(cacheKey, messages, duration: CacheService.shortCacheDuration);
    }
    
    return messages;
  }
  
  Future<bool> insertMessage(Map<String, dynamic> message) async {
    try {
      Logger.debug('SupabaseService.insertMessage called with message: ${message['id']}');
      await client.from('messages').insert(message);
      Logger.debug('Message inserted successfully: ${message['id']}');
      
      // Invalidate related caches
      if (message['conversation_id'] != null) {
        await _cacheService.invalidateCache(CacheService.messagesCacheKey(message['conversation_id']));
      }
      
      return true;
    } catch (e) {
      Logger.error('Error in insertMessage: $e');
      return false;
    }
  }
  
  // Conversation operations
  Future<List<Map<String, dynamic>>> getConversations(String userId, {bool useCache = true}) async {
    if (userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }

    final cacheKey = CacheService.conversationsCacheKey(userId);
    
    if (useCache) {
      final cachedConversations = await _cacheService.getCache<List<dynamic>>(cacheKey, duration: CacheService.shortCacheDuration);
      if (cachedConversations != null) {
        Logger.debug('Retrieved conversations from cache');
        return List<Map<String, dynamic>>.from(cachedConversations);
      }
    }

    final conversations = await _executeWithRetry(() async {
       final response = await client
           .from('conversations')
           .select('*')
           .eq('user_id', userId)
           .order('updated_at', ascending: false);
       
       return List<Map<String, dynamic>>.from(response);
     }, fallback: <Map<String, dynamic>>[], operationName: 'Get Conversations');
    
    if (useCache && conversations.isNotEmpty) {
      await _cacheService.setCache(cacheKey, conversations, duration: CacheService.shortCacheDuration);
    }
    
    return conversations;
  }

  // Send a message with cache invalidation
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String senderId,
    required String message,
  }) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }
    if (senderId.isEmpty) {
      throw ArgumentError('Sender ID cannot be empty');
    }
    if (message.trim().isEmpty) {
      throw ArgumentError('Message cannot be empty');
    }

    final messageData = {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message': _sanitizeString(message.trim()),
      'created_at': DateTime.now().toIso8601String(),
    };

    final result = await _executeWithRetry(() async {
       final response = await client
           .from('messages')
           .insert(messageData)
           .select()
           .single();
       
       return Map<String, dynamic>.from(response);
     }, fallback: <String, dynamic>{}, operationName: 'Send Message');
    
    // Invalidate related caches
    if (result.isNotEmpty) {
      await _cacheService.invalidateCache(CacheService.messagesCacheKey(conversationId));
      await _cacheService.invalidateCache(CacheService.conversationsCacheKey(senderId));
    }
    
    return result;
  }

  Future<void> createConversation(Map<String, dynamic> conversationData) async {
    try {
      await client
          .from('conversations')
          .insert(conversationData);
    } catch (e) {
      Logger.error('Error creating conversation', e);
      rethrow;
    }
  }
  
  // Enhanced real-time subscriptions with error handling
  final Map<String, RealtimeChannel> _activeChannels = {};
  final Map<String, StreamController<Map<String, dynamic>>> _messageStreams = {};
  final Map<String, StreamController<Map<String, dynamic>>> _postStreams = {};
  final Map<String, StreamController<Map<String, dynamic>>> _statusStreams = {};

  // Real-time messaging
  Stream<Map<String, dynamic>> getMessagesStream(String conversationId) {
    final streamKey = 'messages_$conversationId';
    
    if (!_messageStreams.containsKey(streamKey)) {
      _messageStreams[streamKey] = StreamController<Map<String, dynamic>>.broadcast();
      _subscribeToMessages(conversationId);
    }
    
    return _messageStreams[streamKey]!.stream;
  }

  void _subscribeToMessages(String conversationId) {
    final channelKey = 'messages_$conversationId';
    
    try {
      final channel = client.channel(channelKey);
      
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: conversationId),
        callback: (payload) {
          Logger.info('New message in conversation $conversationId');
          final streamKey = 'messages_$conversationId';
          if (_messageStreams.containsKey(streamKey)) {
            _messageStreams[streamKey]!.add(payload.newRecord);
          }
        },
      );
      
      channel.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          Logger.info('Successfully subscribed to messages for conversation $conversationId');
        } else if (error != null) {
          Logger.error('Failed to subscribe to messages: $error');
        }
      });
      
      _activeChannels[channelKey] = channel;
    } catch (e) {
      Logger.error('Error setting up message subscription for conversation $conversationId: $e');
    }
  }

  // Real-time posts updates
  Stream<Map<String, dynamic>> getPostsStream() {
    const streamKey = 'posts_global';
    
    if (!_postStreams.containsKey(streamKey)) {
      _postStreams[streamKey] = StreamController<Map<String, dynamic>>.broadcast();
      _subscribeToPosts();
    }
    
    return _postStreams[streamKey]!.stream;
  }

  void _subscribeToPosts() {
    const channelKey = 'posts_global';
    
    try {
      final channel = client.channel(channelKey);
      
      // Listen for new posts
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: SupabaseConfig.postsTable,
        callback: (payload) {
          Logger.info('New post created');
          const streamKey = 'posts_global';
          if (_postStreams.containsKey(streamKey)) {
            _postStreams[streamKey]!.add({
              'event': 'insert',
              'data': payload.newRecord,
            });
          }
        },
      );
      
      // Listen for post updates (likes, comments, etc.)
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: SupabaseConfig.postsTable,
        callback: (payload) {
          Logger.info('Post updated');
          const streamKey = 'posts_global';
          if (_postStreams.containsKey(streamKey)) {
            _postStreams[streamKey]!.add({
              'event': 'update',
              'data': payload.newRecord,
            });
          }
        },
      );
      
      channel.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          Logger.info('Successfully subscribed to posts updates');
        } else if (error != null) {
          Logger.error('Failed to subscribe to posts: $error');
        }
      });
      
      _activeChannels[channelKey] = channel;
    } catch (e) {
      Logger.error('Error setting up posts subscription: $e');
    }
  }

  // Real-time user status updates
  Stream<Map<String, dynamic>> getUserStatusStream(String userId) {
    final streamKey = 'status_$userId';
    
    if (!_statusStreams.containsKey(streamKey)) {
      _statusStreams[streamKey] = StreamController<Map<String, dynamic>>.broadcast();
      _subscribeToUserStatus(userId);
    }
    
    return _statusStreams[streamKey]!.stream;
  }

  void _subscribeToUserStatus(String userId) {
    final channelKey = 'status_$userId';
    
    try {
      final channel = client.channel(channelKey);
      
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'user_statuses',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
        callback: (payload) {
          Logger.info('User status updated for $userId');
          final streamKey = 'status_$userId';
          if (_statusStreams.containsKey(streamKey)) {
            _statusStreams[streamKey]!.add(payload.newRecord ?? payload.oldRecord);
          }
        },
      );
      
      channel.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          Logger.info('Successfully subscribed to status updates for user $userId');
        } else if (error != null) {
          Logger.error('Failed to subscribe to user status: $error');
        }
      });
      
      _activeChannels[channelKey] = channel;
    } catch (e) {
      Logger.error('Error setting up user status subscription for $userId: $e');
    }
  }

  // Generic subscription method (legacy support)
  RealtimeChannel subscribeToTable(String tableName, Function(Map<String, dynamic>) onInsert, Function(Map<String, dynamic>) onUpdate, Function(Map<String, dynamic>) onDelete) {
    return client
        .channel('public:$tableName')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: tableName,
          callback: (payload) => onInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: tableName,
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: tableName,
          callback: (payload) => onDelete(payload.oldRecord),
        )
        .subscribe();
  }

  // Cleanup methods
  void unsubscribeFromMessages(String conversationId) {
    final channelKey = 'messages_$conversationId';
    final streamKey = 'messages_$conversationId';
    
    if (_activeChannels.containsKey(channelKey)) {
      _activeChannels[channelKey]!.unsubscribe();
      _activeChannels.remove(channelKey);
    }
    
    if (_messageStreams.containsKey(streamKey)) {
      _messageStreams[streamKey]!.close();
      _messageStreams.remove(streamKey);
    }
  }

  void unsubscribeFromPosts() {
    const channelKey = 'posts_global';
    const streamKey = 'posts_global';
    
    if (_activeChannels.containsKey(channelKey)) {
      _activeChannels[channelKey]!.unsubscribe();
      _activeChannels.remove(channelKey);
    }
    
    if (_postStreams.containsKey(streamKey)) {
      _postStreams[streamKey]!.close();
      _postStreams.remove(streamKey);
    }
  }

  void unsubscribeFromUserStatus(String userId) {
    final channelKey = 'status_$userId';
    final streamKey = 'status_$userId';
    
    if (_activeChannels.containsKey(channelKey)) {
      _activeChannels[channelKey]!.unsubscribe();
      _activeChannels.remove(channelKey);
    }
    
    if (_statusStreams.containsKey(streamKey)) {
      _statusStreams[streamKey]!.close();
      _statusStreams.remove(streamKey);
    }
  }

  void unsubscribeAll() {
    // Close all active channels
    for (final channel in _activeChannels.values) {
      try {
        channel.unsubscribe();
      } catch (e) {
        Logger.warning('Error unsubscribing from channel: $e');
      }
    }
    _activeChannels.clear();
    
    // Close all streams
    for (final stream in _messageStreams.values) {
      try {
        stream.close();
      } catch (e) {
        Logger.warning('Error closing message stream: $e');
      }
    }
    _messageStreams.clear();
    
    for (final stream in _postStreams.values) {
      try {
        stream.close();
      } catch (e) {
        Logger.warning('Error closing post stream: $e');
      }
    }
    _postStreams.clear();
    
    for (final stream in _statusStreams.values) {
      try {
        stream.close();
      } catch (e) {
        Logger.warning('Error closing status stream: $e');
      }
    }
    _statusStreams.clear();
  }
  
  // Authentication helpers with enhanced error handling
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => client.auth.currentUser != null;
  
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty');
    }
    
    if (!_isValidEmail(email)) {
      throw Exception('Invalid email format');
    }
    
    return await _executeWithRetry(
      () async {
        return await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      },
      operationName: 'Sign In',
    );
  }
  
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty');
    }
    
    if (!_isValidEmail(email)) {
      throw Exception('Invalid email format');
    }
    
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long');
    }
    
    return await _executeWithRetry(
      () async {
        return await client.auth.signUp(
          email: email,
          password: password,
        );
      },
      operationName: 'Sign Up',
    );
  }
  
  Future<void> signOut() async {
    try {
      await _executeWithRetry(
        () async {
          await client.auth.signOut();
        },
        operationName: 'Sign Out',
      );
    } catch (e) {
      Logger.error('Failed to sign out: $e');
      // Don't rethrow - signing out should always succeed locally
    }
  }

  // Validation helpers
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidUuid(String id) {
    return RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(id);
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  String _sanitizeString(String input) {
    return input.trim()
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('/', '');
  }
  
  // Cache management methods
  Future<void> clearAllCaches() async {
    Logger.info('Clearing all SupabaseService caches');
    await _cacheService.clearAllCache();
  }
  
  Future<void> invalidateUserCaches() async {
    Logger.info('Invalidating user-related caches');
    await _cacheService.invalidateCache(CacheService.usersCacheKey());
  }
  
  Future<void> invalidateDestinationCaches() async {
    Logger.info('Invalidating destination-related caches');
    await _cacheService.invalidateCache(CacheService.destinationsCacheKey());
  }
  
  Future<void> invalidateConversationCaches(String userId) async {
    Logger.info('Invalidating conversation caches for user: $userId');
    await _cacheService.invalidateCache(CacheService.conversationsCacheKey(userId));
  }
  
  Future<void> invalidateMessageCaches(String conversationId) async {
    Logger.info('Invalidating message caches for conversation: $conversationId');
    await _cacheService.invalidateCache(CacheService.messagesCacheKey(conversationId));
  }

  Map<String, dynamic> _sanitizeUserData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in data.entries) {
      if (entry.value is String) {
        sanitized[entry.key] = _sanitizeString(entry.value);
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    
    return sanitized;
  }

  bool _validatePostData(Map<String, dynamic> post) {
    if (!post.containsKey('content') || post['content'] == null) {
      return false;
    }
    
    final content = post['content'].toString().trim();
    if (content.isEmpty || content.length > 2000) {
      return false;
    }
    
    if (post.containsKey('user_id') && !_isValidUuid(post['user_id'])) {
      return false;
    }
    
    return true;
  }

  bool _validateDestinationData(Map<String, dynamic> destination) {
    final requiredFields = ['name', 'description'];
    
    for (final field in requiredFields) {
      if (!destination.containsKey(field) || destination[field] == null) {
        return false;
      }
      
      final value = destination[field].toString().trim();
      if (value.isEmpty) {
        return false;
      }
    }
    
    if (destination.containsKey('image_url') && destination['image_url'] != null) {
      if (!_isValidUrl(destination['image_url'])) {
        return false;
      }
    }
    
    return true;
  }

  // Wallet Operations
  Future<UserWallet?> getUserWallet(String userId) async {
    try {
      final response = await client
          .from('user_wallets')
          .select()
          .eq('user_id', userId)
          .single();
      
      return UserWallet.fromJson(response);
    } catch (e) {
      Logger.error('Error getting user wallet', e);
      return null;
    }
  }

  Future<bool> createUserWallet(String userId) async {
    try {
      await client.from('user_wallets').insert({
        'user_id': userId,
        'total_points': 0,
        'total_earnings': 0.0,
        'level': 1,
        'level_name': 'Bronze Explorer',
        'points_to_next_level': 500,
        'last_updated': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      Logger.error('Error creating user wallet', e);
      return false;
    }
  }

  Future<bool> addWalletTransaction(WalletTransaction transaction) async {
    try {
      // Insert transaction
      await client.from('wallet_transactions').insert(transaction.toJson());
      
      // Update user wallet totals
      await _updateWalletTotals(transaction.userId);
      
      return true;
    } catch (e) {
      Logger.error('Error adding wallet transaction', e);
      return false;
    }
  }

  Future<List<WalletTransaction>> getWalletTransactions(String userId, {int limit = 50}) async {
    try {
      final response = await client
          .from('wallet_transactions')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(limit);
      
      return response.map<WalletTransaction>((json) => WalletTransaction.fromJson(json)).toList();
    } catch (e) {
      Logger.error('Error getting wallet transactions', e);
      return [];
    }
  }

  Future<List<Reward>> getAvailableRewards() async {
    try {
      final response = await client
          .from('rewards')
          .select()
          .eq('is_active', true)
          .order('points_cost', ascending: true);
      
      return response.map<Reward>((json) => Reward.fromJson(json)).toList();
    } catch (e) {
      Logger.error('Error getting rewards', e);
      return [];
    }
  }

  Future<bool> redeemReward(String userId, String rewardId, int pointsCost) async {
    try {
      // Check if user has enough points
      final wallet = await getUserWallet(userId);
      if (wallet == null || wallet.totalPoints < pointsCost) {
        return false;
      }

      // Get reward details
      final rewardResponse = await client
          .from('rewards')
          .select()
          .eq('id', rewardId)
          .single();
      
      final reward = Reward.fromJson(rewardResponse);

      // Create redemption transaction
      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: 'redeemed',
        description: 'Redeemed: ${reward.title}',
        points: -pointsCost,
        timestamp: DateTime.now(),
        category: 'redemption',
      );

      return await addWalletTransaction(transaction);
    } catch (e) {
      Logger.error('Error redeeming reward', e);
      return false;
    }
  }

  Future<bool> awardPoints(String userId, int points, String description, {String? category, double? earnings}) async {
    try {
      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: 'earned',
        description: description,
        points: points,
        amount: earnings,
        timestamp: DateTime.now(),
        category: category,
      );

      return await addWalletTransaction(transaction);
    } catch (e) {
      Logger.error('Error awarding points', e);
      return false;
    }
  }

  Future<void> _updateWalletTotals(String userId) async {
    try {
      // Calculate totals from transactions
      final transactions = await getWalletTransactions(userId);
      
      int totalPoints = 0;
      double totalEarnings = 0.0;
      
      for (final transaction in transactions) {
        totalPoints += transaction.points;
        if (transaction.amount != null) {
          totalEarnings += transaction.amount!;
        }
      }

      // Calculate level based on points
      int level = 1;
      String levelName = 'Bronze Explorer';
      int pointsToNextLevel = 500;

      if (totalPoints >= 3000) {
        level = 4;
        levelName = 'Platinum Explorer';
        pointsToNextLevel = 0;
      } else if (totalPoints >= 1500) {
        level = 3;
        levelName = 'Gold Explorer';
        pointsToNextLevel = 3000 - totalPoints;
      } else if (totalPoints >= 500) {
        level = 2;
        levelName = 'Silver Explorer';
        pointsToNextLevel = 1500 - totalPoints;
      } else {
        pointsToNextLevel = 500 - totalPoints;
      }

      // Update wallet
      await client.from('user_wallets').upsert({
        'user_id': userId,
        'total_points': totalPoints,
        'total_earnings': totalEarnings,
        'level': level,
        'level_name': levelName,
        'points_to_next_level': pointsToNextLevel,
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      Logger.error('Error updating wallet totals', e);
    }
  }

  // Status operations
  Future<List<Map<String, dynamic>>> getStatuses() async {
    try {
      final response = await client
          .from('user_statuses')
          .select('''
            *,
            users!user_statuses_user_id_fkey(
              name,
              avatar
            )
          ''')
          .order('timestamp', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching statuses', e);
      return [];
    }
  }

  Future<Map<String, dynamic>> createStatus(Map<String, dynamic> statusData) async {
    try {
      final response = await client
          .from('user_statuses')
          .insert(statusData)
          .select()
          .single();
      return response;
    } catch (e) {
      Logger.error('Error creating status', e);
      throw Exception('Failed to create status: $e');
    }
  }

  Future<void> toggleStatusLike(String statusId, bool isLiked) async {
    try {
      if (isLiked) {
        // Add like
        await client.from('status_likes').insert({
          'status_id': statusId,
          'user_id': 'current_user', // Replace with actual user ID
          'created_at': DateTime.now().toIso8601String(),
        });
        
        // Increment likes count
        await client.rpc('increment_status_likes', params: {
          'status_id': statusId,
        });
      } else {
        // Remove like
        await client
            .from('status_likes')
            .delete()
            .eq('status_id', statusId)
            .eq('user_id', 'current_user'); // Replace with actual user ID
        
        // Decrement likes count
        await client.rpc('decrement_status_likes', params: {
          'status_id': statusId,
        });
      }
    } catch (e) {
      Logger.error('Error toggling status like', e);
      throw Exception('Failed to toggle like: $e');
    }
  }

  // ============================================================================
  // PROFILE MANAGEMENT
  // ============================================================================

  /// Get user profile by ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      Logger.error('Error fetching user profile', e);
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      await client
          .from('users')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      Logger.info('User profile updated successfully');
    } catch (e) {
      Logger.error('Error updating user profile', e);
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Upload profile image to storage
  static Future<String> uploadProfileImage(File imageFile) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'profile_images/$fileName';

      await Supabase.instance.client.storage
          .from('avatars')
          .upload(filePath, imageFile);

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      Logger.info('Profile image uploaded successfully');
      return publicUrl;
    } catch (e) {
      Logger.error('Error uploading profile image', e);
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete old profile image from storage
  static Future<void> deleteProfileImage(String imageUrl) async {
    try {
      // Extract file path from public URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the path after 'avatars'
      final avatarsIndex = pathSegments.indexOf('avatars');
      if (avatarsIndex >= 0 && pathSegments.length > avatarsIndex + 1) {
        final filePath = pathSegments.sublist(avatarsIndex + 1).join('/');

        await Supabase.instance.client.storage
            .from('avatars')
            .remove([filePath]);

        Logger.info('Profile image deleted successfully');
      }
    } catch (e) {
      Logger.error('Error deleting profile image', e);
      // Don't throw - deletion failure shouldn't block profile update
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      Logger.info('Password updated successfully');
    } catch (e) {
      Logger.error('Error updating password', e);
      throw Exception('Failed to update password: $e');
    }
  }

  /// Delete user account
  Future<void> deleteUserAccount() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // Delete user data from users table
      await client
          .from('users')
          .delete()
          .eq('id', userId);

      // Sign out user
      await client.auth.signOut();

      Logger.info('User account deleted successfully');
    } catch (e) {
      Logger.error('Error deleting user account', e);
      throw Exception('Failed to delete account: $e');
    }
  }
}