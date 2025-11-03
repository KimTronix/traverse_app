class WalletTransaction {
  final String id;
  final String userId;
  final String type; // 'earned' or 'redeemed'
  final String description;
  final int points;
  final double? amount; // For earnings in money
  final DateTime timestamp;
  final String? category; // 'tour_guide', 'referral', 'review', 'booking', etc.

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.points,
    this.amount,
    required this.timestamp,
    this.category,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      description: json['description'],
      points: json['points'],
      amount: json['amount']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'description': description,
      'points': points,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
    };
  }
}

class UserWallet {
  final String userId;
  final int totalPoints;
  final double totalEarnings;
  final int level;
  final String levelName;
  final int pointsToNextLevel;
  final DateTime lastUpdated;

  UserWallet({
    required this.userId,
    required this.totalPoints,
    required this.totalEarnings,
    required this.level,
    required this.levelName,
    required this.pointsToNextLevel,
    required this.lastUpdated,
  });

  factory UserWallet.fromJson(Map<String, dynamic> json) {
    return UserWallet(
      userId: json['user_id'],
      totalPoints: json['total_points'],
      totalEarnings: json['total_earnings']?.toDouble() ?? 0.0,
      level: json['level'],
      levelName: json['level_name'],
      pointsToNextLevel: json['points_to_next_level'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_points': totalPoints,
      'total_earnings': totalEarnings,
      'level': level,
      'level_name': levelName,
      'points_to_next_level': pointsToNextLevel,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String category;
  final bool isActive;
  final DateTime? expiryDate;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.category,
    required this.isActive,
    this.expiryDate,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      pointsCost: json['points_cost'],
      category: json['category'],
      isActive: json['is_active'],
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points_cost': pointsCost,
      'category': category,
      'is_active': isActive,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }
}