import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';

class CarRentalScreen extends StatefulWidget {
  final Map<String, dynamic> car;

  const CarRentalScreen({super.key, required this.car});

  @override
  State<CarRentalScreen> createState() => _CarRentalScreenState();
}

class _CarRentalScreenState extends State<CarRentalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupLocationController = TextEditingController();
  final _dropoffLocationController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _dropoffDate;
  TimeOfDay? _dropoffTime;
  String _selectedInsurance = 'basic';
  bool _needsChildSeat = false;
  bool _needsGPS = false;
  bool _needsWiFi = false;
  bool _additionalDriver = false;
  int _rentalDays = 1;

  final Map<String, double> _insurancePrices = {
    'basic': 0.0,
    'standard': 15.0,
    'premium': 25.0,
    'comprehensive': 35.0,
  };

  final Map<String, double> _addonPrices = {
    'childSeat': 5.0,
    'gps': 8.0,
    'wifi': 10.0,
    'additionalDriver': 12.0,
  };

  @override
  void initState() {
    super.initState();
    _calculateRentalDays();
  }

  void _calculateRentalDays() {
    if (_pickupDate != null && _dropoffDate != null) {
      setState(() {
        _rentalDays = _dropoffDate!.difference(_pickupDate!).inDays + 1;
        if (_rentalDays < 1) _rentalDays = 1;
      });
    }
  }

  double _calculateTotalPrice() {
    double basePrice = (widget.car['price'] ?? 50.0) * _rentalDays;
    double insurancePrice = _insurancePrices[_selectedInsurance]! * _rentalDays;
    double addonsPrice = 0.0;

    if (_needsChildSeat) addonsPrice += _addonPrices['childSeat']! * _rentalDays;
    if (_needsGPS) addonsPrice += _addonPrices['gps']! * _rentalDays;
    if (_needsWiFi) addonsPrice += _addonPrices['wifi']! * _rentalDays;
    if (_additionalDriver) addonsPrice += _addonPrices['additionalDriver']! * _rentalDays;

    return basePrice + insurancePrice + addonsPrice;
  }

  Future<void> _selectDate(BuildContext context, bool isPickup) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
        } else {
          _dropoffDate = picked;
        }
        _calculateRentalDays();
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isPickup) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupTime = picked;
        } else {
          _dropoffTime = picked;
        }
      });
    }
  }

  Future<void> _handleBooking() async {
    if (_formKey.currentState!.validate()) {
      if (_pickupDate == null || _pickupTime == null || _dropoffDate == null || _dropoffTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select pickup and dropoff dates and times')),
        );
        return;
      }

      final bookingDetails = {
        'type': 'car_rental',
        'car': widget.car,
        'pickupLocation': _pickupLocationController.text,
        'dropoffLocation': _dropoffLocationController.text,
        'pickupDate': _pickupDate!.toIso8601String(),
        'pickupTime': '${_pickupTime!.hour}:${_pickupTime!.minute}',
        'dropoffDate': _dropoffDate!.toIso8601String(),
        'dropoffTime': '${_dropoffTime!.hour}:${_dropoffTime!.minute}',
        'rentalDays': _rentalDays,
        'insurance': _selectedInsurance,
        'addons': {
          'childSeat': _needsChildSeat,
          'gps': _needsGPS,
          'wifi': _needsWiFi,
          'additionalDriver': _additionalDriver,
        },
        'driverName': _driverNameController.text,
        'licenseNumber': _licenseNumberController.text,
        'emergencyContact': _emergencyContactController.text,
        'specialRequests': _specialRequestsController.text,
      };

      final totalAmount = _calculateTotalPrice();
      const currency = 'USD';

      context.push('/payment', extra: {
        'bookingDetails': bookingDetails,
        'totalAmount': totalAmount,
        'currency': currency,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Rental Booking'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCarInfoCard(),
              const SizedBox(height: 16),
              _buildLocationCard(),
              const SizedBox(height: 16),
              _buildDateTimeCard(),
              const SizedBox(height: 16),
              _buildInsuranceCard(),
              const SizedBox(height: 16),
              _buildAddonsCard(),
              const SizedBox(height: 16),
              _buildDriverInfoCard(),
              const SizedBox(height: 16),
              _buildAdditionalInfoCard(),
              const SizedBox(height: 16),
              _buildPriceSummaryCard(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  onPressed: _handleBooking,
                  child: Text(
                    'Proceed to Payment - \$${_calculateTotalPrice().toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.car['name'] ?? 'Car Rental',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.car['description'] ?? 'Comfortable and reliable vehicle',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(IconStandards.getBookingTypeIcon('car_rental'), color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text('\$${widget.car['price'] ?? 50}/day'),
                const Spacer(),
                Icon(IconStandards.getUIIcon('people'), color: AppTheme.primaryBlue),
                const SizedBox(width: 4),
                Text('${widget.car['seats'] ?? 4} seats'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pickup & Dropoff Locations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: _pickupLocationController,
              labelText: 'Pickup Location',
              hintText: 'Enter pickup address or location',
              prefixIcon: IconStandards.getUIIcon('location'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter pickup location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: _dropoffLocationController,
              labelText: 'Dropoff Location',
              hintText: 'Enter dropoff address or location',
              prefixIcon: IconStandards.getUIIcon('location'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter dropoff location';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rental Period',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pickup Date', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(IconStandards.getUIIcon('calendar')),
                              const SizedBox(width: 8),
                              Text(
                                _pickupDate != null
                                    ? '${_pickupDate!.day}/${_pickupDate!.month}/${_pickupDate!.year}'
                                    : 'Select date',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pickup Time', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context, true),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(IconStandards.getUIIcon('time')),
                              const SizedBox(width: 8),
                              Text(
                                _pickupTime != null
                                    ? '${_pickupTime!.hour}:${_pickupTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Select time',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dropoff Date', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(IconStandards.getUIIcon('calendar')),
                              const SizedBox(width: 8),
                              Text(
                                _dropoffDate != null
                                    ? '${_dropoffDate!.day}/${_dropoffDate!.month}/${_dropoffDate!.year}'
                                    : 'Select date',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dropoff Time', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(IconStandards.getUIIcon('time')),
                              const SizedBox(width: 8),
                              Text(
                                _dropoffTime != null
                                    ? '${_dropoffTime!.hour}:${_dropoffTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Select time',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(IconStandards.getUIIcon('info'), color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Rental Duration: $_rentalDays day${_rentalDays > 1 ? 's' : ''}',
                    style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insurance Coverage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...['basic', 'standard', 'premium', 'comprehensive'].map((insurance) {
              final price = _insurancePrices[insurance]!;
              return RadioListTile<String>(
                title: Text(_getInsuranceName(insurance)),
                subtitle: Text(
                  price == 0 ? 'Included' : '+\$${price.toStringAsFixed(0)}/day',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                value: insurance,
                groupValue: _selectedInsurance,
                onChanged: (value) {
                  setState(() {
                    _selectedInsurance = value!;
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getInsuranceName(String insurance) {
    switch (insurance) {
      case 'basic':
        return 'Basic Coverage';
      case 'standard':
        return 'Standard Coverage';
      case 'premium':
        return 'Premium Coverage';
      case 'comprehensive':
        return 'Comprehensive Coverage';
      default:
        return insurance;
    }
  }

  Widget _buildAddonsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Child Seat'),
              subtitle: Text('+\$${_addonPrices['childSeat']!.toStringAsFixed(0)}/day'),
              value: _needsChildSeat,
              onChanged: (value) {
                setState(() {
                  _needsChildSeat = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('GPS Navigation'),
              subtitle: Text('+\$${_addonPrices['gps']!.toStringAsFixed(0)}/day'),
              value: _needsGPS,
              onChanged: (value) {
                setState(() {
                  _needsGPS = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('WiFi Hotspot'),
              subtitle: Text('+\$${_addonPrices['wifi']!.toStringAsFixed(0)}/day'),
              value: _needsWiFi,
              onChanged: (value) {
                setState(() {
                  _needsWiFi = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Additional Driver'),
              subtitle: Text('+\$${_addonPrices['additionalDriver']!.toStringAsFixed(0)}/day'),
              value: _additionalDriver,
              onChanged: (value) {
                setState(() {
                  _additionalDriver = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driver Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: _driverNameController,
              labelText: 'Primary Driver Name',
              hintText: 'Enter full name as on license',
              prefixIcon: IconStandards.getUIIcon('person'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter driver name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: _licenseNumberController,
              labelText: 'Driver License Number',
              hintText: 'Enter license number',
              prefixIcon: IconStandards.getPaymentMethodIcon('credit_card'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter license number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: _emergencyContactController,
              labelText: 'Emergency Contact',
              hintText: 'Enter emergency contact number',
              prefixIcon: IconStandards.getUIIcon('phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: _specialRequestsController,
              labelText: 'Special Requests',
              hintText: 'Any special requirements or requests',
              prefixIcon: IconStandards.getUIIcon('note'),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummaryCard() {
    final basePrice = (widget.car['price'] ?? 50.0) * _rentalDays;
    final insurancePrice = _insurancePrices[_selectedInsurance]! * _rentalDays;
    double addonsPrice = 0.0;

    if (_needsChildSeat) addonsPrice += _addonPrices['childSeat']! * _rentalDays;
    if (_needsGPS) addonsPrice += _addonPrices['gps']! * _rentalDays;
    if (_needsWiFi) addonsPrice += _addonPrices['wifi']! * _rentalDays;
    if (_additionalDriver) addonsPrice += _addonPrices['additionalDriver']! * _rentalDays;

    final totalPrice = basePrice + insurancePrice + addonsPrice;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Car Rental ($_rentalDays day${_rentalDays > 1 ? 's' : ''})'),
                Text('\$${basePrice.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Insurance (${_getInsuranceName(_selectedInsurance)})'),
                Text('\$${insurancePrice.toStringAsFixed(2)}'),
              ],
            ),
            if (addonsPrice > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Additional Services'),
                  Text('\$${addonsPrice.toStringAsFixed(2)}'),
                ],
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    _driverNameController.dispose();
    _licenseNumberController.dispose();
    _emergencyContactController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }
}