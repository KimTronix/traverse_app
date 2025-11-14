import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/travel_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/bottom_navigation.dart';

class PlacesListScreen extends StatefulWidget {
  const PlacesListScreen({super.key});

  @override
  State<PlacesListScreen> createState() => _PlacesListScreenState();
}

class _PlacesListScreenState extends State<PlacesListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final travelProvider = Provider.of<TravelProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    // Filter places (exclude events)
    final places = travelProvider.destinations.where((dest) {
      final isEvent = dest['category']?.toString().toLowerCase() == 'event';
      if (isEvent) return false;

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
          'Places to Visit',
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
                hintText: 'Search places...',
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

          // Places List
          Expanded(
            child: places.isEmpty
                ? _buildEmptyState(isSmallScreen)
                : GridView.builder(
                    padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isSmallScreen ? 1 : 2,
                      childAspectRatio: isSmallScreen ? 1.2 : 1.0,
                      crossAxisSpacing: AppConstants.mdSpacing,
                      mainAxisSpacing: AppConstants.mdSpacing,
                    ),
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      final place = places[index];
                      return _buildPlaceCard(place, isSmallScreen);
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
              IconStandards.getUIIcon('place'),
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppConstants.lgSpacing),
            Text(
              'No Places Found',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.smSpacing),
            Text(
              _searchQuery.isEmpty
                  ? 'Check back later for new destinations'
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

  Widget _buildPlaceCard(Map<String, dynamic> place, bool isSmallScreen) {
    final images = place['images'] as List?;
    final hasImage = images != null && images.isNotEmpty;

    return Container(
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
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.mdRadius),
                topRight: Radius.circular(AppConstants.mdRadius),
              ),
              child: hasImage
                  ? Image.network(
                      images!.first,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.backgroundLight,
                          child: Icon(
                            IconStandards.getUIIcon('place'),
                            size: 48,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppTheme.backgroundLight,
                      child: Icon(
                        IconStandards.getUIIcon('place'),
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
          ),

          // Content
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.mdSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place['name'] as String,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (place['location'] != null)
                    Row(
                      children: [
                        Icon(
                          IconStandards.getUIIcon('location'),
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place['location'] as String,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),
                  if (place['rating'] != null && place['rating'] > 0)
                    Row(
                      children: [
                        Icon(IconStandards.getUIIcon('star'), color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${place['rating']}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: FontWeight.w600,
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
    );
  }
}
