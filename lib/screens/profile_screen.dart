import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
// Add this import
import 'dart:io';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/verification_badge.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final userData = authProvider.userData;
    if (userData != null) {
      // Load data from database fields
      _nameController.text = userData['full_name'] ?? userData['label'] ?? '';
      _emailController.text = userData['email'] ?? '';
      _bioController.text = userData['bio'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      String? avatarUrl;
      
      // Upload image if selected
      if (_selectedImage != null) {
        avatarUrl = await SupabaseService.uploadProfileImage(_selectedImage!);
      }
      
      // Update user profile
      final updatedData = {
        'full_name': _nameController.text,
        'email': _emailController.text,
        'bio': _bioController.text,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };
      
      await SupabaseService.instance.updateUserProfile(updatedData);
      
      // Update local auth provider
      final currentData = authProvider.userData ?? {};
      authProvider.updateUserData({
        ...currentData,
        'label': _nameController.text,
        'full_name': _nameController.text,
        'bio': _bioController.text,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });
      
      setState(() {
        _isEditing = false;
        _selectedImage = null;
      });
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userData = authProvider.userData;
        
        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
                child: Text(_isEditing ? 'Cancel' : 'Edit'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.lgSpacing),
            child: Column(
              children: [
                // Profile Avatar
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : userData?['avatar_url'] != null
                                ? NetworkImage(userData!['avatar_url']!)
                                : null,
                        backgroundColor: AppTheme.primaryBlue,
                        child: _selectedImage == null && userData?['avatar_url'] == null
                            ? Text(
                                _getNameInitials(userData),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                               color: AppTheme.primaryBlue,
                               shape: BoxShape.circle,
                             ),
                            child: Icon(
                              IconStandards.getUIIcon('camera'),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.lgSpacing),
                
                // Profile Information
                CustomCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.lgSpacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.lgSpacing),
                        
                        // Name Field
                        _buildProfileField(
                          'Name',
                          _nameController,
                          IconStandards.getUIIcon('person'),
                        ),
                        const SizedBox(height: AppConstants.mdSpacing),
                        
                        // Email Field
                        _buildProfileField(
                          'Email',
                          _emailController,
                          IconStandards.getUIIcon('email'),
                        ),
                        const SizedBox(height: AppConstants.mdSpacing),
                        
                        // Bio Field
                        _buildProfileField(
                          'Bio',
                          _bioController,
                          IconStandards.getUIIcon('info'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppConstants.mdSpacing),

                        // User Type (Read-only)
                        _buildReadOnlyField(
                          'User Type',
                          _getRoleDisplay(userData?['role'] ?? userData?['label'] ?? 'traveler'),
                          IconStandards.getUIIcon('badge'),
                        ),
                        const SizedBox(height: AppConstants.mdSpacing),

                        // Verification Status
                        const Divider(),
                        const SizedBox(height: AppConstants.mdSpacing),
                        Row(
                          children: [
                            Icon(
                              Icons.verified_user,
                              color: AppTheme.primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Verification Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            VerificationBadge(
                              verificationStatus: authProvider.verificationStatus,
                              showText: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.smSpacing),
                        Text(
                          authProvider.isVerified
                            ? 'Your account is verified and has full access to all features.'
                            : 'Verify your account to unlock posting, AI features, and chat saving.',
                          style: TextStyle(
                            color: authProvider.isVerified ? AppTheme.primaryGreen : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        
                        if (_isEditing) ...[
                          const SizedBox(height: AppConstants.lgSpacing),
                          CustomButton(
                             onPressed: _isLoading ? null : _saveProfile,
                             child: _isLoading
                                 ? const CircularProgressIndicator(color: Colors.white)
                                 : const Text('Save Changes'),
                           ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppConstants.lgSpacing),
                
                // Account Actions
                CustomCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.lgSpacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.lgSpacing),
                        
                        ListTile(
                          leading: Icon(IconStandards.getActionIcon('add'), color: AppTheme.primaryBlue),
                          title: const Text(
                            'Create Post',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text('Share your travel experience'),
                          trailing: Icon(IconStandards.getUIIcon('arrow_forward')),
                          onTap: () {
                            context.go('/create-post');
                          },
                        ),

                        ListTile(
                          leading: Icon(IconStandards.getUIIcon('settings')),
                          title: const Text('Settings'),
                          trailing: Icon(IconStandards.getUIIcon('arrow_forward')),
                          onTap: () {
                            // Navigate to settings
                          },
                        ),
                        
                        ListTile(
                          leading: Icon(IconStandards.getUIIcon('help')),
                          title: const Text('Help & Support'),
                          trailing: Icon(IconStandards.getUIIcon('arrow_forward')),
                          onTap: () {
                            // Navigate to help
                          },
                        ),
                        
                        ListTile(
                          leading: const Icon(Icons.notifications_active, color: Colors.blue),
                          title: const Text('Real-Time Features Demo'),
                          subtitle: const Text('Test messaging and notifications'),
                          trailing: Icon(IconStandards.getUIIcon('arrow_forward')),
                          onTap: () {
                            context.push('/real-time-demo');
                          },
                        ),
                        
                        const Divider(),
                        
                        ListTile(
                          leading: Icon(IconStandards.getUIIcon('article')),
                          title: const Text('Terms & Conditions'),
                          trailing: Icon(IconStandards.getUIIcon('arrow_forward_ios'), size: 16),
                          onTap: () => context.go('/terms-conditions'),
                        ),

                        const Divider(height: 1),

                        ListTile(
                          leading: Icon(IconStandards.getUIIcon('logout'), color: Colors.red),
                          title: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: authProvider.isLoading ? null : () async {
                            final router = GoRouter.of(context);
                            await authProvider.signOut();
                            if (mounted) {
                              router.go('/');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const CustomBottomNavigation(),
        );
      },
    );
  }
  
  Widget _buildProfileField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.smSpacing),
        TextField(
          controller: controller,
          enabled: _isEditing,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.mdRadius),
            ),
            filled: !_isEditing,
            fillColor: _isEditing ? null : AppTheme.backgroundLight,
          ),
        ),
      ],
    );
  }
  
  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.smSpacing),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.mdSpacing,
            vertical: AppConstants.lgSpacing,
          ),
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(AppConstants.mdRadius),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.textSecondary),
              const SizedBox(width: AppConstants.mdSpacing),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }

  String _getNameInitials(Map<String, dynamic>? userData) {
    if (userData == null) return 'U';

    // Try different fields for the name
    String? fullName = userData['full_name'] ??
                      userData['label'] ??
                      userData['name'] ??
                      userData['email'];

    if (fullName == null || fullName.isEmpty) return 'U';

    // Extract initials
    List<String> nameParts = fullName.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
    } else {
      return fullName[0].toUpperCase();
    }
  }

  String _getRoleDisplay(String role) {
    // Convert role to display name
    switch (role.toLowerCase()) {
      case 'traveler':
        return 'Traveler';
      case 'business':
        return 'Business Owner';
      case 'guide':
        return 'Tour Guide';
      case 'admin':
        return 'Administrator';
      default:
        return role.substring(0, 1).toUpperCase() + role.substring(1);
    }
  }
}