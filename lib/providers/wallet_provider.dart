import 'package:flutter/material.dart';
import '../models/wallet.dart';
import '../services/supabase_service.dart';

class WalletProvider with ChangeNotifier {
  UserWallet? _userWallet;
  List<WalletTransaction> _transactions = [];
  List<Reward> _rewards = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  UserWallet? get userWallet => _userWallet;
  List<WalletTransaction> get transactions => _transactions;
  List<Reward> get rewards => _rewards;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed getters
  int get totalPoints => _userWallet?.totalPoints ?? 0;
  double get totalEarnings => _userWallet?.totalEarnings ?? 0.0;
  int get level => _userWallet?.level ?? 1;
  String get levelName => _userWallet?.levelName ?? 'Bronze Explorer';
  int get pointsToNextLevel => _userWallet?.pointsToNextLevel ?? 500;

  List<WalletTransaction> get pointsTransactions => 
      _transactions.where((t) => t.type == 'earned').toList();
  
  List<WalletTransaction> get earningsTransactions => 
      _transactions.where((t) => t.amount != null && t.amount! > 0).toList();
  
  List<WalletTransaction> get allHistory => _transactions;

  // Initialize wallet for user
  Future<void> initializeWallet(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      // Get or create user wallet
      _userWallet = await SupabaseService.instance.getUserWallet(userId);
      
      if (_userWallet == null) {
        // Create new wallet for user
        final success = await SupabaseService.instance.createUserWallet(userId);
        if (success) {
          _userWallet = await SupabaseService.instance.getUserWallet(userId);
        }
      }

      // Load transactions and rewards
      await Future.wait([
        loadTransactions(userId),
        loadRewards(),
      ]);
    } catch (e) {
      _error = 'Failed to initialize wallet: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Load wallet transactions
  Future<void> loadTransactions(String userId) async {
    try {
      _transactions = await SupabaseService.instance.getWalletTransactions(userId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load transactions: $e';
      notifyListeners();
    }
  }

  // Load available rewards
  Future<void> loadRewards() async {
    try {
      _rewards = await SupabaseService.instance.getAvailableRewards();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load rewards: $e';
      notifyListeners();
    }
  }

  // Award points to user
  Future<bool> awardPoints(String userId, int points, String description, {String? category, double? earnings}) async {
    _setLoading(true);
    
    try {
      final success = await SupabaseService.instance.awardPoints(
        userId, 
        points, 
        description, 
        category: category, 
        earnings: earnings,
      );
      
      if (success) {
        // Refresh wallet data
        await initializeWallet(userId);
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to award points: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Redeem reward
  Future<bool> redeemReward(String userId, Reward reward) async {
    if (totalPoints < reward.pointsCost) {
      _error = 'Insufficient points for redemption';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    
    try {
      final success = await SupabaseService.instance.redeemReward(
        userId, 
        reward.id, 
        reward.pointsCost,
      );
      
      if (success) {
        // Refresh wallet data
        await initializeWallet(userId);
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to redeem reward: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh wallet data
  Future<void> refreshWallet(String userId) async {
    await initializeWallet(userId);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Check if user can redeem a specific reward
  bool canRedeemReward(Reward reward) {
    return totalPoints >= reward.pointsCost;
  }

  // Get transactions by category
  List<WalletTransaction> getTransactionsByCategory(String category) {
    return _transactions.where((t) => t.category == category).toList();
  }

  // Get transactions by type
  List<WalletTransaction> getTransactionsByType(String type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  // Calculate progress to next level
  double get levelProgress {
    if (pointsToNextLevel <= 0) return 1.0;
    
    int currentLevelPoints = 0;
    int nextLevelPoints = 0;
    
    switch (level) {
      case 1:
        currentLevelPoints = 0;
        nextLevelPoints = 500;
        break;
      case 2:
        currentLevelPoints = 500;
        nextLevelPoints = 1500;
        break;
      case 3:
        currentLevelPoints = 1500;
        nextLevelPoints = 3000;
        break;
      default:
        return 1.0;
    }
    
    final earnedInLevel = totalPoints - currentLevelPoints;
    final totalNeededForLevel = nextLevelPoints - currentLevelPoints;
    
    return earnedInLevel / totalNeededForLevel;
  }
}