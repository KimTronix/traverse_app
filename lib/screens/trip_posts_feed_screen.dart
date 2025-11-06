import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/trip_planning_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/post_card.dart';

class TripPostsFeedScreen extends StatefulWidget {
  final String destination;

  const TripPostsFeedScreen({
    super.key,
    required this.destination,
  });

  @override
  State<TripPostsFeedScreen> createState() => _TripPostsFeedScreenState();
}

class _TripPostsFeedScreenState extends State<TripPostsFeedScreen> {
  final TripPlanningService _tripService = TripPlanningService();
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await _tripService.getPostsByDestination(widget.destination);
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Posts from',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
            Text(
              widget.destination,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        leading: IconButton(
          icon: Icon(IconStandards.getUIIcon('back')),
          color: Colors.white,
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? _buildEmptyState(isSmallScreen)
              : _buildPostsFeed(isSmallScreen),
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
              'No Posts Found',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.smSpacing),
            Text(
              'Be the first to share your experience from ${widget.destination}!',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.xlSpacing),
            ElevatedButton.icon(
              onPressed: () => context.go('/create-post'),
              icon: Icon(IconStandards.getUIIcon('add')),
              label: const Text('Create Post'),
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

  Widget _buildPostsFeed(bool isSmallScreen) {
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
        itemCount: _posts.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(isSmallScreen);
          }
          final post = _posts[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.mdSpacing),
            child: PostCard(post: post),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.lgSpacing),
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.smSpacing),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(AppConstants.smRadius),
            ),
            child: Icon(
              IconStandards.getUIIcon('explore'),
              color: Colors.white,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          const SizedBox(width: AppConstants.mdSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_posts.length} ${_posts.length == 1 ? 'Post' : 'Posts'} Found',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Discover experiences from travelers',
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
    );
  }
}
