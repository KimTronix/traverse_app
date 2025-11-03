import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/wallet.dart';

class ClaimsService {
  static final ClaimsService _instance = ClaimsService._internal();
  factory ClaimsService() => _instance;
  ClaimsService._internal();
  
  static ClaimsService get instance => _instance;

  // Get all claims by type
  Future<List<Map<String, dynamic>>> getClaimsByType(String type) async {
    try {
      final response = await SupabaseService.instance.client
          .from('claims')
          .select('''
            *,
            users!claims_user_id_fkey(name, email)
          ''')
          .eq('type', type)
          .order('created_at', ascending: false);
      
      return response.map<Map<String, dynamic>>((claim) {
        return {
          'id': claim['id'],
          'title': claim['title'],
          'description': claim['description'],
          'type': claim['type'],
          'status': claim['status'],
          'amount': claim['amount'],
          'user_id': claim['user_id'],
          'userName': claim['users']['name'] ?? 'Unknown User',
          'userEmail': claim['users']['email'] ?? '',
          'date': claim['created_at'],
          'created_at': claim['created_at'],
          'updated_at': claim['updated_at'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get claims: $e');
    }
  }

  // Get all claims
  Future<List<Map<String, dynamic>>> getAllClaims() async {
    try {
      final response = await SupabaseService.instance.client
          .from('claims')
          .select('''
            *,
            users!claims_user_id_fkey(name, email)
          ''')
          .order('created_at', ascending: false);
      
      return response.map<Map<String, dynamic>>((claim) {
        return {
          'id': claim['id'],
          'title': claim['title'],
          'description': claim['description'],
          'type': claim['type'],
          'status': claim['status'],
          'amount': claim['amount'],
          'user_id': claim['user_id'],
          'userName': claim['users']['name'] ?? 'Unknown User',
          'userEmail': claim['users']['email'] ?? '',
          'date': claim['created_at'],
          'created_at': claim['created_at'],
          'updated_at': claim['updated_at'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all claims: $e');
    }
  }

  // Search claims
  Future<List<Map<String, dynamic>>> searchClaims(String query, {String? type}) async {
    try {
      var queryBuilder = SupabaseService.instance.client
          .from('claims')
          .select('''
            *,
            users!claims_user_id_fkey(name, email)
          ''');
      
      if (type != null && type != 'all') {
        queryBuilder = queryBuilder.eq('type', type);
      }
      
      final response = await queryBuilder
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return response.map<Map<String, dynamic>>((claim) {
        return {
          'id': claim['id'],
          'title': claim['title'],
          'description': claim['description'],
          'type': claim['type'],
          'status': claim['status'],
          'amount': claim['amount'],
          'user_id': claim['user_id'],
          'userName': claim['users']['name'] ?? 'Unknown User',
          'userEmail': claim['users']['email'] ?? '',
          'date': claim['created_at'],
          'created_at': claim['created_at'],
          'updated_at': claim['updated_at'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to search claims: $e');
    }
  }

  // Update claim status
  Future<Map<String, dynamic>> updateClaimStatus(
    String claimId,
    String status, {
    String? adminNotes,
  }) async {
    try {
      final response = await SupabaseService.instance.client
          .from('claims')
          .update({
            'status': status,
            'admin_notes': adminNotes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', claimId)
          .select()
          .single();
      
      // If approved and it's a token claim, award points to user
      if (status == 'approved' && response['type'] == 'tokens') {
        await SupabaseService.instance.awardPoints(
          response['user_id'],
          response['amount'] ?? 0,
          'Claim approved: ${response['title']}',
          category: 'claim_approval',
        );
      }
      
      return response;
    } catch (e) {
      throw Exception('Failed to update claim status: $e');
    }
  }

  // Create a new claim
  Future<Map<String, dynamic>> createClaim({
    required String userId,
    required String title,
    required String description,
    required String type,
    int? amount,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await SupabaseService.instance.client
          .from('claims')
          .insert({
            'user_id': userId,
            'title': title,
            'description': description,
            'type': type,
            'amount': amount,
            'status': 'pending',
            'metadata': metadata,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Failed to create claim: $e');
    }
  }

  // Get claims statistics
  Future<Map<String, dynamic>> getClaimsStatistics() async {
    try {
      final response = await SupabaseService.instance.client
          .rpc('get_claims_statistics');
      
      return response ?? {
        'total_claims': 0,
        'pending_claims': 0,
        'approved_claims': 0,
        'rejected_claims': 0,
        'total_tokens_awarded': 0,
        'total_rewards_redeemed': 0,
      };
    } catch (e) {
      // Fallback to manual calculation if RPC doesn't exist
      return await _calculateStatisticsManually();
    }
  }

  Future<Map<String, dynamic>> _calculateStatisticsManually() async {
    try {
      final allClaims = await SupabaseService.instance.client
          .from('claims')
          .select('status, amount, type');
      
      int totalClaims = allClaims.length;
      int pendingClaims = allClaims.where((c) => c['status'] == 'pending').length;
      int approvedClaims = allClaims.where((c) => c['status'] == 'approved').length;
      int rejectedClaims = allClaims.where((c) => c['status'] == 'rejected').length;
      
      int totalTokensAwarded = allClaims
          .where((c) => c['status'] == 'approved' && c['type'] == 'tokens')
          .fold<int>(0, (sum, c) => sum + ((c['amount'] as int?) ?? 0));
      
      // Get rewards statistics
      final rewardsResponse = await SupabaseService.instance.client
          .from('wallet_transactions')
          .select('points')
          .eq('type', 'redeemed');
      
      int totalRewardsRedeemed = rewardsResponse
          .fold<int>(0, (sum, t) => sum + ((t['points'] as int?)?.abs() ?? 0));
      
      return {
        'total_claims': totalClaims,
        'pending_claims': pendingClaims,
        'approved_claims': approvedClaims,
        'rejected_claims': rejectedClaims,
        'total_tokens_awarded': totalTokensAwarded,
        'total_rewards_redeemed': totalRewardsRedeemed,
      };
    } catch (e) {
      return {
        'total_claims': 0,
        'pending_claims': 0,
        'approved_claims': 0,
        'rejected_claims': 0,
        'total_tokens_awarded': 0,
        'total_rewards_redeemed': 0,
      };
    }
  }

  // Get available reward types
  List<String> getClaimTypes() {
    return ['tokens', 'awards', 'rewards'];
  }

  // Get status display names
  Map<String, String> getStatusDisplayNames() {
    return {
      'pending': 'Pending Review',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'processing': 'Processing',
    };
  }

  // Get status colors
  Map<String, Color> getStatusColors() {
    return {
      'pending': const Color(0xFFFF9800), // Orange
      'approved': const Color(0xFF4CAF50), // Green
      'rejected': const Color(0xFFF44336), // Red
      'processing': const Color(0xFF2196F3), // Blue
    };
  }

  // Delete claim
  Future<void> deleteClaim(String claimId) async {
    try {
      await SupabaseService.instance.client
          .from('claims')
          .delete()
          .eq('id', claimId);
    } catch (e) {
      throw Exception('Failed to delete claim: $e');
    }
  }

  // Get rewards management data
  Future<List<Reward>> getAllRewards() async {
    try {
      final response = await SupabaseService.instance.client
          .from('rewards')
          .select()
          .order('points_cost', ascending: true);
      
      return response.map<Reward>((json) => Reward.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get rewards: $e');
    }
  }

  // Create new reward
  Future<Reward> createReward({
    required String title,
    required String description,
    required int pointsCost,
    required String category,
    DateTime? expiryDate,
    bool isActive = true,
  }) async {
    try {
      final response = await SupabaseService.instance.client
          .from('rewards')
          .insert({
            'title': title,
            'description': description,
            'points_cost': pointsCost,
            'category': category,
            'expiry_date': expiryDate?.toIso8601String(),
            'is_active': isActive,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      return Reward.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create reward: $e');
    }
  }

  // Update reward
  Future<Reward> updateReward(
    String rewardId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await SupabaseService.instance.client
          .from('rewards')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', rewardId)
          .select()
          .single();
      
      return Reward.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update reward: $e');
    }
  }

  // Delete reward
  Future<void> deleteReward(String rewardId) async {
    try {
      await SupabaseService.instance.client
          .from('rewards')
          .delete()
          .eq('id', rewardId);
    } catch (e) {
      throw Exception('Failed to delete reward: $e');
    }
  }
}