import 'dart:convert';
import '../utils/logger.dart';
import 'supabase_service.dart';

class TripPlanningService {
  static final TripPlanningService _instance = TripPlanningService._internal();
  factory TripPlanningService() => _instance;
  TripPlanningService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;

  /// Extracts trip details from a post to create a similar trip plan
  Future<Map<String, dynamic>> extractTripDetailsFromPost(Map<String, dynamic> post) async {
    try {
      Logger.info('Extracting trip details from post: ${post['id']}');

      // Extract basic information
      final location = post['location'] as String? ?? '';
      final caption = (post['caption'] ?? post['content']) as String? ?? '';
      final budget = _extractBudgetFromPost(post);
      final tags = _extractTagsFromPost(post);
      final images = _extractImagesFromPost(post);
      
      // Analyze caption for activities and preferences
      final activities = _extractActivitiesFromCaption(caption);
      final duration = _extractDurationFromCaption(caption);
      final travelStyle = _extractTravelStyleFromTags(tags);
      
      // Get related attractions and destinations
      final relatedAttractions = await _getRelatedAttractions(location, tags);
      final accommodationSuggestions = await _getAccommodationSuggestions(location, budget);
      
      // Build trip plan structure
      final tripPlan = {
        'source_post_id': post['id'],
        'destination': location,
        'budget_range': budget,
        'duration': duration,
        'travel_style': travelStyle,
        'activities': activities,
        'tags': tags,
        'images': images,
        'suggested_attractions': relatedAttractions,
        'accommodation_suggestions': accommodationSuggestions,
        'inspiration_caption': caption,
        'created_at': DateTime.now().toIso8601String(),
      };

      Logger.info('Successfully extracted trip details for destination: $location');
      return tripPlan;
    } catch (e) {
      Logger.error('Error extracting trip details from post: $e');
      return _getDefaultTripPlan(post);
    }
  }

  /// Extracts budget information from post
  String _extractBudgetFromPost(Map<String, dynamic> post) {
    // Check tags for budget information
    final tags = post['tags'] as List<dynamic>?;
    if (tags != null) {
      for (final tag in tags) {
        final tagStr = tag.toString().toLowerCase();
        if (tagStr.contains('budget:')) {
          return tagStr.substring(tagStr.indexOf('budget:') + 7).trim();
        }
        if (tagStr.contains('luxury')) return 'Luxury';
        if (tagStr.contains('budget')) return 'Budget';
        if (tagStr.contains('mid-range')) return 'Mid-range';
      }
    }

    // Check direct budget field
    final budget = post['budget'] as String?;
    if (budget != null && budget.isNotEmpty) {
      return budget;
    }

    return 'Mid-range';
  }

  /// Extracts tags from post
  List<String> _extractTagsFromPost(Map<String, dynamic> post) {
    final tags = post['tags'] as List<dynamic>?;
    if (tags != null) {
      return tags.map((tag) => tag.toString()).toList();
    }
    return [];
  }

  /// Extracts images from post
  List<String> _extractImagesFromPost(Map<String, dynamic> post) {
    final images = post['images'] as List<dynamic>?;
    if (images != null) {
      return images.map((img) => img.toString()).toList();
    }
    
    // Fallback to single image
    final image = post['image'] as String?;
    if (image != null) {
      return [image];
    }
    
    return [];
  }

