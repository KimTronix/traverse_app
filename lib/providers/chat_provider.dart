import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/supabase_service.dart';
import '../services/openai_service.dart';
import '../utils/logger.dart';

class ChatProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final OpenAIService _openAIService = OpenAIService.instance;
  
  List<Conversation> _conversations = [];
  final bool _isLoading = false; // Make final
  String? _error;
  
  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Helper method to check if user is in demo mode
  bool _isDemoUser(String userId) {
    return userId.startsWith('demo_');
  }

  // Load conversations for a user
  Future<void> loadConversations(String userId) async {
    Logger.debug('ChatProvider.loadConversations called with userId: $userId');
    
    try {
      if (userId == 'demo_user') {
        Logger.debug('Demo mode detected, using local conversations');
        await _loadDemoConversations(userId);
      } else {
        Logger.debug('Calling _supabaseService.getConversations');
        final conversationsData = await _supabaseService.getConversations(userId);
        Logger.debug('Retrieved ${conversationsData.length} conversations from database');
        
        // Replace all other print statements with appropriate Logger calls
      }
    } catch (e) {
      Logger.error('Error loading conversations', e);
    }
  }

  // Load demo conversations (local only)
  Future<void> _loadDemoConversations(String userId) async {
    Logger.debug('Loading demo conversations for userId: $userId');
    
    _conversations = [];
    
    // Create AI conversation
    final aiConversation = Conversation(
      id: 'ai_conversation_$userId',
      name: 'TraverseAI',
      avatar: 'assets/images/ai_avatar.png',
      messages: [
        Message(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'TraverseAI',
          text: '🌟 Welcome to Traverse! I\'m TraverseAI, your intelligent travel companion. I can help you with trip planning, bookings, recommendations, and navigating all of Traverse\'s features. What adventure shall we plan today?',
          timestamp: DateTime.now(),
          isMe: false,
        ),
      ],
      isGroup: false,
      isAI: true,
    );
    
    _conversations.add(aiConversation);
    
    // Create demo conversations
    final sarahConversation = Conversation(
      id: 'sarah_conversation_$userId',
      name: 'Sarah Johnson',
      avatar: 'assets/images/avatar2.jpg',
      messages: [
        Message(
          id: 'sarah_msg1_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'Sarah Johnson',
          text: 'Hey! How was your trip to Paris?',
          timestamp: DateTime.now().subtract(Duration(minutes: 30)),
          isMe: false,
        ),
        Message(
          id: 'user_msg1_${DateTime.now().millisecondsSinceEpoch + 1}',
          sender: 'Me',
          text: 'It was amazing! The Eiffel Tower at sunset was breathtaking.',
          timestamp: DateTime.now().subtract(Duration(minutes: 25)),
          isMe: true,
        ),
        Message(
          id: 'sarah_msg2_${DateTime.now().millisecondsSinceEpoch + 2}',
          sender: 'Sarah Johnson',
          text: 'I\'m so jealous! Can\'t wait to hear all about it.',
          timestamp: DateTime.now().subtract(Duration(minutes: 20)),
          isMe: false,
        ),
      ],
      isGroup: false,
      isAI: false,
    );
    
    _conversations.add(sarahConversation);
    
    final mikeConversation = Conversation(
      id: 'mike_conversation_$userId',
      name: 'Mike Chen',
      avatar: 'assets/images/avatar3.jpg',
      messages: [
        Message(
          id: 'mike_msg1_${DateTime.now().millisecondsSinceEpoch + 3}',
          sender: 'Mike Chen',
          text: 'Are you still planning the hiking trip next weekend?',
          timestamp: DateTime.now().subtract(Duration(hours: 2)),
          isMe: false,
        ),
        Message(
          id: 'user_msg2_${DateTime.now().millisecondsSinceEpoch + 4}',
          sender: 'Me',
          text: 'Yes! I found a great trail in the mountains.',
          timestamp: DateTime.now().subtract(Duration(minutes: 50)),
          isMe: true,
        ),
      ],
      isGroup: false,
      isAI: false,
    );
    
    _conversations.add(mikeConversation);
    
    Logger.debug('Demo conversations created: ${_conversations.length}');
  }

  // Create default AI conversation
  Future<void> _createDefaultAIConversation(String userId) async {
    Logger.debug('_createDefaultAIConversation called with userId: $userId');
    
    // Handle demo mode separately
    if (_isDemoUser(userId)) {
      Logger.debug('Demo mode - creating local AI conversation only');
      
      final aiConversation = Conversation(
        id: 'ai_conversation_$userId',
        name: 'TraverseAI',
        avatar: 'assets/images/ai_avatar.png',
        messages: [
          Message(
            id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
            sender: 'TraverseAI',
            text: '🌟 Welcome to Traverse! I\'m TraverseAI, your intelligent travel companion. I can help you with trip planning, bookings, recommendations, and navigating all of Traverse\'s features. What adventure shall we plan today?',
            timestamp: DateTime.now(),
            isMe: false,
          ),
        ],
        isGroup: false,
        isAI: true,
      );
      
      _conversations.add(aiConversation);
      notifyListeners();
      Logger.debug('Demo AI conversation created successfully');
      return;
    }
    
    // Original database logic for non-demo users
    try {
      final conversationData = {
        'id': 'ai_conversation_$userId',
        'name': 'TraverseAI',
        'avatar': 'assets/images/ai_avatar.png',
        'user1_id': userId,
        'user2_id': 'ai_assistant',
        'is_group': false,
        'is_ai': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      Logger.debug('Inserting AI conversation into database: ${conversationData['id']}');
      
      // Insert conversation into database
      await _supabaseService.client
          .from('conversations')
          .upsert(conversationData);
      
      Logger.debug('AI conversation inserted successfully');
      
      // Add welcome message
      final welcomeMessage = {
        'id': 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': conversationData['id'],
        'sender_id': 'ai_assistant',
        'sender_name': 'TraverseAI',
        'content': '🌟 Welcome to Traverse! I\'m TraverseAI, your intelligent travel companion. I can help you with trip planning, bookings, recommendations, and navigating all of Traverse\'s features. What adventure shall we plan today?',
        'is_from_current_user': false,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      Logger.debug('Inserting welcome message: ${welcomeMessage['id']}');
      await _supabaseService.insertMessage(welcomeMessage);
      Logger.debug('Welcome message inserted successfully');
      
      // Add to local conversations list
      _conversations.add(Conversation(
        id: conversationData['id'] as String,
        name: conversationData['name'] as String,
        avatar: conversationData['avatar'] as String,
        messages: [Message(
          id: welcomeMessage['id'] as String,
          sender: welcomeMessage['sender_name'] as String,
          text: welcomeMessage['content'] as String,
          timestamp: DateTime.parse(welcomeMessage['created_at'] as String),
          isMe: false,
        )],
        isGroup: false,
        isAI: true,
      ));
      
      Logger.debug('AI conversation added to local list. Total conversations: ${_conversations.length}');
      notifyListeners();
      Logger.debug('_createDefaultAIConversation completed successfully');
      
    } catch (e) {
      Logger.error('Error creating default AI conversation', e);
    }
  }

  // Send message
  Future<void> sendMessage(String conversationId, String message, String userId) async {
    try {
      final messageData = {
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': conversationId,
        'sender_id': userId,
        'sender_name': 'Me',
        'content': message, // Fixed: changed from 'text' to 'message'
        'is_from_current_user': true,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      // Handle demo mode separately
      if (_isDemoUser(userId)) {
        Logger.debug('Demo mode - adding message locally only');
        
        // Add to local conversation only
        final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
        if (conversationIndex != -1) {
          final newMessage = Message(
            id: messageData['id'] as String,
            sender: messageData['sender_name'] as String,
            text: messageData['content'] as String,
            timestamp: DateTime.parse(messageData['created_at'] as String),
            isMe: true,
          );
          
          _conversations[conversationIndex].messages.add(newMessage);
          notifyListeners();
          
          // Generate AI response if it's an AI conversation
          final conversation = _conversations[conversationIndex];
          if (conversation.isAI) {
            await _generateAIResponse(conversationId, message); // Fixed: changed from 'text' to 'message'
          }
        }
      } else {
        // Original database logic for non-demo users
        // Insert message into database
        await _supabaseService.insertMessage(messageData);
        
        // Add to local conversation
        final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
        if (conversationIndex != -1) {
          final newMessage = Message(
            id: messageData['id'] as String,
            sender: messageData['sender_name'] as String,
            text: messageData['content'] as String,
            timestamp: DateTime.parse(messageData['created_at'] as String),
            isMe: true,
          );
          
          _conversations[conversationIndex].messages.add(newMessage);
          notifyListeners();
          
          // Generate AI response if it's an AI conversation
          final conversation = _conversations[conversationIndex];
          if (conversation.isAI) {
            await _generateAIResponse(conversationId, message); // Fixed: changed from 'text' to 'message'
          }
        }
      }
      
    } catch (e) {
      _error = 'Failed to send message: $e';
      Logger.error('Error sending message: $e');
      notifyListeners();
    }
  }

  // Load messages for a specific conversation
  Future<List<Message>> _loadMessagesForConversation(String conversationId) async {
    try {
      final messagesData = await _supabaseService.getMessages(conversationId);
      return messagesData.map((msgData) => Message(
        id: msgData['id'],
        sender: msgData['sender_name'] ?? 'Unknown',
        text: msgData['content'] ?? '',
        timestamp: DateTime.parse(msgData['created_at']),
        isMe: msgData['is_from_current_user'] ?? false,
      )).toList();
    } catch (e) {
      Logger.error('Error loading messages for conversation $conversationId', e);
      return [];
    }
  }
  
  // Create demo conversations with sample data
  Future<void> _createDemoConversations(String userId) async {
    try {
      // Create AI Travel Assistant conversation
      final aiConversationData = {
        'id': 'ai_conversation_$userId',
        'name': 'TraverseAI',
        'avatar': 'assets/images/ai_avatar.png',
        'user1_id': userId,
        'user2_id': 'ai_assistant',
        'is_group': false,
        'is_ai': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabaseService.client
          .from('conversations')
          .upsert(aiConversationData);

      final aiWelcomeMessage = {
        'id': 'ai_welcome_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': aiConversationData['id'],
        'sender_id': 'ai_assistant',
        'sender_name': 'TraverseAI',
        'content': '🌟 Welcome to Traverse! I\'m TraverseAI, your intelligent travel companion. I can help you with trip planning, bookings, recommendations, and navigating all of Traverse\'s features. What adventure shall we plan today?',
        'is_from_current_user': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabaseService.insertMessage(aiWelcomeMessage);

      // Create Sarah Johnson conversation
      final sarahConversationData = {
        'id': 'sarah_conversation_$userId',
        'name': 'Sarah Johnson',
        'avatar': 'assets/images/avatar2.jpg',
        'user1_id': userId,
        'user2_id': 'sarah_johnson',
        'is_group': false,
        'is_ai': false,
        'created_at': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        'updated_at': DateTime.now().subtract(Duration(minutes: 20)).toIso8601String(),
      };

      await _supabaseService.client
          .from('conversations')
          .upsert(sarahConversationData);

      // Sarah's messages
      final sarahMessages = [
        {
          'id': 'sarah_msg1_${DateTime.now().millisecondsSinceEpoch}',
          'conversation_id': sarahConversationData['id'],
          'sender_id': 'sarah_johnson',
          'sender_name': 'Sarah Johnson',
          'content': 'Hey! How was your trip to Paris?',
          'is_from_current_user': false,
          'created_at': DateTime.now().subtract(Duration(minutes: 30)).toIso8601String(),
        },
        {
          'id': 'user_msg1_${DateTime.now().millisecondsSinceEpoch + 1}',
          'conversation_id': sarahConversationData['id'],
          'sender_id': userId,
          'sender_name': 'Me',
          'content': 'It was amazing! The Eiffel Tower at sunset was breathtaking.',
          'is_from_current_user': true,
          'created_at': DateTime.now().subtract(Duration(minutes: 25)).toIso8601String(),
        },
        {
          'id': 'sarah_msg2_${DateTime.now().millisecondsSinceEpoch + 2}',
          'conversation_id': sarahConversationData['id'],
          'sender_id': 'sarah_johnson',
          'sender_name': 'Sarah Johnson',
          'content': 'I\'m so jealous! Can\'t wait to hear all about it.',
          'is_from_current_user': false,
          'created_at': DateTime.now().subtract(Duration(minutes: 20)).toIso8601String(),
        },
      ];

      for (final message in sarahMessages) {
        await _supabaseService.insertMessage(message);
      }

      // Create Mike Chen conversation
      final mikeConversationData = {
        'id': 'mike_conversation_$userId',
        'name': 'Mike Chen',
        'avatar': 'assets/images/avatar3.jpg',
        'user1_id': userId,
        'user2_id': 'mike_chen',
        'is_group': false,
        'is_ai': false,
        'created_at': DateTime.now().subtract(Duration(hours: 3)).toIso8601String(),
        'updated_at': DateTime.now().subtract(Duration(minutes: 50)).toIso8601String(),
      };

      await _supabaseService.client
          .from('conversations')
          .upsert(mikeConversationData);

      // Mike's messages
      final mikeMessages = [
        {
          'id': 'mike_msg1_${DateTime.now().millisecondsSinceEpoch + 3}',
          'conversation_id': mikeConversationData['id'],
          'sender_id': 'mike_chen',
          'sender_name': 'Mike Chen',
          'content': 'Are you still planning the hiking trip next weekend?',
          'is_from_current_user': false,
          'created_at': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': 'user_msg2_${DateTime.now().millisecondsSinceEpoch + 4}',
          'conversation_id': mikeConversationData['id'],
          'sender_id': userId,
          'sender_name': 'Me',
          'content': 'Yes! I found a great trail in the mountains.',
          'is_from_current_user': true,
          'created_at': DateTime.now().subtract(Duration(minutes: 50)).toIso8601String(),
        },
      ];

      for (final message in mikeMessages) {
        await _supabaseService.insertMessage(message);
      }

      // Add conversations to local state
      // AI Conversation
      _conversations.add(Conversation(
        id: aiConversationData['id'] as String,
        name: aiConversationData['name'] as String,
        avatar: aiConversationData['avatar'] as String,
        messages: [Message(
          id: aiWelcomeMessage['id'] as String,
          sender: aiWelcomeMessage['sender_name'] as String,
          text: aiWelcomeMessage['content'] as String,
          timestamp: DateTime.parse(aiWelcomeMessage['created_at'] as String),
          isMe: false,
        )],
        isGroup: false,
        isAI: true,
      ));
      
      // Sarah Conversation
      final sarahMessagesList = sarahMessages.map((msgData) => Message(
        id: msgData['id'] as String,
        sender: msgData['sender_name'] as String,
        text: msgData['content'] as String,
        timestamp: DateTime.parse(msgData['created_at'] as String),
        isMe: msgData['is_from_current_user'] as bool,
      )).toList();
      
      _conversations.add(Conversation(
        id: sarahConversationData['id'] as String,
        name: sarahConversationData['name'] as String,
        avatar: sarahConversationData['avatar'] as String,
        messages: sarahMessagesList,
        isGroup: false,
        isAI: false,
      ));
      
      // Mike Conversation
      final mikeMessagesList = mikeMessages.map((msgData) => Message(
        id: msgData['id'] as String,
        sender: msgData['sender_name'] as String,
        text: msgData['content'] as String,
        timestamp: DateTime.parse(msgData['created_at'] as String),
        isMe: msgData['is_from_current_user'] as bool,
      )).toList();
      
      _conversations.add(Conversation(
        id: mikeConversationData['id'] as String,
        name: mikeConversationData['name'] as String,
        avatar: mikeConversationData['avatar'] as String,
        messages: mikeMessagesList,
        isGroup: false,
        isAI: false,
      ));
      
      notifyListeners();

    } catch (e) {
      print('Error creating demo conversations: $e');
    }
  }
  
  // Send a message
  Future<void> sendMessage1(String conversationId, String message, String userId) async {
    try {
      // Handle demo mode
      if (userId.startsWith('demo_') || conversationId.startsWith('local_')) {
        print('🔍 DEBUG: Demo mode message sending');
        
        final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
        if (conversationIndex == -1) return;
        
        // Add user message locally
        final userMessage = Message(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'You',
          text: message,
          timestamp: DateTime.now(),
          isMe: true,
        );
        
        _conversations[conversationIndex].messages.add(userMessage);
        notifyListeners();
        
        // Generate AI response for demo mode
        await _generateAIResponse(conversationId, message);
        return;
      }
      
      // Original database logic for real users
      final messageData = {
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': conversationId,
        'sender_id': userId,
        'sender_name': 'Me',
        'content': message,
        'is_from_current_user': true,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      // Insert message into database
      await _supabaseService.insertMessage(messageData);
      
      // Add to local conversation
      final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (conversationIndex != -1) {
        final newMessage = Message(
          id: messageData['id'] as String,
          sender: messageData['sender_name'] as String,
          text: messageData['content'] as String,
          timestamp: DateTime.parse(messageData['created_at'] as String),
          isMe: true,
        );
        
        _conversations[conversationIndex].messages.add(newMessage);
        notifyListeners();
        
        // Generate AI response if it's an AI conversation
        final conversation = _conversations[conversationIndex];
        if (conversation.isAI) {
          await _generateAIResponse(conversationId, message);
        }
      }
      
    } catch (e) {
      Logger.error('Error sending message: $e');
      print('Error sending message: $e');
      notifyListeners();
    }
  }

  // Generate AI response
  Future<void> _generateAIResponse(String conversationId, String userMessage) async {
    try {
      // Handle demo mode - skip database operations
      if (conversationId.startsWith('local_')) {
        print('🔍 DEBUG: Demo mode AI response generation');
        
        final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
        if (conversationIndex == -1) return;
        
        final conversation = _conversations[conversationIndex];
        final history = conversation.messages
            .takeLast(10) // Last 10 messages for context
            .map((m) => m.text)
            .toList();
        
        final aiResponse = await _openAIService.generateTravelResponse(
          userMessage,
          conversationHistory: history,
        );
        
        // Add AI response locally (no database)
        final aiMessage = Message(
          id: 'ai_msg_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'TraverseAI',
          text: aiResponse,
          timestamp: DateTime.now(),
          isMe: false,
        );
        
        _conversations[conversationIndex].messages.add(aiMessage);
        notifyListeners();
        return;
      }
      
      // Original database logic for real users
      final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (conversationIndex == -1) return;
      
      final conversation = _conversations[conversationIndex];
      final history = conversation.messages
          .takeLast(10) // Last 10 messages for context
          .map((m) => m.text)
          .toList();
      
      final aiResponse = await _openAIService.generateTravelResponse(
        userMessage,
        conversationHistory: history,
      );
      
      final responseMessageData = {
        'id': 'ai_msg_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': conversationId,
        'sender_id': 'ai_assistant',
        'sender_name': 'TraverseAI',
        'content': aiResponse,
        'is_from_current_user': false,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      // Insert AI response into database
      await _supabaseService.insertMessage(responseMessageData);
      
      // Add to local conversation
      final aiMessage = Message(
        id: responseMessageData['id'] as String,
        sender: responseMessageData['sender_name'] as String,
        text: responseMessageData['content'] as String,
        timestamp: DateTime.parse(responseMessageData['created_at'] as String),
        isMe: false,
      );
      
      _conversations[conversationIndex].messages.add(aiMessage);
      notifyListeners();
      
    } catch (e) {
      Logger.error('Error generating AI response: $e');
      // Add error message
      final errorMessage = Message(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'TraverseAI',
        text: 'Sorry, I\'m having trouble responding right now. Please try again later.',
        timestamp: DateTime.now(),
        isMe: false,
      );
      
      final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (conversationIndex != -1) {
        _conversations[conversationIndex].messages.add(errorMessage);
        notifyListeners();
      }
    }
  }

  // Get a specific conversation
  Conversation? getConversation(String conversationId) {
    try {
      return _conversations.firstWhere((c) => c.id == conversationId);
    } catch (e) {
      return null;
    }
  }
  
  // Create a new conversation
  Future<void> createNewConversation({
    required String userId,
    required String contactName,
    required String contactId,
    String? avatar,
    bool isGroup = false,
  }) async {
    try {
      final conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
      
      final conversationData = {
        'id': conversationId,
        'name': contactName,
        'avatar': avatar ?? 'assets/images/default_avatar.png',
        'user1_id': userId,
        'user2_id': contactId,
        'is_group': isGroup,
        'is_ai': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await _supabaseService.client
          .from('conversations')
          .upsert(conversationData);
      
      // Add to local conversations list
      _conversations.add(Conversation(
        id: conversationId,
        name: contactName,
        avatar: avatar ?? 'assets/images/default_avatar.png',
        messages: [],
        isGroup: isGroup,
        isAI: false,
      ));
      
      notifyListeners();
      
    } catch (e) {
      _error = 'Failed to create conversation: $e';
      Logger.error('Error creating conversation: $e');
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Test method to manually trigger AI conversation creation
  Future<void> testAIConversationCreation(String userId) async {
    Logger.debug('Starting AI conversation creation test for userId: $userId');
    
    try {
      await _createDefaultAIConversation(userId);
      await loadConversations(userId);
      
      Logger.debug('AI conversation creation completed. Total conversations: ${_conversations.length}');
      Logger.debug('AI conversations found: ${_conversations.where((c) => c.isAI).length}');
    } catch (e) {
      Logger.error('Error in AI conversation creation test', e);
    }
  }
}

extension ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
}


  // Remove unused methods:
  // - _loadMessagesForConversation
  // - _createDemoConversations