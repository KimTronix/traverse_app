import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/stories_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class StoryViewerScreen extends StatefulWidget {
  final Map<String, dynamic> storyGroup;
  final List<Map<String, dynamic>> allStoryGroups;

  const StoryViewerScreen({
    super.key,
    required this.storyGroup,
    required this.allStoryGroups,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  final StoriesService _storiesService = StoriesService.instance;
  
  late PageController _pageController;
  late AnimationController _progressController;
  
  int _currentGroupIndex = 0;
  int _currentStoryIndex = 0;
  VideoPlayerController? _videoController;
  bool _isPaused = false;
  bool _isLoading = true;

  List<Map<String, dynamic>> get _currentStories =>
      widget.allStoryGroups[_currentGroupIndex]['stories'] as List<Map<String, dynamic>>;
  
  Map<String, dynamic> get _currentStory => _currentStories[_currentStoryIndex];

  @override
  void initState() {
    super.initState();
    _initializeViewer();
  }

  void _initializeViewer() {
    // Find the current group index
    _currentGroupIndex = widget.allStoryGroups.indexWhere(
      (group) => group['user']['id'] == widget.storyGroup['user']['id'],
    );
    if (_currentGroupIndex == -1) _currentGroupIndex = 0;

    _pageController = PageController(initialPage: _currentGroupIndex);
    _progressController = AnimationController(
      duration: const Duration(seconds: 5), // 5 seconds per story
      vsync: this,
    );

    _loadCurrentStory();
    _startProgress();
  }

  Future<void> _loadCurrentStory() async {
    setState(() => _isLoading = true);

    try {
      // Dispose previous video controller
      await _videoController?.dispose();
      _videoController = null;

      final story = _currentStory;
      
      // Increment view count
      await _storiesService.incrementViewCount(story['id']);

      // Initialize video player if it's a video story
      if (story['media_type'] == 'video') {
        _videoController = VideoPlayerController.network(story['media_url']);
        await _videoController!.initialize();
        _videoController!.addListener(_videoListener);
        _videoController!.play();
        
        // Set progress duration to video duration
        _progressController.duration = _videoController!.value.duration;
      } else {
        // For images, use default 5 seconds
        _progressController.duration = const Duration(seconds: 5);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      Logger.error('Error loading story: $e');
      setState(() => _isLoading = false);
    }
  }

  void _videoListener() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final position = _videoController!.value.position;
      final duration = _videoController!.value.duration;
      
      if (duration.inMilliseconds > 0) {
        final progress = position.inMilliseconds / duration.inMilliseconds;
        _progressController.value = progress;
      }

      // Auto advance when video ends
      if (position >= duration && !_isPaused) {
        _nextStory();
      }
    }
  }

  void _startProgress() {
    if (_currentStory['media_type'] != 'video') {
      _progressController.forward();
      _progressController.addStatusListener(_progressListener);
    }
  }

  void _progressListener(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_isPaused) {
      _nextStory();
    }
  }

  void _pauseProgress() {
    setState(() => _isPaused = true);
    _progressController.stop();
    _videoController?.pause();
  }

  void _resumeProgress() {
    setState(() => _isPaused = false);
    if (_currentStory['media_type'] == 'video') {
      _videoController?.play();
    } else {
      _progressController.forward();
    }
  }

  void _nextStory() {
    if (_currentStoryIndex < _currentStories.length - 1) {
      // Next story in current group
      setState(() {
        _currentStoryIndex++;
      });
      _progressController.reset();
      _loadCurrentStory();
      _startProgress();
    } else {
      // Next story group
      _nextGroup();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      // Previous story in current group
      setState(() {
        _currentStoryIndex--;
      });
      _progressController.reset();
      _loadCurrentStory();
      _startProgress();
    } else {
      // Previous story group
      _previousGroup();
    }
  }

  void _nextGroup() {
    if (_currentGroupIndex < widget.allStoryGroups.length - 1) {
      setState(() {
        _currentGroupIndex++;
        _currentStoryIndex = 0;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _progressController.reset();
      _loadCurrentStory();
      _startProgress();
    } else {
      // End of stories
      Navigator.of(context).pop();
    }
  }

  void _previousGroup() {
    if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        _currentStoryIndex = (widget.allStoryGroups[_currentGroupIndex]['stories'] as List).length - 1;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _progressController.reset();
      _loadCurrentStory();
      _startProgress();
    } else {
      // Beginning of stories
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _progressController.removeStatusListener(_progressListener);
    _progressController.dispose();
    _pageController.dispose();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.allStoryGroups.length,
          onPageChanged: (index) {
            setState(() {
              _currentGroupIndex = index;
              _currentStoryIndex = 0;
            });
            _progressController.reset();
            _loadCurrentStory();
            _startProgress();
          },
          itemBuilder: (context, index) => _buildStoryView(),
        ),
      ),
    );
  }

  Widget _buildStoryView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onTapDown: (details) => _pauseProgress(),
      onTapUp: (details) {
        _resumeProgress();
        final screenWidth = MediaQuery.of(context).size.width;
        final tapPosition = details.globalPosition.dx;
        
        if (tapPosition < screenWidth * 0.3) {
          _previousStory();
        } else if (tapPosition > screenWidth * 0.7) {
          _nextStory();
        }
      },
      onTapCancel: () => _resumeProgress(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Story content
          _buildStoryContent(),
          
          // Progress indicators
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildProgressIndicators(),
          ),
          
          // Top controls
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: _buildTopControls(),
          ),
          
          // Tap areas (invisible)
          _buildTapAreas(),
          
          // Pause indicator
          if (_isPaused)
            const Center(
              child: Icon(
                Icons.pause_circle_filled,
                color: Colors.white,
                size: 80,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoryContent() {
    final story = _currentStory;
    
    if (story['media_type'] == 'video' && _videoController != null) {
      return _videoController!.value.isInitialized
          ? VideoPlayer(_videoController!)
          : Container(color: Colors.black);
    } else {
      return Image.network(
        story['media_url'],
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 50,
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildProgressIndicators() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.mdSpacing,
        vertical: AppConstants.smSpacing,
      ),
      child: Row(
        children: List.generate(_currentStories.length, (index) {
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(
                right: index < _currentStories.length - 1 ? 4 : 0,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  double progress = 0.0;
                  if (index < _currentStoryIndex) {
                    progress = 1.0;
                  } else if (index == _currentStoryIndex) {
                    progress = _progressController.value;
                  }
                  
                  return LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopControls() {
    final user = widget.allStoryGroups[_currentGroupIndex]['user'] as Map<String, dynamic>;
    final story = _currentStory;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.mdSpacing),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 20,
            backgroundImage: user['avatar_url'] != null
                ? NetworkImage(user['avatar_url'])
                : null,
            child: user['avatar_url'] == null
                ? Text(
                    user['full_name']?[0] ?? 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          
          const SizedBox(width: AppConstants.smSpacing),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'] ?? user['full_name'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatTimeAgo(DateTime.parse(story['created_at'])),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapAreas() {
    return Row(
      children: [
        // Left tap area (previous)
        Expanded(
          flex: 3,
          child: Container(color: Colors.transparent),
        ),
        // Middle tap area (pause/play)
        Expanded(
          flex: 4,
          child: Container(color: Colors.transparent),
        ),
        // Right tap area (next)
        Expanded(
          flex: 3,
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
