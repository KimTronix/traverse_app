import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/stories_service.dart';
import '../widgets/story_viewer.dart';
import '../widgets/story_creator.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final StoriesService _storiesService = StoriesService.instance;
  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      setState(() => _isLoading = true);
      
      final stories = await _storiesService.getActiveStories();
      
      // Group stories by user
      final Map<String, List<Map<String, dynamic>>> groupedStories = {};
      for (final story in stories) {
        final userId = story['user_id'] as String;
        if (!groupedStories.containsKey(userId)) {
          groupedStories[userId] = [];
        }
        groupedStories[userId]!.add(story);
      }

      // Convert to list format for UI
      final List<Map<String, dynamic>> storyGroups = [];
      for (final entry in groupedStories.entries) {
        final userStories = entry.value;
        if (userStories.isNotEmpty) {
          storyGroups.add({
            'user': userStories.first['users'],
            'stories': userStories,
            'latest_story': userStories.first,
          });
        }
      }

      setState(() {
        _stories = storyGroups;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading stories: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Stories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo, color: AppTheme.primaryBlue),
            onPressed: () => _showStoryCreator(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildStoriesContent(),
    );
  }

  Widget _buildStoriesContent() {
    if (_stories.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadStories,
      child: CustomScrollView(
        slivers: [
          // My Story section
          SliverToBoxAdapter(
            child: _buildMyStorySection(),
          ),
          
          // Stories list
          SliverPadding(
            padding: const EdgeInsets.all(AppConstants.mdSpacing),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: AppConstants.mdSpacing,
                mainAxisSpacing: AppConstants.mdSpacing,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildStoryCard(_stories[index]),
                childCount: _stories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStorySection() {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.userData;

    return Container(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Story',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.smSpacing),
          GestureDetector(
            onTap: () => _showStoryCreator(),
            child: Container(
              height: 120,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                border: Border.all(
                  color: AppTheme.primaryBlue,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                    AppTheme.primaryPurple.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: currentUser?['avatar_url'] != null
                        ? NetworkImage(currentUser!['avatar_url'])
                        : null,
                    child: currentUser?['avatar_url'] == null
                        ? Text(
                            currentUser?['full_name']?[0] ?? 'U',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppConstants.smSpacing),
                  const Icon(
                    Icons.add,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const Text(
                    'Add Story',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> storyGroup) {
    final user = storyGroup['user'] as Map<String, dynamic>;
    final stories = storyGroup['stories'] as List<Map<String, dynamic>>;
    final latestStory = storyGroup['latest_story'] as Map<String, dynamic>;

    return GestureDetector(
      onTap: () => _viewStories(storyGroup),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.mdRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.mdRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Story background image
              Image.network(
                latestStory['media_url'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppTheme.textSecondary,
                      size: 40,
                    ),
                  );
                },
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
              
              // User info
              Positioned(
                bottom: AppConstants.smSpacing,
                left: AppConstants.smSpacing,
                right: AppConstants.smSpacing,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: user['avatar_url'] != null
                              ? NetworkImage(user['avatar_url'])
                              : null,
                          child: user['avatar_url'] == null
                              ? Text(
                                  user['full_name']?[0] ?? 'U',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: AppConstants.smSpacing),
                        Expanded(
                          child: Text(
                            user['username'] ?? user['full_name'] ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (stories.length > 1) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${stories.length} stories',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Story ring indicator
              Positioned(
                top: AppConstants.smSpacing,
                right: AppConstants.smSpacing,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryBlue,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${stories.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppConstants.mdSpacing),
          const Text(
            'No Stories Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.smSpacing),
          const Text(
            'Be the first to share your travel story!',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.lgSpacing),
          ElevatedButton.icon(
            onPressed: () => _showStoryCreator(),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Create Story'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.lgSpacing,
                vertical: AppConstants.mdSpacing,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStoryCreator() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoryCreatorScreen(),
        fullscreenDialog: true,
      ),
    ).then((_) {
      // Refresh stories after creating a new one
      _loadStories();
    });
  }

  void _viewStories(Map<String, dynamic> storyGroup) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          storyGroup: storyGroup,
          allStoryGroups: _stories,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}
