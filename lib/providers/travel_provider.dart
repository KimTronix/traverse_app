import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../services/auth_service.dart';
import '../config/supabase_config.dart';

class TravelProvider extends ChangeNotifier {
  static final SupabaseClient _client = Supabase.instance.client;
  
  List<Map<String, dynamic>> _destinations = [];
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _stories = [];
  final Set<String> _likedPosts = {}; // Changed to String for UUID compatibility
  final Set<String> _savedPosts = {}; // Changed to String for UUID compatibility
  bool _isLoading = false;

  List<Map<String, dynamic>> get destinations => _destinations;
  List<Map<String, dynamic>> get posts => _posts;
  List<Map<String, dynamic>> get stories => _stories;
  Set<String> get likedPosts => _likedPosts;
  Set<String> get savedPosts => _savedPosts;
  bool get isLoading => _isLoading;

  TravelProvider() {
    _loadDataFromDatabase();
  }

  Future<void> _loadDataFromDatabase() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load destinations from Supabase
      final destinationsResponse = await _client
          .from(SupabaseConfig.destinationsTable)
          .select()
          .order('created_at', ascending: false);

      // Load attractions (business listings) from Supabase - only approved ones
      try {
        final attractionsResponse = await _client
            .from('attractions')
            .select('''
              *,
              users!attractions_owner_id_fkey(
                id,
                username,
                full_name,
                avatar_url
              )
            ''')
            .eq('status', 'approved')
            .order('created_at', ascending: false);

        Logger.info('Loaded ${attractionsResponse.length} approved attractions');

        // Merge attractions into destinations
        _destinations = List<Map<String, dynamic>>.from(destinationsResponse);
        _destinations.addAll(List<Map<String, dynamic>>.from(attractionsResponse));
      } catch (e) {
        Logger.error('Error loading attractions (table may not exist yet)', e);
        // If attractions table doesn't exist, just use destinations
        _destinations = List<Map<String, dynamic>>.from(destinationsResponse);
      }

      // Load posts from Supabase (only public posts)
      final postsResponse = await _client
          .from(SupabaseConfig.postsTable)
          .select('''
            *,
            users!posts_user_id_fkey(
              id,
              username,
              full_name,
              avatar_url
            )
          ''')
          .eq('is_public', true)
          .order('created_at', ascending: false);

      // Load stories from Supabase
      final storiesResponse = await _client
          .from(SupabaseConfig.storiesTable)
          .select('''
            *,
            users!stories_user_id_fkey(
              id,
              username,
              full_name,
              avatar_url
            )
          ''')
          .order('created_at', ascending: false);

      _posts = List<Map<String, dynamic>>.from(postsResponse);
      _stories = List<Map<String, dynamic>>.from(storiesResponse);

