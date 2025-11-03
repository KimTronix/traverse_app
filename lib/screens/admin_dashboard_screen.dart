import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

import '../widgets/animated_icon_widget.dart';
import '../widgets/loading_animation.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _cardsAnimationController;
  late AnimationController _statsAnimationController;

  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _cardsScaleAnimation;
  late Animation<double> _statsCounterAnimation;

  bool _isLoading = true;

  // Demo data - replace with real data from your services
  final Map<String, dynamic> _dashboardStats = {
    'totalUsers': 12450,
    'activeUsers': 8234,
    'totalPosts': 34567,
    'totalRevenue': 145780.50,
    'todaySignups': 23,
    'todayBookings': 45,
    'pendingClaims': 12,
    'systemStatus': 'Operational',
  };

  final List<Map<String, dynamic>> _recentActivities = [
    {
      'type': 'user_signup',
      'title': 'New user registered',
      'subtitle': 'sarah@example.com joined as traveler',
      'time': '2 min ago',
      'icon': Icons.person_add,
      'color': AppTheme.primaryGreen,
    },
    {
      'type': 'business_claim',
      'title': 'Business claim submitted',
      'subtitle': 'Tokyo Ramen House - verification needed',
      'time': '15 min ago',
      'icon': Icons.business,
      'color': AppTheme.primaryOrange,
    },
    {
      'type': 'payment',
      'title': 'Payment received',
      'subtitle': '\$125.00 from booking #BK-4521',
      'time': '32 min ago',
      'icon': Icons.payments,
      'color': AppTheme.primaryBlue,
    },
    {
      'type': 'review',
      'title': 'New review posted',
      'subtitle': '5-star review for Santorini Sunset Hotel',
      'time': '1 hour ago',
      'icon': Icons.star,
      'color': AppTheme.primaryPurple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));

    _cardsScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardsAnimationController,
      curve: Curves.elasticOut,
    ));

    _statsCounterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsAnimationController,
      curve: Curves.easeOutQuart,
    ));
  }

  Future<void> _loadDashboardData() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() => _isLoading = false);
      _headerAnimationController.forward();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _cardsAnimationController.forward();
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _statsAnimationController.forward();
      });
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardsAnimationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    final authProvider = Provider.of<AuthProvider>(context);

    return SlideTransition(
      position: _headerSlideAnimation,
      child: FadeTransition(
        opacity: _headerFadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(AppConstants.lgSpacing),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue,
                AppTheme.primaryPurple,
                AppTheme.primaryBlue.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(AppConstants.xlRadius),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.mdSpacing),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppConstants.lgRadius),
                    ),
                    child: AnimatedIconWidget(
                      icon: Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppConstants.lgSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mission Control',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppConstants.smSpacing),
                        Text(
                          'Welcome back, ${authProvider.userData?['full_name'] ?? 'Admin'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.mdSpacing,
                      vertical: AppConstants.smSpacing,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppConstants.lgRadius),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppConstants.smSpacing),
                        Text(
                          _dashboardStats['systemStatus'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppConstants.smSpacing),
                  // Logout Button
                  PopupMenuButton<String>(
                    offset: const Offset(0, 40),
                    icon: Container(
                      padding: const EdgeInsets.all(AppConstants.smSpacing),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings, size: 18),
                            SizedBox(width: 8),
                            Text('Settings'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18, color: AppTheme.primaryRed),
                            SizedBox(width: 8),
                            Text('Logout', style: TextStyle(color: AppTheme.primaryRed)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'logout') {
                        _showLogoutDialog();
                      } else if (value == 'settings') {
                        // Handle settings navigation
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Admin settings coming soon!')),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.lgSpacing),
              Text(
                'Real-time system overview and management',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(
          child: LoadingAnimation(
            size: 60,
            message: 'Loading dashboard...',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Sign out functionality
              final authProvider = context.read<AuthProvider>();
              authProvider.signOut();
              context.go('/');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.lgSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppConstants.xlSpacing),
              _buildStatsGrid(),
              const SizedBox(height: AppConstants.xlSpacing),
              _buildQuickActions(),
              const SizedBox(height: AppConstants.xlSpacing),
              _buildRecentActivity(),
              const SizedBox(height: AppConstants.xlSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {
        'title': 'Total Users',
        'value': _dashboardStats['totalUsers'],
        'change': '+12.5%',
        'isPositive': true,
        'icon': Icons.group,
        'gradient': [AppTheme.primaryBlue, AppTheme.primaryBlue.withValues(alpha: 0.7)],
      },
      {
        'title': 'Active Today',
        'value': _dashboardStats['activeUsers'],
        'change': '+8.2%',
        'isPositive': true,
        'icon': Icons.trending_up,
        'gradient': [AppTheme.primaryGreen, AppTheme.primaryGreen.withValues(alpha: 0.7)],
      },
      {
        'title': 'Total Posts',
        'value': _dashboardStats['totalPosts'],
        'change': '+15.8%',
        'isPositive': true,
        'icon': Icons.photo_library,
        'gradient': [AppTheme.primaryPurple, AppTheme.primaryPurple.withValues(alpha: 0.7)],
      },
      {
        'title': 'Revenue',
        'value': '\$${((_dashboardStats['totalRevenue'] ?? 0) / 1000).toStringAsFixed(1)}K',
        'change': '+22.1%',
        'isPositive': true,
        'icon': Icons.attach_money,
        'gradient': [AppTheme.primaryOrange, AppTheme.primaryOrange.withValues(alpha: 0.7)],
      },
    ];

    return ScaleTransition(
      scale: _cardsScaleAnimation,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppConstants.lgSpacing,
          mainAxisSpacing: AppConstants.lgSpacing,
          childAspectRatio: 1.6,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return _buildStatCard(stat, index);
        },
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, int index) {
    return AnimatedBuilder(
      animation: _statsCounterAnimation,
      builder: (context, child) {
        double animatedValue = 0;
        String displayValue = stat['value'].toString();

        if (stat['value'] is int) {
          animatedValue = (stat['value'] as int) * _statsCounterAnimation.value;
          displayValue = animatedValue.toInt().toString();
        } else {
          displayValue = stat['value'];
        }

        return Container(
          padding: const EdgeInsets.all(AppConstants.lgSpacing),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: stat['gradient'],
            ),
            borderRadius: BorderRadius.circular(AppConstants.xlRadius),
            boxShadow: [
              BoxShadow(
                color: stat['gradient'][0].withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.smSpacing),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                    ),
                    child: Icon(
                      stat['icon'],
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.smSpacing,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: stat['isPositive']
                          ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                          : AppTheme.primaryRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppConstants.smRadius),
                    ),
                    child: Text(
                      stat['change'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppConstants.smSpacing),
              Text(
                stat['title'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'title': 'User Management',
        'subtitle': 'Manage users and roles',
        'icon': Icons.people,
        'route': '/admin/users',
        'color': AppTheme.primaryBlue,
      },
      {
        'title': 'Content Review',
        'subtitle': 'Review posts and reports',
        'icon': Icons.rate_review,
        'route': '/admin/content',
        'color': AppTheme.primaryPurple,
      },
      {
        'title': 'Business Claims',
        'subtitle': '${_dashboardStats['pendingClaims'] ?? 0} pending',
        'icon': Icons.business_center,
        'route': '/admin/claims',
        'color': AppTheme.primaryOrange,
      },
      {
        'title': 'Analytics',
        'subtitle': 'View detailed reports',
        'icon': Icons.analytics,
        'route': '/admin/analytics',
        'color': AppTheme.primaryGreen,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.lgSpacing),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppConstants.mdSpacing,
            mainAxisSpacing: AppConstants.mdSpacing,
            childAspectRatio: 1.2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(action, index);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, action['route']);
      },
      child: Container(
        padding: const EdgeInsets.all(AppConstants.lgSpacing),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.lgRadius),
          border: Border.all(
            color: action['color'].withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: action['color'].withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.mdSpacing),
              decoration: BoxDecoration(
                color: action['color'].withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.mdRadius),
              ),
              child: Icon(
                action['icon'],
                color: action['color'],
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              action['title'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.smSpacing),
            Text(
              action['subtitle'],
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin/activities');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.lgSpacing),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.lgRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentActivities.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final activity = _recentActivities[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppConstants.smSpacing),
                  decoration: BoxDecoration(
                    color: activity['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.smRadius),
                  ),
                  child: Icon(
                    activity['icon'],
                    color: activity['color'],
                    size: 20,
                  ),
                ),
                title: Text(
                  activity['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  activity['subtitle'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                trailing: Text(
                  activity['time'],
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from the admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final router = GoRouter.of(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              navigator.pop();
              await authProvider.signOut();
              if (mounted) {
                router.go('/');
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.primaryRed),
            ),
          ),
        ],
      ),
    );
  }
}