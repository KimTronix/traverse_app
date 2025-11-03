import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Supabase project credentials from environment
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // Database table names
  static const String usersTable = 'users';
  static const String destinationsTable = 'destinations';
  static const String postsTable = 'posts';
  static const String storiesTable = 'stories';
  static const String bookingsTable = 'bookings';
  static const String userInteractionsTable = 'user_interactions';
  static const String conversationsTable = 'conversations';
  static const String messagesTable = 'messages';
  static const String commentsTable = 'comments';
  static const String reviewsTable = 'reviews';

  // New tables from enhanced schema
  static const String attractionsTable = 'attractions';
  static const String businessClaimsTable = 'business_claims';
  static const String tourGuideProfilesTable = 'tour_guide_profiles';
  static const String adminActivitiesTable = 'admin_activities';
  static const String notificationsTable = 'notifications';
  static const String systemSettingsTable = 'system_settings';
  static const String userWalletsTable = 'user_wallets';
  static const String walletTransactionsTable = 'wallet_transactions';
  static const String rewardsTable = 'rewards';
  static const String userRewardRedemptionsTable = 'user_reward_redemptions';

  // Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String postsBucket = 'posts';
  static const String storiesBucket = 'stories';
  
  // Real-time channels
  static const String postsChannel = 'posts_channel';
  static const String storiesChannel = 'stories_channel';
  static const String messagesChannel = 'messages_channel';
}