import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/utils.dart';
import 'counting_screen.dart';

/// Get platform-specific Google Maps Map ID
String _getMapId() {
  if (kIsWeb) {
    return '9798ce98ce76aa462e8bb7ed'; // JavaScript Map ID
  } else if (Platform.isAndroid) {
    return '9798ce98ce76aa46a809f431'; // Android Map ID
  } else if (Platform.isIOS) {
    return '9798ce98ce76aa46b76093cd'; // iOS Map ID
  }
  return '';
}

/// Main screen with Google Maps showing counting locations as markers
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};

  // For manual location selection
  int? _selectedAssociationId;
  Location? _selectedLocation;

  // Association data from API
  Map<int, String> _associationNames = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadAssociations();
  }

  /// Load associations from API
  Future<void> _loadAssociations() async {
    try {
      final apiService = context.read<ApiService>();
      final associations = await apiService.getAssociations();

      setState(() {
        _associationNames = {
          for (var assoc in associations) assoc.id: assoc.name,
        };
      });

      debugPrint('MapScreen: Loaded ${associations.length} associations');
    } catch (e) {
      debugPrint('MapScreen: Error loading associations: $e');
    }
  }

  /// Get current user location
  Future<void> _getCurrentLocation() async {
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Move camera to user location
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  /// Handle location permissions
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission permanently denied')),
      );
      return false;
    }

    return true;
  }

  /// Build markers from locations
  void _buildMarkers(List<Location> locations) {
    _markers.clear();

    for (final location in locations) {
      _markers.add(
        Marker(
          markerId: MarkerId(location.id.toString()),
          position: LatLng(location.lat, location.lng),
          infoWindow: InfoWindow(
            title: location.title,
            snippet: location.description.isNotEmpty
                ? location.description
                : 'Tap to start counting',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          onTap: () => _onMarkerTap(location),
        ),
      );
    }
  }

  /// Handle marker tap to navigate to counting screen
  void _onMarkerTap(Location location) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CountingScreen(location: location)),
    );
  }

  /// Clear cached data with confirmation
  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will delete all cached locations, user types, and vehicle types. '
          'Counts will remain in the database. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final databaseService = context.read<DatabaseService>();

        // Clear cached data
        await databaseService.cacheLocations([]);
        await databaseService.cacheUserTypes([]);
        await databaseService.cacheVehicleTypes([]);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cache cleared successfully')),
          );

          // Reload data
          final locationProvider = context.read<LocationProvider>();
          await locationProvider.loadLocations();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error clearing cache: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<LocationProvider, NetworkProvider, SyncProvider>(
      builder: (context, locationProvider, networkProvider, syncProvider, _) {
        // Update markers when locations change
        _buildMarkers(locationProvider.locations);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ciclable - Counting Locations'),
            actions: [
              // Network status indicator
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Row(
                    children: [
                      Icon(
                        networkProvider.isOnline
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        color: networkProvider.isOnline
                            ? AppTheme.onlineColor
                            : AppTheme.offlineColor,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      if (syncProvider.pendingSyncCount > 0)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${syncProvider.pendingSyncCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Sync button
              IconButton(
                icon: syncProvider.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.sync),
                onPressed: syncProvider.isSyncing
                    ? null
                    : () => syncProvider.syncNow(),
                tooltip: 'Sync counts',
              ),
              // Refresh locations
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => locationProvider.refresh(),
                tooltip: 'Refresh locations',
              ),
              // Clear cache
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: _clearCache,
                tooltip: 'Clear cache',
              ),
            ],
          ),
          body: locationProvider.isLoading && locationProvider.locations.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : locationProvider.locations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text('No locations available'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => locationProvider.loadLocations(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Google Map
                    Expanded(
                      child: GoogleMap(
                        cloudMapId: _getMapId(),
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition != null
                              ? LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                )
                              : LatLng(
                                  locationProvider.locations.first.lat,
                                  locationProvider.locations.first.lng,
                                ),
                          zoom: AppConstants.defaultMapZoom,
                        ),
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                      ),
                    ),
                    // Manual location selector
                    _buildLocationSelector(locationProvider),
                  ],
                ),
          // Sync status bar at bottom
          bottomNavigationBar:
              syncProvider.pendingSyncCount > 0 ||
                  syncProvider.lastSyncMessage != null
              ? Container(
                  color: AppTheme.surfaceColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        syncProvider.isSyncing
                            ? Icons.sync
                            : syncProvider.pendingSyncCount > 0
                            ? Icons.cloud_upload
                            : Icons.check_circle,
                        size: 16,
                        color: syncProvider.isSyncing
                            ? AppTheme.syncingColor
                            : syncProvider.pendingSyncCount > 0
                            ? AppTheme.warningColor
                            : AppTheme.onlineColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          syncProvider.getSyncStatusText(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  /// Build manual location selector widget
  Widget _buildLocationSelector(LocationProvider locationProvider) {
    // Get unique associations from locations
    final associations = _getUniqueAssociations(locationProvider.locations);

    // Get locations for selected association
    final filteredLocations = _selectedAssociationId != null
        ? locationProvider.getLocationsByAssociation(_selectedAssociationId!)
        : <Location>[];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select a location',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),

          // Association dropdown
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Association',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            initialValue: _selectedAssociationId,
            items: associations.map((assoc) {
              return DropdownMenuItem<int>(
                value: assoc['id'],
                child: Text(assoc['name']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedAssociationId = value;
                _selectedLocation =
                    null; // Reset location when association changes
              });
            },
          ),

          const SizedBox(height: 12),

          // Location dropdown
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            initialValue: _selectedLocation?.id,
            items: filteredLocations.map((location) {
              return DropdownMenuItem<int>(
                value: location.id,
                child: Text(location.title),
              );
            }).toList(),
            onChanged: _selectedAssociationId == null
                ? null
                : (value) {
                    final location = filteredLocations.firstWhere(
                      (loc) => loc.id == value,
                    );
                    setState(() {
                      _selectedLocation = location;
                    });
                  },
          ),

          const SizedBox(height: 12),

          // Go button
          ElevatedButton.icon(
            onPressed: _selectedLocation == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CountingScreen(location: _selectedLocation!),
                      ),
                    );
                  },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Start Counting'),
          ),
        ],
      ),
    );
  }

  /// Get unique associations from locations list
  List<Map<String, dynamic>> _getUniqueAssociations(List<Location> locations) {
    final associationMap = <int, String>{};

    for (final location in locations) {
      if (!associationMap.containsKey(location.associationId)) {
        // Use real association name from API if available, otherwise fallback to ID
        associationMap[location.associationId] =
            _associationNames[location.associationId] ??
            'Association ${location.associationId}';
      }
    }

    final associations =
        associationMap.entries
            .map((entry) => {'id': entry.key, 'name': entry.value})
            .toList()
          ..sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String),
          );

    // Debug log: list all association names
    debugPrint('=== Associations (${associations.length}) ===');
    for (final assoc in associations) {
      debugPrint('  - ${assoc['name']} (ID: ${assoc['id']})');
    }

    return associations;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
