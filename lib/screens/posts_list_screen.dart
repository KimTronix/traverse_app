import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/travel_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/post_widget.dart';

class PostsListScreen extends StatefulWidget {
  const PostsListScreen({super.key});

  @override
  State<PostsListScreen> createState() => _PostsListScreenState();
}

class _PostsListScreenState extends State<PostsListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final travelProvider = Provider.of<TravelProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    // Filter posts
    final posts = travelProvider.posts.where((post) {
      if (_searchQuery.isEmpty) return true;

      final query = _searchQuery.toLowerCase();
      final caption = (post['caption'] ?? '').toString().toLowerCase();
      final location = (post['location'] ?? '').toString().toLowerCase();
      final author = (post['author_name'] ?? '').toString().toLowerCase();

      return caption.contains(query) ||
             location.contains(query) ||
             author.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'All Posts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        leading: IconButton(
          icon: Icon(IconStandards.getUIIcon('back')),
          color: Colors.white,
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(IconStandards.getUIIcon('add')),
            color: Colors.white,
            onPressed: () => context.go('/create-post'),
            tooltip: 'Create Post',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppConstants.mdSpacing),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search posts...',
                prefixIcon: Icon(IconStandards.getUIIcon('search')),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.backgroundLight,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Posts List
          Expanded(
            child: posts.isEmpty
                ? _buildEmptyState(isSmallScreen)
                : RefreshIndicator(
                    onRefresh: () async {
                      // Refresh posts
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppConstants.mdSpacing),
                          child: PostWidget(
                            post: post,
                            isLiked: false,
                            isSaved: false,
                            onLike: () {},
                            onSave: () {},
                            onComment: () {},
                            onShare: () {},
                            onPlanTrip: () {
                              context.go('/travel-plan');
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
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
              'No Posts Found',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.smSpacing),
            Text(
              _searchQuery.isEmpty
                  ? 'Be the first to share your travel experience!'
                  : 'Try a different search term',
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
}
