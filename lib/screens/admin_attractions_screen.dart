import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/icon_standards.dart';
import '../services/attractions_service.dart';
import '../utils/logger.dart';

class AdminAttractionsScreen extends StatefulWidget {
  const AdminAttractionsScreen({super.key});

  @override
  State<AdminAttractionsScreen> createState() => _AdminAttractionsScreenState();
}

class _AdminAttractionsScreenState extends State<AdminAttractionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AttractionsService _attractionsService = AttractionsService.instance;
  String searchQuery = '';
  String selectedCategory = 'All';
  List<Map<String, dynamic>> _allAttractions = [];
  bool _isLoading = true;
  
  final List<String> categories = [
    'All',
    'Food',
    'Culture',
    'Sites',
    'Game Parks',
    'Recreation',
    'Nature',
    'Shopping'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length - 1, vsync: this);
    _loadAttractions();
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Tourist Attractions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: categories.skip(1).map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: categories.skip(1).map((category) => _buildAttractionsList(category)).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAttractionDialog,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search attractions...',
                prefixIcon: Icon(IconStandards.getUIIcon('search')),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.backgroundLight,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: AppConstants.smSpacing),
          IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(IconStandards.getUIIcon('filter')),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.backgroundLight,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadAttractions() async {
    try {
      setState(() => _isLoading = true);
      final attractions = await _attractionsService.getAllAttractions();
      setState(() {
        _allAttractions = attractions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load attractions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      // Load attraction statistics
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          // Update stats
        });
      }
    } catch (e) {
      Logger.error('Failed to load attraction stats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load stats: $e')),
        );
      }
    }
  }

  Widget _buildAttractionsList(String category) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    final attractions = _getAttractionsForCategory(category);
    
    if (attractions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconStandards.getUIIcon('place'),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No attractions found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some attractions to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      itemCount: attractions.length,
      itemBuilder: (context, index) {
        final attraction = attractions[index];
        return _buildAttractionCard(attraction);
      },
    );
  }

  Widget _buildAttractionCard(Map<String, dynamic> attraction) {
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.mdRadius),
            ),
            child: Container(
              height: 150,
              width: double.infinity,
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              child: Icon(
                attraction['icon'] as IconData,
                size: 60,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.mdSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        attraction['name'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    _buildCategoryChip(attraction['category'] as String),
                  ],
                ),
                const SizedBox(height: AppConstants.smSpacing),
                Text(
                  attraction['description'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppConstants.smSpacing),
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
                        attraction['location'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Icon(
                      IconStandards.getUIIcon('star'),
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${attraction['rating']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.mdSpacing),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editAttraction(attraction),
                        icon: Icon(IconStandards.getUIIcon('edit'), size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryBlue),
                          foregroundColor: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.smSpacing),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewAttractionDetails(attraction),
                        icon: Icon(IconStandards.getUIIcon('visibility'), size: 16),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    Color color = _getCategoryColor(category);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Culture':
        return Colors.purple;
      case 'Sites':
        return Colors.blue;
      case 'Game Parks':
        return Colors.green;
      case 'Recreation':
        return Colors.red;
      case 'Nature':
        return Colors.teal;
      case 'Shopping':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _getAttractionsForCategory(String category) {
    List<Map<String, dynamic>> filteredAttractions = category == 'All' 
        ? List.from(_allAttractions)
        : _allAttractions
            .where((attraction) => attraction['category'] == category)
            .toList();

    // Apply search filter if search query is not empty
    if (searchQuery.isNotEmpty) {
      filteredAttractions = filteredAttractions.where((attraction) {
        final name = (attraction['name'] ?? '').toString().toLowerCase();
        final description = (attraction['description'] ?? '').toString().toLowerCase();
        final location = (attraction['location'] ?? '').toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        
        return name.contains(query) || 
               description.contains(query) || 
               location.contains(query);
      }).toList();
    }

    return filteredAttractions;
  }

  IconData _getCategoryIcon(String category) {
    return IconStandards.getAttractionCategoryIcon(category);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Attractions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Filter by rating:'),
              const SizedBox(height: AppConstants.smSpacing),
              // Add rating filter options here
              const Text('Filter functionality coming soon!'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _showAddAttractionDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    final websiteController = TextEditingController();
    final contactController = TextEditingController();
    String selectedCategory = 'Food';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Attraction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Attraction Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Info (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.skip(1)
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCategory = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty ||
                    locationController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                try {
                   await _attractionsService.addAttraction(
                     name: nameController.text.trim(),
                     category: selectedCategory,
                     description: descriptionController.text.trim(),
                     location: locationController.text.trim(),
                     website: websiteController.text.trim().isEmpty ? null : websiteController.text.trim(),
                     contactPhone: contactController.text.trim().isEmpty ? null : contactController.text.trim(),
                   );
                  
                  if (mounted) {
                    Navigator.pop(context);
                    await _loadAttractions();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Attraction added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add attraction: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editAttraction(Map<String, dynamic> attraction) async {
    final nameController = TextEditingController(text: attraction['name']);
    final descriptionController = TextEditingController(text: attraction['description']);
    final locationController = TextEditingController(text: attraction['location']);
    final websiteController = TextEditingController(text: attraction['website'] ?? '');
    final contactController = TextEditingController(text: attraction['contact_info'] ?? '');
    String selectedCategory = attraction['category'];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Attraction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Attraction Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Info (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.skip(1)
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCategory = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty ||
                    locationController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                try {
                   await _attractionsService.updateAttraction(
                     attraction['id'],
                     {
                       'name': nameController.text.trim(),
                       'category': selectedCategory,
                       'description': descriptionController.text.trim(),
                       'location': locationController.text.trim(),
                       'website': websiteController.text.trim().isEmpty ? null : websiteController.text.trim(),
                       'contact_phone': contactController.text.trim().isEmpty ? null : contactController.text.trim(),
                     },
                   );
                  
                  if (mounted) {
                    Navigator.pop(context);
                    await _loadAttractions();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Attraction updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update attraction: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewAttractionDetails(Map<String, dynamic> attraction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(attraction['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                   _getCategoryIcon(attraction['category'] ?? 'other'),
                   size: 40,
                   color: AppTheme.primaryBlue,
                 ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Category', attraction['category']),
              _buildDetailRow('Description', attraction['description']),
              _buildDetailRow('Location', attraction['location']),
              if (attraction['website'] != null && attraction['website'].isNotEmpty)
                _buildDetailRow('Website', attraction['website']),
              if (attraction['contact_info'] != null && attraction['contact_info'].isNotEmpty)
                _buildDetailRow('Contact', attraction['contact_info']),
              _buildDetailRow('Rating', '${attraction['rating']} ⭐'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editAttraction(attraction);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}