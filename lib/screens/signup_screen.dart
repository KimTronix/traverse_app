import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_animation.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'traveler';

  final List<String> _roles = [
    'traveler',
    'business',
    'guide',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Check if email already exists
      final emailExists = await AuthService.emailExists(_emailController.text.trim());
      if (emailExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An account with this email already exists'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if username already exists
      final usernameExists = await AuthService.usernameExists(_usernameController.text.trim());
      if (usernameExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This username is already taken'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final userData = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'fullName': _fullNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'role': _selectedRole,
      };

      print('SignUp: Starting signup with role: $_selectedRole');
      final success = await authProvider.signUp(userData);
      print('SignUp: Signup success: $success');

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          context.go(authProvider.getHomeRoute());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Registration failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'I am a',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.smSpacing),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.mdRadius),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            children: _roles.map((role) => _buildRoleOption(role)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleOption(String role) {
    final isSelected = _selectedRole == role;
    final isLast = role == _roles.last;

    String roleTitle;
    String roleDescription;
    IconData roleIcon;

    switch (role) {
      case 'traveler':
        roleTitle = 'Traveler';
        roleDescription = 'Explore destinations and share experiences';
        roleIcon = Icons.luggage;
        break;
      case 'business':
        roleTitle = 'Business Owner';
        roleDescription = 'List and manage your travel business';
        roleIcon = Icons.business;
        break;
      case 'guide':
        roleTitle = 'Tour Guide';
        roleDescription = 'Offer guided tours and experiences';
        roleIcon = Icons.tour;
        break;
      default:
        roleTitle = role;
        roleDescription = '';
        roleIcon = Icons.person;
    }

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.1) : Colors.transparent,
        border: !isLast ? const Border(bottom: BorderSide(color: AppTheme.borderLight)) : null,
      ),
      child: RadioListTile<String>(
        value: role,
        groupValue: _selectedRole,
        onChanged: (value) {
          setState(() => _selectedRole = value!);
        },
        title: Row(
          children: [
            Icon(
              roleIcon,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppConstants.smSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                  ),
                ),
                if (roleDescription.isNotEmpty)
                  Text(
                    roleDescription,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
        activeColor: AppTheme.primaryBlue,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppConstants.mdSpacing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                isSmallScreen ? AppConstants.lgSpacing : AppConstants.xlSpacing,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Icon(
                      IconStandards.getUIIcon('travel_explore'),
                      size: 48,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(height: AppConstants.mdSpacing),

                    const Text(
                      'Join Traverse',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Start your journey with us',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppConstants.lgSpacing),

                    // Form Fields
                    CustomInput(
                      controller: _fullNameController,
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      prefixIcon: IconStandards.getUIIcon('person'),
                      validator: _validateFullName,
                    ),

                    const SizedBox(height: AppConstants.lgSpacing),

                    CustomInput(
                      controller: _usernameController,
                      labelText: 'Username',
                      hintText: 'Choose a unique username',
                      prefixIcon: IconStandards.getUIIcon('alternate_email'),
                      validator: _validateUsername,
                    ),

                    const SizedBox(height: AppConstants.lgSpacing),

                    CustomInput(
                      controller: _emailController,
                      labelText: 'Email',
                      hintText: 'Enter your email address',
                      prefixIcon: IconStandards.getUIIcon('email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),

                    const SizedBox(height: AppConstants.lgSpacing),

                    CustomInput(
                      controller: _passwordController,
                      labelText: 'Password',
                      hintText: 'Create a strong password',
                      prefixIcon: IconStandards.getUIIcon('lock'),
                      obscureText: _obscurePassword,
                      suffixWidget: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? IconStandards.getUIIcon('visibility')
                              : IconStandards.getUIIcon('visibility_off'),
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: _validatePassword,
                    ),

                    const SizedBox(height: AppConstants.lgSpacing),

                    CustomInput(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      hintText: 'Confirm your password',
                      prefixIcon: IconStandards.getUIIcon('lock'),
                      obscureText: _obscureConfirmPassword,
                      suffixWidget: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? IconStandards.getUIIcon('visibility')
                              : IconStandards.getUIIcon('visibility_off'),
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                      validator: _validateConfirmPassword,
                    ),

                    const SizedBox(height: AppConstants.xlSpacing),

                    // Role Selector
                    _buildRoleSelector(),

                    const SizedBox(height: AppConstants.xlSpacing * 2),

                    // Sign Up Button
                    _isLoading
                        ? const LoadingAnimation()
                        : CustomButton(
                            text: 'Create Account',
                            onPressed: _signUp,
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            icon: IconStandards.getUIIcon('person_add'),
                          ),

                    const SizedBox(height: AppConstants.lgSpacing),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.go('/signin');
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.xlSpacing),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}