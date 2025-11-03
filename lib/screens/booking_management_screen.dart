import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';

class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({super.key});

  @override
  State<BookingManagementScreen> createState() => _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> {
  String _selectedFilter = 'all';
  String _selectedSort = 'date_desc';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Management'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(IconStandards.getUIIcon('filter')),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          final filteredBookings = _getFilteredBookings(bookingProvider.bookings);
          
          return Column(
            children: [
              _buildSearchAndFilters(),
              _buildBookingStats(bookingProvider),
              Expanded(
                child: filteredBookings.isEmpty
                    ? _buildEmptyState()
                    : _buildBookingsList(filteredBookings),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[50],
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search bookings...',
              prefixIcon: Icon(IconStandards.getUIIcon('search')),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterChip('All', 'all'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('Active', 'confirmed'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('Pending', 'pending'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('Cancelled', 'cancelled'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingStats(BookingProvider bookingProvider) {
    final bookings = bookingProvider.bookings;
    final totalBookings = bookings.length;
    final activeBookings = bookings.where((b) => b['status'] == 'confirmed').length;
    final totalSpent = bookingProvider.getTotalSpent();

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Total Bookings', totalBookings.toString(), IconStandards.getUIIcon('book')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Active', activeBookings.toString(), IconStandards.getUIIcon('check_circle')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Total Spent', '\$${totalSpent.toStringAsFixed(0)}', IconStandards.getUIIcon('attach_money')),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconStandards.getUIIcon('bookmark_border'),
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No bookings found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or make a new booking',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            onPressed: () => context.go('/wallet'),
            child: const Text('Browse Bookings'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildEnhancedBookingCard(booking);
      },
    );
  }

  Widget _buildEnhancedBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] as String;
    final canModify = status == 'confirmed' || status == 'pending';
    final canCancel = status == 'confirmed' || status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _getBookingTypeIcon(booking['type']),
                      const SizedBox(width: 8),
                      Text(
                        booking['type'].toString().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Confirmation: ${booking['confirmationCode']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(IconStandards.getUIIcon('calendar'), size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Booked: ${_formatDate(booking['bookingDate'])}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${booking['totalAmount']} ${booking['currency']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  if (booking['type'] == 'hotel' || booking['type'] == 'flight')
                    Text(
                      _getBookingDateRange(booking),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      onPressed: () => _showBookingDetails(booking),
                      isOutlined: true,
                      child: const Text('View Details'),
                    ),
                  ),
                  if (canModify) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        onPressed: () => _showModifyDialog(booking),
                        backgroundColor: AppTheme.primaryOrange,
                        child: const Text('Modify'),
                      ),
                    ),
                  ],
                  if (canCancel) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        onPressed: () => _showCancelDialog(booking),
                        backgroundColor: Colors.red,
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getBookingTypeIcon(String type) {
    IconData icon = IconStandards.getBookingTypeIcon(type);
    Color color;
    
    switch (type.toLowerCase()) {
      case 'hotel':
        color = AppTheme.primaryBlue;
        break;
      case 'flight':
        color = AppTheme.primaryOrange;
        break;
      case 'activity':
        color = AppTheme.primaryGreen;
        break;
      case 'car_rental':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }
    
    return Icon(icon, color: color, size: IconStandards.mediumIconSize);
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = AppTheme.primaryGreen;
        break;
      case 'pending':
        color = AppTheme.primaryOrange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getBookingDateRange(Map<String, dynamic> booking) {
    final details = booking['details'] as Map<String, dynamic>? ?? {};
    
    if (booking['type'] == 'hotel') {
      final checkIn = details['checkInDate'] ?? '';
      final checkOut = details['checkOutDate'] ?? '';
      if (checkIn.isNotEmpty && checkOut.isNotEmpty) {
        return '${_formatDate(checkIn)} - ${_formatDate(checkOut)}';
      }
    } else if (booking['type'] == 'flight') {
      final departureDate = details['departureDate'] ?? '';
      if (departureDate.isNotEmpty) {
        return _formatDate(departureDate);
      }
    }
    
    return '';
  }

  List<Map<String, dynamic>> _getFilteredBookings(List<Map<String, dynamic>> bookings) {
    var filtered = bookings.where((booking) {
      // Filter by status
      if (_selectedFilter != 'all' && booking['status'] != _selectedFilter) {
        return false;
      }
      
      // Filter by search term
      final searchTerm = _searchController.text.toLowerCase();
      if (searchTerm.isNotEmpty) {
        final confirmationCode = booking['confirmationCode'].toString().toLowerCase();
        final type = booking['type'].toString().toLowerCase();
        if (!confirmationCode.contains(searchTerm) && !type.contains(searchTerm)) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // Sort bookings
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'date_desc':
          return DateTime.parse(b['bookingDate']).compareTo(DateTime.parse(a['bookingDate']));
        case 'date_asc':
          return DateTime.parse(a['bookingDate']).compareTo(DateTime.parse(b['bookingDate']));
        case 'amount_desc':
          return (b['totalAmount'] as num).toDouble().compareTo((a['totalAmount'] as num).toDouble());
        case 'amount_asc':
          return (a['totalAmount'] as num).toDouble().compareTo((b['totalAmount'] as num).toDouble());
        default:
          return 0;
      }
    });

    return filtered;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort & Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: const Text('Date (Newest)'),
              value: 'date_desc',
              groupValue: _selectedSort,
              onChanged: (value) {
                setState(() => _selectedSort = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Date (Oldest)'),
              value: 'date_asc',
              groupValue: _selectedSort,
              onChanged: (value) {
                setState(() => _selectedSort = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Amount (High to Low)'),
              value: 'amount_desc',
              groupValue: _selectedSort,
              onChanged: (value) {
                setState(() => _selectedSort = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Amount (Low to High)'),
              value: 'amount_asc',
              groupValue: _selectedSort,
              onChanged: (value) {
                setState(() => _selectedSort = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Type', booking['type'].toString().toUpperCase()),
              _buildDetailRow('Status', booking['status'].toString().toUpperCase()),
              _buildDetailRow('Confirmation', booking['confirmationCode']),
              _buildDetailRow('Amount', '\$${booking['totalAmount']} ${booking['currency']}'),
              _buildDetailRow('Booking Date', _formatDate(booking['bookingDate'])),
              const SizedBox(height: 16),
              const Text('Additional Details:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(booking['details'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showModifyDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modify Booking'),
        content: const Text('Booking modification feature will be available soon. Please contact customer support for changes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(Map<String, dynamic> booking) {
    void cancelBooking(Map<String, dynamic> booking) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Cancel Booking'),
          content: Text('Are you sure you want to cancel this booking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Booking cancelled successfully'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
              child: Text('Yes, Cancel'),
            ),
          ],
        ),
      );
    }

    void modifyBooking(Map<String, dynamic> booking) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Modify booking feature coming soon'),
          backgroundColor: AppTheme.primaryOrange,
        ),
      );
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel booking ${booking['confirmationCode']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<BookingProvider>(context, listen: false)
                  .cancelBooking(booking['id']);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking cancelled successfully')),
              );
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}