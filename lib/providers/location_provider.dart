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
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to load from cache first for fast initial load
      if (!forceRefresh && _locations.isEmpty) {
        _locations = await _databaseService.getCachedLocations();
        if (_locations.isNotEmpty) {
          _isLoading = false;
          notifyListeners();
          // Continue loading from API in background
          _loadFromApi();
          return;
        }
      }

      // Load from API
      await _loadFromApi();
    } catch (e) {
      debugPrint('Error loading locations: $e');
      _error = 'Failed to load locations';

      // Try to load from cache as fallback
      try {
        _locations = await _databaseService.getCachedLocations();
        if (_locations.isNotEmpty) {
          _error = 'Showing cached data (offline)';
        }
      } catch (cacheError) {
        debugPrint('Error loading cached locations: $cacheError');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load locations from API and cache them
  Future<void> _loadFromApi() async {
    try {
      final apiLocations = await _apiService.getLocations();
      _locations = apiLocations;

      // Cache for offline use
      await _databaseService.cacheLocations(apiLocations);

      _error = null;
      notifyListeners();
    } catch (e) {
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
