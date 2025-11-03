import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/travel_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/icon_standards.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/bottom_navigation.dart';

class TravelPlanScreen extends StatefulWidget {
  final Map<String, dynamic>? suggestedTrip;
  
  const TravelPlanScreen({super.key, this.suggestedTrip});

  @override
  State<TravelPlanScreen> createState() => _TravelPlanScreenState();
}

class _TravelPlanScreenState extends State<TravelPlanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  String _selectedDestination = '';
  DateTime? _startDate;
  DateTime? _endDate;
  int _travelers = 1;
  String _budget = 'medium';
  List<String> _selectedActivities = [];
  String _travelStyle = 'Casual';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeWithSuggestedTrip();
  }

  void _initializeWithSuggestedTrip() {
    if (widget.suggestedTrip != null) {
      final trip = widget.suggestedTrip!;
      setState(() {
        _selectedDestination = trip['destination'] ?? '';
        _budget = _mapBudgetRange(trip['budget_range'] ?? 'medium');
        _selectedActivities = List<String>.from(trip['activities'] ?? []);
        _travelStyle = trip['travel_style'] ?? 'Casual';
        
        // Set default dates based on suggested duration
        final duration = trip['duration'] as String?;
        if (duration != null) {
          _startDate = DateTime.now().add(const Duration(days: 7));
          _endDate = _calculateEndDate(_startDate!, duration);
        }
      });
    }
  }

  String _mapBudgetRange(String budgetRange) {
    switch (budgetRange.toLowerCase()) {
      case 'budget':
        return 'low';
      case 'luxury':
      case 'premium':
        return 'high';
      case 'mid-range':
      default:
        return 'medium';
    }
  }

  DateTime _calculateEndDate(DateTime startDate, String duration) {
    final durationMatch = RegExp(r'(\d+)').firstMatch(duration);
    if (durationMatch != null) {
      final days = int.tryParse(durationMatch.group(1) ?? '3') ?? 3;
      return startDate.add(Duration(days: days));
    }
    return startDate.add(const Duration(days: 3));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final travelProvider = Provider.of<TravelProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Plan Your Trip',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(IconStandards.getUIIcon('back')),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: Icon(IconStandards.getUIIcon('share')),
            onPressed: () {
              // Handle share
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Form Section
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info Form
                  _buildBasicInfoForm(isSmallScreen),
                  SizedBox(height: isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
                  
                  // Tabs
                  _buildTabs(isSmallScreen),
                  SizedBox(height: isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
                  
                  // Tab Content
                  _buildTabContent(travelProvider, isSmallScreen),
                ],
              ),
            ),
          ),
          
          // Generate Itinerary Button
          _buildGenerateButton(isSmallScreen),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigation(),
    );
  }

  Widget _buildBasicInfoForm(bool isSmallScreen) {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trip Details',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
              
              // Destination Dropdown
              _buildDestinationDropdown(isSmallScreen),
              SizedBox(height: isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
              
              // Date Range
              _buildDateRange(isSmallScreen),
              SizedBox(height: isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
              
              // Travelers and Budget
              if (isSmallScreen)
                Column(
                  children: [
                    _buildTravelersSelector(isSmallScreen),
                    SizedBox(height: AppConstants.mdSpacing),
                    _buildBudgetSelector(isSmallScreen),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: _buildTravelersSelector(isSmallScreen)),
                    SizedBox(width: AppConstants.mdSpacing),
                    Expanded(child: _buildBudgetSelector(isSmallScreen)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationDropdown(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Destination',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 13 : 14,
          ),
        ),
        const SizedBox(height: AppConstants.xsSpacing),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.mdSpacing),
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(AppConstants.mdRadius),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDestination.isEmpty ? null : _selectedDestination,
              isExpanded: true,
              hint: Text(
                'Select destination',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: isSmallScreen ? 13 : 14,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedDestination = value ?? '';
                });
              },
              items: AppConstants.sampleDestinations.map((destination) {
                return DropdownMenuItem<String>(
                  value: destination['name'] as String,
                  child: Text(
                    destination['name'] as String,
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRange(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Travel Dates',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 13 : 14,
          ),
        ),
        const SizedBox(height: AppConstants.xsSpacing),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                'Start Date',
                _startDate,
                (date) => setState(() => _startDate = date),
                isSmallScreen,
              ),
            ),
            SizedBox(width: isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
            Expanded(
              child: _buildDateField(
                'End Date',
                _endDate,
                (date) => setState(() => _endDate = date),
                isSmallScreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? date,
    Function(DateTime?) onDateSelected,
    bool isSmallScreen,
  ) {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppConstants.mdSpacing),
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(AppConstants.mdRadius),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Icon(
              IconStandards.getUIIcon('calendar'),
              size: isSmallScreen ? 16 : 18,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: AppConstants.smSpacing),
            Expanded(
              child: Text(
                date != null
                    ? '${date.day}/${date.month}/${date.year}'
                    : label,
                style: TextStyle(
                  color: date != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: isSmallScreen ? 13 : 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelersSelector(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Travelers',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 13 : 14,
          ),
        ),
        const SizedBox(height: AppConstants.xsSpacing),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.mdSpacing),
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(AppConstants.mdRadius),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_travelers > 1) {
                    setState(() => _travelers--);
                  }
                },
                icon: Icon(IconStandards.getUIIcon('remove')),
                iconSize: isSmallScreen ? 18 : 20,
              ),
              Expanded(
                child: Text(
                  '$_travelers',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  if (_travelers < 10) {
                    setState(() => _travelers++);
                  }
                },
                icon: Icon(IconStandards.getUIIcon('add')),
                iconSize: isSmallScreen ? 18 : 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSelector(bool isSmallScreen) {
    final budgets = [
  {'value': 'budget', 'label': 'Budget', 'icon': IconStandards.getUIIcon('attach_money')},
  {'value': 'medium', 'label': 'Medium', 'icon': IconStandards.getUIIcon('attach_money')},
  {'value': 'luxury', 'label': 'Luxury', 'icon': IconStandards.getUIIcon('attach_money')},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Range',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 13 : 14,
          ),
        ),
        const SizedBox(height: AppConstants.xsSpacing),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.mdSpacing),
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(AppConstants.mdRadius),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _budget,
              isExpanded: true,
              onChanged: (value) {
                setState(() {
                  _budget = value ?? 'medium';
                });
              },
              items: budgets.map((budget) {
                return DropdownMenuItem<String>(
                  value: budget['value'] as String,
                  child: Row(
                    children: [
                      Icon(
                        budget['icon'] as IconData,
                        size: isSmallScreen ? 16 : 18,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: AppConstants.smSpacing),
                      Text(
                        budget['label'] as String,
                        style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryBlue,
        labelStyle: TextStyle(
          fontSize: isSmallScreen ? 12 : 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: isSmallScreen ? 12 : 14,
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(text: 'Destinations'),
          Tab(text: 'Hotels'),
          Tab(text: 'Transport'),
        ],
      ),
    );
  }

  Widget _buildTabContent(TravelProvider travelProvider, bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 300 : 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildDestinationsTab(travelProvider, isSmallScreen),
          _buildHotelsTab(isSmallScreen),
          _buildTransportTab(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildDestinationsTab(TravelProvider travelProvider, bool isSmallScreen) {
    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
      itemCount: AppConstants.sampleDestinations.length,
      itemBuilder: (context, index) {
        final destination = AppConstants.sampleDestinations[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: AssetImage(destination['image'] as String),
            radius: isSmallScreen ? 20 : 24,
          ),
          title: Text(
            destination['name'] as String,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
          subtitle: Text(
            destination['description'] as String,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: AppTheme.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            destination['budget'] as String,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 11 : 12,
              color: AppTheme.primaryBlue,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHotelsTab(bool isSmallScreen) {
    final hotels = [
      {'name': 'Luxury Resort', 'price': '\$200/night', 'rating': '4.8'},
      {'name': 'Boutique Hotel', 'price': '\$150/night', 'rating': '4.5'},
      {'name': 'Budget Inn', 'price': '\$80/night', 'rating': '4.2'},
    ];

    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
      itemCount: hotels.length,
      itemBuilder: (context, index) {
        final hotel = hotels[index];
        return ListTile(
          leading: Container(
            width: isSmallScreen ? 40 : 48,
            height: isSmallScreen ? 40 : 48,
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(AppConstants.mdRadius),
            ),
            child: Icon(IconStandards.getUIIcon('hotel'), color: AppTheme.primaryBlue),
          ),
          title: Text(
            hotel['name'] as String,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
          subtitle: Text(
            hotel['price'] as String,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(IconStandards.getUIIcon('star'), color: Colors.amber, size: 16),
              Text(
                hotel['rating'] as String,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransportTab(bool isSmallScreen) {
    final transport = [
      {'name': 'Flight', 'price': '\$300', 'duration': '2h 30m'},
      {'name': 'Train', 'price': '\$80', 'duration': '4h 15m'},
      {'name': 'Bus', 'price': '\$40', 'duration': '6h 30m'},
    ];

    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? AppConstants.smSpacing : AppConstants.mdSpacing),
      itemCount: transport.length,
      itemBuilder: (context, index) {
        final option = transport[index];
        return ListTile(
          leading: Container(
            width: isSmallScreen ? 40 : 48,
            height: isSmallScreen ? 40 : 48,
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(AppConstants.mdRadius),
            ),
            child: Icon(
              index == 0 ? IconStandards.getUIIcon('flight') : index == 1 ? IconStandards.getUIIcon('train') : IconStandards.getUIIcon('directions_bus'),
              color: AppTheme.primaryBlue,
            ),
          ),
          title: Text(
            option['name'] as String,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
          subtitle: Text(
            option['duration'] as String,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: Text(
            option['price'] as String,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 11 : 12,
              color: AppTheme.primaryBlue,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenerateButton(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? AppConstants.mdSpacing : AppConstants.lgSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderLight,
            width: 1,
          ),
        ),
      ),
      child: CustomButton(
        onPressed: () {
          // Handle generate itinerary
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Generating your personalized itinerary...'),
              backgroundColor: AppTheme.primaryBlue,
            ),
          );
        },
        child: Text(
          'Generate Itinerary',
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
      ),
    );
  }
}