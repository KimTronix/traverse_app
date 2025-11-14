import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/travel_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/bottom_navigation.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final travelProvider = Provider.of<TravelProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    // Filter events
    final events = travelProvider.destinations.where((dest) {
      final isEvent = dest['category']?.toString().toLowerCase() == 'event';
      if (!isEvent) return false;

      if (_searchQuery.isEmpty) return true;

      final query = _searchQuery.toLowerCase();
      final name = (dest['name'] ?? '').toString().toLowerCase();
      final description = (dest['description'] ?? '').toString().toLowerCase();
      final location = (dest['location'] ?? '').toString().toLowerCase();

      return name.contains(query) ||
             description.contains(query) ||
             location.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Upcoming Events',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        leading: IconButton(
          icon: Icon(IconStandards.getUIIcon('back')),
          color: Colors.white,
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppConstants.mdSpacing),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search events...',
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

          // Events List
          Expanded(
            child: events.isEmpty
                ? _buildEmptyState(isSmallScreen)
                : ListView.builder(
                    padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _buildEventCard(event, isSmallScreen);
                    },
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
              IconStandards.getUIIcon('event'),
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppConstants.lgSpacing),
            Text(
              'No Events Found',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.smSpacing),
            Text(
              _searchQuery.isEmpty
                  ? 'Check back later for upcoming events'
                  : 'Try a different search term',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, bool isSmallScreen) {
    final images = event['images'] as List?;
    final hasImage = images != null && images.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.mdSpacing),
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
          // Image
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.mdRadius),
                topRight: Radius.circular(AppConstants.mdRadius),
              ),
              child: Image.network(
                images!.first,
                height: isSmallScreen ? 150 : 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: isSmallScreen ? 150 : 200,
                    color: AppTheme.backgroundLight,
                    child: Icon(
                      IconStandards.getUIIcon('event'),
                      size: 64,
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppConstants.mdSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['name'] as String,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.smSpacing),
                if (event['location'] != null) ...[
                  Row(
                    children: [
                      Icon(
                        IconStandards.getUIIcon('location'),
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event['location'] as String,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.smSpacing),
                ],
                if (event['description'] != null)
                  Text(
                    event['description'] as String,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: AppConstants.mdSpacing),
                Row(
                  children: [
                    if (event['entry_fee'] != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.smSpacing,
                          vertical: AppConstants.xsSpacing,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppConstants.smRadius),
                        ),
                        child: Text(
                          '${event['currency'] ?? 'USD'} \$${event['entry_fee']}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.smSpacing),
                    ],
                    if (event['rating'] != null && event['rating'] > 0) ...[
                      Icon(IconStandards.getUIIcon('star'), color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${event['rating']} (${event['review_count'] ?? 0})',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
