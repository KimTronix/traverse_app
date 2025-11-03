import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import 'auth_service.dart';
import 'verification_service.dart';

class AiChatService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Create a new chat session for verified users
  static Future<String?> createChatSession({String? sessionName}) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is verified and can save chats
      if (!await VerificationService.canUserSaveChats()) {
        throw Exception('User must be verified to save chat sessions');
      }

      final sessionData = {
        'user_id': user.id,
        'session_name': sessionName ?? 'Chat ${DateTime.now().toString().substring(0, 16)}',
        'is_archived': false,
        'message_count': 0,
        'last_message_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('ai_chat_sessions')
          .insert(sessionData)
          .select('id')
          .single();

      Logger.info('Chat session created: ${response['id']}');
      return response['id'] as String;
    } catch (e) {
      Logger.error('Error creating chat session: $e');
      return null;
    }
  }

  // Get user's chat sessions
  static Future<List<Map<String, dynamic>>> getUserChatSessions() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return [];

      // Check if user is verified
      if (!await VerificationService.canUserSaveChats()) {
        return [];
      }

      final response = await _client
          .from('ai_chat_sessions')
          .select('*')
          .eq('user_id', user.id)
          .eq('is_archived', false)
          .order('last_message_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error getting chat sessions: $e');
      return [];
    }
  }

  // Save a message to a chat session
  static Future<bool> saveMessage({
    required String sessionId,
    required String role, // 'user' or 'assistant'
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is verified
      if (!await VerificationService.canUserSaveChats()) {
        throw Exception('User must be verified to save messages');
      }

      // Verify session belongs to user
      final session = await _client
          .from('ai_chat_sessions')
          .select('id, user_id, message_count')
          .eq('id', sessionId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (session == null) {
        throw Exception('Chat session not found or access denied');
      }

      final messageData = {
        'session_id': sessionId,
        'user_id': user.id,
        'message_type': messageType,
        'role': role,
        'content': content,
        'metadata': metadata ?? {},
      };

      // Insert message
      await _client.from('ai_chat_messages').insert(messageData);

      // Update session
      await _client
          .from('ai_chat_sessions')
          .update({
            'message_count': (session['message_count'] as int) + 1,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);

      return true;
    } catch (e) {
      Logger.error('Error saving message: $e');
      return false;
    }
  }

  // Get messages from a chat session
  static Future<List<Map<String, dynamic>>> getSessionMessages(String sessionId) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return [];

      // Check if user is verified
      if (!await VerificationService.canUserSaveChats()) {
        return [];
      }

      // Verify session belongs to user
      final session = await _client
          .from('ai_chat_sessions')
          .select('id')
          .eq('id', sessionId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (session == null) {
        throw Exception('Chat session not found or access denied');
      }

      final response = await _client
          .from('ai_chat_messages')
          .select('*')
          .eq('session_id', sessionId)
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error getting session messages: $e');
      return [];
    }
  }

  // Rename a chat session
  static Future<bool> renameChatSession(String sessionId, String newName) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return false;

      // Check if user is verified
      if (!await VerificationService.canUserSaveChats()) {
        return false;
      }

      await _client
          .from('ai_chat_sessions')
          .update({'session_name': newName})
          .eq('id', sessionId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      Logger.error('Error renaming chat session: $e');
      return false;
    }
  }

  // Archive a chat session
  static Future<bool> archiveChatSession(String sessionId) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return false;

      // Check if user is verified
      if (!await VerificationService.canUserSaveChats()) {
        return false;
      }

      await _client
          .from('ai_chat_sessions')
          .update({'is_archived': true})
          .eq('id', sessionId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      Logger.error('Error archiving chat session: $e');
      return false;
    }
  }

  // Delete a chat session and all its messages
  static Future<bool> deleteChatSession(String sessionId) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return false;

      // Check if user is verified
      if (!await VerificationService.canUserSaveChats()) {
        return false;
      }

      // Verify session belongs to user
      final session = await _client
          .from('ai_chat_sessions')
          .select('id')
          .eq('id', sessionId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (session == null) {
        throw Exception('Chat session not found or access denied');
      }

      // Delete messages first (due to foreign key constraint)
      await _client
          .from('ai_chat_messages')
          .delete()
          .eq('session_id', sessionId)
          .eq('user_id', user.id);

      // Delete session
      await _client
          .from('ai_chat_sessions')
          .delete()
          .eq('id', sessionId)
          .eq('user_id', user.id);

      Logger.info('Chat session deleted: $sessionId');
      return true;
    } catch (e) {
      Logger.error('Error deleting chat session: $e');
      return false;
    }
  }

  // Save a complete conversation to a new session
  static Future<String?> saveConversation({
    required List<Map<String, String>> messages,
    String? sessionName,
  }) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return null;

      // Check if user is verified
      if (!await VerificationService.canUserSaveChats()) {
        throw Exception('User must be verified to save conversations');
      }

      // Create session
      final sessionId = await createChatSession(sessionName: sessionName);
      if (sessionId == null) return null;

      // Save all messages
      for (final message in messages) {
        await saveMessage(
          sessionId: sessionId,
          role: message['role'] ?? 'user',
          content: message['text'] ?? '',
        );
      }

      Logger.info('Conversation saved with ${messages.length} messages');
      return sessionId;
    } catch (e) {
      Logger.error('Error saving conversation: $e');
      return null;
    }
  }

  // Get archived chat sessions
  static Future<List<Map<String, dynamic>>> getArchivedChatSessions() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return [];

      // Check if user is verified
      if (!await VerificationService.canUserSaveChats()) {
        return [];
      }

      final response = await _client
          .from('ai_chat_sessions')
          .select('*')
          .eq('user_id', user.id)
          .eq('is_archived', true)
          .order('last_message_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error getting archived chat sessions: $e');
      return [];
    }
  }

  // Restore archived chat session
  static Future<bool> restoreChatSession(String sessionId) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return false;

      // Check if user is verified
      if (!await VerificationService.canUserSaveChats()) {
        return false;
      }

      await _client
          .from('ai_chat_sessions')
          .update({'is_archived': false})
          .eq('id', sessionId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      Logger.error('Error restoring chat session: $e');
      return false;
    }
  }

  // Get chat statistics for user
  static Future<Map<String, int>> getChatStatistics() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return {};

      // Check if user is verified
      if (!await VerificationService.canUserSaveChats()) {
        return {};
      }

      final sessions = await _client
          .from('ai_chat_sessions')
          .select('id, message_count, is_archived')
          .eq('user_id', user.id);

      int totalSessions = sessions.length;
      int activeSessions = sessions.where((s) => s['is_archived'] == false).length;
      int archivedSessions = sessions.where((s) => s['is_archived'] == true).length;
      int totalMessages = sessions.fold(0, (sum, s) => sum + (s['message_count'] as int));

      return {
        'total_sessions': totalSessions,
        'active_sessions': activeSessions,
        'archived_sessions': archivedSessions,
        'total_messages': totalMessages,
      };
    } catch (e) {
      Logger.error('Error getting chat statistics: $e');
      return {};
    }
  }
}