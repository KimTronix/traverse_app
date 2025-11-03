import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../utils/logger.dart';

class BookingProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _hotels = [];
  List<Map<String, dynamic>> _flights = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _carRentals = [];
  bool _isLoading = false;
  String? _selectedBookingType;
  Map<String, dynamic>? _currentBooking;

  // Getters
  List<Map<String, dynamic>> get bookings => _bookings;
  List<Map<String, dynamic>> get hotels => _hotels;
  List<Map<String, dynamic>> get flights => _flights;
  List<Map<String, dynamic>> get activities => _activities;
  List<Map<String, dynamic>> get carRentals => _carRentals;
  bool get isLoading => _isLoading;
  String? get selectedBookingType => _selectedBookingType;
  Map<String, dynamic>? get currentBooking => _currentBooking;

  BookingProvider() {
    _loadSampleData();
    _loadBookingsFromDatabase();
  }

  Future<void> _loadBookingsFromDatabase() async {
    try {
      // Load sample bookings for demo
      _bookings = [];
    } catch (e) {
      Logger.error('Error loading bookings', e);
    }
    notifyListeners();
  }

  void _loadSampleData() {
    _hotels = [
      {
        'id': 'hotel_1',
        'name': 'Luxury Beach Resort',
        'location': 'Maldives',
        'image': 'assets/images/luxury-accommodation.png',
        'rating': 4.9,
        'pricePerNight': 450,
        'currency': 'USD',
        'amenities': ['Pool', 'Spa', 'Beach Access', 'WiFi', 'Restaurant'],
        'rooms': [
          {
            'type': 'Ocean Villa',
            'price': 450,
            'capacity': 2,
            'available': true,
            'features': ['Ocean View', 'Private Pool', 'Butler Service']
          },
          {
            'type': 'Beach Bungalow',
            'price': 350,
            'capacity': 4,
            'available': true,
            'features': ['Beach Access', 'Terrace', 'Mini Bar']
          }
        ]
      },
      {
        'id': 'hotel_2',
        'name': 'Mountain Lodge',
        'location': 'Swiss Alps',
        'image': 'assets/images/safari-lodge.png',
        'rating': 4.7,
        'pricePerNight': 280,
        'currency': 'USD',
        'amenities': ['Ski Access', 'Fireplace', 'Mountain View', 'WiFi'],
        'rooms': [
          {
            'type': 'Alpine Suite',
            'price': 280,
            'capacity': 2,
            'available': true,
            'features': ['Mountain View', 'Fireplace', 'Balcony']
          }
        ]
      }
    ];

    _flights = [
      {
        'id': 'flight_1',
        'airline': 'SkyLine Airways',
        'flightNumber': 'SL123',
        'departure': {
          'airport': 'JFK',
          'city': 'New York',
          'time': '08:30',
          'date': '2025-02-15'
        },
        'arrival': {
          'airport': 'LHR',
          'city': 'London',
          'time': '20:45',
          'date': '2025-02-15'
        },
        'duration': '7h 15m',
        'price': 650,
        'currency': 'USD',
        'class': 'Economy',
        'available': true
      },
      {
        'id': 'flight_2',
        'airline': 'Global Express',
        'flightNumber': 'GE456',
        'departure': {
          'airport': 'LAX',
          'city': 'Los Angeles',
          'time': '14:20',
          'date': '2025-02-20'
        },
        'arrival': {
          'airport': 'NRT',
          'city': 'Tokyo',
          'time': '18:30+1',
          'date': '2025-02-21'
        },
        'duration': '11h 10m',
        'price': 890,
        'currency': 'USD',
        'class': 'Economy',
        'available': true
      }
    ];

    _activities = [
      {
        'id': 'activity_1',
        'name': 'Sunset Safari Tour',
        'location': 'Kenya',
        'image': 'assets/images/meerkat-safari.png',
        'rating': 4.8,
        'duration': '6 hours',
        'price': 120,
        'currency': 'USD',
        'maxGroupSize': 8,
        'includes': ['Transportation', 'Guide', 'Refreshments'],
        'timeSlots': ['06:00', '14:00'],
        'available': true
      },
      {
        'id': 'activity_2',
        'name': 'Cooking Class Experience',
        'location': 'Italy',
        'image': 'assets/images/local-market.png',
        'rating': 4.9,
        'duration': '4 hours',
        'price': 85,
        'currency': 'USD',
        'maxGroupSize': 12,
        'includes': ['Ingredients', 'Recipe Book', 'Meal'],
        'timeSlots': ['10:00', '15:00'],
        'available': true
      }
    ];

    _carRentals = [
      {
        'id': 'car_1',
        'brand': 'Toyota',
        'model': 'Camry',
        'year': 2023,
        'type': 'Sedan',
        'image': 'assets/images/travel-app-mockup.png',
        'pricePerDay': 45,
        'currency': 'USD',
        'features': ['Automatic', 'AC', 'GPS', '4 Seats'],
        'fuelType': 'Gasoline',
        'available': true
      },
      {
        'id': 'car_2',
        'brand': 'BMW',
        'model': 'X5',
        'year': 2023,
        'type': 'SUV',
        'image': 'assets/images/travel-app-mockup.png',
        'pricePerDay': 95,
        'currency': 'USD',
        'features': ['Automatic', 'AC', 'GPS', '7 Seats', 'Leather'],
        'fuelType': 'Gasoline',
        'available': true
      }
    ];
  }

  // Booking Management
  Future<String> createBooking({
    required String type,
    required Map<String, dynamic> details,
    required double totalAmount,
    required String currency,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? guests,
    int? rooms,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uuid = const Uuid();
      final bookingId = uuid.v4();

      final booking = {
        'id': bookingId,
        'userId': 1,
        'type': type,
        'title': details['name'] ?? details['title'] ?? 'Booking',
        'description': details['description'] ?? '',
        'totalAmount': totalAmount,
        'currency': currency,
        'status': 'confirmed',
        'bookingDate': DateTime.now().toIso8601String(),
        'checkInDate': checkInDate?.toIso8601String(),
        'checkOutDate': checkOutDate?.toIso8601String(),
        'guests': guests,
        'rooms': rooms,
        'data': details.toString(), // Store additional data as JSON string
        'createdAt': DateTime.now().toIso8601String(),
      };

      _bookings.add(booking);
      
      _isLoading = false;
      notifyListeners();
      
      return bookingId;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to create booking: $e');
    }
  }


  void setSelectedBookingType(String type) {
    _selectedBookingType = type;
    notifyListeners();
  }

  void setCurrentBooking(Map<String, dynamic>? booking) {
    _currentBooking = booking;
    notifyListeners();
  }

  Future<void> cancelBooking(String bookingId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final bookingIndex = _bookings.indexWhere((b) => b['id'] == bookingId);
      if (bookingIndex != -1) {
        _bookings[bookingIndex]['status'] = 'cancelled';
      }
    } catch (e) {
      Logger.error('Error cancelling booking', e);
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> getBookingsByType(String type) {
    return _bookings.where((booking) => booking['type'] == type).toList();
  }

  List<Map<String, dynamic>> getActiveBookings() {
    return _bookings.where((booking) => booking['status'] != 'cancelled').toList();
  }

  double getTotalSpent() {
    return _bookings
        .where((booking) => booking['status'] == 'confirmed')
        .fold(0.0, (sum, booking) => sum + (booking['totalAmount'] as num).toDouble());
  }

  Future<void> refreshBookings() async {
    await _loadBookingsFromDatabase();
  }

  // Search and Filter Methods
  List<Map<String, dynamic>> searchHotels({
    String? location,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    double? maxPrice,
  }) {
    var results = List<Map<String, dynamic>>.from(_hotels);
    
    if (location != null && location.isNotEmpty) {
      results = results.where((hotel) => 
        hotel['location'].toString().toLowerCase().contains(location.toLowerCase())
      ).toList();
    }
    
    if (maxPrice != null) {
      results = results.where((hotel) => hotel['pricePerNight'] <= maxPrice).toList();
    }
    
    return results;
  }

  List<Map<String, dynamic>> searchFlights({
    String? from,
    String? to,
    DateTime? departureDate,
    DateTime? returnDate,
    int? passengers,
    String? flightClass,
  }) {
    var results = List<Map<String, dynamic>>.from(_flights);
    
    if (from != null && from.isNotEmpty) {
      results = results.where((flight) => 
        flight['departure']['city'].toString().toLowerCase().contains(from.toLowerCase())
      ).toList();
    }
    
    if (to != null && to.isNotEmpty) {
      results = results.where((flight) => 
        flight['arrival']['city'].toString().toLowerCase().contains(to.toLowerCase())
      ).toList();
    }
    
    return results;
  }
}