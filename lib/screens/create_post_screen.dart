import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/travel_provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/upload_service.dart';
import '../services/verification_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isUploading = false;
  

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
        limit: 10,
      );
      
      if (images.isNotEmpty) {
        final imageFiles = images.map((xFile) => File(xFile.path)).toList();
        setState(() {
          _selectedImages = imageFiles;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
    });

    try {
      final travelProvider = Provider.of<TravelProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = AuthService.currentUser;

      // Check if user is authenticated (either real auth or demo mode)
      if (!authProvider.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Check if user is verified for posting
      if (user != null && user.id.isNotEmpty) {
        final canPost = await VerificationService.canUserPost();
        if (!canPost) {
          throw Exception('Account verification required to create posts. Please verify your email address.');
        }
      }

      String userId;
      List<String> imageUrls = [];

      // Check if user is Supabase authenticated (can upload real images)
      if (user != null && user.id.isNotEmpty) {
        // Real authenticated user - upload to Supabase Storage
        userId = user.id;
        print('DEBUG: Uploading images for authenticated user: ${user.id}');
        for (int i = 0; i < _selectedImages.length; i++) {
          try {
            final imageUrl = await UploadService.uploadImageFile(
              bucket: 'posts',
              imageFile: _selectedImages[i],
            );
            if (imageUrl != null) {
              imageUrls.add(imageUrl);
              print('DEBUG: Image uploaded successfully: $imageUrl');
            }
          } catch (e) {
            print('DEBUG: Error uploading image: $e');
            // Continue with other images even if one fails
          }

          // Update progress
          if (mounted) {
            setState(() {
              // Could add progress indicator here
            });
          }
        }
      } else {
        // Demo user - use demo data
        userId = authProvider.userData?['id'] ?? 'demo_user';
        print('DEBUG: Using demo mode for user: $userId');
        print('DEBUG: Auth provider authenticated: ${authProvider.isAuthenticated}');
        print('DEBUG: User data: ${authProvider.userData}');
        // For demo, use placeholder image URLs
        imageUrls = _selectedImages.map((file) =>
          'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch}'
        ).toList();
        print('DEBUG: Generated ${imageUrls.length} placeholder URLs');
      }
      
      // Create post data
      final postData = {
        'user_id': userId,
        'caption': _captionController.text.trim(),
        'location': _locationController.text.trim(),
        'budget': _budgetController.text.trim(),
        'images': imageUrls,
        'likes_count': 0,
        'comments_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Add post through provider (this will need to be updated to use Supabase)
      await travelProvider.addPost(postData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _createPost,
              child: const Text(
                'Share',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info header
                    _buildUserHeader(),
                    const SizedBox(height: AppConstants.lgSpacing),
                    
                    // Caption input
                    _buildCaptionInput(),
                    const SizedBox(height: AppConstants.lgSpacing),
                    
                    // Location input
                    _buildLocationInput(),
                    const SizedBox(height: AppConstants.lgSpacing),
                    
                    // Budget input
                    _buildBudgetInput(),
                    const SizedBox(height: AppConstants.lgSpacing),
                    
                    // Image selection
                    _buildImageSection(),
                    
                    if (_isUploading) ...[
                      const SizedBox(height: AppConstants.lgSpacing),
                      _buildUploadProgress(),
                    ],
                  ],
                ),
              ),
            ),
            
            // Bottom action area
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(AppConstants.lgSpacing),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = AuthService.currentUser;

    if (!authProvider.isAuthenticated) return const SizedBox.shrink();

    String displayName;
    String? avatarUrl;

    if (user != null) {
      // Real authenticated user
      displayName = user.userMetadata?['full_name'] ??
                   user.userMetadata?['name'] ??
                   user.email ?? 'User';
      avatarUrl = user.userMetadata?['avatar_url'];
    } else {
      // Demo user
      final userData = authProvider.userData;
      displayName = userData?['full_name'] ??
                   userData?['label'] ??
                   userData?['name'] ??
                   'Demo User';
      avatarUrl = userData?['avatar_url'];
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: avatarUrl != null
              ? NetworkImage(avatarUrl)
              : null,
          backgroundColor: AppTheme.primaryBlue,
          child: avatarUrl == null
              ? Text(
                  _getNameInitials(displayName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        const SizedBox(width: AppConstants.mdSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Text(
                'Share your travel experience',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getNameInitials(String fullName) {
    if (fullName.isEmpty) return 'U';

    List<String> nameParts = fullName.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
    } else {
      return fullName[0].toUpperCase();
    }
  }

  Widget _buildCaptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Caption',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: AppConstants.smSpacing),
        TextFormField(
          controller: _captionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Share your travel story...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.mdRadius),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.mdRadius),
              borderSide: const BorderSide(color: AppTheme.primaryBlue),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a caption';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: AppConstants.smSpacing),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Where was this taken?',
            prefixIcon: Icon(IconStandards.getUIIcon('location')),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.mdRadius),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.mdRadius),
              borderSide: const BorderSide(color: AppTheme.primaryBlue),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a location';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBudgetInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget (Optional)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: AppConstants.smSpacing),
        TextFormField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'e.g., \$500',
            prefixIcon: Icon(IconStandards.getUIIcon('attach_money')),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.mdRadius),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.mdRadius),
              borderSide: const BorderSide(color: AppTheme.primaryBlue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            TextButton.icon(
              onPressed: _isLoading ? null : _pickImages,
              icon: Icon(IconStandards.getUIIcon('add_photo_alternate')),
              label: const Text('Add Photos'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.smSpacing),
        
        if (_selectedImages.isEmpty)
          _buildEmptyImageState()
        else
          _buildImageGrid(),
      ],
    );
  }

  Widget _buildEmptyImageState() {
    return GestureDetector(
      onTap: _isLoading ? null : _pickImages,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.borderLight,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconStandards.getUIIcon('add_photo_alternate'),
              size: 48,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: AppConstants.smSpacing),
            const Text(
              'Tap to add photos',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppConstants.smSpacing,
        mainAxisSpacing: AppConstants.smSpacing,
        childAspectRatio: 1,
      ),
      itemCount: _selectedImages.length + 1,
      itemBuilder: (context, index) {
        if (index == _selectedImages.length) {
          // Add more button
          return GestureDetector(
            onTap: _isLoading ? null : _pickImages,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.borderLight,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(AppConstants.smRadius),
              ),
              child: Icon(
                IconStandards.getUIIcon('add'),
                color: AppTheme.textSecondary,
                size: 32,
              ),
            ),
          );
        }
        
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.smRadius),
                image: DecorationImage(
                  image: FileImage(_selectedImages[index]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppConstants.mdSpacing),
          Text(
            'Uploading images...',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}