import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/icon_standards.dart';
import '../services/service_provider_service.dart';
import '../utils/logger.dart';

class AdminServiceProvidersScreen extends StatefulWidget {
  const AdminServiceProvidersScreen({super.key});

  @override
  State<AdminServiceProvidersScreen> createState() => _AdminServiceProvidersScreenState();
}

class _AdminServiceProvidersScreenState extends State<AdminServiceProvidersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';
  String selectedStatus = 'All';
  final List<String> statusOptions = ['All', 'Pending', 'Approved', 'Rejected'];
  final ServiceProviderService _serviceProviderService = ServiceProviderService.instance;
  List<Map<String, dynamic>> _allProviders = [];
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadServiceProviders();
    _loadStats();
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
          'Service Providers',
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
            Tab(text: 'Transport'),
            Tab(text: 'Hotels'),
            Tab(text: 'Tours'),
            Tab(text: 'Restaurants'),
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
                _buildProvidersList('transport'),
                _buildProvidersList('accommodation'),
                _buildProvidersList('tours'),
                _buildProvidersList('restaurants'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProviderDialog,
        backgroundColor: AppTheme.primaryBlue,
        child: Icon(IconStandards.getUIIcon('add'), color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search providers...',
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
        ],
      ),
    );
  }

  Widget _buildProvidersList(String category) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final providers = _getProvidersForCategory(category);
    
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconStandards.getUIIcon('business'),
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No service providers found',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return _buildProviderCard(provider);
      },
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
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
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                child: Icon(
                  _getCategoryIcon(provider['category'] as String),
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: AppConstants.mdSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider['name'] as String? ?? 'Unknown Provider',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      provider['description'] as String? ?? 'No description available',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildStatusChip(provider['status'] as String),
            ],
          ),
          const SizedBox(height: AppConstants.mdSpacing),
          Row(
            children: [
              Icon(
                IconStandards.getUIIcon('location'),
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                provider['location'] as String? ?? 'Location not specified',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: AppConstants.mdSpacing),
              Icon(
                IconStandards.getUIIcon('star'),
                size: 16,
                color: Colors.amber,
              ),
              const SizedBox(width: 4),
              Text(
                '${provider['rating'] ?? 0.0} (${provider['review_count'] ?? 0} reviews)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.mdSpacing),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewProviderDetails(provider),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryBlue),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(color: AppTheme.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.smSpacing),
              if (provider['status'] == 'pending') ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveProvider(provider),
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
                    onPressed: () => _rejectProvider(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ] else if (provider['status'] == 'approved') ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _suspendProvider(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text(
                      'Suspend',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Approved':
        color = Colors.green;
        break;
      case 'Pending':
        color = Colors.orange;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

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
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Future<void> _loadServiceProviders() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final providers = await _serviceProviderService.getAllServiceProviders();
      
      setState(() {
        _allProviders = providers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load service providers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _loadStats() async {
    try {
      final stats = await _serviceProviderService.getServiceProviderStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      Logger.error('Failed to load stats: $e');
    }
  }
  
  IconData _getCategoryIcon(String category) {
    return IconStandards.getServiceProviderIcon(category);
  }
  
  List<Map<String, dynamic>> _getProvidersForCategory(String category) {
    List<Map<String, dynamic>> filteredProviders = _allProviders.where((provider) {
      // Filter by category
      bool matchesCategory = true;
      if (category == 'accommodation') {
        matchesCategory = provider['category'] == 'hotels';
      } else {
        matchesCategory = provider['category'] == category;
      }
      
      // Filter by status
      bool matchesStatus = selectedStatus == 'All' || 
          (provider['status'] as String?)?.toLowerCase() == selectedStatus.toLowerCase();
      
      // Filter by search query
      bool matchesSearch = searchQuery.isEmpty ||
          (provider['name'] as String?)?.toLowerCase().contains(searchQuery.toLowerCase()) == true ||
          (provider['description'] as String?)?.toLowerCase().contains(searchQuery.toLowerCase()) == true ||
          (provider['location'] as String?)?.toLowerCase().contains(searchQuery.toLowerCase()) == true;
      
      return matchesCategory && matchesStatus && matchesSearch;
    }).toList();
    
    return filteredProviders;
  }

  void _showAddProviderDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final websiteController = TextEditingController();
    String selectedCategory = 'transport';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Service Provider'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Provider Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _serviceProviderService.getAvailableCategories().map((category) {
                        final displayNames = _serviceProviderService.getCategoryDisplayNames();
                        return DropdownMenuItem(
                          value: category,
                          child: Text(displayNames[category] ?? category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Website (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        descriptionController.text.trim().isEmpty ||
                        locationController.text.trim().isEmpty ||
                        emailController.text.trim().isEmpty ||
                        phoneController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    try {
                      await _serviceProviderService.addServiceProvider(
                        name: nameController.text.trim(),
                        category: selectedCategory,
                        description: descriptionController.text.trim(),
                        location: locationController.text.trim(),
                        contactEmail: emailController.text.trim(),
                        contactPhone: phoneController.text.trim(),
                        website: websiteController.text.trim().isEmpty ? null : websiteController.text.trim(),
                      );
                      
                      Navigator.of(context).pop();
                      _loadServiceProviders();
                      _loadStats();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Service provider added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add service provider: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Add Provider'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _viewProviderDetails(Map<String, dynamic> provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
             children: [
               Icon(_getCategoryIcon(provider['category'] ?? 'other')),
               const SizedBox(width: 8),
               Expanded(child: Text(provider['name'] ?? 'Unknown Provider')),
             ],
           ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Category', _serviceProviderService.getCategoryDisplayNames()[provider['category']] ?? provider['category'] ?? 'Unknown'),
                 _buildDetailRow('Status', _serviceProviderService.getStatusDisplayNames()[provider['status'] ?? 'pending'] ?? 'Unknown'),
                _buildDetailRow('Location', provider['location'] ?? 'Not specified'),
                _buildDetailRow('Rating', '${provider['rating'] ?? 0.0} (${provider['review_count'] ?? 0} reviews)'),
                _buildDetailRow('Contact Email', provider['contact_email'] ?? 'Not provided'),
                _buildDetailRow('Contact Phone', provider['contact_phone'] ?? 'Not provided'),
                if (provider['website'] != null && provider['website'].toString().isNotEmpty)
                  _buildDetailRow('Website', provider['website']),
                if (provider['created_at'] != null)
                  _buildDetailRow('Registered', DateTime.parse(provider['created_at']).toString().split(' ')[0]),
                const SizedBox(height: 12),
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(provider['description'] ?? 'No description provided'),
                if (provider['rejection_reason'] != null && provider['rejection_reason'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Rejection Reason:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 4),
                  Text(provider['rejection_reason'], style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            if (provider['status'] == 'Pending') ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _approveProvider(provider);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Approve'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _rejectProvider(provider);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reject'),
              ),
            ],
            if (provider['status'] == 'Approved') ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _suspendProvider(provider);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Suspend'),
              ),
            ],
            TextButton(
              onPressed: () => _editProvider(provider),
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _editProvider(Map<String, dynamic> provider) {
    Navigator.of(context).pop(); // Close details dialog
    
    final nameController = TextEditingController(text: provider['name'] ?? '');
    final descriptionController = TextEditingController(text: provider['description'] ?? '');
    final locationController = TextEditingController(text: provider['location'] ?? '');
    final emailController = TextEditingController(text: provider['contact_email'] ?? '');
    final phoneController = TextEditingController(text: provider['contact_phone'] ?? '');
    final websiteController = TextEditingController(text: provider['website'] ?? '');
    String selectedCategory = provider['category'] ?? 'transport';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${provider['name']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Provider Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _serviceProviderService.getAvailableCategories().map((category) {
                         final displayNames = _serviceProviderService.getCategoryDisplayNames();
                         return DropdownMenuItem(
                           value: category,
                           child: Text(displayNames[category] ?? category),
                         );
                       }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Website (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        descriptionController.text.trim().isEmpty ||
                        locationController.text.trim().isEmpty ||
                        emailController.text.trim().isEmpty ||
                        phoneController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    try {
                      await _serviceProviderService.updateServiceProvider(
                        provider['id'],
                        {
                          'name': nameController.text.trim(),
                          'category': selectedCategory,
                          'description': descriptionController.text.trim(),
                          'location': locationController.text.trim(),
                          'contact_email': emailController.text.trim(),
                          'contact_phone': phoneController.text.trim(),
                          'website': websiteController.text.trim().isEmpty ? null : websiteController.text.trim(),
                        },
                      );
                      
                      Navigator.of(context).pop();
                      _loadServiceProviders();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Service provider updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update service provider: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _approveProvider(Map<String, dynamic> provider) async {
    try {
      await _serviceProviderService.approveServiceProvider(provider['id']);
      _loadServiceProviders();
      _loadStats();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${provider['name']} has been approved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve provider: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectProvider(Map<String, dynamic> provider) async {
    final reasonController = TextEditingController();
    
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Service Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide a reason for rejecting ${provider['name']}:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
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
            onPressed: () => Navigator.of(context).pop(reasonController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    
    if (reason != null && reason.isNotEmpty) {
      try {
        await _serviceProviderService.rejectServiceProvider(provider['id'], reason);
        _loadServiceProviders();
        _loadStats();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${provider['name']} has been rejected'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject provider: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _suspendProvider(Map<String, dynamic> provider) async {
    try {
      await _serviceProviderService.updateServiceProvider(
        provider['id'],
        {'status': 'suspended'},
      );
      _loadServiceProviders();
      _loadStats();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${provider['name']} has been suspended'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to suspend provider: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}