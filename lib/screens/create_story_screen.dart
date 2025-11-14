import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/travel_provider.dart';
import '../services/stories_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/custom_button.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final StoriesService _storiesService = StoriesService.instance;
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createStory() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image for your story'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userData?['id'];

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to create a story'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      print('DEBUG: Starting story creation for user: $userId');
      
      // Upload image to storage
      print('DEBUG: Uploading image...');
      final mediaUrl = await _storiesService.uploadStoryMedia(
        userId: userId,
        imageFile: _selectedImage!,
      );

      print('DEBUG: Upload result: $mediaUrl');
      if (mediaUrl == null) {
        throw Exception('Failed to upload image to storage');
      }

      // Create story in database
      print('DEBUG: Creating story in database...');
      final story = await _storiesService.createStory(
        userId: userId,
        mediaUrl: mediaUrl,
        content: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        mediaType: 'image',
        durationHours: 24,
      );
      
      print('DEBUG: Story creation result: $story');

      if (story != null && mounted) {
        // Reload stories in provider
        final travelProvider = context.read<TravelProvider>();
        await travelProvider.refreshData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story created successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );

        // Navigate back to home
        context.go('/home');
      } else {
        throw Exception('Failed to create story');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating story: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Create Story',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(IconStandards.getUIIcon('close'), color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            child: Column(
              children: [
                // Image preview section
                Container(
                  width: double.infinity,
                  height: screenSize.height * 0.5,
                  color: Colors.grey[900],
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          fit: BoxFit.contain,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              IconStandards.getUIIcon('image'),
                              size: 80,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No image selected',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                ),

                // Image picker buttons
                Container(
                  padding: EdgeInsets.all(
                    isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing,
                  ),
                  color: Colors.grey[900],
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: Icon(IconStandards.getUIIcon('camera')),
                          label: const Text('Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.mdSpacing,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.mdSpacing),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: Icon(IconStandards.getUIIcon('image')),
                          label: const Text('Gallery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.mdSpacing,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Caption and location section
                Container(
                  padding: EdgeInsets.all(
                    isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing,
                  ),
                  color: Colors.black,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Caption field
                      Text(
                        'Caption (Optional)',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smSpacing),
                      TextField(
                        controller: _captionController,
                        maxLines: 3,
                        maxLength: 150,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add a caption to your story...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(AppConstants.mdSpacing),
                        ),
                      ),
                      const SizedBox(height: AppConstants.lgSpacing),

                      // Location field
                      Text(
                        'Location (Optional)',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smSpacing),
                      TextField(
                        controller: _locationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add location...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(AppConstants.mdSpacing),
                          prefixIcon: Icon(
                            IconStandards.getUIIcon('location'),
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.lgSpacing),

                      // Info text
                      Row(
                        children: [
                          Icon(
                            IconStandards.getUIIcon('info'),
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your story will be visible for 24 hours',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
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
          ),

          // Post button (fixed at bottom)
          if (!_isUploading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(
                  isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[800]!,
                      width: 1,
                    ),
                  ),
                ),
                child: CustomButton(
                  onPressed: _selectedImage != null ? _createStory : null,
                  child: Text(
                    'Post Story',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // Loading overlay
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Creating your story...',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
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
}
