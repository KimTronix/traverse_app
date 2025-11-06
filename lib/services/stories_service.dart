import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import 'supabase_service.dart';

class StoriesService {
  static final StoriesService _instance = StoriesService._internal();
  factory StoriesService() => _instance;
  StoriesService._internal();

  static StoriesService get instance => _instance;

  final SupabaseService _supabaseService = SupabaseService.instance;

  /// Create a new story
  Future<Map<String, dynamic>?> createStory({
    required String userId,
    required String mediaUrl,
    String? content,
    String? location,
    double? latitude,
    double? longitude,
    String mediaType = 'image',
    int durationHours = 24,
  }) async {
    try {
      Logger.info('Creating story for user: $userId');

      final storyData = {
        'user_id': userId,
        'media_url': mediaUrl,
        'content': content,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'media_type': mediaType,
        'duration': durationHours,
        'is_active': true,
        'view_count': 0,
        'expires_at': DateTime.now().add(Duration(hours: durationHours)).toIso8601String(),
      };

      final response = await _supabaseService.client
          .from('stories')
          .insert(storyData)
          .select('''
            *,
            users!stories_user_id_fkey(
              id,
              username,
              full_name,
              avatar_url
            )
          ''')
          .single();

      Logger.info('Story created successfully: ${response['id']}');
      return response;
    } catch (e, stackTrace) {
      Logger.error('Error creating story: $e');
      Logger.error('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Upload story media to Supabase storage
  Future<String?> uploadStoryMedia({
    required String userId,
    required File imageFile,
  }) async {
    try {
      Logger.info('Uploading story media for user: $userId');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId/story_$timestamp.jpg';

      final response = await _supabaseService.client.storage
          .from('stories')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = _supabaseService.client.storage
          .from('stories')
          .getPublicUrl(fileName);

      Logger.info('Story media uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      Logger.error('Error uploading story media: $e');
      Logger.error('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get all active stories (not expired)
  Future<List<Map<String, dynamic>>> getActiveStories() async {
    try {
      final response = await _supabaseService.client
          .from('stories')
          .select('''
            *,
            users!stories_user_id_fkey(
              id,
              username,
              full_name,
              avatar_url
            )
          ''')
          .eq('is_active', true)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching active stories: $e');
      return [];
    }
  }

  /// Get stories by user
  Future<List<Map<String, dynamic>>> getUserStories(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('stories')
          .select('''
            *,
            users!stories_user_id_fkey(
              id,
              username,
              full_name,
              avatar_url
            )
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching user stories: $e');
      return [];
    }
  }

  /// Increment story view count
  Future<bool> incrementViewCount(String storyId) async {
    try {
      await _supabaseService.client
          .from('stories')
          .update({'view_count': 'view_count + 1'})
          .eq('id', storyId);

      return true;
    } catch (e) {
      Logger.error('Error incrementing view count: $e');
      return false;
    }
  }

  /// Delete a story
  Future<bool> deleteStory(String storyId) async {
    try {
      await _supabaseService.client
          .from('stories')
          .delete()
          .eq('id', storyId);

      Logger.info('Story deleted successfully: $storyId');
      return true;
    } catch (e) {
      Logger.error('Error deleting story: $e');
      return false;
    }
  }

  /// Mark expired stories as inactive (cleanup)
  Future<void> cleanupExpiredStories() async {
    try {
      await _supabaseService.client
          .from('stories')
          .update({'is_active': false})
          .lt('expires_at', DateTime.now().toIso8601String())
          .eq('is_active', true);

      Logger.info('Expired stories cleaned up');
    } catch (e) {
      Logger.error('Error cleaning up expired stories: $e');
    }
  }
}
