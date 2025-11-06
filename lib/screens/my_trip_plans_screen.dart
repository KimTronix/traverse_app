import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/trip_planning_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/bottom_navigation.dart';

class MyTripPlansScreen extends StatefulWidget {
  const MyTripPlansScreen({super.key});

  @override
  State<MyTripPlansScreen> createState() => _MyTripPlansScreenState();
}

class _MyTripPlansScreenState extends State<MyTripPlansScreen> {
  final TripPlanningService _tripService = TripPlanningService();
  List<Map<String, dynamic>> _tripPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTripPlans();
  }

  Future<void> _loadTripPlans() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userData?['id'];

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final plans = await _tripService.getUserTripPlans(userId);
      setState(() {
        _tripPlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTripPlan(String planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip Plan'),
        content: const Text('Are you sure you want to delete this trip plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _tripService.deleteTripPlan(planId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip plan deleted successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        _loadTripPlans();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'My Trip Plans',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(IconStandards.getUIIcon('add')),
            onPressed: () => context.go('/travel-plan'),
            tooltip: 'Create New Plan',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tripPlans.isEmpty
              ? _buildEmptyState(isSmallScreen)
              : _buildTripPlansList(isSmallScreen),
      bottomNavigationBar: const CustomBottomNavigation(),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.xlSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconStandards.getUIIcon('explore'),
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppConstants.lgSpacing),
            Text(
              'No Trip Plans Yet',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.smSpacing),
            Text(
              'Start planning your next adventure!',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.xlSpacing),
            ElevatedButton.icon(
              onPressed: () => context.go('/travel-plan'),
              icon: Icon(IconStandards.getUIIcon('add')),
              label: const Text('Create Trip Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? AppConstants.lgSpacing : AppConstants.xlSpacing,
                  vertical: AppConstants.mdSpacing,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripPlansList(bool isSmallScreen) {
    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
      itemCount: _tripPlans.length,
      itemBuilder: (context, index) {
        final plan = _tripPlans[index];
        return _buildTripPlanCard(plan, isSmallScreen);
      },
    );
  }

  Widget _buildTripPlanCard(Map<String, dynamic> plan, bool isSmallScreen) {
    final destination = plan['destination'] ?? 'Unknown Destination';
    final duration = plan['duration'] ?? '3-5 days';
    final budget = plan['budget_range'] ?? 'Medium';
    final activities = plan['activities'] as List? ?? [];
    final createdAt = DateTime.tryParse(plan['created_at'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.mdSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.mdSpacing),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.mdRadius),
                topRight: Radius.circular(AppConstants.mdRadius),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  IconStandards.getUIIcon('place'),
                  color: AppTheme.primaryBlue,
                  size: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: AppConstants.smSpacing),
                Expanded(
                  child: Text(
                    destination,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    IconStandards.getUIIcon('delete'),
                    color: AppTheme.primaryRed,
                    size: isSmallScreen ? 20 : 22,
                  ),
                  onPressed: () => _deleteTripPlan(plan['id']),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppConstants.mdSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Duration & Budget
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        IconStandards.getUIIcon('calendar'),
                        duration,
                        isSmallScreen,
                      ),
                    ),
                    const SizedBox(width: AppConstants.smSpacing),
                    Expanded(
                      child: _buildInfoChip(
                        IconStandards.getUIIcon('attach_money'),
                        budget,
                        isSmallScreen,
                      ),
                    ),
                  ],
                ),

                if (activities.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.mdSpacing),
                  Text(
                    'Activities',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smSpacing),
                  Wrap(
                    spacing: AppConstants.smSpacing,
                    runSpacing: AppConstants.smSpacing,
                    children: activities.take(5).map((activity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.smSpacing,
                          vertical: AppConstants.xsSpacing,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(AppConstants.smRadius),
                        ),
                        child: Text(
                          activity.toString(),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: AppConstants.mdSpacing),
                Text(
                  'Created ${_formatDate(createdAt)}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: AppConstants.mdSpacing),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to related posts
                    context.go('/trip-posts/${Uri.encodeComponent(destination)}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text('View Related Posts'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.smSpacing),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(AppConstants.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 16 : 18, color: AppTheme.textSecondary),
          const SizedBox(width: AppConstants.xsSpacing),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
