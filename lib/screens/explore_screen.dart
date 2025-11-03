import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/travel_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/comments_dialog.dart';
import '../services/supabase_service.dart';
import '../utils/logger.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService.instance;

  List<Map<String, dynamic>> _people = [];
  bool _isLoadingPeople = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPeople();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChatRooms() async {
    setState(() {
      _isLoadingChatRooms = true;
    });

    try {
      // Load group conversations from Supabase
      final conversations = await _supabaseService.client
          .from('conversations')
          .select('''
            *,
            messages!inner(
              id,
              content,
              created_at,
              sender_id,
              users!messages_sender_id_fkey(username, full_name)
            )
          ''')
          .eq('is_group', true)
          .order('last_message_at', ascending: false);

      if (mounted) {
        setState(() {
          _chatRooms = conversations.map((conv) {
            final lastMessage = conv['messages']?.isNotEmpty == true
                ? conv['messages'][0]
                : null;

            return {
              'id': conv['id'],
              'name': conv['group_name'] ?? 'Travel Group',
              'description': 'Share your travel experiences',
              'members': 0, // TODO: Count group members
              'avatar': conv['group_avatar_url'] ?? 'assets/images/safari-community.png',
              'isActive': true,
              'lastMessage': lastMessage?['content'] ?? 'No messages yet',
              'lastMessageTime': lastMessage != null
                  ? _formatTimeAgo(DateTime.parse(lastMessage['created_at']))
                  : 'New',
            };
          }).toList();
          _isLoadingChatRooms = false;
        });
      }
    } catch (e) {
      Logger.error('Error loading chat rooms: $e');
      // Fallback to demo data
      if (mounted) {
        setState(() {
          _chatRooms = [
            {
              'id': 'demo-1',
              'name': 'Travel Enthusiasts',
              'description': 'Share your travel experiences',
              'members': 1234,
              'avatar': 'assets/images/safari-community.png',
              'isActive': true,
              'lastMessage': 'Just visited Bali! Amazing experience 🌴',
              'lastMessageTime': '2 min ago'
            },
            {
              'id': 'demo-2',
              'name': 'Adventure Seekers',
              'description': 'For thrill seekers and adventurers',
              'members': 856,
              'avatar': 'assets/images/meerkat-safari.png',
              'isActive': true,
              'lastMessage': 'Anyone up for mountain climbing?',
              'lastMessageTime': '5 min ago'
            },
          ];
          _isLoadingChatRooms = false;
        });
      }
    }
  }

  Future<void> _loadPeople() async {
    setState(() {
      _isLoadingPeople = true;
    });

    try {
      // Load active users from Supabase
      final users = await _supabaseService.client
          .from('users')
          .select('id, username, full_name, avatar_url, bio, location')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _people = users.map((user) => {
            'id': user['id'],
            'name': user['full_name'] ?? user['username'] ?? 'Anonymous',
            'username': user['username'],
            'avatar': user['avatar_url'],
            'bio': user['bio'] ?? 'Travel enthusiast',
            'location': user['location'] ?? 'Unknown',
            'isOnline': true, // TODO: Implement real online status
          }).toList();
          _isLoadingPeople = false;
        });
      }
    } catch (e) {
      Logger.error('Error loading people: $e');
      // Fallback to demo data
      if (mounted) {
        setState(() {
          _people = [
            {
              'id': 'demo-user-1',
              'name': 'Alex Rivera',
              'username': 'alex_travels',
              'avatar': null,
              'bio': 'Adventure seeker and photographer',
              'location': 'New York, USA',
              'isOnline': true,
            },
            {
              'id': 'demo-user-2',
              'name': 'Sarah Chen',
              'username': 'sarah_explorer',
              'avatar': null,
              'bio': 'Digital nomad sharing travel tips',
              'location': 'Tokyo, Japan',
              'isOnline': false,
            },
          ];
          _isLoadingPeople = false;
        });
      }
    }
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
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(authProvider, isSmallScreen),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChatRoomsTab(isSmallScreen),
                  _buildPostsTab(isSmallScreen),
                  _buildPeopleTab(isSmallScreen),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigation(),
    );
  }

  Widget _buildHeader(AuthProvider authProvider, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(
          isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.smSpacing),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  IconStandards.getUIIcon('explore'),
                  color: Colors.white,
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              const SizedBox(width: AppConstants.smSpacing),
              Text(
                'Explore',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  IconStandards.getUIIcon('notifications'),
                  color: AppTheme.textSecondary,
                ),
              ),
              _buildUserAvatar(authProvider, isSmallScreen),
            ],
          ),
          const SizedBox(height: AppConstants.mdSpacing),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(AppConstants.lgRadius),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search chat rooms, posts, people...',
                prefixIcon: Icon(
                  IconStandards.getUIIcon('search'),
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.mdSpacing,
                  vertical: AppConstants.mdSpacing,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(AuthProvider authProvider, bool isSmallScreen) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      child: CircleAvatar(
        radius: isSmallScreen ? 16 : 18,
        backgroundColor: AppTheme.primaryBlue,
        backgroundImage: authProvider.userData?['avatar'] != null
            ? AssetImage(authProvider.userData!['avatar'] as String)
            : null,
        child: authProvider.userData?['avatar'] == null
            ? Text(
                (authProvider.userData?['name'] as String?)
                        ?.substring(0, 2)
                        .toUpperCase() ??
                    'U',
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
            context.go('/profile');
            break;
          case 'logout':
            // Handle logout
            break;
        }
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryBlue,
        tabs: [
          Tab(
            icon: Icon(IconStandards.getUIIcon('chat')),
            text: 'Chatrooms',
          ),
          Tab(
            icon: Icon(IconStandards.getUIIcon('post_add')),
            text: 'Posts',
          ),
          Tab(
            icon: Icon(IconStandards.getUIIcon('people')),
            text: 'People',
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomsTab(bool isSmallScreen) {
    if (_isLoadingChatRooms) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_chatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconStandards.getUIIcon('chat_bubble_outline'),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No chat rooms yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.go('/messages'),
              child: const Text('Start a Conversation'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(
          isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
      itemCount: _chatRooms.length,
      itemBuilder: (context, index) {
        final room = _chatRooms[index];
        return _buildChatRoomCard(room, isSmallScreen);
      },
    );
  }

  Widget _buildChatRoomCard(Map<String, dynamic> room, bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.mdSpacing),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailPopup('chat_room', room),
          borderRadius: BorderRadius.circular(AppConstants.mdRadius),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.mdSpacing),
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
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage(room['avatar']),
                    ),
                    if (room['isActive'])
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppConstants.mdSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              room['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            room['lastMessageTime'],
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        room['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        room['lastMessage'],
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            IconStandards.getUIIcon('people'),
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${room['members']} members',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildPostsTab(bool isSmallScreen) {
    return Consumer<TravelProvider>(
      builder: (context, travelProvider, child) {
        if (travelProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (travelProvider.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  IconStandards.getUIIcon('post_add'),
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.go('/create-post'),
                  child: const Text('Create First Post'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // TODO: Implement refresh for posts
          },
          child: ListView.builder(
            padding: EdgeInsets.all(
                isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
            itemCount: travelProvider.posts.length,
            itemBuilder: (context, index) {
              final post = travelProvider.posts[index];
              return _buildPostCard(post, isSmallScreen);
            },
          ),
        );
      },
    );
  }

  Widget _buildPeopleTab(bool isSmallScreen) {
    if (_isLoadingPeople) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_people.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconStandards.getUIIcon('people_outline'),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No people found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadPeople,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(
          isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
      itemCount: _people.length,
      itemBuilder: (context, index) {
        final person = _people[index];
        return _buildPersonCard(person, isSmallScreen);
      },
    );
  }

  Widget _buildPersonCard(Map<String, dynamic> person, bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.mdSpacing),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to user profile
          },
          borderRadius: BorderRadius.circular(AppConstants.mdRadius),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.mdSpacing),
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
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: person['avatar'] != null
                          ? NetworkImage(person['avatar'])
                          : null,
                      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      child: person['avatar'] == null
                          ? Text(
                              person['name'][0].toUpperCase(),
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    if (person['isOnline'] == true)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppConstants.mdSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              person['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (person['username'] != null)
                            Text(
                              '@${person['username']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        person['bio'] ?? 'Travel enthusiast',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            IconStandards.getUIIcon('location_on'),
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              person['location'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Follow/Unfollow functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text(
                        'Follow',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      onPressed: () {
                        // TODO: Start conversation
                        context.go('/messages');
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(80, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text(
                        'Message',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.lgSpacing),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPostDetailDialog(post),
          borderRadius: BorderRadius.circular(AppConstants.mdRadius),
          child: Container(
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
                Padding(
                  padding: const EdgeInsets.all(AppConstants.mdSpacing),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: post['users']?['avatar_url'] != null
                            ? NetworkImage(post['users']['avatar_url'])
                            : null,
                        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        child: post['users']?['avatar_url'] == null
                            ? Text(
                                (post['users']?['full_name']?[0] ??
                                        post['users']?['username']?[0] ??
                                        'U')
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: AppConstants.smSpacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['users']?['full_name'] ??
                                  post['users']?['username'] ??
                                  'Anonymous',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              _formatTimeAgo(DateTime.parse(post['created_at'])),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          IconStandards.getUIIcon('more_vert'),
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Post content
                if (post['content'] != null && post['content'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.mdSpacing),
                    child: Text(
                      post['content'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                const SizedBox(height: AppConstants.smSpacing),
                // Post images
                if (post['images'] != null && post['images'].isNotEmpty)
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (post['images'] as List).length,
                      itemBuilder: (context, imageIndex) {
                        final imageUrl = post['images'][imageIndex];
                        return Container(
                          width: 300,
                          margin: EdgeInsets.only(
                            left: imageIndex == 0 ? AppConstants.mdSpacing : 4,
                            right: imageIndex == post['images'].length - 1
                                ? AppConstants.mdSpacing
                                : 4,
                          ),
                          child: GestureDetector(
                            onDoubleTap: () {
                              final travelProvider = Provider.of<TravelProvider>(context, listen: false);
                              final postId = post['id'].toString();
                              travelProvider.toggleLike(postId);

                              // Show heart animation
                              _showLikeAnimation(context);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                              child: Image.network(
                                imageUrl,
                                width: 300,
                                height: 300,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 300,
                                    height: 300,
                                    color: Colors.grey[200],
                                    child: Icon(
                                      IconStandards.getUIIcon('image_not_supported'),
                                      color: Colors.grey,
                                      size: 50,
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 300,
                                    height: 300,
                                    color: Colors.grey[100],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppConstants.mdSpacing),
                  child: Row(
                    children: [
                      Consumer<TravelProvider>(
                        builder: (context, travelProvider, child) {
                          final postId = post['id'].toString();
                          final isLiked = travelProvider.isPostLiked(postId);
                          final likeCount = post['like_count'] ?? 0;

                          return _buildActionButton(
                            icon: isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            label: '$likeCount',
                            color: isLiked ? Colors.red : AppTheme.textSecondary,
                            onTap: () => travelProvider.toggleLike(postId),
                          );
                        },
                      ),
                      const SizedBox(width: AppConstants.lgSpacing),
                      _buildActionButton(
                        icon: IconStandards.getUIIcon('comment'),
                        label: '${post['comment_count'] ?? 0}',
                        color: AppTheme.textSecondary,
                        onTap: () => _showCommentsDialog(post),
                      ),
                      const SizedBox(width: AppConstants.lgSpacing),
                      _buildActionButton(
                        icon: IconStandards.getUIIcon('share'),
                        label: '${post['share_count'] ?? 0}',
                        color: AppTheme.textSecondary,
                        onTap: () => _sharePost(post),
                      ),
                      const Spacer(),
                      Consumer<TravelProvider>(
                        builder: (context, travelProvider, child) {
                          final postId = post['id'].toString();
                          final isSaved = travelProvider.isPostSaved(postId);

                          return _buildActionButton(
                            icon: isSaved
                                ? IconStandards.getUIIcon('bookmark')
                                : IconStandards.getUIIcon('bookmark_border'),
                            label: '',
                            color: isSaved ? AppTheme.primaryBlue : AppTheme.textSecondary,
                            onTap: () => travelProvider.toggleSave(postId),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.smRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.smSpacing,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLikeAnimation(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedLikeHeart(
        onAnimationComplete: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
  }

  void _showPostDetailDialog(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.lgRadius),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppConstants.mdSpacing),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppConstants.lgRadius),
                    topRight: Radius.circular(AppConstants.lgRadius),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: post['users']?['avatar_url'] != null
                          ? NetworkImage(post['users']['avatar_url'])
                          : null,
                      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      child: post['users']?['avatar_url'] == null
                          ? Text(
                              (post['users']?['full_name']?[0] ??
                                      post['users']?['username']?[0] ??
                                      'U')
                                  .toUpperCase(),
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: AppConstants.smSpacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['users']?['full_name'] ??
                                post['users']?['username'] ??
                                'Anonymous',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatTimeAgo(DateTime.parse(post['created_at'])),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post content
                      if (post['content'] != null && post['content'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppConstants.mdSpacing),
                          child: Text(
                            post['content'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),

                      // Post images
                      if (post['images'] != null && post['images'].isNotEmpty)
                        SizedBox(
                          height: 300,
                          child: PageView.builder(
                            itemCount: (post['images'] as List).length,
                            itemBuilder: (context, index) {
                              final imageUrl = post['images'][index];
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onDoubleTap: () {
                                    final travelProvider = Provider.of<TravelProvider>(context, listen: false);
                                    final postId = post['id'].toString();
                                    travelProvider.toggleLike(postId);
                                    _showLikeAnimation(context);
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: Icon(
                                            IconStandards.getUIIcon('image_not_supported'),
                                            color: Colors.grey,
                                            size: 50,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // Actions
                      Padding(
                        padding: const EdgeInsets.all(AppConstants.mdSpacing),
                        child: Consumer<TravelProvider>(
                          builder: (context, travelProvider, child) {
                            final postId = post['id'].toString();
                            final isLiked = travelProvider.isPostLiked(postId);
                            final isSaved = travelProvider.isPostSaved(postId);
                            final likeCount = post['like_count'] ?? 0;
                            final commentCount = post['comment_count'] ?? 0;
                            final shareCount = post['share_count'] ?? 0;

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    _buildActionButton(
                                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                                      label: '',
                                      color: isLiked ? Colors.red : AppTheme.textSecondary,
                                      onTap: () => travelProvider.toggleLike(postId),
                                    ),
                                    const SizedBox(width: AppConstants.lgSpacing),
                                    _buildActionButton(
                                      icon: IconStandards.getUIIcon('comment'),
                                      label: '',
                                      color: AppTheme.textSecondary,
                                      onTap: () => _showCommentsDialog(post),
                                    ),
                                    const SizedBox(width: AppConstants.lgSpacing),
                                    _buildActionButton(
                                      icon: IconStandards.getUIIcon('share'),
                                      label: '',
                                      color: AppTheme.textSecondary,
                                      onTap: () => _sharePost(post),
                                    ),
                                    const Spacer(),
                                    _buildActionButton(
                                      icon: isSaved
                                          ? IconStandards.getUIIcon('bookmark')
                                          : IconStandards.getUIIcon('bookmark_border'),
                                      label: '',
                                      color: isSaved ? AppTheme.primaryBlue : AppTheme.textSecondary,
                                      onTap: () => travelProvider.toggleSave(postId),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppConstants.smSpacing),
                                Row(
                                  children: [
                                    Text(
                                      '$likeCount likes',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: AppConstants.mdSpacing),
                                    Text(
                                      '$commentCount comments',
                                      style: TextStyle(color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(width: AppConstants.mdSpacing),
                                    Text(
                                      '$shareCount shares',
                                      style: TextStyle(color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
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

  void _showCommentsDialog(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) => CommentsDialog(
        postId: post['id'].toString(),
        postTitle: post['content'] ?? 'Post',
      ),
    );
  }

  void _sharePost(Map<String, dynamic> post) {
    final content = post['content'] ?? '';
    final userDisplayName = post['users']?['full_name'] ??
                           post['users']?['username'] ??
                           'Anonymous';

    final shareText = 'Check out this post by $userDisplayName: $content\n\nShared via Traverse Travel App';

    // For web/mobile, we'll show a share options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Link'),
              onTap: () {
                // TODO: Implement copy to clipboard
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Text'),
              onTap: () {
                // TODO: Implement native share
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share functionality coming soon!')),
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

  void _showDetailPopup(String type, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.lgRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.mdSpacing),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppConstants.lgRadius),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      type == 'chat_room'
                          ? IconStandards.getUIIcon('chat_bubble')
                        : type == 'status'
                        ? IconStandards.getUIIcon('timeline')
                        : IconStandards.getUIIcon('video_library'),
                      color: Colors.white,
                    ),
                    const SizedBox(width: AppConstants.smSpacing),
                    Expanded(
                      child: Text(
                        type == 'chat_room'
                            ? item['name']
                            : type == 'status'
                                ? 'User Status'
                                : 'User Post',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(IconStandards.getUIIcon('close'), color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.mdSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (type == 'chat_room') ..._buildChatRoomDetails(item),
                      if (type == 'status') ..._buildStatusDetails(item),
                      if (type == 'post') ..._buildPostDetails(item),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppConstants.mdSpacing),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (type == 'chat_room') {
                            context.go('/messages');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppConstants.mdSpacing,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                          ),
                        ),
                        child: Text(
                          type == 'chat_room'
                              ? 'Join Chat'
                              : type == 'status'
                                  ? 'View Profile'
                                  : 'Watch Video',
                        ),
                      ),
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

  List<Widget> _buildChatRoomDetails(Map<String, dynamic> data) {
    return [
      Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage(data['avatar']),
          ),
          const SizedBox(width: AppConstants.mdSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  data['description'],
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      IconStandards.getUIIcon('people'),
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${data['members']} members',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: AppConstants.lgSpacing),
      Text(
        'Recent Activity',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: AppConstants.smSpacing),
      Container(
        padding: const EdgeInsets.all(AppConstants.mdSpacing),
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        ),
        child: Text(
          data['lastMessage'],
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildStatusDetails(Map<String, dynamic> data) {
    return [
      Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage(data['avatar']),
          ),
          const SizedBox(width: AppConstants.mdSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['user'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  data['time'],
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: AppConstants.mdSpacing),
      Text(
        data['content'],
        style: const TextStyle(fontSize: 14),
      ),
      const SizedBox(height: AppConstants.mdSpacing),
      ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        child: Image.asset(
          data['image'],
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(height: AppConstants.mdSpacing),
      Row(
        children: [
          Icon(IconStandards.getUIIcon('favorite'), color: Colors.red, size: 16),
          const SizedBox(width: 4),
          Text('${data['likes']} likes'),
          const SizedBox(width: AppConstants.mdSpacing),
          Icon(IconStandards.getUIIcon('comment'), color: AppTheme.textSecondary, size: 16),
          const SizedBox(width: 4),
          Text('${data['comments']} comments'),
        ],
      ),
    ];
  }

  List<Widget> _buildPostDetails(Map<String, dynamic> data) {
    return [
      Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage(data['avatar']),
          ),
          const SizedBox(width: AppConstants.mdSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['user'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${data['views']} views',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: AppConstants.mdSpacing),
      Text(
        data['content'],
        style: const TextStyle(fontSize: 14),
      ),
      const SizedBox(height: AppConstants.mdSpacing),
      Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.mdRadius),
            child: Image.asset(
              data['video'],
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
             top: 0,
             left: 0,
             right: 0,
             bottom: 0,
             child: Center(
               child: Container(
                 padding: const EdgeInsets.all(AppConstants.mdSpacing),
                 decoration: BoxDecoration(
                   color: Colors.black.withValues(alpha: 0.6),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(
                   IconStandards.getUIIcon('play'),
                   color: Colors.white,
                   size: 30,
                 ),
               ),
             ),
           ),
        ],
      ),
      const SizedBox(height: AppConstants.mdSpacing),
      Row(
        children: [
          Icon(IconStandards.getUIIcon('favorite'), color: Colors.red, size: 16),
          const SizedBox(width: 4),
          Text('${data['likes']} likes'),
          const SizedBox(width: AppConstants.mdSpacing),
          Icon(IconStandards.getUIIcon('comment'), color: AppTheme.textSecondary, size: 16),
          const SizedBox(width: 4),
          Text('${data['comments']} comments'),
          const SizedBox(width: AppConstants.mdSpacing),
          Icon(IconStandards.getUIIcon('visibility'), color: AppTheme.textSecondary, size: 16),
          const SizedBox(width: 4),
          Text(data['views']),
        ],
      ),
    ];
  }
}

class AnimatedLikeHeart extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const AnimatedLikeHeart({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  State<AnimatedLikeHeart> createState() => _AnimatedLikeHeartState();
}

class _AnimatedLikeHeartState extends State<AnimatedLikeHeart>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height / 2 - 50,
      left: MediaQuery.of(context).size.width / 2 - 50,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 100,
              ),
            ),
          );
        },
      ),
    );
  }
}