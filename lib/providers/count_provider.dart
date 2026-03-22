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
  Future<void> initializeForLocation(Location location) async {
    _currentLocation = location;
    _error = null;
    notifyListeners();

    await loadTypes();
  }

  /// Load user and vehicle types
  Future<void> loadTypes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to load from cache first
      _userTypes = await _databaseService.getCachedUserTypes();
      _vehicleTypes = await _databaseService.getCachedVehicleTypes();

      // If cache is empty, load from API
      if (_userTypes.isEmpty || _vehicleTypes.isEmpty) {
        await _loadTypesFromApi();
      } else {
        // Load from API in background to refresh cache
        _loadTypesFromApi().catchError((e) {
          debugPrint('Background types refresh failed: $e');
        });
      }
    } catch (e) {
      debugPrint('Error loading types: $e');
      _error = 'Failed to load counting types';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load types from API and cache them
  Future<void> _loadTypesFromApi() async {
    final userTypes = await _apiService.getUserTypes();
    final vehicleTypes = await _apiService.getVehicleTypes();

    _userTypes = userTypes;
    _vehicleTypes = vehicleTypes;

    await _databaseService.cacheUserTypes(userTypes);
    await _databaseService.cacheVehicleTypes(vehicleTypes);

    notifyListeners();
  }

  /// Create a count (stores locally, syncs immediately if online)
  Future<bool> createCount({
    required int userTypeId,
    required int vehicleTypeId,
    String? inputRoad,
    String? outputRoad,
  }) async {
    if (_currentLocation == null) {
      _error = 'No location selected';
      notifyListeners();
      return false;
    }

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
      final localId = await _databaseService.insertCount(count);
      final countWithId = count.copyWith(id: localId);

      // Try to sync immediately if online
      try {
        final serverId = await _apiService.createCount(countWithId);
        // Mark as synced if successful
        await _databaseService.markCountSynced(localId, serverId);
        _lastCount = countWithId.copyWith(id: serverId, synced: true);
      } catch (e) {
        // If sync fails, keep as unsynced for background sync
        debugPrint('Immediate sync failed, will retry later: $e');
        _lastCount = countWithId;
      }

      _error = null;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error creating count: $e');
      _error = 'Failed to save count';
      notifyListeners();
      return false;
    }
  }

  /// Undo last count
  Future<bool> undoLastCount() async {
    if (_lastCount == null || _lastCount!.id == null) {
      return false;
    }

    try {
      // If already synced, try to delete from server
      if (_lastCount!.synced && _lastCount!.id != null) {
        try {
          await _apiService.deleteCount(_lastCount!.id!);
        } catch (e) {
          debugPrint('Failed to delete count from server: $e');
          // Continue with local deletion anyway
        }
      }

      // Delete from local database
      await _databaseService.deleteCount(_lastCount!.id!);

      _lastCount = null;
      _error = null;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error undoing count: $e');
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
