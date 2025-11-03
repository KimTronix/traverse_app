import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/supabase_config.dart';
import '../utils/logger.dart';
import 'verification_service.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Storage keys for user data
  static const String _usersStorageKey = 'traverse_users';
  static const String _currentUserKey = 'traverse_current_user';

  // Get current user
  static User? get currentUser => _client.auth.currentUser;

  // Check if user is authenticated
  static bool get isAuthenticated => _client.auth.currentUser != null;

  // Get stored users from SharedPreferences
  static Future<Map<String, Map<String, dynamic>>> _getStoredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersStorageKey);
      if (usersJson != null) {
        final decoded = json.decode(usersJson) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
      }
    } catch (e) {
      Logger.error('Error loading stored users: $e');
    }
    return {};
  }

  // Save users to SharedPreferences
  static Future<void> _saveUsers(Map<String, Map<String, dynamic>> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = json.encode(users);
      await prefs.setString(_usersStorageKey, usersJson);
      Logger.info('Users saved to storage');
    } catch (e) {
      Logger.error('Error saving users: $e');
    }
  }

  // Store user data after signup
  static Future<void> _storeUser({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String role,
  }) async {
    try {
      final users = await _getStoredUsers();
      users[email.toLowerCase()] = {
        'email': email,
        'password': password, // In a real app, this would be hashed
        'fullName': fullName,
        'username': username,
        'role': role,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };
      await _saveUsers(users);
      Logger.info('User stored: $email');
    } catch (e) {
      Logger.error('Error storing user: $e');
    }
  }

  // Validate user credentials
  static Future<Map<String, dynamic>?> _validateCredentials(String email, String password) async {
    try {
      final users = await _getStoredUsers();
      final user = users[email.toLowerCase()];

      if (user != null && user['password'] == password && user['isActive'] == true) {
        Logger.info('Credentials validated for: $email');
        return user;
      }

      Logger.warning('Invalid credentials for: $email');
      return null;
    } catch (e) {
      Logger.error('Error validating credentials: $e');
      return null;
    }
  }

  // Sign in with email and password using real Supabase authentication
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      Logger.info('Attempting real Supabase signin for email: $email');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        Logger.info('Successfully signed in with Supabase: $email');
        // Sync user data to local database
        await _syncUserToDatabase(response.user!);
        // Auto-verify email if confirmed
        await VerificationService.autoVerifyEmail();
      }

      return response;
    } catch (e) {
      Logger.error('Supabase signin error for $email: $e');
      rethrow;
    }
  }

  // Sync authenticated user to local users table
  static Future<void> _syncUserToDatabase(User user) async {
    try {
      // Check if user exists in our users table
      final existingUser = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        // User doesn't exist, create profile
        final userData = {
          'id': user.id,
          'email': user.email,
          'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
          'username': user.userMetadata?['username'] ?? user.email?.split('@')[0].replaceAll('.', '_'),
          'role': user.userMetadata?['role'] ?? 'traveler',
          'email_verified': user.emailConfirmedAt != null,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _client.from('users').insert(userData);
        Logger.info('Created user profile in database for: ${user.email}');
      } else {
        Logger.info('User profile already exists in database: ${user.email}');
      }
    } catch (e) {
      Logger.error('Error syncing user to database: $e');
    }
  }

  // Legacy mock signin (keeping for fallback)
  static Future<AuthResponse> _mockSignInWithEmail(String email, String password) async {
    try {
      Logger.info('Attempting mock signin for email: $email');

      // Validate credentials against stored users
      final userData = await _validateCredentials(email, password);

      if (userData == null) {
        throw Exception('Invalid email or password');
      }

      // Create authenticated user with stored data
      final authenticatedUser = User(
        id: 'user-${email.hashCode}',
        appMetadata: {},
        userMetadata: {
          'email': userData['email'],
          'full_name': userData['fullName'],
          'username': userData['username'],
          'role': userData['role'],
        },
        aud: 'authenticated',
        createdAt: userData['createdAt'],
      );

      final userSession = Session(
        accessToken: 'access-token-${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'refresh-token-${DateTime.now().millisecondsSinceEpoch}',
        expiresIn: 3600,
        tokenType: 'bearer',
        user: authenticatedUser,
      );

      Logger.info('Signin successful for: $email (${userData['role']})');
      return AuthResponse(user: authenticatedUser, session: userSession);
    } catch (e) {
      Logger.error('Error in signin: $e');
      rethrow;
    }
  }

  // Sign up with email and password using real Supabase authentication
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String username,
    String role = 'traveler',
  }) async {
    try {
      Logger.info('Attempting real Supabase signup for email: $email');

      // Check if username is already taken in our users table
      final existingUsername = await _client
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existingUsername != null) {
        throw Exception('This username is already taken');
      }

      // Create user with Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'username': username,
          'role': role,
        },
      );

      if (response.user != null) {
        Logger.info('Successfully signed up with Supabase: $email');

        // Immediately create user profile in the users table
        try {
          final userData = {
            'id': response.user!.id,
            'email': email,
            'full_name': fullName,
            'username': username,
            'role': role,
            'email_verified': response.user!.emailConfirmedAt != null,
            'is_active': true,
            'provider': 'email',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };

          await _client.from('users').insert(userData);
          Logger.info('Created user profile in database for: $email');
        } catch (dbError) {
          Logger.error('Error creating user profile in database: $dbError');
          // Don't throw error here - the user is created in auth, profile can be synced later
        }

        // Auto-verify email if confirmed
        await VerificationService.autoVerifyEmail();
      }

      return response;
    } catch (e) {
      Logger.error('Supabase signup error for $email: $e');
      rethrow;
    }
  }

  // Legacy mock signup (keeping for fallback)
  static Future<AuthResponse> _mockSignUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String username,
    String role = 'traveler',
  }) async {
    try {
      Logger.info('Mock signup process for email: $email');

      // Check if user already exists
      final existingUsers = await _getStoredUsers();
      if (existingUsers.containsKey(email.toLowerCase())) {
        throw Exception('An account with this email already exists');
      }

      // Check if username is already taken
      final usernameTaken = existingUsers.values.any((user) =>
        user['username']?.toLowerCase() == username.toLowerCase());
      if (usernameTaken) {
        throw Exception('This username is already taken');
      }

      // Store user data
      await _storeUser(
        email: email,
        password: password,
        fullName: fullName,
        username: username,
        role: role,
      );

      // Create authenticated user
      final newUser = User(
        id: 'user-$email.hashCode',
        appMetadata: {},
        userMetadata: {
          'email': email,
          'full_name': fullName,
          'username': username,
          'role': role,
        },
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      final userSession = Session(
        accessToken: 'access-token-${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'refresh-token-${DateTime.now().millisecondsSinceEpoch}',
        expiresIn: 3600,
        tokenType: 'bearer',
        user: newUser,
      );

      Logger.info('Signup successful for: $email (${role})');
      return AuthResponse(user: newUser, session: userSession);
    } catch (e) {
      Logger.error('Error in signup: $e');
      rethrow;
    }
  }

  // Get all stored users (for debugging and user management)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final users = await _getStoredUsers();
      return users.values.map((user) {
        // Remove password from returned data for security
        final safeUser = Map<String, dynamic>.from(user);
        safeUser.remove('password');
        return safeUser;
      }).toList();
    } catch (e) {
      Logger.error('Error getting all users: $e');
      return [];
    }
  }

  // Check if email exists (for signup validation)
  static Future<bool> emailExists(String email) async {
    try {
      final users = await _getStoredUsers();
      return users.containsKey(email.toLowerCase());
    } catch (e) {
      Logger.error('Error checking email existence: $e');
      return false;
    }
  }

  // Check if username exists (for signup validation)
  static Future<bool> usernameExists(String username) async {
    try {
      final users = await _getStoredUsers();
      return users.values.any((user) =>
        user['username']?.toLowerCase() == username.toLowerCase());
    } catch (e) {
      Logger.error('Error checking username existence: $e');
      return false;
    }
  }

  // Sign in with Google
  static Future<AuthResponse> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw Exception('No Access Token found.');
      }
      if (idToken == null) {
        throw Exception('No ID Token found.');
      }

      // Sign in to Supabase with Google credentials
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // Create or update user profile
      if (response.user != null) {
        await _createOrUpdateUserProfile(
          user: response.user!,
          provider: 'google',
          providerData: {
            'google_id': googleUser.id,
            'display_name': googleUser.displayName,
            'photo_url': googleUser.photoUrl,
          },
        );
        // Auto-verify email for Google users
        await VerificationService.autoVerifyEmail();
      }

      return response;
    } catch (e) {
      Logger.error('Error signing in with Google', e);
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      // Sign out from Supabase
      await _client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile with role
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await _client
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      Logger.error('Error getting user profile', e);
      return null;
    }
  }

  // Check if user has admin role
  static Future<bool> isAdmin() async {
    try {
      final profile = await getUserProfile();
      return profile?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  // Check if user has specific role
  static Future<bool> hasRole(String role) async {
    try {
      final profile = await getUserProfile();
      return profile?['role'] == role;
    } catch (e) {
      return false;
    }
  }

  // Create demo account if it doesn't exist (mock version)
  static Future<bool> createDemoAccountIfNeeded() async {
    try {
      const demoEmail = 'innocentmafusire@gmail.com';
      const demoPassword = 'sirpass';
      
      Logger.info('Setting up mock demo account...');
      
      // Since we're using mock authentication, we can always "create" the demo account
      Logger.info('Creating mock demo account...');
      
      final response = await signUpWithEmail(
        email: demoEmail,
        password: demoPassword,
        fullName: 'Demo User',
        username: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
        role: 'traveler',
      );
      
      if (response.user != null) {
        Logger.info('Mock demo account created successfully with ID: ${response.user!.id}');
        await _client.auth.signOut(); // Sign out after creation
        return true;
      } else {
        Logger.warning('Mock demo account creation returned null user');
        return false;
      }
    } catch (e) {
      Logger.error('Error in createDemoAccountIfNeeded', e);
      return false;
    }
   }
   
   // Test demo credentials functionality (mock version)
   static Future<bool> testDemoCredentials() async {
     try {
       const demoEmail = 'innocentmafusire@gmail.com';
       const demoPassword = 'sirpass';
       
       Logger.info('Testing mock demo credentials...');
       
       // Try to sign in with mock system
       final signInResponse = await signInWithEmail(demoEmail, demoPassword);
       if (signInResponse.user != null) {
         Logger.info('Mock demo credentials work! User ID: ${signInResponse.user!.id}');
         Logger.info('Mock demo user: ${signInResponse.user!.userMetadata?['full_name']} (${signInResponse.user!.userMetadata?['role']})');
         Logger.info('Mock demo account is ready for posting and liking!');
         
         // Sign out after testing
         await _client.auth.signOut();
         return true;
       } else {
         Logger.warning('Mock demo credentials sign in failed');
         return false;
       }
     } catch (e) {
       Logger.error('Error testing mock demo credentials', e);
       return false;
     }
   }
 
    // Update user role (admin only)
  static Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      // Check if current user is admin
      if (!await isAdmin()) {
        throw Exception('Unauthorized: Admin access required');
      }

      await _client
          .from(SupabaseConfig.usersTable)
          .update({'role': newRole})
          .eq('id', userId);

      return true;
    } catch (e) {
      Logger.error('Error updating user role', e);
      return false;
    }
  }


  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Listen to auth state changes
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Create admin user (for initial setup)
  static Future<bool> createAdminUser({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    try {
      final response = await signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        username: username,
        role: 'admin',
      );
      
      return response.user != null;
    } catch (e) {
      Logger.error('Error creating admin user', e);
      return false;
    }
  }

  // Helper method to create or update user profile for OAuth users
  static Future<void> _createOrUpdateUserProfile({
    required User user,
    required String provider,
    Map<String, dynamic>? providerData,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await _client
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final userData = {
        'id': user.id,
        'email': user.email ?? '',
        'full_name': user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? '',
        'avatar_url': user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
        'provider': provider,
        'provider_id': providerData?['google_id'] ?? user.id,
        'provider_data': providerData ?? {},
        'email_verified': user.emailConfirmedAt != null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existingUser == null) {
        // Create new user profile
        userData['username'] = _generateUsername(userData['full_name'] as String);
        userData['created_at'] = DateTime.now().toIso8601String();
        
        await _client.from(SupabaseConfig.usersTable).insert(userData);
      } else {
        // Update existing user profile
        await _client
            .from(SupabaseConfig.usersTable)
            .update(userData)
            .eq('id', user.id);
      }
    } catch (e) {
      Logger.error('Error creating/updating user profile', e);
      rethrow;
    }
  }

  // Helper method to generate username from full name
  static String _generateUsername(String fullName) {
    final baseUsername = fullName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .substring(0, fullName.length > 15 ? 15 : fullName.length);
    
    // Add random numbers to make it unique
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return '${baseUsername}_${timestamp.substring(timestamp.length - 4)}';
  }

  // Admin functions for user management
  static Future<List<Map<String, dynamic>>> getAllUsersForAdmin() async {
    try {
      // Check if current user is admin
      if (!await isAdmin()) {
        throw Exception('Unauthorized: Admin access required');
      }

      final response = await _client
          .from(SupabaseConfig.usersTable)
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error getting all users for admin: $e');
      rethrow;
    }
  }

  // Delete user (admin only)
  static Future<bool> deleteUserAsAdmin(String userId) async {
    try {
      // Check if current user is admin
      if (!await isAdmin()) {
        throw Exception('Unauthorized: Admin access required');
      }

      // Delete user from Supabase Auth (this will cascade delete related data)
      await _client.auth.admin.deleteUser(userId);

      // Also delete from our users table
      await _client
          .from(SupabaseConfig.usersTable)
          .delete()
          .eq('id', userId);

      Logger.info('User deleted successfully by admin: $userId');
      return true;
    } catch (e) {
      Logger.error('Error deleting user as admin: $e');
      return false;
    }
  }

  // Create user as admin
  static Future<AuthResponse?> createUserAsAdmin({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String role,
  }) async {
    try {
      // Check if current user is admin
      if (!await isAdmin()) {
        throw Exception('Unauthorized: Admin access required');
      }

      final response = await signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        username: username,
        role: role,
      );

      Logger.info('User created by admin: $email');
      return response;
    } catch (e) {
      Logger.error('Error creating user as admin: $e');
      rethrow;
    }
  }

  // Update user role (admin only)
  static Future<bool> updateUserRoleAsAdmin(String userId, String newRole) async {
    try {
      // Check if current user is admin
      if (!await isAdmin()) {
        throw Exception('Unauthorized: Admin access required');
      }

      await _client
          .from(SupabaseConfig.usersTable)
          .update({'role': newRole, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);

      Logger.info('User role updated by admin: $userId -> $newRole');
      return true;
    } catch (e) {
      Logger.error('Error updating user role as admin: $e');
      return false;
    }
  }

  // Toggle user active status (admin only)
  static Future<bool> toggleUserActiveStatus(String userId, bool isActive) async {
    try {
      // Check if current user is admin
      if (!await isAdmin()) {
        throw Exception('Unauthorized: Admin access required');
      }

      await _client
          .from(SupabaseConfig.usersTable)
          .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);

      Logger.info('User active status updated by admin: $userId -> $isActive');
      return true;
    } catch (e) {
      Logger.error('Error updating user active status as admin: $e');
      return false;
    }
  }
}