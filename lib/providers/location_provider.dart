import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/services.dart';

/// Provider for managing locations
/// Handles fetching, caching, and accessing counting locations
class LocationProvider with ChangeNotifier {
  final ApiService _apiService;
  final DatabaseService _databaseService;

  List<Location> _locations = [];
  bool _isLoading = false;
  String? _error;
  Location? _selectedLocation;

  LocationProvider({
    required ApiService apiService,
    required DatabaseService databaseService,
  }) : _apiService = apiService,
       _databaseService = databaseService;

  /// Get all locations
  List<Location> get locations => _locations;

  /// Get loading state
  bool get isLoading => _isLoading;

  /// Get error message
  String? get error => _error;

  /// Get currently selected location
  Location? get selectedLocation => _selectedLocation;

  /// Load locations (tries API first, falls back to cache)
  Future<void> loadLocations({bool forceRefresh = false}) async {
    if (_isLoading) {
      debugPrint('LocationProvider: Already loading, skipping...');
      return;
    }

    debugPrint(
      'LocationProvider: Loading locations (forceRefresh: $forceRefresh)',
    );
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to load from cache first for fast initial load
      if (!forceRefresh && _locations.isEmpty) {
        debugPrint('LocationProvider: Attempting to load from cache...');
        _locations = await _databaseService.getCachedLocations();
        if (_locations.isNotEmpty) {
          debugPrint(
            'LocationProvider: Loaded ${_locations.length} locations from cache',
          );
          _isLoading = false;
          notifyListeners();
          // Continue loading from API in background
          debugPrint('LocationProvider: Starting background API refresh...');
          _loadFromApi();
          return;
        }
        debugPrint('LocationProvider: Cache is empty, loading from API...');
      }

      // Load from API
      await _loadFromApi();
    } catch (e) {
      debugPrint('LocationProvider: Error loading locations: $e');
      _error = 'Failed to load locations';

      // Try to load from cache as fallback
      try {
        debugPrint('LocationProvider: Attempting fallback to cache...');
        _locations = await _databaseService.getCachedLocations();
        if (_locations.isNotEmpty) {
          debugPrint(
            'LocationProvider: Loaded ${_locations.length} locations from cache as fallback',
          );
          _error = 'Showing cached data (offline)';
        } else {
          debugPrint('LocationProvider: Cache is also empty');
        }
      } catch (cacheError) {
        debugPrint(
          'LocationProvider: Error loading cached locations: $cacheError',
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint(
        'LocationProvider: Load complete (${_locations.length} locations)',
      );
    }
  }

  /// Load locations from API and cache them
  Future<void> _loadFromApi() async {
    try {
      debugPrint('LocationProvider: Fetching locations from API...');
      final apiLocations = await _apiService.getLocations();
      _locations = apiLocations;
      debugPrint(
        'LocationProvider: API returned ${apiLocations.length} locations',
      );

      // Cache for offline use
      debugPrint('LocationProvider: Caching locations...');
      await _databaseService.cacheLocations(apiLocations);
      debugPrint('LocationProvider: Locations cached successfully');

      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('LocationProvider: API fetch failed: $e');
      // Let the caller handle the error
      rethrow;
    }
  }

  /// Select a location for counting
  void selectLocation(Location location) {
    _selectedLocation = location;
    notifyListeners();
  }

  /// Clear selected location
  void clearSelection() {
    _selectedLocation = null;
    notifyListeners();
  }

  /// Get a location by ID
  Location? getLocationById(int id) {
    try {
      return _locations.firstWhere((loc) => loc.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get locations by association ID
  List<Location> getLocationsByAssociation(int associationId) {
    return _locations
        .where((loc) => loc.associationId == associationId)
        .toList();
  }

  /// Refresh locations from API
  Future<void> refresh() async {
    await loadLocations(forceRefresh: true);
  }
}