  /// Analyzes caption to extract activities
  List<String> _extractActivitiesFromCaption(String caption) {
    final activities = <String>[];
    final lowerCaption = caption.toLowerCase();

    // Activity keywords mapping
    final activityKeywords = {
      'hiking': ['hiking', 'trekking', 'walking', 'trail'],
      'beach': ['beach', 'swimming', 'surfing', 'snorkeling'],
      'cultural': ['museum', 'temple', 'church', 'cultural', 'history', 'heritage'],
      'adventure': ['adventure', 'climbing', 'zip-line', 'bungee', 'skydiving'],
      'food': ['food', 'restaurant', 'cuisine', 'eating', 'dining', 'taste'],
      'shopping': ['shopping', 'market', 'bazaar', 'souvenir'],
      'nightlife': ['nightlife', 'bar', 'club', 'party'],
      'nature': ['nature', 'wildlife', 'safari', 'park', 'forest'],
      'photography': ['photo', 'photography', 'instagram', 'scenic'],
      'relaxation': ['relax', 'spa', 'wellness', 'peaceful', 'quiet'],
    };

    for (final entry in activityKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerCaption.contains(keyword)) {
          activities.add(entry.key);
          break;
        }
      }
    }

    return activities.isEmpty ? ['sightseeing'] : activities;
  }

  /// Extracts duration from caption
  String _extractDurationFromCaption(String caption) {
    final lowerCaption = caption.toLowerCase();
    
    // Look for duration patterns
    final durationPatterns = [
      RegExp(r'(\d+)\s*days?'),
      RegExp(r'(\d+)\s*weeks?'),
      RegExp(r'weekend'),
      RegExp(r'day\s*trip'),
    ];

    for (final pattern in durationPatterns) {
      final match = pattern.firstMatch(lowerCaption);
      if (match != null) {
        if (pattern.pattern.contains('weekend')) return '2-3 days';
        if (pattern.pattern.contains('day trip')) return '1 day';
        if (pattern.pattern.contains('weeks')) {
          final weeks = int.tryParse(match.group(1) ?? '1') ?? 1;
          return '${weeks * 7} days';
        }
        return '${match.group(1)} days';
      }
    }

    return '3-5 days'; // Default duration
  }

  /// Extracts travel style from tags
  String _extractTravelStyleFromTags(List<String> tags) {
    final lowerTags = tags.map((tag) => tag.toLowerCase()).toList();
    
    if (lowerTags.any((tag) => tag.contains('luxury') || tag.contains('premium'))) {
      return 'Luxury';
    }
    if (lowerTags.any((tag) => tag.contains('budget') || tag.contains('backpack'))) {
      return 'Budget';
    }
    if (lowerTags.any((tag) => tag.contains('family') || tag.contains('kids'))) {
      return 'Family';
    }
    if (lowerTags.any((tag) => tag.contains('adventure') || tag.contains('extreme'))) {
      return 'Adventure';
    }
    if (lowerTags.any((tag) => tag.contains('romantic') || tag.contains('couple'))) {
      return 'Romantic';
    }
    
    return 'Casual';
  }

  /// Gets related attractions based on location and tags
  Future<List<Map<String, dynamic>>> _getRelatedAttractions(String location, List<String> tags) async {
    try {
      if (location.isEmpty) return [];

      final query = _supabaseService.client
          .from('attractions')
          .select('*')
          .or('location.ilike.%$location%,name.ilike.%$location%')
          .limit(10);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching related attractions: $e');
      return [];
    }
  }

  /// Gets accommodation suggestions based on location and budget
  Future<List<Map<String, dynamic>>> _getAccommodationSuggestions(String location, String budget) async {
    try {
      if (location.isEmpty) return [];

      final query = _supabaseService.client
          .from('accommodations')
          .select('*')
          .or('location.ilike.%$location%,city.ilike.%$location%')
          .limit(8);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching accommodation suggestions: $e');
      return [];
    }
  }

  /// Returns a default trip plan when extraction fails
  Map<String, dynamic> _getDefaultTripPlan(Map<String, dynamic> post) {
    return {
      'source_post_id': post['id'],
      'destination': post['location'] ?? 'Unknown Destination',
      'budget_range': 'Mid-range',
      'duration': '3-5 days',
      'travel_style': 'Casual',
      'activities': ['sightseeing'],
      'tags': [],
      'images': [],
      'suggested_attractions': [],
      'accommodation_suggestions': [],
      'inspiration_caption': post['caption'] ?? post['content'] ?? '',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Saves a trip plan to the database
  Future<Map<String, dynamic>?> saveTripPlan(Map<String, dynamic> tripPlan, String userId) async {
    try {
      final planData = {
        ...tripPlan,
        'user_id': userId,
        'status': 'draft',
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from('trip_plans')
          .insert(planData)
          .select()
          .single();

      Logger.info('Trip plan saved successfully: ${response['id']}');
      return response;
    } catch (e) {
      Logger.error('Error saving trip plan: $e');
      return null;
    }
  }

  /// Get all trip plans for a user
  Future<List<Map<String, dynamic>>> getUserTripPlans(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('trip_plans')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching user trip plans: $e');
      return [];
    }
  }

  /// Get posts by destination/location
  Future<List<Map<String, dynamic>>> getPostsByDestination(String destination) async {
    try {
      if (destination.isEmpty) return [];

      final response = await _supabaseService.client
          .from('posts')
          .select('*')
          .or('location.ilike.%$destination%,caption.ilike.%$destination%,tags.cs.{$destination}')
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching posts by destination: $e');
      return [];
    }
  }

  /// Delete a trip plan
  Future<bool> deleteTripPlan(String planId) async {
    try {
      await _supabaseService.client
          .from('trip_plans')
          .delete()
          .eq('id', planId);

      Logger.info('Trip plan deleted successfully: $planId');
      return true;
    } catch (e) {
      Logger.error('Error deleting trip plan: $e');
      return false;
    }
  }
}