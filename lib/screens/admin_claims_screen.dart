import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/icon_standards.dart';
import '../services/claims_service.dart';

class AdminClaimsScreen extends StatefulWidget {
  const AdminClaimsScreen({super.key});

  @override
  State<AdminClaimsScreen> createState() => _AdminClaimsScreenState();
}

class _AdminClaimsScreenState extends State<AdminClaimsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClaimsService _claimsService = ClaimsService();
  String searchQuery = '';
  String selectedStatus = 'All';
  final List<String> statusOptions = ['All', 'Pending', 'Approved', 'Rejected'];
  List<Map<String, dynamic>> _allClaims = [];
  List<Map<String, dynamic>> _allRewards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final claims = await _claimsService.getAllClaims();
       final rewardsData = await _claimsService.getAllRewards();
       final rewards = rewardsData.map((reward) => {
         'id': reward.id,
         'title': reward.title,
         'description': reward.description,
         'pointsCost': reward.pointsCost,
         'isActive': reward.isActive,
         'category': reward.category,
       }).toList();
  // stats fetched but not required in this screen for now
  // final statsData = await _claimsService.getClaimsStatistics();
      
      setState(() {
        _allClaims = claims;
        _allRewards = rewards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Claims & Rewards',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Token Claims'),
            Tab(text: 'Awards'),
            Tab(text: 'Rewards'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildClaimsList('tokens'),
                _buildClaimsList('awards'),
                _buildClaimsList('rewards'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRewardDialog,
        backgroundColor: AppTheme.primaryBlue,
  child: Icon(IconStandards.getUIIcon('add'), color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search claims...',
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
          ),
          const SizedBox(width: AppConstants.smSpacing),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(AppConstants.mdRadius),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedStatus,
                items: statusOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedStatus = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimsList(String type) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final claims = _getClaimsForType(type);
    
    if (claims.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconStandards.getUIIcon('inbox_outlined'),
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: AppConstants.mdSpacing),
            Text(
              'No $type found',
              style: const TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      itemCount: claims.length,
      itemBuilder: (context, index) {
        final claim = claims[index];
        return _buildClaimCard(claim, type);
      },
    );
  }

  Widget _buildClaimCard(Map<String, dynamic> claim, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.mdSpacing),
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
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
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: _getTypeColor(type).withValues(alpha: 0.1),
                child: Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type),
                ),
              ),
              const SizedBox(width: AppConstants.mdSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'User: ${claim['userName']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(claim['status'] as String),
            ],
          ),
          const SizedBox(height: AppConstants.mdSpacing),
          Text(
            claim['description'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.smSpacing),
          Row(
            children: [
              Icon(
                IconStandards.getUIIcon('calendar'),
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Submitted: ${claim['date']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              if (type == 'tokens')
                Text(
                  '${claim['amount']} tokens',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.mdSpacing),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewClaimDetails(claim),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryBlue),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(color: AppTheme.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.smSpacing),
              if (claim['status'] == 'Pending') ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveClaim(claim),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Approve',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.smSpacing),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rejectClaim(claim),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusColors = _claimsService.getStatusColors();
    final statusDisplayNames = _claimsService.getStatusDisplayNames();
    
    final displayName = statusDisplayNames[status.toLowerCase()] ?? status;
    final color = statusColors[status.toLowerCase()] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'tokens':
        return Colors.amber;
      case 'awards':
        return Colors.purple;
      case 'rewards':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'tokens':
        return IconStandards.getUIIcon('monetization');
      case 'awards':
        return IconStandards.getUIIcon('trophy');
      case 'rewards':
        return IconStandards.getUIIcon('gift');
      default:
        return IconStandards.getUIIcon('help');
    }
  }

  List<Map<String, dynamic>> _getClaimsForType(String type) {
    List<Map<String, dynamic>> filteredData;
    
    if (type == 'rewards') {
      filteredData = _allRewards;
    } else {
      filteredData = _allClaims.where((claim) => claim['type'] == type).toList();
    }
    
    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filteredData = filteredData.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final description = (item['description'] ?? '').toString().toLowerCase();
        final userName = (item['user_name'] ?? item['userName'] ?? '').toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        
        return title.contains(query) || 
               description.contains(query) || 
               userName.contains(query);
      }).toList();
    }
    
    // Apply status filter
    if (selectedStatus != 'All') {
      filteredData = filteredData.where((item) {
        final status = (item['status'] ?? '').toString();
        return status.toLowerCase() == selectedStatus.toLowerCase();
      }).toList();
    }
    
    return filteredData;
  }

  void _showCreateRewardDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsCostController = TextEditingController();
    final categoryController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Reward'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Reward Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppConstants.mdSpacing),
              TextField(
                controller: pointsCostController,
                decoration: const InputDecoration(
                  labelText: 'Points Cost',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppConstants.mdSpacing),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppConstants.mdSpacing),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    pointsCostController.text.isNotEmpty &&
                    categoryController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  try {
                    await _claimsService.createReward(
                      title: titleController.text,
                      description: descriptionController.text,
                      pointsCost: int.parse(pointsCostController.text),
                      category: categoryController.text,
                    );
                    Navigator.of(context).pop();
                    await _loadData(); // Refresh data
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reward created successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error creating reward: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _viewClaimDetails(Map<String, dynamic> claim) {
    // TODO: Navigate to claim details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${claim['title']}'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  Future<void> _approveClaim(Map<String, dynamic> claim) async {
    try {
      await _claimsService.updateClaimStatus(
        claim['id'],
        'approved',
      );
      await _loadData(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${claim['title']} has been approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving claim: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectClaim(Map<String, dynamic> claim) async {
    try {
      await _claimsService.updateClaimStatus(
        claim['id'],
        'rejected',
      );
      await _loadData(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${claim['title']} has been rejected'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting claim: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}