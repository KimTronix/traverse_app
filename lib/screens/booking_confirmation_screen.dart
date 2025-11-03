import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  
  const BookingConfirmationScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _emailSent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareBooking,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSuccessHeader(),
                    const SizedBox(height: 24),
                    _buildBookingDetails(),
                    const SizedBox(height: 24),
                    _buildQRCode(),
                    const SizedBox(height: 24),
                    _buildDigitalTicket(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                    _buildEmailNotification(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ${widget.booking['type']} booking has been successfully confirmed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Confirmation: ${widget.booking['confirmationCode']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetails() {
    final details = widget.booking['details'] as Map<String, dynamic>? ?? {};
    
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getBookingIcon(),
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Booking Details',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Type', widget.booking['type'].toString().toUpperCase()),
            _buildDetailRow('Status', widget.booking['status'].toString().toUpperCase()),
            _buildDetailRow('Total Amount', '\$${widget.booking['totalAmount']} ${widget.booking['currency']}'),
            _buildDetailRow('Booking Date', _formatDate(widget.booking['bookingDate'])),
            
            if (widget.booking['type'] == 'hotel') ..._buildHotelDetails(details),
            if (widget.booking['type'] == 'flight') ..._buildFlightDetails(details),
            if (widget.booking['type'] == 'activity') ..._buildActivityDetails(details),
            if (widget.booking['type'] == 'car_rental') ..._buildCarRentalDetails(details),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHotelDetails(Map<String, dynamic> details) {
    return [
      const Divider(),
      _buildDetailRow('Hotel', details['hotelName'] ?? 'N/A'),
      _buildDetailRow('Room Type', details['roomType'] ?? 'N/A'),
      _buildDetailRow('Check-in', _formatDate(details['checkInDate'] ?? '')),
      _buildDetailRow('Check-out', _formatDate(details['checkOutDate'] ?? '')),
      _buildDetailRow('Guests', '${details['adults'] ?? 0} Adults, ${details['children'] ?? 0} Children'),
    ];
  }

  List<Widget> _buildFlightDetails(Map<String, dynamic> details) {
    return [
      const Divider(),
      _buildDetailRow('From', details['from'] ?? 'N/A'),
      _buildDetailRow('To', details['to'] ?? 'N/A'),
      _buildDetailRow('Departure', _formatDateTime(details['departureDate'] ?? '', details['departureTime'] ?? '')),
      _buildDetailRow('Return', _formatDateTime(details['returnDate'] ?? '', details['returnTime'] ?? '')),
      _buildDetailRow('Passengers', '${details['adults'] ?? 0} Adults, ${details['children'] ?? 0} Children'),
      _buildDetailRow('Class', details['class'] ?? 'N/A'),
    ];
  }

  List<Widget> _buildActivityDetails(Map<String, dynamic> details) {
    return [
      const Divider(),
      _buildDetailRow('Activity', details['activityName'] ?? 'N/A'),
      _buildDetailRow('Date', _formatDate(details['date'] ?? '')),
      _buildDetailRow('Time', details['time'] ?? 'N/A'),
      _buildDetailRow('Participants', '${details['participants'] ?? 0}'),
      _buildDetailRow('Difficulty', details['difficulty'] ?? 'N/A'),
    ];
  }

  List<Widget> _buildCarRentalDetails(Map<String, dynamic> details) {
    return [
      const Divider(),
      _buildDetailRow('Vehicle', details['vehicleName'] ?? 'N/A'),
      _buildDetailRow('Pickup Location', details['pickupLocation'] ?? 'N/A'),
      _buildDetailRow('Dropoff Location', details['dropoffLocation'] ?? 'N/A'),
      _buildDetailRow('Pickup Date', _formatDateTime(details['pickupDate'] ?? '', details['pickupTime'] ?? '')),
      _buildDetailRow('Return Date', _formatDateTime(details['returnDate'] ?? '', details['returnTime'] ?? '')),
    ];
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.qr_code,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'QR Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_2,
                    size: 120,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.booking['confirmationCode'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Show this QR code at check-in',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalTicket() {
    return CustomCard(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.confirmation_number,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Digital Ticket',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.booking['type'].toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.booking['confirmationCode'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '\$${widget.booking['totalAmount']} ${widget.booking['currency']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _formatDate(widget.booking['bookingDate']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                onPressed: _downloadTicket,
                backgroundColor: AppTheme.primaryBlue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(IconStandards.getUIIcon('download'), color: Colors.white),
                    SizedBox(width: 8),
                    Text('Download Ticket'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                onPressed: _addToCalendar,
                backgroundColor: AppTheme.primaryGreen,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(IconStandards.getUIIcon('calendar'), color: Colors.white),
                    SizedBox(width: 8),
                    Text('Add to Calendar'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CustomButton(
          onPressed: () => _copyConfirmationCode(),
          isOutlined: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(IconStandards.getUIIcon('copy')),
              SizedBox(width: 8),
              Text('Copy Confirmation Code'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailNotification() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _emailSent ? Icons.mark_email_read : Icons.email_outlined,
                  color: _emailSent ? AppTheme.primaryGreen : AppTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _emailSent ? 'Email Sent' : 'Email Confirmation',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _emailSent
                  ? 'Confirmation email has been sent to your registered email address.'
                  : 'Send booking confirmation to your email address.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            if (!_emailSent)
              CustomButton(
                onPressed: _isLoading ? null : _sendEmailConfirmation,
                backgroundColor: AppTheme.primaryOrange,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Send Email'),
                        ],
                      ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Email sent successfully',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getBookingIcon() {
    return IconStandards.getBookingTypeIcon(widget.booking['type'].toString());
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateString, String timeString) {
    if (dateString.isEmpty) return 'N/A';
    final formattedDate = _formatDate(dateString);
    if (timeString.isNotEmpty) {
      return '$formattedDate at $timeString';
    }
    return formattedDate;
  }

  void _shareBooking() {
    final shareText = '''
Booking Confirmation

Confirmation Code: ${widget.booking['confirmationCode']}
Destination: ${widget.booking['destination']}
Date: ${widget.booking['date']}
Guests: ${widget.booking['guests']}
Total: ${widget.booking['total']}

Thank you for choosing our service!
''';
    
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking details copied to clipboard'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _downloadTicket() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ticket download started'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _addToCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event added to calendar'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _copyConfirmationCode() {
    Clipboard.setData(ClipboardData(text: widget.booking['confirmationCode']));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Confirmation code copied to clipboard'),
        backgroundColor: AppTheme.primaryOrange,
      ),
    );
  }

  Future<void> _sendEmailConfirmation() async {
    setState(() => _isLoading = true);
    
    // Simulate email sending
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isLoading = false;
      _emailSent = true;
    });
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Confirmation email sent successfully!'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }
}