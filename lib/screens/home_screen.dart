import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/travel_provider.dart';
import '../services/navigation_service.dart';
import '../services/trip_planning_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/story_widget.dart';
import '../widgets/story_detail_popup.dart';
import '../widgets/post_widget.dart';
import '../widgets/place_detail_popup.dart';
import '../widgets/animated_fab.dart';
import '../widgets/comments_dialog.dart';
import '../widgets/tai_chat_bubble.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _headerAnimationController;
  late AnimationController _storyAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _fabScaleAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void dispose() {
    _searchController.dispose();
    _headerAnimationController.dispose();
    _storyAnimationController.dispose();
    _fabAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _storyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    ));

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _scrollController.addListener(_onScroll);

    _startAnimations();
  }

  void _startAnimations() {
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _storyAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _fabAnimationController.forward();
    });
  }

  void _onScroll() {
    final isScrolled = _scrollController.offset > 0;
    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final travelProvider = Provider.of<TravelProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header - doesn't scroll
            AnimatedBuilder(
              animation: _headerAnimationController,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _headerSlideAnimation.value),
                child: FadeTransition(
                  opacity: _headerFadeAnimation,
                  child: _buildHeader(authProvider, isSmallScreen),
                ),
              ),
            ),

            // Scrollable content
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Animated Stories
                  SliverToBoxAdapter(
                    child: AnimatedBuilder(
                      animation: _storyAnimationController,
                      builder: (context, child) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(-1.0, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _storyAnimationController,
                          curve: Curves.easeOutCubic,
                        )),
                        child: _buildStories(travelProvider, isSmallScreen),
                      ),
                    ),
                  ),

                  // Animated Places Section
                  SliverToBoxAdapter(
                    child: AnimatedBuilder(
                      animation: _storyAnimationController,
                      builder: (context, child) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _storyAnimationController,
                          curve: Curves.easeOutCubic,
                        )),
                        child: _buildPlacesSection(travelProvider, isSmallScreen),
                      ),
                    ),
                  ),

                  // Animated Posts by Others Section
                  SliverToBoxAdapter(
                    child: AnimatedBuilder(
                      animation: _storyAnimationController,
                      builder: (context, child) => FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _storyAnimationController,
                          curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                        ),
                        child: _buildPostsByOthersSection(travelProvider, isSmallScreen),
                      ),
                    ),
                  ),

                  // Posts By Others Section Header
                  SliverToBoxAdapter(
                    child: AnimatedBuilder(
                      animation: _storyAnimationController,
                      builder: (context, child) => FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _storyAnimationController,
                          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing,
                            vertical: AppConstants.smSpacing,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Posts By Others',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 20 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/explore'),
                                child: Text(
                                  'View All',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Posts Feed
                  _buildAnimatedPostsFeed(travelProvider, isSmallScreen),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          // TAI Chat Bubble - positioned above the create post FAB
          Positioned(
            bottom: 80,
            right: 0,
            child: const TAIChatBubble(),
          ),
          // Create Post FAB - at the bottom
          Positioned(
            bottom: 0,
            right: 0,
            child: AnimatedFAB(
              onPressed: () => NavigationService.navigateToCreatePost(context),
              icon: IconStandards.getActionIcon('add'),
              tooltip: 'Create Post',
              isScrolled: _isScrolled,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigation(),
    );
  }

  Widget _buildHeader(AuthProvider authProvider, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // App Logo and Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(0.0),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(AppConstants.xxlRadius),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.xxlRadius),
                  child: Image.asset(
                    'assets/icons/logo.png',
                    width: isSmallScreen ? 32 : 32,
                    height: isSmallScreen ? 32 : 32,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.smSpacing),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Search Bar (hidden on small screens)
          if (!isSmallScreen)
            Container(
              width: 250,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search destinations...',
                  prefixIcon: Icon(IconStandards.getActionIcon('search'), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: AppConstants.mdSpacing),
                ),
              ),
            ),
          
          if (!isSmallScreen) const SizedBox(width: AppConstants.smSpacing),
          
          // Notifications
          CustomIconButton(
            onPressed: () => NavigationService.navigateToNotifications(context),
            icon: IconStandards.getActionIcon('notifications'),
            size: isSmallScreen ? 20 : 24,
          ),

          const SizedBox(width: AppConstants.smSpacing),

          // AI Chat - Enhanced button
          Container(
            
            child: CustomIconButton(
              onPressed: () => context.go('/traverse-ai'),
              icon: Icons.psychology,
              size: isSmallScreen ? 20 : 24,
              color: AppTheme.primaryBlue,
            ),
          ),

          const SizedBox(width: AppConstants.smSpacing),

          // Wallet
          CustomIconButton(
            onPressed: () => NavigationService.navigateToWallet(context),
            icon: IconStandards.getUIIcon('wallet_outlined'),
            size: isSmallScreen ? 20 : 24,
          ),
          
          const SizedBox(width: AppConstants.smSpacing),
          
          // User Avatar
          _buildUserAvatar(authProvider, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(AuthProvider authProvider, bool isSmallScreen) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      child: CircleAvatar(
        radius: isSmallScreen ? 14 : 16,
        backgroundColor: AppTheme.primaryBlue,
        backgroundImage: authProvider.userData?['avatar'] != null
            ? AssetImage(authProvider.userData!['avatar'] as String)
            : null,
        child: authProvider.userData?['avatar'] == null
            ? Text(
                (authProvider.userData?['name'] as String?)?.substring(0, 2).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(IconStandards.getUIIcon('person_outline'), size: 20),
              const SizedBox(width: AppConstants.smSpacing),
              const Text('View Profile'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'wallet',
          child: Row(
            children: [
              Icon(IconStandards.getUIIcon('wallet_outlined'), size: 20),
              const SizedBox(width: AppConstants.smSpacing),
              const Text('Wallet'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(IconStandards.getUIIcon('logout'), size: 20, color: AppTheme.primaryRed),
              SizedBox(width: 8),
              Text('Logout', style: TextStyle(color: AppTheme.primaryRed)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'profile':
            NavigationService.navigateToProfile(context);
            break;
          case 'wallet':
            NavigationService.navigateToWallet(context);
            break;
          case 'logout':
            _showLogoutDialog(authProvider);
            break;
        }
      },
    );
  }

  Widget _buildMyStoryWidget(TravelProvider travelProvider, bool isSmallScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 375;
    final cardWidth = isVerySmallScreen ? 100.0 : 120.0;
    final cardMargin = isVerySmallScreen ? 8.0 : 12.0;
    final borderRadius = isVerySmallScreen ? 12.0 : 16.0;
    final profileSize = isVerySmallScreen ? 28.0 : 32.0;
    final padding = isVerySmallScreen ? 8.0 : 12.0;
    final fontSize = isVerySmallScreen ? 10.0 : 12.0;
    
    // Calculate dotted border based on user's posts count
    final postsCount = travelProvider.posts.length;
    final segments = postsCount > 0 ? postsCount : 1;
    
    return GestureDetector(
      onTap: () {
        // Handle My Story tap - could open camera or story creation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add to your story')),
        );
      },
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.only(right: cardMargin),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.1),
          Colors.black.withValues(alpha: 0.6),
            ],
          ),
          image: const DecorationImage(
            image: AssetImage('assets/images/travel-app-mockup.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black26,
              BlendMode.darken,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CustomPaint(
          painter: DottedBorderPainter(
            segments: segments,
            color: AppTheme.primaryBlue,
            strokeWidth: 3,
            borderRadius: borderRadius,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture with add icon
                  Container(
                    width: profileSize,
                    height: profileSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/travel-app-mockup.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        IconStandards.getUIIcon('add'),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // "My Story" label
                  Text(
                    'My Story',
                    style: TextStyle(
                      fontSize: fontSize,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlacesSection(TravelProvider travelProvider, bool isSmallScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 375;
    final cardHeight = isVerySmallScreen ? 200.0 : 240.0;
    final verticalPadding = isVerySmallScreen ? 12.0 : 16.0;

    // Filter destinations to exclude events (only show places)
    final places = travelProvider.destinations.where((dest) =>
      dest['category']?.toString().toLowerCase() != 'event'
    ).toList();

    return Container(
      height: cardHeight + (verticalPadding * 2),
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Places to Visit',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.go('/explore?filter=places');
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing,
              ),
              itemCount: places.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final destination = places[index];
                return _buildPlaceCard(destination, isSmallScreen);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> destination, bool isSmallScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 375;
    final cardWidth = isVerySmallScreen ? 160.0 : 200.0;
    final cardMargin = isVerySmallScreen ? 8.0 : 12.0;
    final borderRadius = isVerySmallScreen ? 12.0 : 16.0;
    final padding = isVerySmallScreen ? 12.0 : 16.0;
    
    // Create multiple images for each place
    final List<String> placeImages = [
      destination['image'] as String? ?? 'assets/images/travel-app-mockup.png',
      'assets/images/treehouse-waterfall.png',
      'assets/images/meerkat-safari.png',
    ];
    
    return GestureDetector(
      onTap: () {
        _showPlaceDetailPopup(destination, placeImages);
      },
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.only(right: cardMargin),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              // Background image with PageView for multiple images
              SizedBox(
                height: double.infinity,
                child: PageView.builder(
                  itemCount: placeImages.length,
                  itemBuilder: (context, imageIndex) {
                    return Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(placeImages[imageIndex]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        destination['name'] as String? ?? 'Unknown Place',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        destination['location'] as String? ?? 'Unknown Location',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 12 : 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            IconStandards.getUIIcon('star'),
                            color: Colors.amber,
                            size: isVerySmallScreen ? 14 : 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${destination['rating'] ?? 4.5}',
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 12 : 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${placeImages.length} pics',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 10 : 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlaceDetailPopup(Map<String, dynamic> destination, List<String> images) {
    showDialog(
      context: context,
      builder: (context) => PlaceDetailPopup(
        destination: destination,
        images: images,
      ),
    );
  }

  Widget _buildStories(TravelProvider travelProvider, bool isSmallScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 375;
    final storyHeight = isVerySmallScreen ? 140.0 : (isSmallScreen ? 160.0 : 180.0);
    final verticalPadding = isVerySmallScreen ? 8.0 : (isSmallScreen ? 12.0 : 16.0);
    
    return Container(
      height: storyHeight,
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderLight,
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
        itemCount: travelProvider.stories.length + 1, // +1 for My Story
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          if (index == 0) {
            // My Story card as first item
            return _buildMyStoryWidget(travelProvider, isSmallScreen);
          }
          
          final story = travelProvider.stories[index - 1]; // Adjust index for stories
          return StoryWidget(
            story: story,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => StoryDetailPopup(story: story),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPostsByOthersSection(TravelProvider travelProvider, bool isSmallScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 375;
    final verticalPadding = isVerySmallScreen ? 8.0 : 12.0;

    // Filter destinations to get only events (category='event')
    final events = travelProvider.destinations.where((dest) =>
      dest['category']?.toString().toLowerCase() == 'event'
    ).toList();

    // Sort events by created_at (newest first)
    events.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.go('/explore?filter=events');
                  },
                  child: Text(
                    'View All Events',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          events.isEmpty
              ? Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Text(
                    'No events available',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                )
              : SizedBox(
                  height: 300, // Fixed height to prevent overflow
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing,
                    ),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        child: _buildEventCard(event, isSmallScreen),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, bool isSmallScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 375;
    final cardHeight = isVerySmallScreen ? 200.0 : 240.0;
    final borderRadius = isVerySmallScreen ? 12.0 : 16.0;
    final padding = isVerySmallScreen ? 12.0 : 16.0;

    // Get images from event (attractions have images array)
    final List<String> eventImages = event['images'] != null && (event['images'] as List).isNotEmpty
        ? List<String>.from(event['images'])
        : [
            event['image'] as String? ?? 'assets/images/travel-app-mockup.png',
            'assets/images/treehouse-waterfall.png',
            'assets/images/meerkat-safari.png',
          ];

    final user = event['users']; // From join with users table
    final userName = user?['full_name'] ?? user?['username'] ?? 'Event Organizer';
    final userAvatar = user?['avatar_url'] ?? 'assets/images/travel-app-mockup.png';

    return GestureDetector(
      onTap: () {
        _showPlaceDetailPopup(event, eventImages);
      },
      child: Container(
        height: cardHeight,
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              // Background image with PageView for multiple images
              SizedBox(
                height: double.infinity,
                child: PageView.builder(
                  itemCount: eventImages.length,
                  itemBuilder: (context, imageIndex) {
                    return Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(eventImages[imageIndex]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              
              // User avatar at top
              Positioned(
                top: padding,
                left: padding,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    image: DecorationImage(
                      image: AssetImage(userAvatar),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              
              // Engagement metrics at top right
              Positioned(
                top: padding,
                right: padding,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rating
                      Icon(
                        IconStandards.getUIIcon('star'),
                        color: Colors.amber,
                        size: 12,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${event['rating'] ?? 0.0}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      // Reviews
                      Icon(
                        IconStandards.getUIIcon('comment'),
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${event['review_count'] ?? 0}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Content at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Event name
                      Text(
                        event['name'] as String? ?? 'Unknown Event',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      // Location
                      Text(
                        event['location'] as String? ?? 'Unknown Location',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 12 : 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      // Entry fee and date
                      Row(
                        children: [
                          if (event['entry_fee'] != null)
                            Text(
                              '${event['currency'] ?? 'USD'} ${event['entry_fee']}',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 11 : 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              'Free Entry',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 11 : 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          Spacer(),
                          Text(
                            _formatEventDate(event['created_at']),
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 10 : 11,
                              color: Colors.white.withValues(alpha: 0.8),
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      // Description preview
                      Text(
                        event['description'] as String? ?? '',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 10 : 11,
                          color: Colors.white.withValues(alpha: 0.9),
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Image count indicator
              Positioned(
                bottom: padding,
                right: padding,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${eventImages.length} pics',
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 9 : 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostDetailPopup(Map<String, dynamic> post, List<String> images) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage(
                        (post['user'] ?? post['users'])?['avatar'] ?? 
                        (post['user'] ?? post['users'])?['avatar_url'] ?? 
                        'assets/images/travel-app-mockup.png'
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (post['user'] ?? post['users'])?['name'] ?? 
                            (post['user'] ?? post['users'])?['full_name'] ?? 
                            'Unknown User',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            post['location'] as String? ?? 'Unknown Location',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Images
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: AssetImage(images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Budget: ${post['budget'] ?? 'N/A'}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        Spacer(),
                        Text(
                          post['timeAgo'] as String? ?? '1d',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      post['caption'] as String? ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          IconStandards.getUIIcon('heart'),
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text('${post['likes'] ?? 0} likes'),
                        SizedBox(width: 16),
                        Icon(
                          IconStandards.getUIIcon('comment'),
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text('${post['comments'] ?? 0} comments'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedPostsFeed(TravelProvider travelProvider, bool isSmallScreen) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final post = travelProvider.posts[index];
          return AnimatedBuilder(
            animation: _storyAnimationController,
            builder: (context, child) {
              final delayFactor = (index * 0.1).clamp(0.0, 1.0);
              final animation = CurvedAnimation(
                parent: _storyAnimationController,
                curve: Interval(
                  delayFactor,
                  (delayFactor + 0.5).clamp(0.0, 1.0),
                  curve: Curves.easeOutBack,
                ),
              );

              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(
                  opacity: animation,
                  child: Container(
                    margin: EdgeInsets.only(
                      bottom: isSmallScreen ? 12 : 16,
                      left: isSmallScreen ? 12 : 16,
                      right: isSmallScreen ? 12 : 16,
                    ),
                    child: PostWidget(
                      post: post,
                      isLiked: travelProvider.isLiked(_getPostId(post)),
                      isSaved: travelProvider.isSaved(_getPostId(post)),
                      onLike: () => travelProvider.toggleLike(_getPostId(post)),
                      onSave: () => travelProvider.toggleSave(_getPostId(post)),
                      onComment: () {
                        showDialog(
                          context: context,
                          builder: (context) => CommentsDialog(
                            postId: _getPostId(post),
                            postTitle: post['caption'] ?? post['content'] ?? 'Post',
                          ),
                        );
                      },
                      onShare: () => _sharePost(post),
                      onPlanTrip: () => _planSimilarTrip(post),
                      onTap: () => _showPostDetailDialog(context, post, travelProvider),
                    ),
                  ),
                ),
              );
            },
          );
        },
        childCount: travelProvider.posts.length,
      ),
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close dialog
              Navigator.of(context).pop();
              await authProvider.signOut();
              if (mounted) {
                // Use GoRouter navigation (app uses GoRouter / MaterialApp.router)
                context.go('/');
              }
            },
            child: const Text('Logout', style: TextStyle(color: AppTheme.primaryRed)),
          ),
        ],
      ),
    );
  }

  String _getPostId(Map<String, dynamic> post) {
    final id = post['id'];
    if (id is String) return id;
    if (id is int) return id.toString();
    return '0';
  }

  void _sharePost(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Share via Message'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening messages...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.more_horiz),
              title: const Text('More Options'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('More sharing options...')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showPostDetailDialog(BuildContext context, Map<String, dynamic> post, TravelProvider travelProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Post Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Post Content
              Expanded(
                child: SingleChildScrollView(
                  child: PostWidget(
                    post: post,
                    isLiked: travelProvider.isLiked(_getPostId(post)),
                    isSaved: travelProvider.isSaved(_getPostId(post)),
                    onLike: () => travelProvider.toggleLike(_getPostId(post)),
                    onSave: () => travelProvider.toggleSave(_getPostId(post)),
                    onComment: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => CommentsDialog(
                          postId: _getPostId(post),
                          postTitle: post['caption'] ?? post['content'] ?? 'Post',
                        ),
                      );
                    },
                    onShare: () {
                      Navigator.pop(context);
                      _sharePost(post);
                    },
                    onPlanTrip: () {
                      Navigator.pop(context);
                      _planSimilarTrip(post);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _planSimilarTrip(Map<String, dynamic> post) async {
    try {
      // Use the trip planning service to extract trip details from the post
      final tripPlanningService = TripPlanningService();
      final suggestedTrip = await tripPlanningService.extractTripDetailsFromPost(post);

      // Navigate to travel plan screen with the suggested trip data
      if (mounted) {
        NavigationService.navigateToTravelPlanWithSuggestion(context, suggestedTrip);
      }
    } catch (e) {
      // If extraction fails, navigate to regular travel plan screen
      if (mounted) {
        NavigationService.navigateToTravelPlan(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to extract trip details. Starting with a blank plan.'),
          ),
        );
      }
    }
  }

  String _formatEventDate(dynamic dateString) {
    if (dateString == null) return 'Recently';

    try {
      final date = DateTime.parse(dateString.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()}w ago';
      } else if (difference.inDays < 365) {
        return '${(difference.inDays / 30).floor()}mo ago';
      } else {
        return '${(difference.inDays / 365).floor()}y ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}

class DottedBorderPainter extends CustomPainter {
  final int segments;
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  DottedBorderPainter({
    required this.segments,
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
        size.width - strokeWidth, size.height - strokeWidth);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    
    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();
    
    for (final pathMetric in pathMetrics) {
      final totalLength = pathMetric.length;
      final segmentLength = totalLength / segments;
      final gapLength = segmentLength * 0.1; // 10% gap between segments
      final dashLength = segmentLength - gapLength;
      
      for (int i = 0; i < segments; i++) {
        final startDistance = i * segmentLength;
        final endDistance = startDistance + dashLength;
        
        final startPath = pathMetric.extractPath(startDistance, endDistance);
        canvas.drawPath(startPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! DottedBorderPainter ||
        oldDelegate.segments != segments ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class CustomIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double size;
  final Color? color;

  const CustomIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: size,
        color: color ?? AppTheme.textSecondary,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}