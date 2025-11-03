import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/wallet.dart';
import '../utils/icon_standards.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize wallet data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated && authProvider.userData != null) {
        final userId = authProvider.userData!['id'];
        if (userId != null) {
          context.read<WalletProvider>().initializeWallet(userId);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(builder: (context, walletProvider, child) {
      final wallet = walletProvider.userWallet;
      final isLoading = walletProvider.isLoading;
      
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: Icon(IconStandards.getUIIcon('back')),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildWalletSummary(wallet, walletProvider),
                    const SizedBox(height: 20),
                    _buildLevelProgress(wallet),
                    const SizedBox(height: 20),
                    _buildWalletTabs(walletProvider),
                  ],
                ),
              ),
      );
    });
  }

  Widget _buildWalletSummary(wallet, WalletProvider walletProvider) {
    final totalPoints = wallet?.totalPoints ?? 0;
    final totalEarnings = wallet?.totalEarnings ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B73FF), Color(0xFF9B59B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Points',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    totalPoints.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Earnings',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    '\$${totalEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showEarnPointsDialog(walletProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6B73FF),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Earn Points'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showRedeemDialog(walletProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Redeem Points'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(wallet) {
    final level = wallet?.level ?? 1;
    final levelName = wallet?.levelName ?? 'Bronze Explorer';
    final pointsToNextLevel = wallet?.pointsToNextLevel ?? 500;
    final progress = context.read<WalletProvider>().levelProgress;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level - $levelName',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B73FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Level $level',
                  style: const TextStyle(
                    color: Color(0xFF6B73FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B73FF)),
          ),
          const SizedBox(height: 8),
          Text(
            '$pointsToNextLevel points to next level',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletTabs(WalletProvider walletProvider) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF6B73FF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF6B73FF),
            tabs: const [
              Tab(text: 'Points'),
              Tab(text: 'Earnings'),
              Tab(text: 'Rewards'),
              Tab(text: 'History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPointsTab(walletProvider),
                _buildEarningsTab(walletProvider),
                _buildRewardsTab(walletProvider),
                _buildHistoryTab(walletProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsTab(WalletProvider walletProvider) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Points earned through various activities'),
          SizedBox(height: 20),
          Text('• Complete bookings: +100 points'),
          Text('• Write reviews: +50 points'),
          Text('• Share experiences: +25 points'),
          Text('• Refer friends: +200 points'),
        ],
      ),
    );
  }

  Widget _buildEarningsTab(WalletProvider walletProvider) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Convert points to real money'),
          SizedBox(height: 20),
          Text('Exchange Rate: 100 points = \$1.00'),
          Text('Minimum redemption: 500 points'),
        ],
      ),
    );
  }

  Widget _buildRewardsTab(WalletProvider walletProvider) {
    final rewards = walletProvider.rewards;
    
    if (rewards.isEmpty) {
      return const Center(
        child: Text('No rewards available'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        return Card(
          child: ListTile(
            title: Text(reward.title),
            subtitle: Text(reward.description),
            trailing: Text('${reward.pointsCost} pts'),
            onTap: () => _redeemReward(walletProvider, reward),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(WalletProvider walletProvider) {
    final transactions = walletProvider.transactions;
    
    if (transactions.isEmpty) {
      return const Center(
        child: Text('No transaction history'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Card(
          child: ListTile(
            title: Text(transaction.description),
             subtitle: Text(transaction.timestamp.toString()),
            trailing: Text(
              '${transaction.points > 0 ? '+' : ''}${transaction.points} pts',
              style: TextStyle(
                color: transaction.points > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEarnPointsDialog(WalletProvider walletProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Earn Points'),
        content: const Text('Complete activities to earn points:\n\n• Book a trip: 100 points\n• Write a review: 50 points\n• Share experience: 25 points'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
               final authProvider = context.read<AuthProvider>();
               final navigator = Navigator.of(context);
               final userId = authProvider.userData?['id'];
               if (userId != null) {
                 await walletProvider.awardPoints(userId, 100, 'Demo points awarded');
               }
               navigator.pop();
             },
            child: const Text('Award Demo Points'),
          ),
        ],
      ),
    );
  }

  void _showRedeemDialog(WalletProvider walletProvider) {
    final pointsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Points'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Convert points to cash (100 points = \$1.00)'),
            const SizedBox(height: 16),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Points to redeem',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
               final points = int.tryParse(pointsController.text) ?? 0;
               final authProvider = context.read<AuthProvider>();
               final navigator = Navigator.of(context);
               if (points > 0) {
                 final userId = authProvider.userData?['id'];
                 if (userId != null) {
                   // Create a cash redemption reward
                   final cashReward = Reward(
                     id: 'cash-${DateTime.now().millisecondsSinceEpoch}',
                     title: 'Cash Redemption',
                     description: 'Convert points to cash',
                     pointsCost: points,
                     category: 'cash',
                     isActive: true,
                   );
                   await walletProvider.redeemReward(userId, cashReward);
                 }
               }
               navigator.pop();
             },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  void _redeemReward(WalletProvider walletProvider, reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem ${reward.title}?'),
        content: Text('This will cost ${reward.pointsCost} points.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
               final authProvider = context.read<AuthProvider>();
               final navigator = Navigator.of(context);
               final userId = authProvider.userData?['id'];
               if (userId != null) {
                 await walletProvider.redeemReward(userId, reward);
               }
               navigator.pop();
             },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }
}