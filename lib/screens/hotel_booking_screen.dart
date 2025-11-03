import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_input.dart';

class HotelBookingScreen extends StatefulWidget {
  final Map<String, dynamic> hotel;
  
  const HotelBookingScreen({super.key, required this.hotel});

  @override
  State<HotelBookingScreen> createState() => _HotelBookingScreenState();
}

class _HotelBookingScreenState extends State<HotelBookingScreen> {
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 3));
  int _guests = 2;
  int _rooms = 1;
  String _selectedRoomType = 'Standard';
  final List<String> _roomTypes = ['Standard', 'Deluxe', 'Suite', 'Presidential'];
  final Map<String, double> _roomPrices = {
    'Standard': 1.0,
    'Deluxe': 1.5,
    'Suite': 2.0,
    'Presidential': 3.0,
  };
  
  bool _showCalendar = false;
  bool _isSelectingCheckIn = true;
  
  final TextEditingController _specialRequestsController = TextEditingController();
  
  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }
  
  double get _totalPrice {
    final nights = _checkOutDate.difference(_checkInDate).inDays;
    final basePrice = (widget.hotel['pricePerNight'] as num).toDouble();
    final roomMultiplier = _roomPrices[_selectedRoomType] ?? 1.0;
    return basePrice * roomMultiplier * nights * _rooms;
  }
  
  int get _numberOfNights {
    return _checkOutDate.difference(_checkInDate).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Book ${widget.hotel['name']}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(IconStandards.getUIIcon('back')),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel Info Card
            _buildHotelInfoCard(isSmallScreen),
            
            SizedBox(height: AppConstants.lgSpacing),
            
            // Booking Details
            _buildBookingDetailsCard(isSmallScreen),
            
            SizedBox(height: AppConstants.lgSpacing),
            
            // Room Selection
            _buildRoomSelectionCard(isSmallScreen),
            
            SizedBox(height: AppConstants.lgSpacing),
            
            // Special Requests
            _buildSpecialRequestsCard(isSmallScreen),
            
            SizedBox(height: AppConstants.lgSpacing),
            
            // Price Summary
            _buildPriceSummaryCard(isSmallScreen),
            
            SizedBox(height: AppConstants.lgSpacing),
            
            // Book Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: () => _handleBooking(context),
                child: Text(
                  'Book Now - \$${_totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHotelInfoCard(bool isSmallScreen) {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.mdRadius),
              ),
              child: Center(
                  child: Icon(
                    IconStandards.getBookingTypeIcon('hotel'),
                  size: 64,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            SizedBox(height: AppConstants.mdSpacing),
            Text(
              widget.hotel['name'],
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.smSpacing),
            Row(
              children: [
                  Icon(
                    IconStandards.getUIIcon('location'),
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                SizedBox(width: AppConstants.xsSpacing),
                Expanded(
                  child: Text(
                    widget.hotel['location'],
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                  Icon(
                    IconStandards.getUIIcon('star'),
                  size: 16,
                  color: AppTheme.primaryOrange,
                ),
                SizedBox(width: AppConstants.xsSpacing),
                Text(
                  widget.hotel['rating'].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBookingDetailsCard(bool isSmallScreen) {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.mdSpacing),
            
            // Check-in Date
            _buildDateSelector(
              'Check-in Date',
              _checkInDate,
              () {
                setState(() {
                  _isSelectingCheckIn = true;
                  _showCalendar = true;
                });
              },
              isSmallScreen,
            ),
            
            SizedBox(height: AppConstants.mdSpacing),
            
            // Check-out Date
            _buildDateSelector(
              'Check-out Date',
              _checkOutDate,
              () {
                setState(() {
                  _isSelectingCheckIn = false;
                  _showCalendar = true;
                });
              },
              isSmallScreen,
            ),
            
            if (_showCalendar) ...[
              SizedBox(height: AppConstants.mdSpacing),
              _buildCalendar(),
            ],
            
            SizedBox(height: AppConstants.mdSpacing),
            
            // Guests and Rooms
            Row(
              children: [
                Expanded(
                  child: _buildCounterSelector(
                    'Guests',
                    _guests,
                    (value) => setState(() => _guests = value),
                    1,
                    10,
                    isSmallScreen,
                  ),
                ),
                SizedBox(width: AppConstants.mdSpacing),
                Expanded(
                  child: _buildCounterSelector(
                    'Rooms',
                    _rooms,
                    (value) => setState(() => _rooms = value),
                    1,
                    5,
                    isSmallScreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDateSelector(String label, DateTime date, VoidCallback onTap, bool isSmallScreen) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppConstants.mdSpacing),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppConstants.smRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
              Icon(
                IconStandards.getUIIcon('calendar'),
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppConstants.smRadius),
      ),
      child: TableCalendar<dynamic>(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _isSelectingCheckIn ? _checkInDate : _checkOutDate,
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          selectedDecoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryOrange,
            shape: BoxShape.circle,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            if (_isSelectingCheckIn) {
              _checkInDate = selectedDay;
              if (_checkOutDate.isBefore(_checkInDate)) {
                _checkOutDate = _checkInDate.add(const Duration(days: 1));
              }
            } else {
              if (selectedDay.isAfter(_checkInDate)) {
                _checkOutDate = selectedDay;
              }
            }
            _showCalendar = false;
          });
        },
        selectedDayPredicate: (day) {
          return isSameDay(_isSelectingCheckIn ? _checkInDate : _checkOutDate, day);
        },
      ),
    );
  }
  
  Widget _buildCounterSelector(
    String label,
    int value,
    Function(int) onChanged,
    int min,
    int max,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.all(AppConstants.mdSpacing),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppConstants.smRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: AppConstants.smSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: Icon(IconStandards.getUIIcon('remove')),
                color: AppTheme.primaryBlue,
              ),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: Icon(IconStandards.getUIIcon('add')),
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoomSelectionCard(bool isSmallScreen) {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room Type',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.mdSpacing),
            ..._roomTypes.map((roomType) {
              final price = (widget.hotel['pricePerNight'] as num).toDouble() * (_roomPrices[roomType] ?? 1.0);
              return Container(
                margin: EdgeInsets.only(bottom: AppConstants.smSpacing),
                child: RadioListTile<String>(
                  title: Text(
                    roomType,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  subtitle: Text(
                    '\$${price.toStringAsFixed(0)}/night',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: roomType,
                  groupValue: _selectedRoomType,
                  onChanged: (value) {
                    setState(() {
                      _selectedRoomType = value!;
                    });
                  },
                  activeColor: AppTheme.primaryBlue,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSpecialRequestsCard(bool isSmallScreen) {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Special Requests',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.mdSpacing),
            CustomInput(
              controller: _specialRequestsController,
              hintText: 'Any special requests or preferences...',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriceSummaryCard(bool isSmallScreen) {
    final basePrice = (widget.hotel['pricePerNight'] as num).toDouble();
    final roomMultiplier = _roomPrices[_selectedRoomType] ?? 1.0;
    final pricePerNight = basePrice * roomMultiplier;
    final subtotal = pricePerNight * _numberOfNights * _rooms;
    final taxes = subtotal * 0.12; // 12% tax
    final total = subtotal + taxes;
    
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Summary',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.mdSpacing),
            _buildPriceRow('Room Type', _selectedRoomType, isSmallScreen),
            _buildPriceRow('Nights', '$_numberOfNights nights', isSmallScreen),
            _buildPriceRow('Rooms', '$_rooms room(s)', isSmallScreen),
            _buildPriceRow('Price per night', '\$${pricePerNight.toStringAsFixed(0)}', isSmallScreen),
            const Divider(),
            _buildPriceRow('Subtotal', '\$${subtotal.toStringAsFixed(0)}', isSmallScreen),
            _buildPriceRow('Taxes & Fees', '\$${taxes.toStringAsFixed(0)}', isSmallScreen),
            const Divider(),
            _buildPriceRow(
              'Total',
              '\$${total.toStringAsFixed(0)}',
              isSmallScreen,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriceRow(String label, String value, bool isSmallScreen, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppConstants.xsSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppTheme.primaryGreen : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  void _handleBooking(BuildContext context) {
    final bookingDetails = {
      'type': 'hotel',
      'hotelId': widget.hotel['id'],
      'hotelName': widget.hotel['name'],
      'location': widget.hotel['location'],
      'checkInDate': _checkInDate.toIso8601String(),
      'checkOutDate': _checkOutDate.toIso8601String(),
      'guests': _guests,
      'rooms': _rooms,
      'roomType': _selectedRoomType,
      'specialRequests': _specialRequestsController.text,
    };
    
    // Navigate to payment screen
    context.push('/payment', extra: {
      'bookingDetails': bookingDetails,
      'totalAmount': _totalPrice,
      'currency': 'USD',
    });
  }
}