      // Load user interactions if user is authenticated
      await _loadUserInteractions();

    } catch (e) {
      Logger.error('Error loading data from database', e);
      // NO dummy data fallback - keep lists empty
      _destinations = [];
      _posts = [];
      _stories = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserInteractions() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    try {
      // Load user's likes and saves
      final interactions = await _client
          .from(SupabaseConfig.userInteractionsTable)
          .select('target_id, interaction_type')
          .eq('user_id', currentUser.id)
          .eq('target_type', 'post');

      _likedPosts.clear();
      _savedPosts.clear();

      for (final interaction in interactions) {
        final targetId = interaction['target_id'] as String;
        final interactionType = interaction['interaction_type'] as String;

        if (interactionType == 'like') {
          _likedPosts.add(targetId);
        } else if (interactionType == 'save') {
          _savedPosts.add(targetId);
        }
      }

      Logger.info('Loaded ${_likedPosts.length} likes and ${_savedPosts.length} saves');
    } catch (e) {
      Logger.error('Error loading user interactions', e);
    }
  }

  Future<void> toggleLike(String postId) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    try {
      if (_likedPosts.contains(postId)) {
        // Remove like
        await _client
            .from(SupabaseConfig.userInteractionsTable)
            .delete()
            .eq('user_id', currentUser.id)
            .eq('target_id', postId)
            .eq('target_type', 'post')
            .eq('interaction_type', 'like');

        _likedPosts.remove(postId);

        // Update post like count
        await _updatePostLikeCount(postId, -1);
      } else {
        // Add like
        await _client
            .from(SupabaseConfig.userInteractionsTable)
            .upsert({
              'user_id': currentUser.id,
              'target_id': postId,
              'target_type': 'post',
              'interaction_type': 'like',
              'created_at': DateTime.now().toIso8601String(),
            });

        _likedPosts.add(postId);

        // Update post like count
        await _updatePostLikeCount(postId, 1);
      }

      notifyListeners();
    } catch (e) {
      Logger.error('Error toggling like', e);
    }
  }

  Future<void> toggleSave(String postId) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    try {
      if (_savedPosts.contains(postId)) {
        // Remove save
        await _client
            .from(SupabaseConfig.userInteractionsTable)
            .delete()
            .eq('user_id', currentUser.id)
            .eq('target_id', postId)
            .eq('target_type', 'post')
            .eq('interaction_type', 'save');

        _savedPosts.remove(postId);
      } else {
        // Add save
        await _client
            .from(SupabaseConfig.userInteractionsTable)
            .upsert({
              'user_id': currentUser.id,
              'target_id': postId,
              'target_type': 'post',
              'interaction_type': 'save',
              'created_at': DateTime.now().toIso8601String(),
            });

        _savedPosts.add(postId);
      }

      notifyListeners();
    } catch (e) {
      Logger.error('Error toggling save', e);
    }
  }

  bool isLiked(String postId) {
    return _likedPosts.contains(postId);
  }

  bool isSaved(String postId) {
    return _savedPosts.contains(postId);
  }

  Future<void> _updatePostLikeCount(String postId, int increment) async {
    try {
      // Get current like count
      final postResponse = await _client
          .from(SupabaseConfig.postsTable)
          .select('like_count')
          .eq('id', postId)
          .single();

      final currentCount = (postResponse['like_count'] as int? ?? 0);
      final newCount = (currentCount + increment).clamp(0, 999999);

      // Update the like count
      await _client
          .from(SupabaseConfig.postsTable)
          .update({'like_count': newCount})
          .eq('id', postId);

      // Update local post data
      final postIndex = _posts.indexWhere((post) => post['id'] == postId);
      if (postIndex != -1) {
        _posts[postIndex]['like_count'] = newCount;
      }
    } catch (e) {
      Logger.error('Error updating post like count', e);
    }
  }

  bool isPostLiked(String postId) {
    return _likedPosts.contains(postId);
  }

  bool isPostSaved(String postId) {
    return _savedPosts.contains(postId);
  }

  int getLikeCount(String postId) {
    final post = _posts.firstWhere(
      (p) => p['id'] == postId,
      orElse: () => {'likes': 0, 'like_count': 0},
    );
    return post['likes'] ?? post['like_count'] ?? 0;
  }

  // Helper method to normalize IDs from different sources
  int _normalizeId(dynamic id) {
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    return 0;
  }

  Future<void> addPost(Map<String, dynamic> post) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = AuthService.currentUser;
      Logger.debug('TravelProvider.addPost - User: ${user?.id ?? "null"}');
      Logger.debug('TravelProvider.addPost - Post data: $post');

      // Check if this is a Supabase authenticated user
      if (user != null && user.id.isNotEmpty) {
        // Real Supabase authenticated user - save to Supabase database
        try {
          final response = await _client
              .from(SupabaseConfig.postsTable)
              .insert({
                'user_id': user.id,
                'content': post['caption'], // Map caption to content
                'location': post['location'],
                'images': post['images'], // Array of image URLs
                'like_count': 0,
                'comment_count': 0,
                'is_public': true, // Ensure posts are public
                'tags': post['budget'] != null && post['budget'].isNotEmpty
                    ? ['budget:${post['budget']}']
                    : [],
              })
              .select('''
                *,
                users!posts_user_id_fkey(
                  id,
                  username,
                  full_name,
                  avatar_url
                )
              ''');

          if (response.isNotEmpty) {
            final newPost = response.first;
            _posts.insert(0, newPost);
            Logger.info('Post added successfully to Supabase database');
          }
        } catch (e) {
          Logger.error('Error saving to Supabase, falling back to local storage', e);
          // Fall back to local storage if Supabase fails
          _addPostLocally(post);
        }
      } else {
        // Demo/local user - add to local storage
        _addPostLocally(post);
      }
    } catch (e) {
      Logger.error('Error adding post', e);
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addStory(Map<String, dynamic> story) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newStory = {
        'id': _stories.length + 1,
        'userId': 1,
        'avatar': story['avatar'],
        'hasStory': 1,
        'isAdd': 0,
        'createdAt': DateTime.now().toIso8601String(),
      };

      _stories.insert(0, newStory);
    } catch (e) {
      // Handle error
      Logger.error('Error adding story', e);
    }
    
    _isLoading = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> getDestinationsByBudget(double minBudget, double maxBudget) {
    return _destinations.where((destination) {
      final budget = double.tryParse(destination['budget'].toString().replaceAll('\$', '').replaceAll(',', '')) ?? 0;
      return budget >= minBudget && budget <= maxBudget;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> searchDestinations(String query) async {
    if (query.isEmpty) return _destinations;
    
    // Local search implementation
    return _destinations.where((destination) {
      final name = destination['name'].toString().toLowerCase();
      final location = destination['location'].toString().toLowerCase();
      final description = destination['description'].toString().toLowerCase();
      final searchQuery = query.toLowerCase();
      
      return name.contains(searchQuery) || 
             location.contains(searchQuery) || 
             description.contains(searchQuery);
    }).toList();
  }

  Map<String, dynamic>? getDestinationById(int id) {
    try {
      return _destinations.firstWhere((destination) => destination['id'] == id);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic>? getPostById(int id) {
    try {
      return _posts.firstWhere((post) => post['id'] == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshData() async {
    // Reload from database - NO sample data
    await _loadDataFromDatabase();
  }

  void _addPostLocally(Map<String, dynamic> post) {
    final localPost = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'user_id': post['user_id'],
      'content': post['caption'], // Map caption to content for consistency
      'location': post['location'],
      'images': post['images'],
      'like_count': 0,
      'comment_count': 0,
      'created_at': post['created_at'] ?? DateTime.now().toIso8601String(),
      'is_public': true,
      'tags': post['budget'] != null && post['budget'].isNotEmpty
          ? ['budget:${post['budget']}']
          : [],
      'users': {
        'id': post['user_id'],
        'username': 'demo_user',
        'full_name': 'Demo User',
        'avatar_url': null,
      }
    };

    _posts.insert(0, localPost);
    Logger.info('Post added locally successfully');
  }
}