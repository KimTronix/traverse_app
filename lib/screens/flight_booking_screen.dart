import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_input.dart';

class FlightBookingScreen extends StatefulWidget {
  final Map<String, dynamic> flight;
  
  const FlightBookingScreen({super.key, required this.flight});

  @override
  State<FlightBookingScreen> createState() => _FlightBookingScreenState();
}

class _FlightBookingScreenState extends State<FlightBookingScreen> {
  DateTime _departureDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _returnDate;
  int _passengers = 1;
  String _flightClass = 'Economy';
  bool _isRoundTrip = false;
  final List<String> _flightClasses = ['Economy', 'Premium Economy', 'Business', 'First Class'];
  final Map<String, double> _classMultipliers = {
    'Economy': 1.0,
    'Premium Economy': 1.5,
    'Business': 3.0,
    'First Class': 5.0,
  };
  
  bool _showDepartureCalendar = false;
  bool _showReturnCalendar = false;
  
  final TextEditingController _specialRequestsController = TextEditingController();
  
  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }
  
  double get _totalPrice {
    final basePrice = (widget.flight['price'] as num).toDouble();
    final classMultiplier = _classMultipliers[_flightClass] ?? 1.0;
    var total = basePrice * classMultiplier * _passengers;
    
    if (_isRoundTrip) {
      total *= 2; // Double for round trip
    }
    
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Book Flight',
          style: TextStyle(
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
            // Flight Info Card
            _buildFlightInfoCard(isSmallScreen),
            
            SizedBox(height: AppConstants.lgSpacing),
            
            // Trip Type Selection
            _buildTripTypeCard(isSmallScreen),
            
            SizedBox(height: AppConstants.lgSpacing),
            
            // Flight Details
            _buildFlightDetailsCard(isSmallScreen),
            
            SizedBox(height: AppConstants.lgSpacing),
            
            // Class Selection
            _buildClassSelectionCard(isSmallScreen),
            
            SizedBox(height: AppConstants.lgSpacing),
            
            // Passenger Info
            _buildPassengerInfoCard(isSmallScreen),
            
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
                  'Book Flight - \$${_totalPrice.toStringAsFixed(0)}',
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
  
  Widget _buildFlightInfoCard(bool isSmallScreen) {
    final departure = widget.flight['departure'];
    final arrival = widget.flight['arrival'];
    
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                  ),
                  child: Center(
                    child: Icon(
                      IconStandards.getBookingTypeIcon('flight'),
                      size: 32,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                SizedBox(width: AppConstants.mdSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.flight['airline'],
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Flight ${widget.flight['flightNumber']}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.lgSpacing),
            
            // Route Information
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        departure['time'],
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        departure['airport'],
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        departure['city'],
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Column(
                  children: [
                    Icon(
                      IconStandards.getBookingTypeIcon('flight'),
                      color: AppTheme.primaryBlue,
                    ),
                    SizedBox(height: AppConstants.xsSpacing),
                    Text(
                      widget.flight['duration'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        arrival['time'],
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        arrival['airport'],
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        arrival['city'],
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTripTypeCard(bool isSmallScreen) {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Type',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.mdSpacing),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('One Way'),
                    value: false,
                    groupValue: _isRoundTrip,
                    onChanged: (value) {
                      setState(() {
                        _isRoundTrip = value!;
                        if (!_isRoundTrip) {
                          _returnDate = null;
                        }
                      });
                    },
                    activeColor: AppTheme.primaryBlue,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Round Trip'),
                    value: true,
                    groupValue: _isRoundTrip,
                    onChanged: (value) {
                      setState(() {
                        _isRoundTrip = value!;
                        if (_isRoundTrip && _returnDate == null) {
                          _returnDate = _departureDate.add(const Duration(days: 7));
                        }
                      });
                    },
                    activeColor: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFlightDetailsCard(bool isSmallScreen) {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Flight Details',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.mdSpacing),
            
            // Departure Date
            _buildDateSelector(
              'Departure Date',
              _departureDate,
              () {
                setState(() {
                  _showDepartureCalendar = !_showDepartureCalendar;
                  _showReturnCalendar = false;
                });
              },
              isSmallScreen,
            ),
            
            if (_showDepartureCalendar) ...[
              SizedBox(height: AppConstants.mdSpacing),
              _buildCalendar(true),
            ],
            
            if (_isRoundTrip) ...[
              SizedBox(height: AppConstants.mdSpacing),
              
              // Return Date
              _buildDateSelector(
                'Return Date',
                _returnDate ?? _departureDate.add(const Duration(days: 7)),
                () {
                  setState(() {
                    _showReturnCalendar = !_showReturnCalendar;
                    _showDepartureCalendar = false;
                  });
                },
                isSmallScreen,
              ),
              
              if (_showReturnCalendar) ...[
                SizedBox(height: AppConstants.mdSpacing),
                _buildCalendar(false),
              ],
            ],
            
            SizedBox(height: AppConstants.mdSpacing),
            
            // Passengers
            _buildCounterSelector(
              'Passengers',
              _passengers,
              (value) => setState(() => _passengers = value),
              1,
              9,
              isSmallScreen,
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
  
  Widget _buildCalendar(bool isDeparture) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppConstants.smRadius),
      ),
      child: TableCalendar<dynamic>(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: isDeparture ? _departureDate : (_returnDate ?? _departureDate),
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
            if (isDeparture) {
              _departureDate = selectedDay;
              if (_isRoundTrip && _returnDate != null && _returnDate!.isBefore(_departureDate)) {
                _returnDate = _departureDate.add(const Duration(days: 1));
              }
              _showDepartureCalendar = false;
            } else {
              if (selectedDay.isAfter(_departureDate)) {
                _returnDate = selectedDay;
              }
              _showReturnCalendar = false;
            }
          });
        },
        selectedDayPredicate: (day) {
          return isSameDay(isDeparture ? _departureDate : _returnDate, day);
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
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
  
  Widget _buildClassSelectionCard(bool isSmallScreen) {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Flight Class',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.mdSpacing),
            ..._flightClasses.map((flightClass) {
              final basePrice = (widget.flight['price'] as num).toDouble();
              final multiplier = _classMultipliers[flightClass] ?? 1.0;
              final price = basePrice * multiplier;
              
              return Container(
                margin: EdgeInsets.only(bottom: AppConstants.smSpacing),
                child: RadioListTile<String>(
                  title: Text(
                    flightClass,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  subtitle: Text(
                    '\$${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: flightClass,
                  groupValue: _flightClass,
                  onChanged: (value) {
                    setState(() {
                      _flightClass = value!;
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
  
  Widget _buildPassengerInfoCard(bool isSmallScreen) {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Passenger Information',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.mdSpacing),
            Text(
              'Passenger details will be collected during checkout.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
            SizedBox(height: AppConstants.smSpacing),
            Container(
              padding: EdgeInsets.all(AppConstants.mdSpacing),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.smRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    IconStandards.getUIIcon('info'),
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  SizedBox(width: AppConstants.smSpacing),
                  Expanded(
                    child: Text(
                      'Please ensure passenger names match government-issued ID.',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
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
              hintText: 'Meal preferences, accessibility needs, etc...',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriceSummaryCard(bool isSmallScreen) {
    final basePrice = (widget.flight['price'] as num).toDouble();
    final classMultiplier = _classMultipliers[_flightClass] ?? 1.0;
    final pricePerPerson = basePrice * classMultiplier;
    final subtotal = pricePerPerson * _passengers * (_isRoundTrip ? 2 : 1);
    final taxes = subtotal * 0.15; // 15% tax
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
            _buildPriceRow('Flight Class', _flightClass, isSmallScreen),
            _buildPriceRow('Trip Type', _isRoundTrip ? 'Round Trip' : 'One Way', isSmallScreen),
            _buildPriceRow('Passengers', '$_passengers passenger(s)', isSmallScreen),
            _buildPriceRow('Price per person', '\$${pricePerPerson.toStringAsFixed(0)}', isSmallScreen),
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
      'type': 'flight',
      'flightId': widget.flight['id'],
      'airline': widget.flight['airline'],
      'flightNumber': widget.flight['flightNumber'],
      'departure': widget.flight['departure'],
      'arrival': widget.flight['arrival'],
      'departureDate': _departureDate.toIso8601String(),
      'returnDate': _isRoundTrip ? _returnDate?.toIso8601String() : null,
      'passengers': _passengers,
      'flightClass': _flightClass,
      'isRoundTrip': _isRoundTrip,
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