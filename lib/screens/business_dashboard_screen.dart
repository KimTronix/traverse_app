import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/icon_standards.dart';
import '../services/attractions_service.dart';
import '../providers/auth_provider.dart';
import '../utils/logger.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_navigation.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AttractionsService _attractionsService = AttractionsService.instance;
  String searchQuery = '';
  List<Map<String, dynamic>> _myAttractions = [];
  bool _isLoading = true;
  String? _currentUserId;

  final List<String> categories = [
    'All',
    'restaurant',
    'hotel',
    'activity',
    'transport',
    'event',
  ];

  final Map<String, String> categoryDisplayNames = {
    'All': 'All',
    'restaurant': 'Restaurants',
    'hotel': 'Hotels',
    'activity': 'Activities',
    'transport': 'Transport',
    'event': 'Events',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authProvider = context.read<AuthProvider>();
    final userData = authProvider.userData;

    if (userData != null && userData['id'] != null) {
      setState(() {
        _currentUserId = userData['id'];
      });
      await _loadMyAttractions();
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to manage your attractions'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyAttractions() async {
    if (_currentUserId == null) return;

    try {
      setState(() => _isLoading = true);
      final attractions = await _attractionsService.getAttractionsByOwner(
        _currentUserId!,
      );
      setState(() {
        _myAttractions = attractions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Logger.error('Failed to load my attractions: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
          tabs: categories
              .map(
                (category) =>
                    Tab(text: categoryDisplayNames[category] ?? category),
              )
              .toList(),
        ),
      ),
      body: Column(
        children: [
          _buildStatsOverview(),
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: categories
                  .map((category) => _buildAttractionsList(category))
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAttractionDialog,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.xxlRadius),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigation(),
    );
  }

  Widget _buildStatsOverview() {
    final totalAttractions = _myAttractions.length;
    final pendingApproval = _myAttractions
        .where((a) => a['status'] == 'pending')
        .length;
    final activeAttractions = _myAttractions
        .where((a) => a['status'] == 'approved')
        .length;

    return Container(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              totalAttractions.toString(),
              Icons.business,
              AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: AppConstants.smSpacing),
          Expanded(
            child: _buildStatCard(
              'Active',
              activeAttractions.toString(),
              Icons.check_circle,
              AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: AppConstants.smSpacing),
          Expanded(
            child: _buildStatCard(
              'Pending',
              pendingApproval.toString(),
              Icons.pending,
              AppTheme.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.smSpacing),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search your businesses...',
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
    );
  }

  Widget _buildAttractionsList(String category) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final attractions = _getAttractionsForCategory(category);

    if (attractions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              category == 'All'
                  ? 'No businesses yet'
                  : 'No ${categoryDisplayNames[category]} yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first business to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddAttractionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Business'),
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
    final status = attraction['status'] as String? ?? 'pending';
    final statusColor = status == 'approved'
        ? AppTheme.primaryGreen
        : status == 'pending'
        ? AppTheme.primaryOrange
        : AppTheme.primaryRed;

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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.smSpacing),
                Text(
                  attraction['description'] as String? ?? '',
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
                        attraction['location'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    if (attraction['rating'] != null &&
                        attraction['rating'] > 0) ...[
                      Icon(
                        IconStandards.getUIIcon('star'),
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${attraction['rating']} (${attraction['review_count'] ?? 0})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
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
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteAttraction(attraction),
                        icon: Icon(IconStandards.getUIIcon('delete'), size: 16),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryRed),
                          foregroundColor: AppTheme.primaryRed,
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

  List<Map<String, dynamic>> _getAttractionsForCategory(String category) {
    List<Map<String, dynamic>> filteredAttractions = category == 'All'
        ? List.from(_myAttractions)
        : _myAttractions
              .where((attraction) => attraction['category'] == category)
              .toList();

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filteredAttractions = filteredAttractions.where((attraction) {
        final name = (attraction['name'] ?? '').toString().toLowerCase();
        final description = (attraction['description'] ?? '')
            .toString()
            .toLowerCase();
        final location = (attraction['location'] ?? '')
            .toString()
            .toLowerCase();
        final query = searchQuery.toLowerCase();

        return name.contains(query) ||
            description.contains(query) ||
            location.contains(query);
      }).toList();
    }

    return filteredAttractions;
  }

  void _showAddAttractionDialog() {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to add an attraction'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    final websiteController = TextEditingController();
    final contactController = TextEditingController();
    final emailController = TextEditingController();
    final entryFeeController = TextEditingController();
    // final imageUrlController = TextEditingController(); // Removed in favor of image picker
    final openingHoursController = TextEditingController();
    final amenitiesController = TextEditingController();
    String? _uploadedImageUrl;
    bool _isUploadingImage = false;
    final ImagePicker _picker = ImagePicker();

    void _showError(String message) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error', style: TextStyle(color: Colors.red)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    Future<void> _pickAndUploadImage(StateSetter setDialogState) async {
      try {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
        );
        if (image == null) return;

        setDialogState(() {
          _isUploadingImage = true;
        });

        final file = File(image.path);
        final fileExt = image.path.split('.').last;
        final fileName = '${DateTime.now().toIso8601String()}_${image.name}';
        final filePath = 'business_images/$fileName';

        await Supabase.instance.client.storage
            .from('attractions')
            .upload(filePath, file);

        final imageUrl = Supabase.instance.client.storage
            .from('attractions')
            .getPublicUrl(filePath);

        setDialogState(() {
          _uploadedImageUrl = imageUrl;
          _isUploadingImage = false;
        });
      } catch (e) {
        setDialogState(() {
          _isUploadingImage = false;
        });
        if (context.mounted) {
          _showError('Failed to upload image: $e');
        }
      }
    }

    String selectedCategory = 'restaurant';
    String selectedCurrency = 'USD';
    String selectedPriceRange = '\$\$';

    // Helper function to build section headers
    Widget _buildSectionHeader(String title) {
      return Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      );
    }

    // Helper function to build text fields
    Widget _buildTextField({
      required TextEditingController controller,
      required String label,
      required String hint,
      required IconData icon,
      int maxLines = 1,
      TextInputType keyboardType = TextInputType.text,
      String? helperText,
      bool isRequired = false,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRequired)
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                const Text('*', style: TextStyle(color: Colors.red)),
              ],
            )
          else
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.mdRadius),
              ),
              filled: true,
              fillColor: AppTheme.backgroundLight,
              helperText: helperText,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: maxLines,
            keyboardType: keyboardType,
          ),
        ],
      );
    }

    // Helper function to build dropdowns
    Widget _buildDropdown({
      required String? value,
      required Function(String?) onChanged,
      required String label,
      IconData? icon,
      required List<DropdownMenuItem<String>> items,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              prefixIcon: icon != null ? Icon(icon) : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.mdRadius),
              ),
              filled: true,
              fillColor: AppTheme.backgroundLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: items,
            onChanged: onChanged,
            isExpanded: true,
          ),
        ],
      );
    }

    // Submission logic
    Future<void> _submitBusinessForm() async {
      // Validate required fields
      if (nameController.text.trim().isEmpty ||
          descriptionController.text.trim().isEmpty ||
          locationController.text.trim().isEmpty) {
        _showError('Please fill in all required fields');
        return;
      }

      try {
        // Entry fee is stored as a string (character varying) in the DB
        String? entryFee;
        if (entryFeeController.text.trim().isNotEmpty) {
          entryFee = entryFeeController.text.trim();
        }

        // Images list (uploaded image URL)
        List<String>? images;
        if (_uploadedImageUrl != null) {
          images = [_uploadedImageUrl!];
        }

        // Amenities list
        List<String>? amenities;
        if (amenitiesController.text.trim().isNotEmpty) {
          amenities = amenitiesController.text
              .trim()
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }

        await _attractionsService.addAttraction(
          name: nameController.text.trim(),
          category: selectedCategory,
          description: descriptionController.text.trim(),
          location: locationController.text.trim(),
          ownerId: _currentUserId!,
          contactPhone: contactController.text.trim().isEmpty
              ? null
              : contactController.text.trim(),
          contactEmail: emailController.text.trim().isEmpty
              ? null
              : emailController.text.trim(),
          website: websiteController.text.trim().isEmpty
              ? null
              : websiteController.text.trim(),
          entryFee: entryFee,
          currency: selectedCurrency,
          priceRange: selectedPriceRange,
          images: images,
          amenities: amenities,
          openingHours: openingHoursController.text.trim().isEmpty
              ? null
              : {'text': openingHoursController.text.trim()},
        );

        if (context.mounted) {
          Navigator.pop(context);
          await _loadMyAttractions();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Business added successfully! Awaiting admin approval.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          _showError('Failed to add business: $e');
        }
      }
    }

    // Show Add Business as a Bottom Sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.lgRadius)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.lgSpacing),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.lgRadius)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.business, color: Colors.white, size: 28),
                        const Text(
                          'Add New Business',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Form Content
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.lgSpacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Required fields section
                        _buildSectionHeader('Basic Information'),
                        const SizedBox(height: AppConstants.mdSpacing),

                        _buildTextField(
                          controller: nameController,
                          label: 'Business Name',
                          hint: 'e.g., Victoria Falls Hotel',
                          icon: Icons.storefront,
                          isRequired: true,
                        ),
                        const SizedBox(height: AppConstants.mdSpacing),

                        _buildDropdown(
                          value: selectedCategory,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedCategory = value);
                            }
                          },
                          label: 'Category',
                          icon: Icons.category,
                          items: categories
                              .skip(1)
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    categoryDisplayNames[category] ?? category,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: AppConstants.mdSpacing),

                        _buildTextField(
                          controller: descriptionController,
                          label: 'Description',
                          hint: 'Tell customers about your business',
                          icon: Icons.description,
                          maxLines: 4,
                          isRequired: true,
                        ),
                        const SizedBox(height: AppConstants.mdSpacing),

                        _buildTextField(
                          controller: locationController,
                          label: 'Location',
                          hint: 'City, Zimbabwe',
                          icon: Icons.location_on,
                          isRequired: true,
                        ),
                        const SizedBox(height: AppConstants.xlSpacing),

                        // Optional fields section
                        _buildSectionHeader('Contact Information (Optional)'),
                        const SizedBox(height: AppConstants.mdSpacing),

                        _buildTextField(
                          controller: contactController,
                          label: 'Phone Number',
                          hint: '+263...',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppConstants.mdSpacing),

                        _buildTextField(
                          controller: emailController,
                          label: 'Email',
                          hint: 'contact@business.com',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppConstants.mdSpacing),

                        _buildTextField(
                          controller: websiteController,
                          label: 'Website',
                          hint: 'https://example.com',
                          icon: Icons.language,
                          isRequired: false, // Explicitly optional
                        ),
                        const SizedBox(height: AppConstants.mdSpacing),

                        // Image Upload Section
                        _buildSectionHeader('Business Image'),
                        const SizedBox(height: AppConstants.smSpacing),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(
                              AppConstants.mdRadius,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (_uploadedImageUrl != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _uploadedImageUrl!,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _isUploadingImage
                                      ? null
                                      : () => _pickAndUploadImage(setState),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Change Image'),
                                ),
                              ] else ...[
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload a cover image for your business',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 16),
                                _isUploadingImage
                                    ? const CircularProgressIndicator()
                                    : ElevatedButton.icon(
                                        onPressed: () =>
                                            _pickAndUploadImage(setState),
                                        icon: const Icon(Icons.upload),
                                        label: const Text('Select Image'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryBlue,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppConstants.mdSpacing),

                        // Additional Information section
                        _buildSectionHeader(
                          'Additional Information (Optional)',
                        ),
                        const SizedBox(height: AppConstants.mdSpacing),

                        // Price row
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: entryFeeController,
                                label: 'Entry Fee / Price',
                                hint: '0.00',
                                icon: Icons.attach_money,
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppConstants.mdSpacing),
                            Expanded(
                              child: _buildDropdown(
                                value: selectedCurrency,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => selectedCurrency = value);
                                  }
                                },
                                label: 'Currency',
                                items: ['USD', 'ZWL', 'EUR', 'GBP', 'ZAR']
                                    .map(
                                      (currency) => DropdownMenuItem(
                                        value: currency,
                                        child: Text(currency),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.mdSpacing),

                        _buildDropdown(
                          value: selectedPriceRange,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedPriceRange = value);
                            }
                          },
                          label: 'Price Range',
                          icon: Icons.money,
                          items: [
                            DropdownMenuItem(
                              value: '\$',
                              child: const Text('\$ - Budget'),
                            ),
                            DropdownMenuItem(
                              value: '\$\$',
                              child: const Text('\$\$ - Moderate'),
                            ),
                            DropdownMenuItem(
                              value: '\$\$\$',
                              child: const Text('\$\$\$ - Expensive'),
                            ),
                            DropdownMenuItem(
                              value: '\$\$\$\$',
                              child: const Text('\$\$\$\$ - Luxury'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.mdSpacing),

                        _buildTextField(
                          controller: openingHoursController,
                          label: 'Opening Hours',
                          hint: 'e.g., Mon-Fri: 9AM-5PM, Sat: 10AM-3PM',
                          icon: Icons.access_time,
                          maxLines: 2,
                        ),
                        const SizedBox(height: AppConstants.mdSpacing),

                        _buildTextField(
                          controller: amenitiesController,
                          label: 'Amenities / Features',
                          hint: 'WiFi, Parking, Air Conditioning, Pool',
                          icon: Icons.stars,
                          maxLines: 2,
                          helperText: 'Separate multiple amenities with commas',
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons - Fixed to prevent overflow
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.lgSpacing,
                    vertical: AppConstants.mdSpacing,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppTheme.borderLight, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.lgSpacing,
                              vertical: AppConstants.mdSpacing,
                            ),
                            minimumSize: const Size(0, 0),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppConstants.mdSpacing),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: _submitBusinessForm,
                          icon: const Icon(Icons.add, size: 20),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Add Business'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.lgSpacing,
                              vertical: AppConstants.mdSpacing,
                            ),
                            minimumSize: const Size(0, 0),
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
      ),
    );
  }

  void _editAttraction(Map<String, dynamic> attraction) {
    final nameController = TextEditingController(text: attraction['name']);
    final descriptionController = TextEditingController(
      text: attraction['description'],
    );
    final locationController = TextEditingController(
      text: attraction['location'],
    );
    final websiteController = TextEditingController(
      text: attraction['website'] ?? '',
    );
    final contactController = TextEditingController(
      text: attraction['contact_phone'] ?? '',
    );
    final emailController = TextEditingController(
      text: attraction['contact_email'] ?? '',
    );
    final entryFeeController = TextEditingController(
      text: attraction['entry_fee']?.toString() ?? '',
    );
    final imageUrlController = TextEditingController(
      text:
          attraction['images'] != null &&
              (attraction['images'] as List).isNotEmpty
          ? (attraction['images'] as List).first
          : '',
    );
    final openingHoursController = TextEditingController(
      text: attraction['opening_hours'] != null
          ? attraction['opening_hours']['text'] ?? ''
          : '',
    );
    final amenitiesController = TextEditingController(
      text: attraction['amenities'] != null
          ? (attraction['amenities'] as List).join(', ')
          : '',
    );
    String selectedCategory = attraction['category'];
    String selectedCurrency = attraction['currency'] ?? 'USD';
    String selectedPriceRange = attraction['price_range'] ?? '\$\$';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Business'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .skip(1)
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(
                            categoryDisplayNames[category] ?? category,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: entryFeeController,
                        decoration: const InputDecoration(
                          labelText: 'Entry Fee / Price',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCurrency,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          border: OutlineInputBorder(),
                        ),
                        items: ['USD', 'ZWL', 'EUR', 'GBP', 'ZAR']
                            .map(
                              (currency) => DropdownMenuItem(
                                value: currency,
                                child: Text(currency),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedCurrency = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPriceRange,
                  decoration: const InputDecoration(
                    labelText: 'Price Range',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: '\$', child: Text('\$ - Budget')),
                    DropdownMenuItem(
                      value: '\$\$',
                      child: Text('\$\$ - Moderate'),
                    ),
                    DropdownMenuItem(
                      value: '\$\$\$',
                      child: Text('\$\$\$ - Expensive'),
                    ),
                    DropdownMenuItem(
                      value: '\$\$\$\$',
                      child: Text('\$\$\$\$ - Luxury'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedPriceRange = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: openingHoursController,
                  decoration: const InputDecoration(
                    labelText: 'Opening Hours',
                    hintText: 'e.g., Mon-Fri: 9AM-5PM',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://example.com/image.jpg',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amenitiesController,
                  decoration: const InputDecoration(
                    labelText: 'Amenities / Features',
                    hintText: 'WiFi, Parking, Pool (comma-separated)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                  // Parse entry fee
                  double? entryFee;
                  if (entryFeeController.text.trim().isNotEmpty) {
                    entryFee = double.tryParse(entryFeeController.text.trim());
                  }

                  // Parse images
                  List<String>? images;
                  if (imageUrlController.text.trim().isNotEmpty) {
                    images = [imageUrlController.text.trim()];
                  }

                  // Parse amenities
                  List<String>? amenities;
                  if (amenitiesController.text.trim().isNotEmpty) {
                    amenities = amenitiesController.text
                        .trim()
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                  }

                  await _attractionsService.updateAttraction(attraction['id'], {
                    'name': nameController.text.trim(),
                    'category': selectedCategory,
                    'description': descriptionController.text.trim(),
                    'location': locationController.text.trim(),
                    'contact_phone': contactController.text.trim().isEmpty
                        ? null
                        : contactController.text.trim(),
                    'contact_email': emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                    'website': websiteController.text.trim().isEmpty
                        ? null
                        : websiteController.text.trim(),
                    'entry_fee': entryFee,
                    'currency': entryFee != null ? selectedCurrency : null,
                    'price_range': selectedPriceRange,
                    'images': images,
                    'amenities': amenities,
                    'opening_hours': openingHoursController.text.trim().isEmpty
                        ? null
                        : {'text': openingHoursController.text.trim()},
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    await _loadMyAttractions();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Business updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update business: $e'),
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

  void _deleteAttraction(Map<String, dynamic> attraction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Business'),
        content: Text(
          'Are you sure you want to delete "${attraction['name']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _attractionsService.deleteAttraction(attraction['id']);

                if (mounted) {
                  Navigator.pop(context);
                  await _loadMyAttractions();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Business deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete business: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
