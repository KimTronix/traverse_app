import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';
import 'auth_service.dart';

class VerificationService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Check if user is verified for a specific type
  // VERIFICATION DISABLED - Always returns true
  static Future<bool> isUserVerified({
    String? userId,
    String verificationType = 'email',
  }) async {
    // Verification disabled - all users are considered verified
    return true;
  }

  // Get comprehensive verification status for user
  static Future<Map<String, dynamic>> getVerificationStatus({String? userId}) async {
    try {
      final String targetUserId = userId ?? AuthService.currentUser?.id ?? '';
      if (targetUserId.isEmpty) return {};

      final response = await _client.rpc('get_user_verification_status', params: {
        'user_uuid': targetUserId,
      });

      return Map<String, dynamic>.from(response ?? {});
    } catch (e) {
      Logger.error('Error getting verification status: $e');
      return {};
    }
  }

  // Check if user can post (verification disabled)
  static Future<bool> canUserPost({String? userId}) async {
    // Verification disabled - all users can post
    return true;
  }

  // Check if user can access AI features (verification disabled)
  static Future<bool> canUserAccessAI({String? userId}) async {
    // Verification disabled - all users can access AI
    return true;
  }

  // Check if user can save chats (verification disabled)
  static Future<bool> canUserSaveChats({String? userId}) async {
    // Verification disabled - all users can save chats
    return true;
  }

  // Request verification for a specific type
  static Future<bool> requestVerification({
    required String verificationType,
    Map<String, dynamic>? verificationData,
    List<String>? documentUrls,
  }) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final requestData = {
        'user_id': user.id,
        'request_type': verificationType,
        'status': 'pending',
        'verification_method': _getVerificationMethod(verificationType),
        'verification_data': verificationData ?? {},
        'submitted_documents': documentUrls ?? [],
        'expires_at': _getExpirationDate(verificationType),
      };

      await _client.from('verification_requests').insert(requestData);

      Logger.info('Verification request submitted for type: $verificationType');
      return true;
    } catch (e) {
      Logger.error('Error requesting verification: $e');
      return false;
    }
  }

  // Get user's verification requests
  static Future<List<Map<String, dynamic>>> getUserVerificationRequests() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('verification_requests')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error getting verification requests: $e');
      return [];
    }
  }

  // Verify user (admin function)
  static Future<bool> verifyUser({
    required String userId,
    required String verificationType,
    Map<String, dynamic>? verificationData,
  }) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        throw Exception('Admin not authenticated');
      }

      // Check if current user is admin
      if (!await AuthService.isAdmin()) {
        throw Exception('Insufficient permissions');
      }

      // Add verification level
      final verificationLevel = {
        'user_id': userId,
        'verification_type': verificationType,
        'verified_at': DateTime.now().toIso8601String(),
        'verification_data': verificationData ?? {},
      };

      await _client.from('user_verification_levels').upsert(verificationLevel);

      // Update user's is_verified status if it's email verification
      if (verificationType == 'email') {
        await _client
            .from(SupabaseConfig.usersTable)
            .update({'is_verified': true})
            .eq('id', userId);
      }

      // Update verification request status if exists
      await _client
          .from('verification_requests')
          .update({
            'status': 'approved',
            'verified_at': DateTime.now().toIso8601String(),
            'verified_by': currentUser.id,
          })
          .eq('user_id', userId)
          .eq('request_type', verificationType)
          .eq('status', 'pending');

      Logger.info('User verified successfully: $userId ($verificationType)');
      return true;
    } catch (e) {
      Logger.error('Error verifying user: $e');
      return false;
    }
  }

  // Reject verification request (admin function)
  static Future<bool> rejectVerificationRequest({
    required String requestId,
    String? adminNotes,
  }) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        throw Exception('Admin not authenticated');
      }

      // Check if current user is admin
      if (!await AuthService.isAdmin()) {
        throw Exception('Insufficient permissions');
      }

      await _client
          .from('verification_requests')
          .update({
            'status': 'rejected',
            'admin_notes': adminNotes,
            'verified_by': currentUser.id,
            'verified_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      Logger.info('Verification request rejected: $requestId');
      return true;
    } catch (e) {
      Logger.error('Error rejecting verification request: $e');
      return false;
    }
  }

  // Get all pending verification requests (admin function)
  static Future<List<Map<String, dynamic>>> getPendingVerificationRequests() async {
    try {
      // Check if current user is admin
      if (!await AuthService.isAdmin()) {
        throw Exception('Insufficient permissions');
      }

      final response = await _client
          .from('verification_requests')
          .select('''
            *,
            users!inner(
              id,
              email,
              full_name,
              username
            )
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error getting pending verification requests: $e');
      return [];
    }
  }

  // Auto-verify email for authenticated users
  static Future<bool> autoVerifyEmail() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return false;

      // Check if email is confirmed by Supabase
      if (user.emailConfirmedAt != null) {
        // Add email verification level
        final verificationLevel = {
          'user_id': user.id,
          'verification_type': 'email',
          'verified_at': user.emailConfirmedAt!,
          'verification_data': {'method': 'supabase_email_confirmation'},
        };

        await _client.from('user_verification_levels').upsert(verificationLevel);

        // Update user's is_verified status
        await _client
            .from(SupabaseConfig.usersTable)
            .update({'is_verified': true})
            .eq('id', user.id);

        Logger.info('Email auto-verified for user: ${user.id}');
        return true;
      }

      return false;
    } catch (e) {
      Logger.error('Error auto-verifying email: $e');
      return false;
    }
  }

  // Helper method to get verification method based on type
  static String _getVerificationMethod(String verificationType) {
    switch (verificationType) {
      case 'email':
        return 'email_link';
      case 'phone':
        return 'phone_sms';
      case 'identity':
      case 'business':
        return 'document_upload';
      default:
        return 'manual_review';
    }
  }

  // Helper method to get expiration date based on verification type
  static String? _getExpirationDate(String verificationType) {
    switch (verificationType) {
      case 'email':
      case 'phone':
        // Email and phone verifications expire in 24 hours
        return DateTime.now().add(Duration(hours: 24)).toIso8601String();
      default:
        // Other verifications don't expire by default
        return null;
    }
  }

  // Get verification badge/status text for UI
  static String getVerificationStatusText(Map<String, dynamic> verificationStatus) {
    if (verificationStatus.isEmpty) {
      return 'Unverified';
    }

    final types = verificationStatus.keys.toList();

    if (types.contains('premium')) {
      return 'Premium Verified';
    } else if (types.contains('business')) {
      return 'Business Verified';
    } else if (types.contains('identity')) {
      return 'Identity Verified';
    } else if (types.contains('email')) {
      return 'Email Verified';
    }

    return 'Partially Verified';
  }

  // Get verification level (for privilege checks)
  static int getVerificationLevel(Map<String, dynamic> verificationStatus) {
    if (verificationStatus.isEmpty) return 0;

    int level = 0;
    if (verificationStatus.containsKey('email')) level = 1;
    if (verificationStatus.containsKey('phone')) level = 2;
    if (verificationStatus.containsKey('identity')) level = 3;
    if (verificationStatus.containsKey('business')) level = 4;
    if (verificationStatus.containsKey('premium')) level = 5;

    return level;
  }
}