import 'package:flutter/material.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/status.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class StatusProvider extends ChangeNotifier {
  List<Status> _statuses = [];
  bool _isLoading = false;
  String? _error;
  DeviceInfo? _currentDeviceInfo;

  // Getters
  List<Status> get statuses => _statuses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DeviceInfo? get currentDeviceInfo => _currentDeviceInfo;

  StatusProvider() {
    _initializeDeviceInfo();
    _loadStatuses();
  }

  // Initialize device information
  Future<void> _initializeDeviceInfo() async {
    try {
      _currentDeviceInfo = await _collectDeviceInfo();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize device info: $e';
      notifyListeners();
    }
  }

  // Collect current device information
  Future<DeviceInfo> _collectDeviceInfo() async {
    try {
      // Collect real device information
      final locationInfo = await _getLocationInfo();
      final batteryInfo = await _getBatteryInfo();
      final connectivityInfo = await _getConnectivityInfo();
      final deviceModel = await _getDeviceModel();
      final operatingSystem = await _getOperatingSystem();
      
      return DeviceInfo(
        location: locationInfo,
        battery: batteryInfo,
        connectivity: connectivityInfo,
        deviceModel: deviceModel,
        operatingSystem: operatingSystem,
        appVersion: AppConstants.appVersion,
      );
    } catch (e) {
      Logger.error('Error collecting device info', e);
      // Fallback to basic info if collection fails
      return DeviceInfo(
        location: LocationInfo(
          latitude: 0.0,
          longitude: 0.0,
          city: 'Unknown',
          country: 'Unknown',
          accuracy: 0.0,
        ),
        battery: BatteryInfo(
          level: 0,
          isCharging: false,
          chargingStatus: 'unknown',
        ),
        connectivity: ConnectivityInfo(
          type: 'unknown',
          networkName: 'Unknown',
          signalStrength: null,
          isConnected: false,
        ),
        deviceModel: 'Unknown Device',
        operatingSystem: 'Unknown OS',
        appVersion: AppConstants.appVersion,
      );
    }
  }

  // Get connectivity information
  Future<ConnectivityInfo> _getConnectivityInfo() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      String type;
      bool isConnected = true;
      
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        type = 'wifi';
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        type = 'mobile';
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        type = 'ethernet';
      } else {
        type = 'none';
        isConnected = false;
      }
      
      return ConnectivityInfo(
        type: type,
        networkName: type == 'wifi' ? 'WiFi Network' : type.toUpperCase(),
        signalStrength: null, // Signal strength requires platform-specific implementation
        isConnected: isConnected,
      );
    } catch (e) {
      Logger.error('Error getting connectivity info', e);
      return ConnectivityInfo(
        type: 'unknown',
        networkName: 'Unknown',
        signalStrength: null,
        isConnected: false,
      );
    }
  }

  // Get battery information
  Future<BatteryInfo?> _getBatteryInfo() async {
    try {
      final battery = Battery();
      final level = await battery.batteryLevel;
      final state = await battery.batteryState;
      
      String chargingStatus;
      bool isCharging;
      
      switch (state) {
        case BatteryState.charging:
          chargingStatus = 'charging';
          isCharging = true;
          break;
        case BatteryState.discharging:
          chargingStatus = 'discharging';
          isCharging = false;
          break;
        case BatteryState.full:
          chargingStatus = 'full';
          isCharging = false;
          break;
        default:
          chargingStatus = 'unknown';
          isCharging = false;
      }
      
      return BatteryInfo(
        level: level,
        isCharging: isCharging,
        chargingStatus: chargingStatus,
      );
    } catch (e) {
      Logger.error('Error getting battery info', e);
      return null;
    }
  }

  // Get location information
  Future<LocationInfo?> _getLocationInfo() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      
      // For demo purposes, map coordinates to cities
      String city = 'Unknown';
      String country = 'Unknown';
      
      // Simple city mapping based on coordinates
      if (position.latitude > 40.0 && position.latitude < 41.0 && 
          position.longitude > -75.0 && position.longitude < -73.0) {
        city = 'New York';
        country = 'USA';
      } else if (position.latitude > 51.0 && position.latitude < 52.0 && 
                 position.longitude > -1.0 && position.longitude < 1.0) {
        city = 'London';
        country = 'UK';
      }
      
      return LocationInfo(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        country: country,
        accuracy: position.accuracy,
      );
    } catch (e) {
      Logger.error('Error getting location', e);
      return null;
    }
  }

  // Get device model
  Future<String> _getDeviceModel() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model}';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return macInfo.model;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.computerName;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return linuxInfo.name;
      } else {
        final webInfo = await deviceInfo.webBrowserInfo;
        return '${webInfo.browserName} Browser';
      }
    } catch (e) {
      Logger.error('Error getting device model', e);
      return 'Unknown Device';
    }
  }

  // Get operating system
  Future<String> _getOperatingSystem() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'iOS ${iosInfo.systemVersion}';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'Android ${androidInfo.version.release}';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return 'macOS ${macInfo.osRelease}';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return 'Windows ${windowsInfo.displayVersion}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return 'Linux ${linuxInfo.version}';
      } else {
        final webInfo = await deviceInfo.webBrowserInfo;
        return 'Web Platform (${webInfo.platform})';
      }
    } catch (e) {
      Logger.error('Error getting OS info', e);
      return Platform.operatingSystem;
    }
  }

  // Load statuses from database
  Future<void> _loadStatuses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final statusData = await SupabaseService.instance.getStatuses();
      _statuses = statusData.map((data) => Status.fromJson(data)).toList();
      
      // Sort by timestamp (newest first)
      _statuses.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      _error = 'Failed to load statuses: $e';
      // Fallback to mock data
      _loadMockStatuses();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load mock statuses for demo
  void _loadMockStatuses() {
    final mockDeviceInfo = DeviceInfo(
      location: LocationInfo(
        latitude: 40.7128,
        longitude: -74.0060,
        city: 'New York',
        country: 'USA',
        accuracy: 15.0,
      ),
      battery: BatteryInfo(
        level: 85,
        isCharging: false,
        chargingStatus: 'discharging',
      ),
      connectivity: ConnectivityInfo(
        type: 'wifi',
        networkName: 'Demo Network',
        signalStrength: null,
        isConnected: true,
      ),
      deviceModel: 'Web Browser',
      operatingSystem: 'Web Platform',
      appVersion: AppConstants.appVersion,
    );

    _statuses = [
      Status(
        id: '1',
        userId: 'user1',
        content: 'Just landed in Tokyo! The city lights are incredible ✨🏙️',
        imageUrl: 'assets/images/ancient-walls.png',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        deviceInfo: mockDeviceInfo,
        likes: 234,
        comments: 45,
        shares: 12,
        isLiked: false,
      ),
      Status(
        id: '2',
        userId: 'user2',
        content: 'Safari adventure in Kenya was life-changing! 🦁🐘',
        imageUrl: 'assets/images/wildlife-encounter.png',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        deviceInfo: mockDeviceInfo,
        likes: 567,
        comments: 89,
        shares: 34,
        isLiked: true,
      ),
      Status(
        id: '3',
        userId: 'user3',
        content: 'Moroccan architecture is absolutely stunning! 🕌',
        imageUrl: 'assets/images/moroccan-luxury.png',
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        deviceInfo: mockDeviceInfo,
        likes: 123,
        comments: 23,
        shares: 8,
        isLiked: false,
      ),
    ];
  }

  // Create a new status
  Future<void> createStatus(String content, {String? imageUrl}) async {
    if (content.trim().isEmpty) {
      _error = 'Status content cannot be empty';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Refresh device info before creating status
      final deviceInfo = await _collectDeviceInfo();
      
      final statusData = {
        'user_id': 'current_user', // Replace with actual user ID
        'content': content,
        'image_url': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'device_info': deviceInfo.toJson(),
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'is_liked': false,
      };

      final result = await SupabaseService.instance.createStatus(statusData);
      final newStatus = Status.fromJson(result);
      
      // Add to local list
      _statuses.insert(0, newStatus);
      
    } catch (e) {
      _error = 'Failed to create status: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Like/unlike a status
  Future<void> toggleLike(String statusId) async {
    final statusIndex = _statuses.indexWhere((s) => s.id == statusId);
    if (statusIndex == -1) return;

    final status = _statuses[statusIndex];
    final newLikedState = !status.isLiked;
    final newLikesCount = newLikedState ? status.likes + 1 : status.likes - 1;

    // Optimistic update
    _statuses[statusIndex] = status.copyWith(
      isLiked: newLikedState,
      likes: newLikesCount,
    );
    notifyListeners();

    try {
      await SupabaseService.instance.toggleStatusLike(statusId, newLikedState);
    } catch (e) {
      // Revert on error
      _statuses[statusIndex] = status;
      _error = 'Failed to update like: $e';
      notifyListeners();
    }
  }

  // Refresh statuses
  Future<void> refreshStatuses() async {
    await _loadStatuses();
  }

  // Refresh device info
  Future<void> refreshDeviceInfo() async {
    await _initializeDeviceInfo();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get formatted device info string
  String getDeviceInfoSummary() {
    if (_currentDeviceInfo == null) return 'Device info not available';
    
    final info = _currentDeviceInfo!;
    final parts = <String>[];
    
    // Add location if available
    if (info.location != null) {
      parts.add('📍 ${info.location!.city}, ${info.location!.country}');
    }
    
    // Add battery if available
    if (info.battery != null) {
      final batteryIcon = info.battery!.isCharging ? '🔌' : '🔋';
      parts.add('$batteryIcon ${info.battery!.level}%');
    }
    
    // Add connectivity
    final connectIcon = info.connectivity.isConnected ? '📶' : '📵';
    parts.add('$connectIcon ${info.connectivity.type.toUpperCase()}');
    
    return parts.join(' • ');
  }
}