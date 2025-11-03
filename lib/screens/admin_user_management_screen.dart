import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/verification_service.dart';
import '../utils/theme.dart';
import '../utils/logger.dart';
import '../widgets/verification_badge.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _client = Supabase.instance.client;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _verifiedUsers = [];
  List<Map<String, dynamic>> _unverifiedUsers = [];

  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if current user is admin
      if (!await AuthService.isAdmin()) {
        throw Exception('Unauthorized: Admin access required');
      }

      // Fetch all users with verification status
      final response = await _client
          .from('users')
          .select('''
            *,
            user_verification_levels!left(
              verification_type,
              verified_at,
              expires_at
            )
          ''')
          .order('created_at', ascending: false);

      final users = List<Map<String, dynamic>>.from(response);

      // Process users and categorize them
      _allUsers = users.map((user) {
        final verificationLevels = user['user_verification_levels'] as List?;
        final hasVerification = verificationLevels?.isNotEmpty ?? false;

        return {
          ...user,
          'is_verified_computed': hasVerification,
          'verification_count': verificationLevels?.length ?? 0,
          'verification_types': verificationLevels?.map((v) => v['verification_type']).toList() ?? [],
        };
      }).toList();

      _verifiedUsers = _allUsers.where((user) => user['is_verified_computed'] == true).toList();
      _unverifiedUsers = _allUsers.where((user) => user['is_verified_computed'] == false).toList();

      Logger.info('Loaded ${_allUsers.length} users (${_verifiedUsers.length} verified, ${_unverifiedUsers.length} unverified)');
    } catch (e) {
      Logger.error('Error loading users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteUser(String userId, String userEmail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to permanently delete the user "$userEmail"?\n\nThis action cannot be undone and will remove all their data including posts, messages, and verification records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Check if current user is admin
      if (!await AuthService.isAdmin()) {
        throw Exception('Unauthorized: Admin access required');
      }

      // Delete user from auth (this will cascade to delete related data due to foreign keys)
      await _client.auth.admin.deleteUser(userId);

      // Also delete from our users table if it exists
      await _client
          .from('users')
          .delete()
          .eq('id', userId);

      Logger.info('User deleted successfully: $userEmail');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User "$userEmail" deleted successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }

      // Reload users list
      await _loadUsers();
    } catch (e) {
      Logger.error('Error deleting user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyUser(String userId, String userEmail) async {
    try {
      final success = await VerificationService.verifyUser(
        userId: userId,
        verificationType: 'email',
        verificationData: {'verified_by_admin': true},
      );

      if (success) {
        Logger.info('User verified successfully: $userEmail');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User "$userEmail" verified successfully'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
        await _loadUsers();
      } else {
        throw Exception('Failed to verify user');
      }
    } catch (e) {
      Logger.error('Error verifying user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying user: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  Future<void> _showAddUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController();
    final usernameController = TextEditingController();
    String selectedRole = 'traveler';
    bool shouldVerify = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        hintText: 'user@example.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password *',
                        hintText: 'Minimum 6 characters',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'John Doe',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username *',
                        hintText: 'johndoe',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                          return 'Username can only contain letters, numbers, and underscores';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'traveler', child: Text('Traveler')),
                        DropdownMenuItem(value: 'business', child: Text('Business')),
                        DropdownMenuItem(value: 'guide', child: Text('Guide')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedRole = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Verify email automatically'),
                      subtitle: const Text('User will have full access to all features'),
                      value: shouldVerify,
                      onChanged: (value) {
                        setDialogState(() {
                          shouldVerify = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _createUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        fullName: fullNameController.text.trim(),
        username: usernameController.text.trim(),
        role: selectedRole,
        shouldVerify: shouldVerify,
      );
    }

    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    usernameController.dispose();
  }

  Future<void> _createUser({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String role,
    required bool shouldVerify,
  }) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Check if current user is admin
      if (!await AuthService.isAdmin()) {
        throw Exception('Unauthorized: Admin access required');
      }

      // Create user with Supabase Auth
      final response = await AuthService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        username: username,
        role: role,
      );

      if (response.user != null) {
        // If should verify, add verification
        if (shouldVerify) {
          await VerificationService.verifyUser(
            userId: response.user!.id,
            verificationType: 'email',
            verificationData: {'verified_by_admin': true},
          );
        }

        Logger.info('User created successfully: $email');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User "$email" created successfully'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }

        // Reload users list
        await _loadUsers();
      } else {
        throw Exception('Failed to create user');
      }
    } catch (e) {
      Logger.error('Error creating user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating user: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredUsers(List<Map<String, dynamic>> users) {
    if (_searchQuery.isEmpty) return users;

    return users.where((user) {
      final email = user['email']?.toString().toLowerCase() ?? '';
      final fullName = user['full_name']?.toString().toLowerCase() ?? '';
      final username = user['username']?.toString().toLowerCase() ?? '';
      final role = user['role']?.toString().toLowerCase() ?? '';

      return email.contains(_searchQuery.toLowerCase()) ||
             fullName.contains(_searchQuery.toLowerCase()) ||
             username.contains(_searchQuery.toLowerCase()) ||
             role.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildUsersList(List<Map<String, dynamic>> users) {
    final filteredUsers = _getFilteredUsers(users);

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No users found' : 'No users match your search',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final verificationTypes = user['verification_types'] as List? ?? [];
    final verificationStatus = Map<String, dynamic>.fromEntries(
      verificationTypes.map((type) => MapEntry(type.toString(), true))
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: user['avatar_url'] != null
                      ? NetworkImage(user['avatar_url'])
                      : null,
                  backgroundColor: AppTheme.primaryBlue,
                  child: user['avatar_url'] == null
                      ? Text(
                          _getNameInitials(user['full_name'] ?? user['email'] ?? 'U'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user['full_name'] ?? 'No Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          VerificationBadge(
                            verificationStatus: verificationStatus,
                            showText: false,
                            iconSize: 18,
                          ),
                        ],
                      ),
                      Text(
                        user['email'] ?? 'No Email',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (user['username'] != null)
                        Text(
                          '@${user['username']}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'verify':
                        await _verifyUser(user['id'], user['email'] ?? '');
                        break;
                      case 'delete':
                        await _deleteUser(user['id'], user['email'] ?? '');
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!user['is_verified_computed'])
                      const PopupMenuItem(
                        value: 'verify',
                        child: Row(
                          children: [
                            Icon(Icons.verified, color: AppTheme.primaryGreen),
                            SizedBox(width: 8),
                            Text('Verify User'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppTheme.primaryRed),
                          SizedBox(width: 8),
                          Text('Delete User'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip('Role', user['role'] ?? 'traveler'),
                const SizedBox(width: 8),
                _buildInfoChip(
                  'Status',
                  user['is_active'] == true ? 'Active' : 'Inactive',
                  color: user['is_active'] == true ? AppTheme.primaryGreen : AppTheme.primaryRed,
                ),
                const SizedBox(width: 8),
                if (user['verification_count'] > 0)
                  _buildInfoChip(
                    'Verifications',
                    '${user['verification_count']}',
                    color: AppTheme.primaryBlue,
                  ),
              ],
            ),
            if (user['created_at'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Joined: ${_formatDate(user['created_at'])}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryBlue).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color ?? AppTheme.primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getNameInitials(String name) {
    if (name.isEmpty) return 'U';
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words.first[0]}${words.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'All Users (${_allUsers.length})'),
            Tab(text: 'Verified (${_verifiedUsers.length})'),
            Tab(text: 'Unverified (${_unverifiedUsers.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddUserDialog,
            tooltip: 'Add User',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by email, name, username, or role...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUsersList(_allUsers),
                      _buildUsersList(_verifiedUsers),
                      _buildUsersList(_unverifiedUsers),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}