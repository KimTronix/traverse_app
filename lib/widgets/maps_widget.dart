import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/maps_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class MapsWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final Set<Marker>? initialMarkers;
  final bool showCurrentLocation;
  final bool showPopularDestinations;
  final Function(LatLng)? onLocationSelected;
  final Function(Marker)? onMarkerTapped;
  final double height;

  const MapsWidget({
    super.key,
    this.initialLocation,
    this.initialMarkers,
    this.showCurrentLocation = true,
    this.showPopularDestinations = true,
    this.onLocationSelected,
    this.onMarkerTapped,
    this.height = 400,
  });

  @override
  State<MapsWidget> createState() => _MapsWidgetState();
}

class _MapsWidgetState extends State<MapsWidget> {
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(-1.2921, 36.8219); // Default to Nairobi
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Initialize maps service
      await MapsService.initialize();

      // Get current location if enabled
      if (widget.showCurrentLocation) {
        final currentLocation = await MapsService.getCurrentLocation();
        if (currentLocation != null) {
          _currentLocation = currentLocation;
        }
      }

      // Use initial location if provided
      if (widget.initialLocation != null) {
        _currentLocation = widget.initialLocation!;
      }

      // Add popular destinations if enabled
      if (widget.showPopularDestinations) {
        MapsService.addPopularDestinations();
      }

      // Add initial markers if provided
      if (widget.initialMarkers != null) {
        _markers.addAll(widget.initialMarkers!);
      }

      // Get markers from service
      _markers.addAll(MapsService.getMarkers());

      setState(() {
        _isLoading = false;
      });

      Logger.info('Maps widget initialized successfully');
    } catch (e) {
      Logger.error('Error initializing maps widget: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    MapsService.setMapController(controller);
    
    // Move to current location
    MapsService.moveCameraToLocation(_currentLocation);
  }

  void _onMapTapped(LatLng location) {
    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(location);
    }

    // Add a temporary marker at tapped location
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'selected_location');
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          infoWindow: const InfoWindow(
            title: 'Selected Location',
            snippet: 'Tap to get details',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  void _onMarkerTapped(MarkerId markerId) {
    final marker = _markers.firstWhere(
      (m) => m.markerId == markerId,
      orElse: () => _markers.first,
    );
    
    if (widget.onMarkerTapped != null) {
      widget.onMarkerTapped!(marker);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppConstants.mdSpacing),
              Text(
                'Loading map...',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _currentLocation,
            zoom: 12.0,
          ),
          markers: _markers,
          polylines: MapsService.getPolylines(),
          onTap: _onMapTapped,
          onCameraMove: (CameraPosition position) {
            // Update current location as user moves the map
            _currentLocation = position.target;
          },
          myLocationEnabled: widget.showCurrentLocation,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          compassEnabled: true,
          mapType: MapType.normal,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// Search widget for places
class PlaceSearchWidget extends StatefulWidget {
  final Function(Map<String, dynamic>)? onPlaceSelected;
  final String hintText;

  const PlaceSearchWidget({
    super.key,
    this.onPlaceSelected,
    this.hintText = 'Search for places...',
  });

  @override
  State<PlaceSearchWidget> createState() => _PlaceSearchWidgetState();
}

class _PlaceSearchWidgetState extends State<PlaceSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await MapsService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      Logger.error('Error searching places: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search input
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults.clear();
                          });
                        },
                      )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.mdRadius),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) {
            // Debounce search
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_searchController.text == value) {
                _searchPlaces(value);
              }
            });
          },
        ),

        // Search results
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: AppConstants.smSpacing),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.mdRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                return ListTile(
                  leading: const Icon(
                    Icons.place,
                    color: AppTheme.primaryBlue,
                  ),
                  title: Text(
                    place['name'] ?? 'Unknown Place',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    place['address'] ?? '',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    if (widget.onPlaceSelected != null) {
                      widget.onPlaceSelected!(place);
                    }
                    _searchController.clear();
                    setState(() {
                      _searchResults.clear();
                    });
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
