import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_animation.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (mounted) {
        if (success) {
          context.go(authProvider.getHomeRoute());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Sign in failed'),
              backgroundColor: AppTheme.primaryRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithDemo() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInAsDemo();

      if (mounted) {
        context.go(authProvider.getHomeRoute());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demo login failed: $e'),
            backgroundColor: AppTheme.primaryRed,
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
      return 'Please enter your password';
    }
    return null;
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
                    Center(
      child: Container(
        width: 80, // Adjust size as needed
        height: 80, // Adjust size as needed
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue, // Blue background
          shape: BoxShape.circle, // Makes it circular
        ),
        child: ClipOval( // Use ClipOval for circular clipping
          child: Container(
            padding: const EdgeInsets.all(16), // Add padding inside the circle
            child: Image.asset(
              'assets/icons/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    ),
                    const SizedBox(height: AppConstants.mdSpacing),

                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Sign in to continue your journey',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppConstants.lgSpacing),

                    // // Demo Login Card
                    // Container(
                    //   padding: const EdgeInsets.all(AppConstants.lgSpacing),
                    //   decoration: BoxDecoration(
                    //     gradient: LinearGradient(
                    //       colors: [
                    //         AppTheme.primaryBlue.withValues(alpha: 0.1),
                    //         AppTheme.primaryPurple.withValues(alpha: 0.1),
                    //       ],
                    //       begin: Alignment.topLeft,
                    //       end: Alignment.bottomRight,
                    //     ),
                    //     borderRadius: BorderRadius.circular(AppConstants.lgRadius),
                    //     border: Border.all(
                    //       color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    //     ),
                    //   ),
                    //   child: Column(
                    //     children: [
                    //       Icon(
                    //         Icons.rocket_launch,
                    //         color: AppTheme.primaryBlue,
                    //         size: 32,
                    //       ),
                    //       const SizedBox(height: AppConstants.smSpacing),
                    //       const Text(
                    //         'Try Demo Mode',
                    //         style: TextStyle(
                    //           fontSize: 18,
                    //           fontWeight: FontWeight.w600,
                    //           color: AppTheme.textPrimary,
                    //         ),
                    //       ),
                    //       const SizedBox(height: AppConstants.smSpacing),
                    //       const Text(
                    //         'Experience Traverse without creating an account',
                    //         style: TextStyle(
                    //           fontSize: 14,
                    //           color: AppTheme.textSecondary,
                    //         ),
                    //         textAlign: TextAlign.center,
                    //       ),
                    //       const SizedBox(height: AppConstants.lgSpacing),
                    //       CustomButton(
                    //         text: 'Continue as Demo',
                    //         onPressed: _isLoading ? null : _signInWithDemo,
                    //         backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    //         foregroundColor: AppTheme.primaryBlue,
                    //         icon: Icons.preview,
                    //         isOutlined: true,
                    //       ),
                    //     ],
                    //   ),
                    // ),

                    // const SizedBox(height: AppConstants.xlSpacing),

                    // // Divider
                    // Row(
                    //   children: [
                    //     const Expanded(child: Divider(color: AppTheme.borderLight)),
                    //     Padding(
                    //       padding: const EdgeInsets.symmetric(horizontal: AppConstants.mdSpacing),
                    //       child: Text(
                    //         'Or sign in with your account',
                    //         style: TextStyle(
                    //           color: AppTheme.textSecondary,
                    //           fontSize: 14,
                    //         ),
                    //       ),
                    //     ),
                    //     const Expanded(child: Divider(color: AppTheme.borderLight)),
                    //   ],
                    // ),
                    const SizedBox(height: AppConstants.xlSpacing),

                    // Form Fields
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
                      hintText: 'Enter your password',
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

                    const SizedBox(height: AppConstants.mdSpacing),

                    // Remember Me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() => _rememberMe = value ?? false);
                              },
                              activeColor: AppTheme.primaryBlue,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            // TODO: Implement forgot password
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Forgot password feature coming soon!',
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.xlSpacing),

                    // Sign In Button
                    _isLoading
                        ? const LoadingAnimation()
                        : CustomButton(
                            text: 'Sign In',
                            onPressed: _signIn,
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            icon: IconStandards.getUIIcon('login'),
                          ),

                    const SizedBox(height: AppConstants.lgSpacing),

                    // Social Sign In Section
                    _buildSocialSignInSection(),

                    const SizedBox(height: AppConstants.lgSpacing),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.go('/signup');
                          },
                          child: const Text(
                            'Sign Up',
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

                    // Footer
                    const Text(
                      'By signing in, you agree to our Terms of Service and Privacy Policy',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialSignInSection() {
    return Column(
      children: [
        // Divider with "OR" text
        Row(
          children: [
            const Expanded(child: Divider(color: AppTheme.borderLight)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.mdSpacing),
              child: Text(
                'OR',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppTheme.borderLight)),
          ],
        ),

        const SizedBox(height: AppConstants.lgSpacing),

        // Social Sign In Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSocialButton(
              'Google',
              'assets/icons/google.png',
              () => _signInWithGoogle(),
            ),
            _buildSocialButton(
              'Facebook',
              'assets/icons/facebook.png',
              () => _signInWithFacebook(),
            ),
            if (Theme.of(context).platform == TargetPlatform.iOS)
              _buildSocialButton(
                'Apple',
                'assets/icons/apple.png',
                () => _signInWithApple(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(String name, String iconPath, VoidCallback onPressed) {
    return GestureDetector(
      onTap: _isLoading ? null : onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.mdRadius),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            iconPath,
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to text if image not found
              return Text(
                name[0],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithGoogle();

      if (mounted) {
        if (success) {
          context.go(authProvider.getHomeRoute());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Google sign in failed'),
              backgroundColor: AppTheme.primaryRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithFacebook();

      if (mounted) {
        if (success) {
          context.go(authProvider.getHomeRoute());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Facebook sign in failed'),
              backgroundColor: AppTheme.primaryRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithApple();

      if (mounted) {
        if (success) {
          context.go(authProvider.getHomeRoute());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Apple sign in failed'),
              backgroundColor: AppTheme.primaryRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
