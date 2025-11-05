import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  String _selectedUserType = 'traveler';
  late AnimationController _heroAnimationController;
  late AnimationController _featureAnimationController;
  late AnimationController _formAnimationController;
  late Animation<double> _heroSlideAnimation;
  late Animation<double> _heroFadeAnimation;
  late Animation<double> _formSlideAnimation;
  late Animation<double> _formScaleAnimation;

  @override
  void initState() {
    super.initState();

    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _featureAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _heroSlideAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _heroAnimationController,
      curve: Curves.easeOutBack,
    ));

    _heroFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroAnimationController,
      curve: Curves.easeOut,
    ));

    _formSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _formScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.elasticOut,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    _heroAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _featureAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _formAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _featureAnimationController.dispose();
    _formAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEBF4FF),
              Color(0xFFE0E7FF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),
                    SizedBox(height: isSmallScreen ? AppConstants.lgSpacing : AppConstants.xlSpacing),
                    
                    // Hero Section
                    _buildHeroSection(isSmallScreen),
                    SizedBox(height: isSmallScreen ? AppConstants.lgSpacing : AppConstants.xlSpacing),
                    
                    // Features Grid
                    _buildFeaturesGrid(isSmallScreen),
                    SizedBox(height: isSmallScreen ? AppConstants.lgSpacing : AppConstants.xlSpacing),
                    
                    // Real Authentication Options
                    _buildRealAuthOptions(isSmallScreen),
                    SizedBox(height: AppConstants.lgSpacing),

                  

                    SizedBox(height: AppConstants.lgSpacing),

                    // Terms & Conditions Button
                    _buildTermsButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(0.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 30, 64, 175),
            borderRadius: BorderRadius.circular(AppConstants.xxlRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.xxlRadius),
            child: Image.asset(
              'assets/icons/logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: AppConstants.smSpacing),
        Expanded(
          child: Text(
            AppConstants.appName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan, Share, and Explore\nthe World Together',
          style: TextStyle(
            fontSize: isSmallScreen ? 28 : 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppConstants.mdSpacing),
        Text(
          'Connect with fellow travelers, plan amazing trips, and discover hidden gems around the globe.',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(bool isSmallScreen) {
    final features = [
      {
        'icon': IconStandards.getUIIcon('planning'),
        'title': 'Travel Planning',
        'subtitle': 'Smart itineraries',
        'color': AppTheme.primaryBlue,
        'route': '/travel-plan',
      },
      {
        'icon': IconStandards.getUIIcon('group'),
        'title': 'Group Travel',
        'subtitle': 'Plan together',
        'color': AppTheme.primaryGreen,
        'route': '/home',
      },
      {
        'icon': IconStandards.getUIIcon('account_balance_wallet'),
        'title': 'In-App Wallet',
        'subtitle': 'Multi-currency',
        'color': AppTheme.primaryPurple,
        'route': '/wallet',
      },
      {
        'icon': IconStandards.getUIIcon('camera'),
        'title': 'Share Stories',
        'subtitle': 'Inspire others',
        'color': AppTheme.primaryOrange,
        'route': '/home',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : 2,
        crossAxisSpacing: AppConstants.mdSpacing,
        mainAxisSpacing: AppConstants.mdSpacing,
        childAspectRatio: isSmallScreen ? 2.2 : 2.5,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return GestureDetector(
          onTap: () => context.go(feature['route'] as String),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.mdSpacing),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.lgRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.smSpacing),
                  decoration: BoxDecoration(
                    color: feature['color'] as Color,
                    borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: Colors.white,
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                const SizedBox(width: AppConstants.smSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        feature['subtitle'] as String,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: isSmallScreen ? 11 : 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRealAuthOptions(bool isSmallScreen) {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.smSpacing),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.smRadius),
                  ),
                  child: Icon(
                    IconStandards.getUIIcon('person_outlined'),
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.smSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Your Account',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Join the community and start your journey',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.lgSpacing),

            // Auth Buttons
            Column(
              children: [
                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Create Account',
                    onPressed: () => context.go('/signup'),
                    style: CustomButtonStyle.primary,
                    icon: IconStandards.getUIIcon('person_add_outlined'),
                  ),
                ),
                SizedBox(height: AppConstants.mdSpacing),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Sign In',
                    onPressed: () => context.go('/signin'),
                    style: CustomButtonStyle.secondary,
                    icon: IconStandards.getUIIcon('login_outlined'),
                  ),
                ),

                SizedBox(height: AppConstants.smSpacing),

                // Admin Access Button
                // SizedBox(
                //   width: double.infinity,
                //   child: CustomButton(
                //     text: 'Admin Access',
                //     onPressed: () => context.go('/admin-login'),
                //     style: CustomButtonStyle.outline,
                //     icon: Icons.admin_panel_settings_outlined,
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.mdSpacing),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.mdSpacing,
              vertical: AppConstants.smSpacing,
            ),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(AppConstants.lgRadius),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Text(
              'OR TRY DEMO',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildDemoAuthForm(AuthProvider authProvider, bool isSmallScreen) {
    final selectedUser = AppConstants.userTypes.firstWhere(
      (user) => user['value'] == _selectedUserType,
    );

    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.smSpacing),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.smRadius),
                  ),
                  child: Icon(
                    IconStandards.getUIIcon('lightbulb_outlined'),
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.smSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Try Demo Mode',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Explore the platform with demo accounts',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
            
            // User Type Selection
            _buildUserTypeSelector(),
            const SizedBox(height: AppConstants.mdSpacing),
            
            Text(
              selectedUser['description'] as String,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: isSmallScreen ? 11 : 12,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
            const Divider(),
            SizedBox(height: isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
            
            // Demo Credentials
            _buildDemoCredentials(selectedUser, isSmallScreen),
            SizedBox(height: isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
            
            // Sign In Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: authProvider.isLoading ? null : () async {
                  await authProvider.signInAsDemo(_selectedUserType);
                  if (mounted) {
                    context.go(authProvider.getHomeRoute());
                  }
                },
                child: authProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Sign In as ${selectedUser['label']}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.mdSpacing),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUserType,
          isExpanded: true,
          icon: Icon(IconStandards.getUIIcon('arrow_down')),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedUserType = value;
              });
            }
          },
          items: AppConstants.userTypes.map((user) {
            return DropdownMenuItem<String>(
              value: user['value'] as String,
              child: Row(
                children: [
                  Icon(
                    _getIconData(user['icon'] as String),
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppConstants.smSpacing),
                  Expanded(
                    child: Text(
                      user['label'] as String,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDemoCredentials(Map<String, dynamic> selectedUser, bool isSmallScreen) {
    final credentials = selectedUser['credentials'] as Map<String, dynamic>;
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demo Credentials:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 11 : 12,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.smSpacing),
          Text(
            'Email: ${credentials['email']}',
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            'Password: ${credentials['password']}',
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLogin(bool isSmallScreen) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.mdSpacing),
              child: Text(
                'Or continue with',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: isSmallScreen ? 11 : 12,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppConstants.lgSpacing),
        // Always use horizontal layout for social buttons
        Row(
          children: [
            Expanded(child: _buildSocialButton('Google', IconStandards.getSocialMediaIcon('google'))),
            SizedBox(width: isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
            Expanded(child: _buildSocialButton('Facebook', IconStandards.getSocialMediaIcon('facebook'))),
            SizedBox(width: isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
            Expanded(child: _buildSocialButton('Twitter', IconStandards.getSocialMediaIcon('twitter'))),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(String label, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () async {
        if (label == 'Google') {
          // Handle Google Sign-In
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          try {
            await authProvider.signInWithGoogle();
            if (authProvider.isAuthenticated && mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Google Sign-In failed: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          // Show a demo message for other social logins
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label login is not available in demo mode'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.mdSpacing,
          horizontal: AppConstants.smSpacing,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        ),
        side: BorderSide(
          color: AppTheme.borderLight,
          width: 1,
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'camera':
  return IconStandards.getUIIcon('camera');
      case 'briefcase':
  return IconStandards.getUIIcon('business');
      case 'star':
  return IconStandards.getUIIcon('star');
      case 'shield':
  return IconStandards.getUIIcon('security');
      default:
  return IconStandards.getUIIcon('person');
    }
  }

  Widget _buildTermsButton() {
    return Center(
      child: TextButton(
        onPressed: () => context.go('/terms-conditions'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.mdSpacing,
            vertical: AppConstants.smSpacing,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.mdRadius),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconStandards.getUIIcon('article'),
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: AppConstants.smSpacing),
            Text(
              'T&Cs',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}