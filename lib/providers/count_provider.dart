import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/services.dart';

/// Provider for managing the current counting session
/// Handles count creation, undo, and local/remote synchronization
class CountProvider with ChangeNotifier {
  final DatabaseService _databaseService;
  final ApiService _apiService;

  List<UserType> _userTypes = [];
  List<VehicleType> _vehicleTypes = [];
  Location? _currentLocation;
  Count? _lastCount;
  bool _isLoading = false;
  String? _error;

  CountProvider({
    required DatabaseService databaseService,
    required ApiService apiService,
  }) : _databaseService = databaseService,
       _apiService = apiService;

  /// Get user types
  List<UserType> get userTypes => _userTypes;

  /// Get vehicle types
  List<VehicleType> get vehicleTypes => _vehicleTypes;

  /// Get current location
  Location? get currentLocation => _currentLocation;

  /// Get last count (for undo)
  Count? get lastCount => _lastCount;

  /// Get loading state
  bool get isLoading => _isLoading;

  /// Get error message
  String? get error => _error;

  /// Initialize counting for a specific location
  /// Loads location-specific vehicle and user types
  Future<void> initializeForLocation(Location location) async {
    _currentLocation = location;
    _error = null;
    notifyListeners();

    await loadTypesForLocation(location.id);
  }

