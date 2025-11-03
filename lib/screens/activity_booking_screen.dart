import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_input.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';

class ActivityBookingScreen extends StatefulWidget {
  final Map<String, dynamic> activity;

  const ActivityBookingScreen({
    super.key,
    required this.activity,
  });

  @override
  State<ActivityBookingScreen> createState() => _ActivityBookingScreenState();
}

class _ActivityBookingScreenState extends State<ActivityBookingScreen> {
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  String? selectedTimeSlot;
  int participants = 1;
  String selectedDifficulty = 'beginner';
  bool includeEquipment = false;
  bool includeGuide = true;
  bool includeTransport = false;
  bool includeMeals = false;
  
  final TextEditingController specialRequestsController = TextEditingController();
  final TextEditingController emergencyContactController = TextEditingController();
  final TextEditingController dietaryRequirementsController = TextEditingController();
  
  final List<String> timeSlots = [
    '08:00 AM - 12:00 PM',
    '09:00 AM - 01:00 PM',
    '02:00 PM - 06:00 PM',
    '03:00 PM - 07:00 PM',
    '06:00 PM - 10:00 PM',
  ];
  
  final List<String> difficultyLevels = [
    'beginner',
    'intermediate',
    'advanced',
    'expert',
  ];
  
  double get basePrice => (widget.activity['price'] as num?)?.toDouble() ?? 0.0;
  
  double get equipmentPrice => includeEquipment ? 25.0 : 0.0;
  double get guidePrice => includeGuide ? 50.0 : 0.0;
  double get transportPrice => includeTransport ? 30.0 : 0.0;
  double get mealsPrice => includeMeals ? 40.0 : 0.0;
  
  double get totalPrice => (basePrice * participants) + equipmentPrice + guidePrice + transportPrice + mealsPrice;

  @override
  void initState() {
    super.initState();
    selectedTimeSlot = timeSlots.first;
  }

  @override
  void dispose() {
    specialRequestsController.dispose();
    emergencyContactController.dispose();
    dietaryRequirementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Activity'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(IconStandards.getUIIcon('back')),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActivityInfo(),
            const SizedBox(height: 24),
            _buildDateTimeSelection(),
            const SizedBox(height: 24),
            _buildParticipantsAndDifficulty(),
            const SizedBox(height: 24),
            _buildAddOnsSelection(),
            const SizedBox(height: 24),
            _buildAdditionalInfo(),
            const SizedBox(height: 24),
            _buildPriceSummary(),
            const SizedBox(height: 32),
            _buildBookButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityInfo() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                widget.activity['image'] ?? 'assets/images/safari-lodge.png',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: Icon(IconStandards.getUIIcon('image'), size: 50),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.activity['name'] ?? 'Activity',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(IconStandards.getUIIcon('location'), size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  widget.activity['location'] ?? 'Location',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                Icon(IconStandards.getUIIcon('star'), size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${widget.activity['rating'] ?? 4.5}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.activity['description'] ?? 'Experience an amazing activity',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date & Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activity Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(IconStandards.getUIIcon('calendar'), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                style: const TextStyle(fontSize: 16),
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
            const Text(
              'Time Slot',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedTimeSlot,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: timeSlots.map((String slot) {
                return DropdownMenuItem<String>(
                  value: slot,
                  child: Text(slot),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedTimeSlot = newValue;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsAndDifficulty() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Participants & Difficulty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Number of Participants',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: participants > 1 ? () {
                              setState(() {
                                participants--;
                              });
                            } : null,
                            icon: Icon(IconStandards.getUIIcon('remove')),
                          ),
                          Text(
                            participants.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: participants < 10 ? () {
                              setState(() {
                                participants++;
                              });
                            } : null,
                            icon: Icon(IconStandards.getUIIcon('add')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Difficulty Level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedDifficulty,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: difficultyLevels.map((String level) {
                return DropdownMenuItem<String>(
                  value: level,
                  child: Text(level.toUpperCase()),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedDifficulty = newValue!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOnsSelection() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add-ons & Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildAddOnOption(
              'Equipment Rental',
              'Includes all necessary equipment',
              equipmentPrice,
              includeEquipment,
              (value) => setState(() => includeEquipment = value),
            ),
            _buildAddOnOption(
              'Professional Guide',
              'Expert guide for the activity',
              guidePrice,
              includeGuide,
              (value) => setState(() => includeGuide = value),
            ),
            _buildAddOnOption(
              'Transportation',
              'Round-trip transportation included',
              transportPrice,
              includeTransport,
              (value) => setState(() => includeTransport = value),
            ),
            _buildAddOnOption(
              'Meals & Refreshments',
              'Lunch and refreshments provided',
              mealsPrice,
              includeMeals,
              (value) => setState(() => includeMeals = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOnOption(
    String title,
    String description,
    double price,
    bool isSelected,
    Function(bool) onChanged,
  ) {
    return CheckboxListTile(
      value: isSelected,
      onChanged: (bool? value) => onChanged(value ?? false),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          Text(
            '+\$${price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildAdditionalInfo() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: emergencyContactController,
              labelText: 'Emergency Contact',
              hintText: 'Phone number for emergency contact',
              keyboardType: TextInputType.phone,
              prefixIcon: IconStandards.getUIIcon('phone'),
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: dietaryRequirementsController,
              labelText: 'Dietary Requirements',
              hintText: 'Any dietary restrictions or allergies',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: specialRequestsController,
              labelText: 'Special Requests',
              hintText: 'Any special requests or requirements',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Activity (${participants}x)', basePrice * participants),
            if (includeEquipment) _buildPriceRow('Equipment Rental', equipmentPrice),
            if (includeGuide) _buildPriceRow('Professional Guide', guidePrice),
            if (includeTransport) _buildPriceRow('Transportation', transportPrice),
            if (includeMeals) _buildPriceRow('Meals & Refreshments', mealsPrice),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
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

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('\$${amount.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        onPressed: _handleBooking,
        child: const Text(
          'Book Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _handleBooking() {
    if (!_validateBookingForm()) {
      return;
    }

    final bookingDetails = {
      'type': 'activity',
      'activityId': widget.activity['id'],
      'activityName': widget.activity['name'],
      'date': selectedDate.toIso8601String(),
      'timeSlot': selectedTimeSlot,
      'participants': participants,
      'difficulty': selectedDifficulty,
      'includeEquipment': includeEquipment,
      'includeGuide': includeGuide,
      'includeTransport': includeTransport,
      'includeMeals': includeMeals,
      'emergencyContact': emergencyContactController.text,
      'dietaryRequirements': dietaryRequirementsController.text,
      'specialRequests': specialRequestsController.text,
    };
    
    // Navigate to payment screen
    context.push('/payment', extra: {
      'bookingDetails': bookingDetails,
      'totalAmount': totalPrice,
      'currency': 'USD',
    });
  }

  bool _validateBookingForm() {
    if (selectedTimeSlot == null) {
      _showErrorSnackBar('Please select a time slot');
      return false;
    }
    
    if (emergencyContactController.text.isEmpty) {
      _showErrorSnackBar('Please provide an emergency contact');
      return false;
    }
    
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}