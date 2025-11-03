import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import 'supabase_service.dart';

class AIDataService {
  static AIDataService? _instance;
  static AIDataService get instance => _instance ??= AIDataService._();
  
  AIDataService._();
  
  final SupabaseService _supabaseService = SupabaseService.instance;

  /// Analyze user query to determine if database lookup is needed
  bool requiresDataLookup(String query) {
    final keywords = [
      // Location-based queries
      'event', 'events', 'happening', 'activities', 'things to do',
      'places', 'attractions', 'destinations', 'hotels', 'restaurants',
      'bookings', 'reservations', 'availability', 'accommodation',
      
      // Location indicators
      'in harare', 'in zimbabwe', 'in cape town', 'in johannesburg',
      'near me', 'around', 'nearby', 'close to',
      
      // Time-based queries
      'next', 'upcoming', 'this weekend', 'today', 'tomorrow',
      'this week', 'next month', 'soon',
      
      // Recommendation queries
      'recommendations', 'suggest', 'best', 'top', 'popular',
      'where to', 'what to', 'how to get to',
      
      // Booking and travel queries
      'book', 'reserve', 'plan', 'trip', 'travel', 'visit',
      'stay', 'eat', 'drink', 'shop', 'explore',
      
      // User-specific queries
      'my bookings', 'my trips', 'my reservations', 'my plans'
    ];

    final queryLower = query.toLowerCase();
    return keywords.any((keyword) => queryLower.contains(keyword));
  }

