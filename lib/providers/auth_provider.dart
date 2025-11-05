import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import '../services/auth_service.dart';
import '../services/verification_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userType = 'traveler';
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _verificationStatus = {};

  bool get isAuthenticated => _isAuthenticated;
  String? get userType => _userType;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _userType == 'admin';
  Map<String, dynamic> get verificationStatus => _verificationStatus;
  bool get isVerified => _verificationStatus.isNotEmpty;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Listen to auth state changes
    AuthService.authStateChanges.listen((AuthState data) {
      _handleAuthStateChange(data);
    });
    
    // Check current auth state
    await _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    try {
      final user = AuthService.currentUser;
      if (user != null) {
        _isAuthenticated = true;

        // Try to get user profile from database first
        try {
          final profile = await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', user.id)
              .maybeSingle();

          if (profile != null) {
            // Use database profile
            _userType = profile['role'] ?? 'traveler';
            _userData = {
              'id': user.id,
              'email': user.email,
              'full_name': profile['full_name'],
              'username': profile['username'],
              'role': profile['role'],
              'bio': profile['bio'],
              'location': profile['location'],
              'avatar_url': profile['avatar_url'],
              'is_verified': profile['is_verified'] ?? false,
              'is_active': profile['is_active'] ?? true,
              'provider': 'supabase',
            };
            Logger.info('Real Supabase user authenticated: ${user.email} (@${profile['username']})');

            // Load verification status
            await _loadVerificationStatus();
          } else {
            // Fallback to user metadata if no profile exists yet
            _userType = user.userMetadata?['role'] ?? 'traveler';
            _userData = {
              'id': user.id,
              'email': user.email,
              'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
              'username': user.userMetadata?['username'] ?? user.email?.split('@')[0].replaceAll('.', '_'),
              'role': user.userMetadata?['role'] ?? 'traveler',
              'is_verified': user.emailConfirmedAt != null,
              'is_active': true,
              'provider': 'supabase',
            };
            Logger.info('Supabase user authenticated (no profile yet): ${user.email}');
          }
        } catch (dbError) {
          Logger.warning('Could not fetch user profile from database: $dbError');
          // Fallback to user metadata
          _userType = user.userMetadata?['role'] ?? 'traveler';
          _userData = {
            'id': user.id,
            'email': user.email,
            'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
            'username': user.userMetadata?['username'] ?? user.email?.split('@')[0].replaceAll('.', '_'),
            'role': user.userMetadata?['role'] ?? 'traveler',
            'is_verified': user.emailConfirmedAt != null,
            'is_active': true,
            'provider': 'supabase',
          };
        }
      } else {
        _isAuthenticated = false;
        _userType = null;
        _userData = null;
        _verificationStatus = {};
      }
    } catch (e) {
      Logger.error('Error in _checkCurrentUser: $e');
      _isAuthenticated = false;
      _userType = null;
      _userData = null;
      _verificationStatus = {};
    }
    notifyListeners();
  }

  void _handleAuthStateChange(AuthState data) {
    if (data.event == AuthChangeEvent.signedIn) {
      _checkCurrentUser();
    } else if (data.event == AuthChangeEvent.signedOut) {
      _isAuthenticated = false;
      _userType = null;
      _userData = null;
      _verificationStatus = {};
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load verification status for current user
  Future<void> _loadVerificationStatus() async {
    try {
      _verificationStatus = await VerificationService.getVerificationStatus();
    } catch (e) {
      Logger.error('Error loading verification status: $e');
      _verificationStatus = {};
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.signInWithEmail(email, password);
      
      if (response.user != null) {
        await _checkCurrentUser();
        return true;
      } else {
        _errorMessage = 'Sign in failed';
        return false;
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String username,
    String role = 'traveler',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Logger.info('AuthProvider: Attempting signup for $email with role $role');

      final response = await AuthService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        username: username,
        role: role,
      );

      Logger.info('AuthProvider: Signup response received - User: ${response.user?.id ?? "null"}');

      if (response.user != null) {
        Logger.info('AuthProvider: User created successfully, checking current user');
        await _checkCurrentUser();
        Logger.info('AuthProvider: Signup complete');
        return true;
      } else {
        Logger.error('AuthProvider: Signup failed - no user in response');
        _errorMessage = 'Sign up failed';
        return false;
      }
    } catch (e, stackTrace) {
      Logger.error('AuthProvider: Signup exception: $e');
      Logger.error('AuthProvider: Stack trace: $stackTrace');
      _errorMessage = _getErrorMessage(e.toString());
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // General sign in method that delegates to appropriate service
  Future<bool> signIn(String email, String password, {bool rememberMe = false}) async {
    return await signInWithEmail(email, password);
  }

  // Sign up method that delegates to appropriate service
  Future<bool> signUp(Map<String, dynamic> userData) async {
    try {
      print('AuthProvider: Starting signup with data: ${userData.keys.toList()}');
      final result = await signUpWithEmail(
        email: userData['email'],
        password: userData['password'],
        fullName: userData['fullName'],
        username: userData['username'],
        role: userData['role'] ?? 'traveler',
      );
      print('AuthProvider: Signup result: $result');
      return result;
    } catch (e) {
      print('AuthProvider: Signup error: $e');
      rethrow;
    }
  }

  // Demo sign in (for backward compatibility)
  Future<void> signInAsDemo([String? userType]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get demo credentials
      final userTypeData = AppConstants.userTypes.firstWhere(
        (user) => user['value'] == userType,
      );
      
      final credentials = userTypeData['credentials'] as Map<String, dynamic>;
      final success = await signInWithEmail(
        credentials['email'] as String,
        credentials['password'] as String,
      );
      
      if (!success && _errorMessage != null) {
        // If real auth fails, fall back to demo mode for development
        _isAuthenticated = true;
        _userType = userType;
        // Add demo user ID for chat functionality
        _userData = {
          ...userTypeData,
          'id': 'demo_${userType}_${DateTime.now().millisecondsSinceEpoch}',
          'email': credentials['email'],
        };
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.signOut();
      _isAuthenticated = false;
      _userType = null;
      _userData = null;
      _verificationStatus = {};
      _errorMessage = null;
      await _secureStorage.delete(key: 'session_token');
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateUserData(Map<String, dynamic> userData) {
    _userData = userData;
    notifyListeners();
  }

  String getHomeRoute() {
    switch (_userType) {
      case 'admin':
        return '/admin';
      case 'business':
        return '/home';
      case 'guide':
      case 'traveler':
      default:
        return '/home';
    }
  }

  // Check if user has admin privileges
  Future<bool> checkAdminAccess() async {
    try {
      return await AuthService.isAdmin();
    } catch (e) {
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.signInWithGoogle();
      
      if (response.user != null) {
        await _checkCurrentUser();
        return true;
      } else {
        _errorMessage = 'Google sign in failed';
        return false;
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load saved session from secure storage
  Future<void> _loadSavedSession() async {
    final savedToken = await _secureStorage.read(key: 'session_token');
    if (savedToken != null) {
      // restore your session using savedToken
      // e.g., supabaseClient.auth.setSession(...) or validate token and set local user state
      _isAuthenticated = true; // set your internal flags accordingly
      notifyListeners();
    }
  }

  // Helper method to format error messages
  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (error.contains('Email not confirmed')) {
      return 'Please check your email and confirm your account';
    } else if (error.contains('User already registered')) {
      return 'An account with this email already exists';
    } else if (error.contains('Password should be at least 6 characters')) {
      return 'Password must be at least 6 characters long';
    } else if (error.contains('duplicate key value violates unique constraint')) {
      if (error.contains('users_email_key')) {
        return 'An account with this email already exists';
      } else if (error.contains('users_username_key')) {
        return 'This username is already taken';
      } else {
        return 'This information is already in use';
      }
    } else if (error.contains('Database insert error')) {
      return 'Failed to create user profile. Please try again.';
    } else if (error.contains('connection')) {
      return 'Connection error. Please check your internet connection.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }
}