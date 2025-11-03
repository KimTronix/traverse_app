import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/logger.dart';

class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  static StatisticsService get instance => _instance;

  final SupabaseClient _supabase = SupabaseService.instance.client;

  // Track user visits
  Future<void> trackVisit(String userId, String? location) async {
    try {
      await _supabase.from('user_visits').insert({
        'user_id': userId,
        'location': location,
        'timestamp': DateTime.now().toIso8601String(),
        'date': DateTime.now().toIso8601String().split('T')[0],
      });
    } catch (e) {
      Logger.error('Error tracking visit', e);
    }
  }

  // Track place registration
  Future<void> trackPlaceRegistration(String placeId, String placeName, String category, String location) async {
    try {
      await _supabase.from('registered_places').insert({
        'place_id': placeId,
        'name': placeName,
        'category': category,
        'location': location,
        'registered_at': DateTime.now().toIso8601String(),
        'status': 'active',
      });
    } catch (e) {
      Logger.error('Error tracking place registration', e);
    }
  }

  // Get total visits count
  Future<int> getTotalVisits() async {
    try {
      final response = await _supabase
          .from('user_visits')
          .select('id')
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      Logger.error('Error getting total visits', e);
      return 0;
    }
  }

  // Get total registered places count
  Future<int> getTotalRegisteredPlaces() async {
    try {
      final response = await _supabase
          .from('registered_places')
          .select('id')
          .eq('status', 'active')
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      Logger.error('Error getting total registered places', e);
      return 0;
    }
  }

  // Get total active users count
  Future<int> getTotalActiveUsers() async {
    try {
      final response = await _supabase
          .from('user_visits')
          .select('user_id')
          .gte('timestamp', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());
      
      final uniqueUsers = <String>{};
      for (final visit in response) {
        uniqueUsers.add(visit['user_id']);
      }
      return uniqueUsers.length;
    } catch (e) {
      Logger.error('Error getting total active users', e);
      return 0;
    }
  }

  // Get total service providers count
  Future<int> getTotalServiceProviders() async {
    try {
      final response = await _supabase
          .from('service_providers')
          .select('id')
          .eq('status', 'approved')
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      Logger.error('Error getting total service providers', e);
      return 0;
    }
  }

  // Get daily visits for the last 7 days
  Future<List<Map<String, dynamic>>> getDailyVisits() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final response = await _supabase
          .from('user_visits')
          .select('date')
          .gte('timestamp', sevenDaysAgo.toIso8601String())
          .order('date');

      final Map<String, int> dailyCounts = {};
      for (final visit in response) {
        final date = visit['date'] as String;
        dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
      }

      return dailyCounts.entries
          .map((entry) => {'date': entry.key, 'visits': entry.value})
          .toList();
    } catch (e) {
      Logger.error('Error getting daily visits', e);
      return [];
    }
  }

  // Get user growth data for the last 30 days
  Future<List<Map<String, dynamic>>> getUserGrowth() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final response = await _supabase
          .from('user_visits')
          .select('date, user_id')
          .gte('timestamp', thirtyDaysAgo.toIso8601String())
          .order('date');

      final Map<String, Set<String>> dailyUsers = {};
      for (final visit in response) {
        final date = visit['date'] as String;
        final userId = visit['user_id'] as String;
        dailyUsers[date] ??= <String>{};
        dailyUsers[date]!.add(userId);
      }

      return dailyUsers.entries
          .map((entry) => {'date': entry.key, 'users': entry.value.length})
          .toList();
    } catch (e) {
      Logger.error('Error getting user growth', e);
      return [];
    }
  }

  // Get top destinations
  Future<List<Map<String, dynamic>>> getTopDestinations() async {
    try {
      final response = await _supabase
          .from('user_visits')
          .select('location')
          .not('location', 'is', null);

      final Map<String, int> locationCounts = {};
      for (final visit in response) {
        final location = visit['location'] as String?;
        if (location != null && location.isNotEmpty) {
          locationCounts[location] = (locationCounts[location] ?? 0) + 1;
        }
      }

      final sortedLocations = locationCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedLocations
          .take(10)
          .map((entry) => {'location': entry.key, 'visits': entry.value})
          .toList();
    } catch (e) {
      Logger.error('Error getting top destinations', e);
      return [];
    }
  }

  // Get registered places by category
  Future<List<Map<String, dynamic>>> getPlacesByCategory() async {
    try {
      final response = await _supabase
          .from('registered_places')
          .select('category')
          .eq('status', 'active');

      final Map<String, int> categoryCounts = {};
      for (final place in response) {
        final category = place['category'] as String;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      return categoryCounts.entries
          .map((entry) => {'category': entry.key, 'count': entry.value})
          .toList();
    } catch (e) {
      Logger.error('Error getting places by category', e);
      return [];
    }
  }

  // Get all registered places
  Future<List<Map<String, dynamic>>> getAllRegisteredPlaces() async {
    try {
      final response = await _supabase
          .from('registered_places')
          .select('*')
          .eq('status', 'active')
          .order('registered_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error getting all registered places', e);
      return [];
    }
  }

  // Get service providers by category
  Future<List<Map<String, dynamic>>> getServiceProvidersByCategory() async {
    try {
      final response = await _supabase
          .from('service_providers')
          .select('*')
          .eq('status', 'approved')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error getting service providers', e);
      return [];
    }
  }
}