  /// Load user and vehicle types for a specific location
  /// Uses the new /api/locations/{counter_id} endpoint
  Future<void> loadTypesForLocation(int locationId) async {
    debugPrint('CountProvider: Loading types for location $locationId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch location data including enabled types
      debugPrint('CountProvider: Fetching location data from API...');
      final locationData = await _apiService.getLocationData(locationId);

      // Extract types for this location from locationTypes map
      final locationTypes =
          locationData['locationTypes'] as Map<String, dynamic>?;
      final typesForLocation =
          locationTypes?[locationId.toString()] as Map<String, dynamic>?;

      if (typesForLocation != null) {
        debugPrint('CountProvider: Found types for location in response');
        // Parse vehicle types
        final vehicleTypesJson = typesForLocation['vehicleTypes'] as List?;
        if (vehicleTypesJson != null) {
          _vehicleTypes = vehicleTypesJson
              .map((json) => VehicleType.fromJson(json as Map<String, dynamic>))
              .toList();
          debugPrint(
            'CountProvider: Loaded ${_vehicleTypes.length} vehicle types',
          );
        }

        // Parse user types
        final userTypesJson = typesForLocation['userTypes'] as List?;
        if (userTypesJson != null) {
          _userTypes = userTypesJson
              .map((json) => UserType.fromJson(json as Map<String, dynamic>))
              .toList();
          debugPrint('CountProvider: Loaded ${_userTypes.length} user types');
        }

        // Cache the types for offline use
        if (_vehicleTypes.isNotEmpty) {
          debugPrint(
            'CountProvider: Caching ${_vehicleTypes.length} vehicle types',
          );
          await _databaseService.cacheVehicleTypes(_vehicleTypes);
        }
        if (_userTypes.isNotEmpty) {
          debugPrint('CountProvider: Caching ${_userTypes.length} user types');
          await _databaseService.cacheUserTypes(_userTypes);
        }
      } else {
        // Fallback to cached types if location types not found
        debugPrint(
          'CountProvider: Location types not found in response, using cache',
        );
        _userTypes = await _databaseService.getCachedUserTypes();
        _vehicleTypes = await _databaseService.getCachedVehicleTypes();
        debugPrint(
          'CountProvider: Loaded ${_userTypes.length} user types and ${_vehicleTypes.length} vehicle types from cache',
        );
      }

      if (_userTypes.isEmpty || _vehicleTypes.isEmpty) {
        debugPrint('CountProvider: WARNING - No types available!');
        _error = 'No counting types available for this location';
      }
    } catch (e) {
      debugPrint('CountProvider: Error loading types for location: $e');
      _error = 'Failed to load counting types';

      // Try to load from cache as fallback
      try {
        debugPrint('CountProvider: Attempting to load types from cache...');
        _userTypes = await _databaseService.getCachedUserTypes();
        _vehicleTypes = await _databaseService.getCachedVehicleTypes();
        debugPrint(
          'CountProvider: Loaded ${_userTypes.length} user types and ${_vehicleTypes.length} vehicle types from cache',
        );

        if (_userTypes.isNotEmpty && _vehicleTypes.isNotEmpty) {
          _error = null; // Clear error if cache worked
        }
      } catch (cacheError) {
        debugPrint('CountProvider: Cache fallback also failed: $cacheError');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('CountProvider: Type loading complete');
    }
  }

  /// Create a count (stores locally, syncs immediately if online)
  Future<bool> createCount({
    required int userTypeId,
    required int vehicleTypeId,
    String? inputRoad,
    String? outputRoad,
  }) async {
    if (_currentLocation == null) {
      debugPrint('CountProvider: Cannot create count - no location selected');
      _error = 'No location selected';
      notifyListeners();
      return false;
    }

    debugPrint(
      'CountProvider: Creating count (location=${_currentLocation!.id}, user=$userTypeId, vehicle=$vehicleTypeId, input=$inputRoad, output=$outputRoad)',
    );
    try {
      final count = Count(
        dt: DateTime.now(),
        counterId: _currentLocation!.id,
        userTypeId: userTypeId,
        vehicleTypeId: vehicleTypeId,
        inputRoad: inputRoad,
        outputRoad: outputRoad,
        synced: false,
      );

      // Store locally first (for reliability)
      debugPrint('CountProvider: Storing count locally...');
      final localId = await _databaseService.insertCount(count);
      final countWithId = count.copyWith(id: localId);
      debugPrint('CountProvider: Count stored locally with ID: $localId');

      // Try to sync immediately if online
      try {
        debugPrint('CountProvider: Attempting immediate sync to server...');
        final serverId = await _apiService.createCount(countWithId);
        debugPrint('CountProvider: Count synced to server with ID: $serverId');
        // Mark as synced if successful
        await _databaseService.markCountSynced(localId, serverId);
        _lastCount = countWithId.copyWith(id: serverId, synced: true);
        debugPrint('CountProvider: Count marked as synced');
      } catch (e) {
        // If sync fails, keep as unsynced for background sync
        debugPrint(
          'CountProvider: Immediate sync failed, will retry later: $e',
        );
        _lastCount = countWithId;
      }

      _error = null;
      notifyListeners();

      debugPrint('CountProvider: Count creation completed successfully');
      return true;
    } catch (e) {
      debugPrint('CountProvider: Error creating count: $e');
      _error = 'Failed to save count';
      notifyListeners();
      return false;
    }
  }

  /// Undo last count
  Future<bool> undoLastCount() async {
    if (_lastCount == null || _lastCount!.id == null) {
      debugPrint('CountProvider: Cannot undo - no last count available');
      return false;
    }

    debugPrint(
      'CountProvider: Undoing last count (ID: ${_lastCount!.id}, synced: ${_lastCount!.synced})',
    );
    try {
      // If already synced, try to delete from server
      if (_lastCount!.synced && _lastCount!.id != null) {
        try {
          debugPrint('CountProvider: Deleting count from server...');
          await _apiService.deleteCount(_lastCount!.id!);
          debugPrint('CountProvider: Count deleted from server');
        } catch (e) {
          debugPrint('CountProvider: Failed to delete count from server: $e');
          // Continue with local deletion anyway
        }
      }

      // Delete from local database
      debugPrint('CountProvider: Deleting count from local database...');
      await _databaseService.deleteCount(_lastCount!.id!);
      debugPrint('CountProvider: Count deleted from local database');

      _lastCount = null;
      _error = null;
      notifyListeners();

      debugPrint('CountProvider: Undo completed successfully');
      return true;
    } catch (e) {
      debugPrint('CountProvider: Error undoing count: $e');
      _error = 'Failed to undo count';
      notifyListeners();
      return false;
    }
  }

  /// Clear last count (e.g., after undo timeout)
  void clearLastCount() {
    _lastCount = null;
    notifyListeners();
  }

  /// Get counts for current location
  Future<List<Count>> getCurrentLocationCounts() async {
    if (_currentLocation == null) return [];

    try {
      return await _databaseService.getCountsByLocation(_currentLocation!.id);
    } catch (e) {
      debugPrint('Error loading counts: $e');
      return [];
    }
  }

  /// Clear current counting session
  void clearSession({bool notify = true}) {
    _currentLocation = null;
    _lastCount = null;
    _error = null;
    if (notify) {
      notifyListeners();
    }
  }
}
