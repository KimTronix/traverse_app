import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/ui_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import 'animated_icon_widget.dart';

class CustomBottomNavigation extends StatefulWidget {
  const CustomBottomNavigation({super.key});

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiProvider = Provider.of<UIProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentIndex = uiProvider.currentBottomNavIndex;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    // Check if user is a business owner
    final isBusinessOwner = authProvider.userType == 'business';

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.borderLight,
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 40,
                    offset: const Offset(0, -8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing,
                    vertical: isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        context,
                        index: 0,
                        currentIndex: currentIndex,
                        icon: IconStandards.getNavigationIcon('explore_outlined'),
                        activeIcon: IconStandards.getNavigationIcon('explore'),
                        label: 'Explore',
                        route: '/home',
                        isSmallScreen: isSmallScreen,
                      ),
                      _buildNavItem(
                        context,
                        index: 1,
                        currentIndex: currentIndex,
                        icon: IconStandards.getNavigationIcon('plan_outlined'),
                        activeIcon: IconStandards.getNavigationIcon('plan'),
                        label: 'Plan',
                        route: '/travel-plan',
                        isSmallScreen: isSmallScreen,
                      ),
                      _buildNavItem(
                        context,
                        index: 2,
                        currentIndex: currentIndex,
                        icon: IconStandards.getNavigationIcon('chat_outlined'),
                        activeIcon: IconStandards.getNavigationIcon('chat'),
                        label: 'Chat',
                        route: '/messages',
                        isSmallScreen: isSmallScreen,
                      ),
                      // Conditional: Show Business for business owners, Wallet for others
                      _buildNavItem(
                        context,
                        index: 3,
                        currentIndex: currentIndex,
                        icon: isBusinessOwner
                            ? Icons.business_outlined
                            : IconStandards.getNavigationIcon('wallet_outlined'),
                        activeIcon: isBusinessOwner
                            ? Icons.business
                            : IconStandards.getNavigationIcon('wallet'),
                        label: isBusinessOwner ? 'Business' : 'Wallet',
                        route: isBusinessOwner ? '/business-dashboard' : '/wallet',
                        isSmallScreen: isSmallScreen,
                      ),
                      _buildNavItem(
                        context,
                        index: 4,
                        currentIndex: currentIndex,
                        icon: IconStandards.getNavigationIcon('profile_outlined'),
                        activeIcon: IconStandards.getNavigationIcon('profile'),
                        label: 'Profile',
                        route: '/profile',
                        isSmallScreen: isSmallScreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    required bool isSmallScreen,
  }) {
    final isActive = currentIndex == index;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? AppConstants.xsSpacing : AppConstants.smSpacing,
        vertical: isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing,
      ),
      child: GestureDetector(
        onTap: () {
          final uiProvider = Provider.of<UIProvider>(context, listen: false);
          uiProvider.setBottomNavIndex(index);
          context.go(route);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing,
            vertical: isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing,
          ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.mdRadius),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedIconWidget(
              icon: isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
              size: isSmallScreen ? 24 : 28,
              duration: const Duration(milliseconds: 300),
              isAnimating: isActive,
            ),
            SizedBox(height: isSmallScreen ? AppConstants.xsSpacing : AppConstants.xsSpacing),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
              ),
              child: Text(label),
            ),
          ],
        ),
        ),
      ),
    );
  }
}