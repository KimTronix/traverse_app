import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';

class StoryWidget extends StatelessWidget {
  final Map<String, dynamic> story;
  final VoidCallback? onTap;

  const StoryWidget({
    super.key,
    required this.story,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Handle both boolean and integer values for hasStory and isAdd
    final hasStoryValue = story['hasStory'];
    final isAddValue = story['isAdd'];
    
    final hasStory = hasStoryValue is bool ? hasStoryValue : (hasStoryValue as int?) == 1;
    final isAdd = isAddValue is bool ? isAddValue : (isAddValue as int?) == 1;
    
    final userId = story['userId'] as int?;
    final avatar = story['avatar'] as String? ?? 'assets/images/travel-app-mockup.png';
    final user = story['user'] as String? ?? 'User $userId';

    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375;
    
    // Responsive dimensions
    final cardWidth = isSmallScreen ? 100.0 : 120.0;
    final cardMargin = isSmallScreen ? 8.0 : 12.0;
    final borderRadius = isSmallScreen ? 12.0 : 16.0;
    final profileSize = isSmallScreen ? 28.0 : 32.0;
    final padding = isSmallScreen ? 8.0 : 12.0;
    final fontSize = isSmallScreen ? 10.0 : 12.0;

    return GestureDetector(
      onTap: onTap,
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
          image: DecorationImage(
            image: AssetImage(avatar),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.3),
              BlendMode.darken,
            ),
          ),
          border: hasStory
              ? Border.all(
                  color: AppTheme.primaryBlue,
                  width: 3,
                )
              : Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: hasStory ? 0.2 : 0.0),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient overlay
            Container(
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
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture at top
                  Container(
                    width: profileSize,
                    height: profileSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: AssetImage(avatar),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: isAdd
                        ? Container(
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
                          )
                        : null,
                  ),
                  
                  const Spacer(),
                  
                  // Username at bottom
                  Text(
                    user,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Story indicator
                  if (hasStory)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}