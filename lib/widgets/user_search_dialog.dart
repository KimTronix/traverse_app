import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../utils/theme.dart';
import '../utils/logger.dart';

class UserSearchDialog extends StatefulWidget {
  final Function(Map<String, dynamic> user) onUserSelected;

  const UserSearchDialog({
    super.key,
    required this.onUserSelected,
  });

  @override
  State<UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<UserSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService.instance;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      _searchQuery = query;
      if (query.length >= 2) {
        _searchUsers(query);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final users = await _supabaseService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = users;
          _isSearching = false;
        });
      }
    } catch (e) {
      Logger.error('Failed to search users: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Find User to Chat With',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by username, name, or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // Search results
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching users...'),
          ],
        ),
      );
    }

    if (_searchQuery.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Type at least 2 characters to search for users',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_searchQuery.length < 2) {
      return const Center(
        child: Text(
          'Type at least 2 characters to search',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _UserSearchTile(
          user: user,
          onTap: () {
            widget.onUserSelected(user);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class _UserSearchTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  const _UserSearchTile({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final username = user['username'] as String?;
    final fullName = user['full_name'] as String?;
    final email = user['email'] as String?;
    final avatarUrl = user['avatar_url'] as String?;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl != null
          ? NetworkImage(avatarUrl)
          : null,
        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
        child: avatarUrl == null
          ? Text(
              (fullName?.isNotEmpty == true ? fullName![0] : username?[0] ?? '?').toUpperCase(),
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      ),
      title: Text(
        fullName?.isNotEmpty == true ? fullName! : (username ?? 'Unknown'),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (username != null && username.isNotEmpty)
            Text('@$username', style: const TextStyle(color: Colors.grey)),
          if (email != null && email.isNotEmpty)
            Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      trailing: const Icon(Icons.chat_bubble_outline),
      onTap: onTap,
    );
  }
}