  /// Extract location from user query using regex patterns
  String? extractLocation(String query) {
    final locationPatterns = [
      r'in\s+([A-Za-z\s]+?)(?:\s|$|,|\?|!)',
      r'at\s+([A-Za-z\s]+?)(?:\s|$|,|\?|!)',
      r'near\s+([A-Za-z\s]+?)(?:\s|$|,|\?|!)',
      r'around\s+([A-Za-z\s]+?)(?:\s|$|,|\?|!)',
    ];

    for (final pattern in locationPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(query);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  /// Get upcoming events with location filtering
  Future<List<Map<String, dynamic>>> getUpcomingEvents({String? location}) async {
    try {
      if (location != null) {
        final response = await _supabaseService.client
            .from('events')
            .select('*')
            .gte('date', DateTime.now().toIso8601String())
            .or('location.ilike.%$location%,name.ilike.%$location%')
            .order('date', ascending: true)
            .limit(10);
        return List<Map<String, dynamic>>.from(response);
      }

      final response = await _supabaseService.client
          .from('events')
          .select('*')
          .gte('date', DateTime.now().toIso8601String())
          .order('date', ascending: true)
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching upcoming events: $e');
      return [];
    }
  }

  /// Get destinations by location
  Future<List<Map<String, dynamic>>> getDestinations({String? location}) async {
    try {
      if (location != null) {
        final response = await _supabaseService.client
            .from('destinations')
            .select('''
              id, name, description, location, country, city,
              latitude, longitude, category, rating, review_count,
              price_range, best_time_to_visit, images, amenities
            ''')
            .or('location.ilike.%$location%,city.ilike.%$location%,country.ilike.%$location%')
            .order('rating', ascending: false)
            .limit(10);
        return List<Map<String, dynamic>>.from(response);
      }

      final response = await _supabaseService.client
          .from('destinations')
          .select('''
            id, name, description, location, country, city,
            latitude, longitude, category, rating, review_count,
            price_range, best_time_to_visit, images, amenities
          ''')
          .order('rating', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching destinations', e);
      return [];
    }
  }

  /// Get recent posts for social context
  Future<List<Map<String, dynamic>>> getRecentPosts({String? location, int limit = 5}) async {
    try {
      if (location != null) {
        final response = await _supabaseService.client
            .from('posts')
            .select('''
              id, title, content, location, like_count,
              comment_count, created_at,
              users!inner(full_name, username)
            ''')
            .eq('is_public', true)
            .ilike('location', '%$location%')
            .order('created_at', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      }

      final response = await _supabaseService.client
          .from('posts')
          .select('''
            id, title, content, location, like_count,
            comment_count, created_at,
            users!inner(full_name, username)
          ''')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching recent posts', e);
      return [];
    }
  }

  /// Get user bookings for personalized responses
  Future<List<Map<String, dynamic>>> getUserBookings(String userId, {bool upcomingOnly = true}) async {
    try {
      var query = _supabaseService.client
          .from('bookings')
          .select('''
            id, booking_type, title, description, start_date,
            end_date, location, price, currency, status
          ''')
          .eq('user_id', userId)
          .eq('status', 'confirmed');

      if (upcomingOnly) {
        query = query.gte('start_date', DateTime.now().toIso8601String());
      }

      final response = await query.order('start_date', ascending: true).limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching user bookings', e);
      return [];
    }
  }

  /// Generate enhanced context string for AI from database data
  Future<String> generateContextString(String userQuery, {String? userId}) async {
    final context = StringBuffer();
    final location = extractLocation(userQuery);
    final queryLower = userQuery.toLowerCase();

    // Add query analysis context
    context.writeln('User Query Analysis:');
    context.writeln('- Query: "$userQuery"');
    if (location != null) {
      context.writeln('- Detected Location: $location');
    }
    context.writeln('- Query Type: ${_analyzeQueryType(queryLower)}');
    context.writeln();

    // Get relevant data based on query
    final futures = <Future<dynamic>>[
      getUpcomingEvents(location: location),
      getDestinations(location: location),
      getRecentPosts(location: location),
    ];

    // Add user bookings if userId is provided
    if (userId != null) {
      futures.add(getUserBookings(userId));
    }

    try {
      final results = await Future.wait(futures);
      final events = results[0] as List<Map<String, dynamic>>;
      final destinations = results[1] as List<Map<String, dynamic>>;
      final posts = results[2] as List<Map<String, dynamic>>;
      final bookings = userId != null ? results[3] as List<Map<String, dynamic>> : <Map<String, dynamic>>[];

      // Add events context with priority based on query
      if (events.isNotEmpty && (queryLower.contains('event') || queryLower.contains('happening') || queryLower.contains('activities'))) {
        context.writeln('🎉 RELEVANT EVENTS:');
        for (final event in events.take(3)) {
          context.writeln('- ${event['name']} at ${event['location']} on ${event['date']}');
          if (event['description'] != null) {
            context.writeln('  Description: ${event['description']}');
          }
        }
        context.writeln();
      }

      // Add destinations context
      if (destinations.isNotEmpty) {
        context.writeln('🏞️ DESTINATIONS:');
        for (final dest in destinations.take(3)) {
          context.writeln('- ${dest['name']} in ${dest['location']} (Rating: ${dest['rating']}/5)');
          if (dest['description'] != null) {
            context.writeln('  ${dest['description']}');
          }
        }
        context.writeln();
      }

      // Add social context from recent posts
      if (posts.isNotEmpty && (queryLower.contains('recommend') || queryLower.contains('suggest') || queryLower.contains('popular'))) {
        context.writeln('💬 COMMUNITY INSIGHTS:');
        for (final post in posts.take(2)) {
          final user = post['users'] as Map<String, dynamic>?;
          final userName = user?['full_name'] ?? user?['username'] ?? 'Anonymous';
          context.writeln('- $userName shared: "${post['title']}" (${post['like_count']} likes)');
          if (post['location'] != null) {
            context.writeln('  Location: ${post['location']}');
          }
        }
        context.writeln();
      }

      // Add personalized booking context
      if (bookings.isNotEmpty) {
        context.writeln('📅 YOUR BOOKINGS:');
        for (final booking in bookings.take(3)) {
          context.writeln('- ${booking['title']} in ${booking['location']} on ${booking['start_date']}');
          context.writeln('  Status: ${booking['status']}, Type: ${booking['booking_type']}');
        }
        context.writeln();
      }

      // Add contextual recommendations based on query intent
      if (queryLower.contains('budget') || queryLower.contains('cheap') || queryLower.contains('affordable')) {
        context.writeln('💰 BUDGET CONSIDERATIONS: Focus on cost-effective options and value for money.');
      }
      
      if (queryLower.contains('luxury') || queryLower.contains('premium') || queryLower.contains('high-end')) {
        context.writeln('✨ LUXURY FOCUS: Emphasize premium experiences and high-quality services.');
      }

      if (queryLower.contains('family') || queryLower.contains('kids') || queryLower.contains('children')) {
        context.writeln('👨‍👩‍👧‍👦 FAMILY-FRIENDLY: Prioritize family-suitable activities and accommodations.');
      }

    } catch (e) {
      Logger.error('Error generating context string: $e');
      context.writeln('Note: Some contextual data may be limited due to connectivity issues.');
    }

    final contextString = context.toString();
    Logger.debug('Generated context string length: ${contextString.length}');
    return contextString;
  }

  /// Analyze query type for better context generation
  String _analyzeQueryType(String queryLower) {
    if (queryLower.contains('event') || queryLower.contains('happening')) return 'Event Search';
    if (queryLower.contains('hotel') || queryLower.contains('accommodation')) return 'Accommodation Search';
    if (queryLower.contains('restaurant') || queryLower.contains('food')) return 'Dining Search';
    if (queryLower.contains('attraction') || queryLower.contains('places')) return 'Attraction Search';
    if (queryLower.contains('booking') || queryLower.contains('reserve')) return 'Booking Inquiry';
    if (queryLower.contains('recommend') || queryLower.contains('suggest')) return 'Recommendation Request';
    if (queryLower.contains('plan') || queryLower.contains('itinerary')) return 'Trip Planning';
    return 'General Travel Query';
  }

  /// Get query-specific data based on keywords
  Future<List<Map<String, dynamic>>> getQuerySpecificData(String query, {String? userId}) async {
    final queryLower = query.toLowerCase();
    
    try {
      // Event-specific queries
      if (queryLower.contains('event') || queryLower.contains('happening')) {
        final location = extractLocation(query);
        return await getUpcomingEvents(location: location);
      }
      
      // Restaurant queries
      if (queryLower.contains('restaurant') || queryLower.contains('food') || queryLower.contains('eat')) {
        final response = await _supabaseService.client
            .from('attractions')
            .select('*')
            .eq('category', 'restaurant')
            .eq('status', 'active')
            .order('rating', ascending: false)
            .limit(10);
        return List<Map<String, dynamic>>.from(response);
      }
      
      // Hotel queries
      if (queryLower.contains('hotel') || queryLower.contains('accommodation') || queryLower.contains('stay')) {
        final response = await _supabaseService.client
            .from('attractions')
            .select('*')
            .eq('category', 'hotel')
            .eq('status', 'active')
            .order('rating', ascending: false)
            .limit(10);
        return List<Map<String, dynamic>>.from(response);
      }
      
      // User booking queries
      if (queryLower.contains('booking') && userId != null) {
        return await getUserBookings(userId);
      }
      
      // Default to general destinations
      final location = extractLocation(query);
      return await getDestinations(location: location);
      
    } catch (e) {
      Logger.error('Error getting query-specific data: $e');
      return [];
    }
  }
}