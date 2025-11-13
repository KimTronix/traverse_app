import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

class MapsService {
  static const LatLng _defaultLocation = LatLng(-1.2921, 36.8219); // Nairobi, Kenya
  static GoogleMapController? _mapController;
  static Set<Marker> _markers = {};
  static Set<Polyline> _polylines = {};

  // Initialize maps service
  static Future<void> initialize() async {
    Logger.info('Initializing Maps Service');
    await _requestLocationPermission();
  }

  // Request location permission
  static Future<bool> _requestLocationPermission() async {
    try {
      final permission = await Permission.location.request();
      if (permission.isGranted) {
        Logger.info('Location permission granted');
        return true;
      } else {
        Logger.warning('Location permission denied');
        return false;
      }
    } catch (e) {
      Logger.error('Error requesting location permission: $e');
      return false;
    }
  }

  // Get current user location
  static Future<LatLng?> getCurrentLocation() async {
    try {
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      Logger.info('Current location: ${position.latitude}, ${position.longitude}');
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      Logger.error('Error getting current location: $e');
      return null;
    }
  }

  // Get default location (fallback)
  static LatLng getDefaultLocation() {
    return _defaultLocation;
  }

  // Set map controller
  static void setMapController(GoogleMapController controller) {
    _mapController = controller;
    Logger.info('Map controller set');
  }

  // Move camera to location
  static Future<void> moveCameraToLocation(LatLng location, {double zoom = 14.0}) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: location,
            zoom: zoom,
          ),
        ),
      );
    }
  }

  // Add marker to map
  static void addMarker({
    required String markerId,
    required LatLng position,
    required String title,
    String? description,
    BitmapDescriptor? icon,
    VoidCallback? onTap,
  }) {
    final marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: description,
      ),
      icon: icon ?? BitmapDescriptor.defaultMarker,
      onTap: onTap,
    );

    _markers.add(marker);
    Logger.info('Marker added: $title at ${position.latitude}, ${position.longitude}');
  }

  // Remove marker
  static void removeMarker(String markerId) {
    _markers.removeWhere((marker) => marker.markerId.value == markerId);
    Logger.info('Marker removed: $markerId');
  }

  // Clear all markers
  static void clearMarkers() {
    _markers.clear();
    Logger.info('All markers cleared');
  }

  // Get all markers
  static Set<Marker> getMarkers() {
    return _markers;
  }

  // Add popular destinations as markers
  static void addPopularDestinations() {
    final destinations = [
      {
        'id': 'nairobi',
        'name': 'Nairobi',
        'position': const LatLng(-1.2921, 36.8219),
        'description': 'Capital city of Kenya',
      },
      {
        'id': 'mombasa',
        'name': 'Mombasa',
        'position': const LatLng(-4.0435, 39.6682),
        'description': 'Coastal city with beautiful beaches',
      },
      {
        'id': 'masai_mara',
        'name': 'Masai Mara',
        'position': const LatLng(-1.4061, 35.0061),
        'description': 'World-famous wildlife reserve',
      },
      {
        'id': 'mount_kenya',
        'name': 'Mount Kenya',
        'position': const LatLng(-0.1521, 37.3084),
        'description': 'Second highest mountain in Africa',
      },
      {
        'id': 'lake_nakuru',
        'name': 'Lake Nakuru',
        'position': const LatLng(-0.3031, 36.0800),
        'description': 'Famous for flamingos and wildlife',
      },
      {
        'id': 'diani_beach',
        'name': 'Diani Beach',
        'position': const LatLng(-4.3297, 39.5771),
        'description': 'Pristine white sand beach',
      },
    ];

    for (final destination in destinations) {
      addMarker(
        markerId: destination['id'] as String,
        position: destination['position'] as LatLng,
        title: destination['name'] as String,
        description: destination['description'] as String,
      );
    }

    Logger.info('Popular destinations added to map');
  }

  // Search for places
  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    try {
      final locations = await locationFromAddress(query);
      final results = <Map<String, dynamic>>[];

      for (final location in locations) {
        final placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          results.add({
            'name': placemark.name ?? query,
            'address': '${placemark.locality}, ${placemark.country}',
            'position': LatLng(location.latitude, location.longitude),
            'latitude': location.latitude,
            'longitude': location.longitude,
          });
        }
      }

      Logger.info('Found ${results.length} places for query: $query');
      return results;
    } catch (e) {
      Logger.error('Error searching places: $e');
      return [];
    }
  }

  // Get address from coordinates
  static Future<String?> getAddressFromCoordinates(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = '${placemark.name}, ${placemark.locality}, ${placemark.country}';
        Logger.info('Address found: $address');
        return address;
      }
    } catch (e) {
      Logger.error('Error getting address from coordinates: $e');
    }
    return null;
  }

  // Calculate distance between two points
  static double calculateDistance(LatLng start, LatLng end) {
    final distance = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    return distance / 1000; // Convert to kilometers
  }

  // Add route polyline
  static void addRoute({
    required String routeId,
    required List<LatLng> points,
    required Color color,
    double width = 5.0,
  }) {
    final polyline = Polyline(
      polylineId: PolylineId(routeId),
      points: points,
      color: color,
      width: width.toInt(),
    );

    _polylines.add(polyline);
    Logger.info('Route added: $routeId with ${points.length} points');
  }

  // Clear routes
  static void clearRoutes() {
    _polylines.clear();
    Logger.info('All routes cleared');
  }

  // Get polylines
  static Set<Polyline> getPolylines() {
    return _polylines;
  }

  // Get nearby places (mock implementation)
  static Future<List<Map<String, dynamic>>> getNearbyPlaces(
    LatLng location, {
    String type = 'tourist_attraction',
    int radius = 5000,
  }) async {
    // This would typically use Google Places API
    // For now, return mock data based on location
    final nearbyPlaces = <Map<String, dynamic>>[];

    // Mock nearby attractions
    if (type == 'tourist_attraction') {
      nearbyPlaces.addAll([
        {
          'name': 'Local Museum',
          'type': 'Museum',
          'rating': 4.2,
          'distance': 1.2,
          'position': LatLng(
            location.latitude + 0.01,
            location.longitude + 0.01,
          ),
        },
        {
          'name': 'City Park',
          'type': 'Park',
          'rating': 4.5,
          'distance': 0.8,
          'position': LatLng(
            location.latitude - 0.005,
            location.longitude + 0.008,
          ),
        },
        {
          'name': 'Historic Site',
          'type': 'Historical',
          'rating': 4.0,
          'distance': 2.1,
          'position': LatLng(
            location.latitude + 0.015,
            location.longitude - 0.01,
          ),
        },
      ]);
    }

    Logger.info('Found ${nearbyPlaces.length} nearby places of type: $type');
    return nearbyPlaces;
  }

  // Dispose resources
  static void dispose() {
    _mapController?.dispose();
    _mapController = null;
    _markers.clear();
    _polylines.clear();
    Logger.info('Maps service disposed');
  }
}
