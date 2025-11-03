import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';

class PostWidget extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onPlanTrip;
  final VoidCallback? onTap;

  const PostWidget({
    super.key,
    required this.post,
    required this.isLiked,
    required this.isSaved,
    required this.onLike,
    required this.onSave,
    required this.onComment,
    required this.onShare,
    required this.onPlanTrip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Handle both database and sample data structures
    final user = (post['user'] ?? post['users']) as Map<String, dynamic>? ?? {
      'name': 'Anonymous User',
      'full_name': 'Anonymous User',
      'avatar': 'assets/images/travel-app-mockup.png',
      'avatar_url': 'assets/images/travel-app-mockup.png',
      'username': '@anonymous',
    };

    final location = post['location'] as String? ?? 'Unknown Location';
    final budget = _extractBudget(post);
    final image = _extractImageUrl(post);
    final caption = (post['caption'] ?? post['content']) as String? ?? '';
    final likes = (post['likes'] ?? post['like_count']) as int? ?? 0;
    final comments = (post['comments'] ?? post['comment_count']) as int? ?? 0;
    final shares = (post['shares'] ?? post['share_count']) as int? ?? 0;
    final saves = (post['saves'] ?? post['save_count']) as int? ?? 0;
    final timeAgo = _calculateTimeAgo(post);
    
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        margin: EdgeInsets.zero,
        borderRadius: BorderRadius.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            _buildPostHeader(user, location, budget, timeAgo, isSmallScreen),

            // Post Image
            _buildPostImage(image, isSmallScreen),

            // Post Actions
            _buildPostActions(likes, comments, shares, saves, isSmallScreen),

            // Post Caption
            _buildPostCaption(user, caption, isSmallScreen),

            // Plan Trip Button
            _buildPlanTripButton(isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(
    Map<String, dynamic> user,
    String location,
    String budget,
    String timeAgo,
    bool isSmallScreen,
  ) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
      child: Row(
        children: [
          // User Avatar
          CircleAvatar(
            radius: isSmallScreen ? 18 : 20,
            backgroundImage: AssetImage(_getUserAvatar(user)),
          ),
          
          SizedBox(width: isSmallScreen ? AppConstants.xsSpacing : AppConstants.smSpacing),
          
          // User Info and Location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getUserName(user),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      IconStandards.getUIIcon('location'),
                      size: isSmallScreen ? 10 : 12,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(width: isSmallScreen ? AppConstants.xsSpacing : AppConstants.xsSpacing),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? AppConstants.xsSpacing : AppConstants.xsSpacing),
                    Text('•', style: TextStyle(color: AppTheme.textSecondary, fontSize: isSmallScreen ? 10 : 12)),
                    SizedBox(width: isSmallScreen ? AppConstants.xsSpacing : AppConstants.xsSpacing),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Budget Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? AppConstants.xsSpacing : AppConstants.smSpacing,
              vertical: isSmallScreen ? AppConstants.xsSpacing : AppConstants.xsSpacing,
            ),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(AppConstants.mdRadius),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IconStandards.getUIIcon('attach_money'),
                  size: isSmallScreen ? 10 : 12,
                  color: AppTheme.textSecondary,
                ),
                SizedBox(width: isSmallScreen ? AppConstants.xsSpacing : AppConstants.xsSpacing),
                Text(
                  budget,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage(String image, bool isSmallScreen) {
    return GestureDetector(
      onDoubleTap: onLike,
      child: Container(
        width: double.infinity,
        height: isSmallScreen ? 250 : 300,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: _getImageProvider(image),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String image) {
    // Check if it's a URL (uploaded image from Supabase Storage)
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return NetworkImage(image);
    }
    // Otherwise, it's a local asset
    return AssetImage(image);
  }

  Widget _buildPostActions(int likes, int comments, int shares, int saves, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
      child: Column(
        children: [
          // Action Buttons
          Row(
            children: [
              // Like Button
              _buildActionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : null,
                onTap: onLike,
                size: isSmallScreen ? 22 : 24,
              ),
              
              SizedBox(width: isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
              
              // Comment Button
              _buildActionButton(
                icon: IconStandards.getActionIcon('comment_outlined'),
                onTap: onComment,
                size: isSmallScreen ? 22 : 24,
              ),
              
              SizedBox(width: isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
              
              // Share Button
              _buildActionButton(
                icon: IconStandards.getActionIcon('share_outlined'),
                onTap: onShare,
                size: isSmallScreen ? 22 : 24,
              ),
              
              const Spacer(),
              
              // Save Button
              _buildActionButton(
                icon: isSaved ? IconStandards.getActionIcon('bookmark') : IconStandards.getActionIcon('bookmark_outlined'),
                onTap: onSave,
                size: isSmallScreen ? 22 : 24,
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? AppConstants.xsSpacing : AppConstants.smSpacing),
          
          // Enhanced Stats Row with all metrics
          Row(
            children: [
              // Likes
              _buildStatItem(
                count: likes + (isLiked ? 1 : 0),
                label: 'likes',
                isSmallScreen: isSmallScreen,
                isBold: true,
              ),
              
              if (comments > 0) ...[
                SizedBox(width: isSmallScreen ? 12 : 16),
                GestureDetector(
                  onTap: onComment,
                  child: _buildStatItem(
                    count: comments,
                    label: 'comments',
                    isSmallScreen: isSmallScreen,
                    isClickable: true,
                  ),
                ),
              ],
              
              if (shares > 0) ...[
                SizedBox(width: isSmallScreen ? 12 : 16),
                _buildStatItem(
                  count: shares,
                  label: 'shares',
                  isSmallScreen: isSmallScreen,
                ),
              ],
              
              if (saves > 0) ...[
                SizedBox(width: isSmallScreen ? 12 : 16),
                _buildStatItem(
                  count: saves + (isSaved ? 1 : 0),
                  label: 'saves',
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
    double size = 24,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: size,
        color: color ?? AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildStatItem({
    required int count,
    required String label,
    required bool isSmallScreen,
    bool isBold = false,
    bool isClickable = false,
  }) {
    return Text(
      count == 1 ? '$count ${label.substring(0, label.length - 1)}' : '$count $label',
      style: TextStyle(
        fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
        fontSize: isSmallScreen ? 13 : 14,
        color: isClickable ? AppTheme.textSecondary : AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildPostCaption(Map<String, dynamic> user, String caption, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            color: AppTheme.textPrimary,
          ),
          children: [
            TextSpan(
              text: '${_getUserUsername(user)} ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: caption),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTripButton(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
      child: CustomButton(
        onPressed: onPlanTrip,
        isOutlined: true,
        child: Text(
          'Plan Similar Trip',
          style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
        ),
      ),
    );
  }

  // Helper methods to handle different data structures
  String _getUserName(Map<String, dynamic> user) {
    return user['name'] ?? user['full_name'] ?? 'Unknown User';
  }

  String _getUserAvatar(Map<String, dynamic> user) {
    return user['avatar'] ?? user['avatar_url'] ?? 'assets/images/travel-app-mockup.png';
  }

  String _getUserUsername(Map<String, dynamic> user) {
    return user['username'] ?? '@${(user['name'] ?? user['full_name'] ?? 'unknown').toString().toLowerCase().replaceAll(' ', '')}';
  }

  String _extractBudget(Map<String, dynamic> post) {
    // Check if budget is in tags
    final tags = post['tags'] as List<dynamic>?;
    if (tags != null) {
      for (final tag in tags) {
        if (tag.toString().startsWith('budget:')) {
          return tag.toString().substring(7); // Remove 'budget:' prefix
        }
      }
    }

    // Fallback to direct budget field
    return post['budget'] as String? ?? 'Budget not specified';
  }

  String _extractImageUrl(Map<String, dynamic> post) {
    // Handle images array (from database)
    final images = post['images'] as List<dynamic>?;
    if (images != null && images.isNotEmpty) {
      return images.first.toString();
    }

    // Fallback to direct image field (from sample data)
    return post['image'] as String? ?? 'assets/images/travel-app-mockup.png';
  }

  String _calculateTimeAgo(Map<String, dynamic> post) {
    // Check if timeAgo is already provided (sample data)
    if (post['timeAgo'] != null) {
      return post['timeAgo'] as String;
    }

    // Calculate from created_at (database data)
    final createdAtStr = post['created_at'] as String?;
    if (createdAtStr != null) {
      try {
        final createdAt = DateTime.parse(createdAtStr);
        final now = DateTime.now();
        final difference = now.difference(createdAt);

        if (difference.inDays > 0) {
          return '${difference.inDays}d';
        } else if (difference.inHours > 0) {
          return '${difference.inHours}h';
        } else if (difference.inMinutes > 0) {
          return '${difference.inMinutes}m';
        } else {
          return 'now';
        }
      } catch (e) {
        return 'Unknown time';
      }
    }

    return 'Unknown time';
  }
}