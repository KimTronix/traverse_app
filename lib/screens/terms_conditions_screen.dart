import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scrollController.addListener(() {
      final isScrolled = _scrollController.offset > 0;
      if (isScrolled != _isScrolled) {
        setState(() {
          _isScrolled = isScrolled;
        });
      }
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: _isScrolled ? 4 : 0,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            IconStandards.getUIIcon('arrow_back'),
            color: AppTheme.textPrimary,
          ),
        ),
        title: Text(
          'Terms & Conditions',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _showHelpDialog();
            },
            icon: Icon(
              IconStandards.getUIIcon('help_outline'),
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(
              isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isSmallScreen),
                SizedBox(height: AppConstants.lgSpacing),
                _buildLastUpdated(),
                SizedBox(height: AppConstants.xlSpacing),

                // App Information Section
                _buildSection(
                  'About Traverse',
                  _buildAppInfoContent(),
                  IconStandards.getUIIcon('flight'),
                  AppTheme.primaryBlue,
                ),

                // Features Section
                _buildSection(
                  'Key Features',
                  _buildFeaturesContent(),
                  IconStandards.getUIIcon('star'),
                  AppTheme.primaryOrange,
                ),

                // Technology Section
                _buildSection(
                  'Technology Stack',
                  _buildTechnologyContent(),
                  IconStandards.getUIIcon('settings'),
                  AppTheme.primaryPurple,
                ),

                // Architecture Section
                _buildSection(
                  'App Architecture',
                  _buildArchitectureContent(),
                  IconStandards.getUIIcon('account_tree'),
                  AppTheme.primaryGreen,
                ),

                // Demo Information Section
                _buildSection(
                  'Demo Mode Information',
                  _buildDemoInfoContent(),
                  IconStandards.getUIIcon('lightbulb_outlined'),
                  AppTheme.primaryOrange,
                ),

                // Contact Section
                _buildSection(
                  'Contact Information',
                  _buildContactContent(),
                  IconStandards.getUIIcon('contact_mail'),
                  AppTheme.primaryBlue,
                ),

                SizedBox(height: AppConstants.xxlSpacing),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(
        isSmallScreen ? AppConstants.lgSpacing : AppConstants.xlSpacing,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.primaryPurple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.lgRadius),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.mdSpacing),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(AppConstants.mdRadius),
            ),
            child: Icon(
              IconStandards.getUIIcon('flight'),
              color: Colors.white,
              size: isSmallScreen ? 28 : 32,
            ),
          ),
          SizedBox(width: AppConstants.mdSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: AppConstants.xsSpacing),
                Text(
                  AppConstants.appDescription,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: AppConstants.smSpacing),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.smSpacing,
                    vertical: AppConstants.xsSpacing,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.smRadius),
                  ),
                  child: Text(
                    'Version ${AppConstants.appVersion}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            IconStandards.getUIIcon('schedule'),
            color: AppTheme.primaryGreen,
            size: 20,
          ),
          SizedBox(width: AppConstants.smSpacing),
          Text(
            'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.lgSpacing),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.lgSpacing),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.lgRadius),
                topRight: Radius.circular(AppConstants.lgRadius),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.smSpacing),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppConstants.smRadius),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppConstants.mdSpacing),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.lgSpacing),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Traverse is a comprehensive Flutter travel application designed to revolutionize how people plan, share, and explore travel experiences.',
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: AppConstants.mdSpacing),
        _buildInfoItem('Platform', 'Cross-platform mobile application built with Flutter'),
        _buildInfoItem('Purpose', 'Social travel planning and experience sharing'),
        _buildInfoItem('Target Users', 'Travelers, Business Owners, Tour Guides, Administrators'),
        _buildInfoItem('Current Status', 'Demo version with comprehensive functionality'),
      ],
    );
  }

  Widget _buildFeaturesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeatureItem('Social Travel Sharing', 'Instagram-style posts and stories with likes, comments, and social interactions'),
        _buildFeatureItem('Trip Planning', 'Comprehensive destination browsing and itinerary generation'),
        _buildFeatureItem('Real-time Chat', 'Messaging system with AI-powered travel assistance'),
        _buildFeatureItem('Wallet System', 'Points, rewards, and multi-currency support'),
        _buildFeatureItem('Booking Management', 'Hotels, flights, activities, and car rental bookings'),
        _buildFeatureItem('Multi-Role Support', 'Different interfaces for travelers, businesses, guides, and admins'),
      ],
    );
  }

  Widget _buildTechnologyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTechItem('Framework', 'Flutter 3.32.7 with Dart 3.8.1'),
        _buildTechItem('State Management', 'Provider pattern for centralized state'),
        _buildTechItem('Navigation', 'GoRouter for declarative routing'),
        _buildTechItem('Database', 'Supabase PostgreSQL with real-time capabilities'),
        _buildTechItem('Authentication', 'Supabase Auth with Google OAuth integration'),
        _buildTechItem('AI Integration', 'OpenAI API for travel recommendations'),
        _buildTechItem('Design System', 'Material Design 3 with custom theming'),
        _buildTechItem('Performance', 'Comprehensive caching and optimization'),
      ],
    );
  }

  Widget _buildArchitectureContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The app follows a clean architecture pattern with clear separation of concerns:',
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: AppConstants.mdSpacing),
        _buildArchItem('Presentation Layer', '25+ screens with responsive design and custom animations'),
        _buildArchItem('Business Logic Layer', '8+ providers managing different aspects of the app'),
        _buildArchItem('Data Layer', 'Services for API communication, caching, and data persistence'),
        _buildArchItem('Database Schema', '20+ tables supporting all app functionality'),
        _buildArchItem('Real-time Features', 'WebSocket integration for live messaging and updates'),
      ],
    );
  }

  Widget _buildDemoInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.mdSpacing),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.mdRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Demo Mode Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryOrange,
                ),
              ),
              SizedBox(height: AppConstants.smSpacing),
              Text(
                'This app is currently running in demo mode with mock authentication and sample data. All features are functional for demonstration purposes.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppConstants.mdSpacing),
        Text(
          'Available Demo Accounts:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: AppConstants.smSpacing),
        _buildDemoAccount('Traveler', 'innocentmafusire@gmail.com', 'Experience sharing and trip planning'),
        _buildDemoAccount('Business Owner', 'business@demo.com', 'Manage accommodations and services'),
        _buildDemoAccount('Tour Guide', 'guide@demo.com', 'Offer guided tours and experiences'),
        _buildDemoAccount('Administrator', 'admin@demo.com', 'Platform management and oversight'),
      ],
    );
  }

  Widget _buildContactContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'For questions, feedback, or technical support regarding this demonstration application:',
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: AppConstants.mdSpacing),
        _buildContactItem(
          IconStandards.getUIIcon('email'),
          'Email',
          'info@traverse-demo.com',
          AppTheme.primaryBlue,
        ),
        _buildContactItem(
          IconStandards.getUIIcon('language'),
          'Website',
          'www.traverse-demo.com',
          AppTheme.primaryGreen,
        ),
        _buildContactItem(
          IconStandards.getUIIcon('code'),
          'Repository',
          'GitHub Repository Available',
          AppTheme.primaryPurple,
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.smSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.mdSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: AppConstants.smSpacing),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: AppConstants.xsSpacing),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechItem(String category, String technology) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.smSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$category:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryPurple,
              ),
            ),
          ),
          Expanded(
            child: Text(
              technology,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchItem(String component, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.mdSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: AppConstants.smSpacing),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: AppConstants.xsSpacing),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoAccount(String role, String email, String description) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.smSpacing),
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                role,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.smSpacing,
                  vertical: AppConstants.xsSpacing,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.smRadius),
                ),
                child: Text(
                  'demo123',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.xsSpacing),
          Text(
            email,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppConstants.xsSpacing),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.mdSpacing),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.smSpacing),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.smRadius),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(width: AppConstants.mdSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.lgSpacing),
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppConstants.lgRadius),
      ),
      child: Column(
        children: [
          Icon(
            IconStandards.getUIIcon('flight'),
            color: AppTheme.primaryBlue,
            size: 32,
          ),
          SizedBox(height: AppConstants.mdSpacing),
          Text(
            '${AppConstants.appName} v${AppConstants.appVersion}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: AppConstants.smSpacing),
          Text(
            'Demonstration Application',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: AppConstants.smSpacing),
          Text(
            '© ${DateTime.now().year} Traverse Demo. All rights reserved.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              IconStandards.getUIIcon('help'),
              color: AppTheme.primaryBlue,
            ),
            SizedBox(width: AppConstants.smSpacing),
            const Text('Help'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This page contains comprehensive information about the Traverse application, including:',
              style: TextStyle(
                height: 1.4,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: AppConstants.mdSpacing),
            _buildHelpItem('App features and capabilities'),
            _buildHelpItem('Technical architecture details'),
            _buildHelpItem('Demo account information'),
            _buildHelpItem('Technology stack overview'),
            _buildHelpItem('Contact information'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.xsSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: AppConstants.smSpacing),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}