import 'package:flutter/material.dart';
import '../services/statistics_service.dart';

class StatisticsProvider with ChangeNotifier {
  final StatisticsService _statisticsService = StatisticsService.instance;

  // Statistics data
  int _totalVisits = 0;
  int _totalRegisteredPlaces = 0;
  int _totalActiveUsers = 0;
  int _totalServiceProviders = 0;
  List<Map<String, dynamic>> _dailyVisits = [];
  List<Map<String, dynamic>> _userGrowth = [];
  List<Map<String, dynamic>> _topDestinations = [];
  List<Map<String, dynamic>> _placesByCategory = [];
  List<Map<String, dynamic>> _allRegisteredPlaces = [];
  List<Map<String, dynamic>> _serviceProviders = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  int get totalVisits => _totalVisits;
  int get totalRegisteredPlaces => _totalRegisteredPlaces;
  int get totalActiveUsers => _totalActiveUsers;
  int get totalServiceProviders => _totalServiceProviders;
  List<Map<String, dynamic>> get dailyVisits => _dailyVisits;
  List<Map<String, dynamic>> get userGrowth => _userGrowth;
  List<Map<String, dynamic>> get topDestinations => _topDestinations;
  List<Map<String, dynamic>> get placesByCategory => _placesByCategory;
  List<Map<String, dynamic>> get allRegisteredPlaces => _allRegisteredPlaces;
  List<Map<String, dynamic>> get serviceProviders => _serviceProviders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all statistics
  Future<void> loadStatistics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load basic statistics
      await Future.wait([
        _loadTotalVisits(),
        _loadTotalRegisteredPlaces(),
        _loadTotalActiveUsers(),
        _loadTotalServiceProviders(),
      ]);

      // Load chart data
      await Future.wait([
        _loadDailyVisits(),
        _loadUserGrowth(),
        _loadTopDestinations(),
        _loadPlacesByCategory(),
      ]);

      // Load detailed data
      await Future.wait([
        _loadAllRegisteredPlaces(),
        _loadServiceProviders(),
      ]);
    } catch (e) {
      _error = 'Failed to load statistics: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load individual statistics
  Future<void> _loadTotalVisits() async {
    _totalVisits = await _statisticsService.getTotalVisits();
  }

  Future<void> _loadTotalRegisteredPlaces() async {
    _totalRegisteredPlaces = await _statisticsService.getTotalRegisteredPlaces();
  }

  Future<void> _loadTotalActiveUsers() async {
    _totalActiveUsers = await _statisticsService.getTotalActiveUsers();
  }

  Future<void> _loadTotalServiceProviders() async {
    _totalServiceProviders = await _statisticsService.getTotalServiceProviders();
  }

  Future<void> _loadDailyVisits() async {
    _dailyVisits = await _statisticsService.getDailyVisits();
  }

  Future<void> _loadUserGrowth() async {
    _userGrowth = await _statisticsService.getUserGrowth();
  }

  Future<void> _loadTopDestinations() async {
    _topDestinations = await _statisticsService.getTopDestinations();
  }

  Future<void> _loadPlacesByCategory() async {
    _placesByCategory = await _statisticsService.getPlacesByCategory();
  }

  Future<void> _loadAllRegisteredPlaces() async {
    _allRegisteredPlaces = await _statisticsService.getAllRegisteredPlaces();
  }

  Future<void> _loadServiceProviders() async {
    _serviceProviders = await _statisticsService.getServiceProvidersByCategory();
  }

  // Track user visit
  Future<void> trackVisit(String userId, String? location) async {
    await _statisticsService.trackVisit(userId, location);
    // Refresh statistics after tracking
    await _loadTotalVisits();
    await _loadDailyVisits();
    notifyListeners();
  }

  // Track place registration
  Future<void> trackPlaceRegistration(String placeId, String placeName, String category, String location) async {
    await _statisticsService.trackPlaceRegistration(placeId, placeName, category, location);
    // Refresh statistics after tracking
    await _loadTotalRegisteredPlaces();
    await _loadPlacesByCategory();
    await _loadAllRegisteredPlaces();
    notifyListeners();
  }

  // Refresh specific statistics
  Future<void> refreshBasicStats() async {
    await Future.wait([
      _loadTotalVisits(),
      _loadTotalRegisteredPlaces(),
      _loadTotalActiveUsers(),
      _loadTotalServiceProviders(),
    ]);
    notifyListeners();
  }

  Future<void> refreshChartData() async {
    await Future.wait([
      _loadDailyVisits(),
      _loadUserGrowth(),
      _loadTopDestinations(),
      _loadPlacesByCategory(),
    ]);
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}