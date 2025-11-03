import '../services/supabase_service.dart';
import '../utils/logger.dart';

class TestData {
  static final SupabaseService _supabaseService = SupabaseService.instance;

  static Future<void> createTestUsers() async {
    final testUsers = [
      {
        'id': 'test_user_alice',
        'username': 'alice_travels',
        'full_name': 'Alice Johnson',
        'email': 'alice@traverse.app',
        'bio': 'Adventure seeker and travel photographer 📸',
        'location': 'San Francisco, CA',
        'role': 'traveler',
        'is_verified': true,
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      },
      {
        'id': 'test_user_bob',
        'username': 'bob_explorer',
        'full_name': 'Bob Smith',
        'email': 'bob@traverse.app',
        'bio': 'Mountain climber and nature lover 🏔️',
        'location': 'Denver, CO',
        'role': 'traveler',
        'is_verified': true,
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 25)).toIso8601String(),
      },
      {
        'id': 'test_user_sarah',
        'username': 'sarah_wanderlust',
        'full_name': 'Sarah Chen',
        'email': 'sarah@traverse.app',
        'bio': 'Digital nomad exploring the world 🌍',
        'location': 'Bali, Indonesia',
        'role': 'traveler',
        'is_verified': false,
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      },
      {
        'id': 'test_user_mike',
        'username': 'mike_backpacker',
        'full_name': 'Mike Rodriguez',
        'email': 'mike@traverse.app',
        'bio': 'Backpacking through Europe 🎒',
        'location': 'Barcelona, Spain',
        'role': 'traveler',
        'is_verified': true,
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      },
      {
        'id': 'test_user_emma',
        'username': 'emma_foodie',
        'full_name': 'Emma Wilson',
        'email': 'emma@traverse.app',
        'bio': 'Food blogger and culinary traveler 🍜',
        'location': 'Tokyo, Japan',
        'role': 'traveler',
        'is_verified': false,
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      },
      {
        'id': 'test_user_david',
        'username': 'david_guide',
        'full_name': 'David Thompson',
        'email': 'david@traverse.app',
        'bio': 'Professional tour guide in Thailand 🏛️',
        'location': 'Bangkok, Thailand',
        'role': 'guide',
        'is_verified': true,
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
      },
    ];

    for (final user in testUsers) {
      try {
        // Check if user already exists
        final existingUser = await _supabaseService.getUserById(user['id'] as String);
        if (existingUser == null) {
          await _supabaseService.insertUser(user);
          Logger.info('Created test user: ${user['username']}');
        } else {
          Logger.debug('Test user already exists: ${user['username']}');
        }
      } catch (e) {
        Logger.error('Failed to create test user ${user['username']}: $e');
      }
    }
  }

  static Future<void> initializeTestData() async {
    Logger.info('Initializing test data...');

    try {
      await createTestUsers();
      Logger.info('Test data initialization completed');
    } catch (e) {
      Logger.error('Failed to initialize test data: $e');
    }
  }
}