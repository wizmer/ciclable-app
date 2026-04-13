import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';

/// Service for handling local Hive database operations (cross-platform)
/// Stores counts offline for later synchronization
/// Works on mobile, web, and desktop platforms
class DatabaseService {
  static bool _initialized = false;

  // Box names
  static const String _countsBox = 'counts';
  static const String _locationsBox = 'locations';
  static const String _userTypesBox = 'user_types';
  static const String _vehicleTypesBox = 'vehicle_types';

  /// Initialize Hive database (call once at app startup)
  Future<void> get database async {
    if (_initialized) return;

    debugPrint('DatabaseService: Initializing Hive...');
    await Hive.initFlutter();

    // Open all boxes
    await Future.wait([
      Hive.openBox<Map>(_countsBox),
      Hive.openBox<Map>(_locationsBox),
      Hive.openBox<Map>(_userTypesBox),
      Hive.openBox<Map>(_vehicleTypesBox),
    ]);

    _initialized = true;
    debugPrint('DatabaseService: Hive initialized successfully');
  }

  // ============================================================
  // COUNTS
  // ============================================================

  /// Insert a new count
  Future<int> insertCount(Count count) async {
    final box = Hive.box<Map>(_countsBox);

    // Generate auto-increment ID
    final id =
        count.id ??
        (box.isEmpty
            ? 1
            : box.keys.cast<int>().reduce((a, b) => a > b ? a : b) + 1);

    final countWithId = Count.fromJson({...count.toJson(), 'id': id});

    await box.put(id, _countToMap(countWithId));
    debugPrint('DatabaseService: Inserted count with ID: $id');
    return id;
  }

  /// Get all unsynced counts
  Future<List<Count>> getUnsyncedCounts() async {
    final box = Hive.box<Map>(_countsBox);

    final unsyncedCounts = <Count>[];
    for (var key in box.keys) {
      final map = box.get(key) as Map;
      if (map['synced'] == false || map['synced'] == 0) {
        unsyncedCounts.add(_countFromMap(Map<String, dynamic>.from(map)));
      }
    }

    // Sort by datetime
    unsyncedCounts.sort((a, b) => a.dt.compareTo(b.dt));
    debugPrint(
      'DatabaseService: Found ${unsyncedCounts.length} unsynced counts',
    );
    return unsyncedCounts;
  }

  /// Mark a count as synced
  Future<void> markCountSynced(int localId, int? serverId) async {
    final box = Hive.box<Map>(_countsBox);

    if (box.containsKey(localId)) {
      final map = Map<String, dynamic>.from(box.get(localId) as Map);
      map['synced'] = true;
      if (serverId != null) {
        map['server_id'] = serverId; // Store server ID separately
      }
      await box.put(localId, map);
      debugPrint(
        'DatabaseService: Marked count $localId as synced (server ID: $serverId)',
      );
    }
  }

  /// Delete a count by local ID
  Future<void> deleteCount(int localId) async {
    final box = Hive.box<Map>(_countsBox);
    await box.delete(localId);
    debugPrint('DatabaseService: Deleted count with ID: $localId');
  }

  /// Get counts for a specific location
  Future<List<Count>> getCountsByLocation(int counterId) async {
    final box = Hive.box<Map>(_countsBox);

    final counts = <Count>[];
    for (var key in box.keys) {
      final map = Map<String, dynamic>.from(box.get(key) as Map);
      if (map['counter_id'] == counterId) {
        counts.add(_countFromMap(map));
      }
    }

    // Sort by datetime descending
    counts.sort((a, b) => b.dt.compareTo(a.dt));
    return counts;
  }

  /// Get the most recent count (for undo functionality)
  Future<Count?> getLastCount() async {
    final box = Hive.box<Map>(_countsBox);

    if (box.isEmpty) return null;

    // Get the highest ID (most recent)
    final lastKey = box.keys.cast<int>().reduce((a, b) => a > b ? a : b);
    final map = Map<String, dynamic>.from(box.get(lastKey) as Map);
    return _countFromMap(map);
  }

  // ============================================================
  // LOCATIONS (Cache)
  // ============================================================

  /// Cache locations from API
  Future<void> cacheLocations(List<Location> locations) async {
    final box = Hive.box<Map>(_locationsBox);

    // Clear existing cache
    await box.clear();

    // Insert new data
    for (final location in locations) {
      await box.put(location.id, _locationToMap(location));
    }
    debugPrint('DatabaseService: Cached ${locations.length} locations');
  }

  /// Get all cached locations
  Future<List<Location>> getCachedLocations() async {
    final box = Hive.box<Map>(_locationsBox);

    final locations = box.values
        .map((map) => _locationFromMap(Map<String, dynamic>.from(map)))
        .toList();

    debugPrint(
      'DatabaseService: Retrieved ${locations.length} cached locations',
    );
    return locations;
  }

  // ============================================================
  // USER TYPES (Cache)
  // ============================================================

  /// Cache user types from API
  Future<void> cacheUserTypes(List<UserType> userTypes) async {
    final box = Hive.box<Map>(_userTypesBox);

    await box.clear();
    for (final userType in userTypes) {
      await box.put(userType.id, _userTypeToMap(userType));
    }
    debugPrint('DatabaseService: Cached ${userTypes.length} user types');
  }

  /// Get all cached user types
  Future<List<UserType>> getCachedUserTypes() async {
    final box = Hive.box<Map>(_userTypesBox);

    final userTypes = box.values
        .map((map) => _userTypeFromMap(Map<String, dynamic>.from(map)))
        .toList();

    // Sort by is_default DESC, sort_order ASC, name ASC
    userTypes.sort((a, b) {
      if (a.isDefault != b.isDefault) return b.isDefault ? 1 : -1;
      if (a.sortOrder != b.sortOrder) return a.sortOrder.compareTo(b.sortOrder);
      return a.name.compareTo(b.name);
    });

    return userTypes;
  }

  // ============================================================
  // VEHICLE TYPES (Cache)
  // ============================================================

  /// Cache vehicle types from API
  Future<void> cacheVehicleTypes(List<VehicleType> vehicleTypes) async {
    final box = Hive.box<Map>(_vehicleTypesBox);

    await box.clear();
    for (final vehicleType in vehicleTypes) {
      await box.put(vehicleType.id, _vehicleTypeToMap(vehicleType));
    }
    debugPrint('DatabaseService: Cached ${vehicleTypes.length} vehicle types');
  }

  /// Get all cached vehicle types
  Future<List<VehicleType>> getCachedVehicleTypes() async {
    final box = Hive.box<Map>(_vehicleTypesBox);

    final vehicleTypes = box.values
        .map((map) => _vehicleTypeFromMap(Map<String, dynamic>.from(map)))
        .toList();

    // Sort by is_default DESC, sort_order ASC, name ASC
    vehicleTypes.sort((a, b) {
      if (a.isDefault != b.isDefault) return b.isDefault ? 1 : -1;
      if (a.sortOrder != b.sortOrder) return a.sortOrder.compareTo(b.sortOrder);
      return a.name.compareTo(b.name);
    });

    return vehicleTypes;
  }

  // ============================================================
  // HELPER METHODS - Mapping
  // ============================================================

  Map<String, dynamic> _countToMap(Count count) {
    return {
      if (count.id != null) 'id': count.id,
      'dt': count.dt.toIso8601String(),
      'counter_id': count.counterId,
      'user_type_id': count.userTypeId,
      'vehicle_type_id': count.vehicleTypeId,
      'input_road': count.inputRoad,
      'output_road': count.outputRoad,
      'synced': count.synced,
    };
  }

  Count _countFromMap(Map<String, dynamic> map) {
    return Count.fromJson({
      'id': map['id'] as int,
      'dt': map['dt'] as String,
      'counter_id': map['counter_id'] as int,
      'user_type_id': map['user_type_id'] as int,
      'vehicle_type_id': map['vehicle_type_id'] as int,
      'input_road': map['input_road'] as String?,
      'output_road': map['output_road'] as String?,
      'synced': map['synced'] == true || map['synced'] == 1,
    });
  }

  Map<String, dynamic> _locationToMap(Location location) {
    return {
      'id': location.id,
      'lng': location.lng,
      'lat': location.lat,
      'title': location.title,
      'association_id': location.associationId,
      'description': location.description,
      'nom': location.nom,
      'comptage_directionnel': location.comptageDirectionnel,
      'routes': jsonEncode(location.routes),
      'history': jsonEncode(location.history),
      'parent_id': location.parentId,
      'ui_option': location.uiOption,
    };
  }

  Location _locationFromMap(Map<String, dynamic> map) {
    return Location.fromJson({
      'id': map['id'] as int,
      'lng': map['lng'] as double,
      'lat': map['lat'] as double,
      'title': map['title'] as String,
      'association_id': map['association_id'] as int,
      'description': map['description'] as String?,
      'nom': map['nom'] as String?,
      'comptage_directionnel':
          map['comptage_directionnel'] == true ||
          map['comptage_directionnel'] == 1,
      'routes': map['routes'] as String,
      'history': map['history'] as String,
      'parent_id': map['parent_id'] as int?,
      'ui_option': map['ui_option'] as String,
    });
  }

  Map<String, dynamic> _userTypeToMap(UserType userType) {
    return {
      'id': userType.id,
      'name': userType.name,
      'icon_class': userType.iconClass,
      'is_default': userType.isDefault,
      'sort_order': userType.sortOrder,
    };
  }

  UserType _userTypeFromMap(Map<String, dynamic> map) {
    return UserType.fromJson({
      'id': map['id'] as int,
      'name': map['name'] as String,
      'icon_class': map['icon_class'] as String?,
      'is_default': map['is_default'] == true || map['is_default'] == 1,
      'sort_order': map['sort_order'] as int,
    });
  }

  Map<String, dynamic> _vehicleTypeToMap(VehicleType vehicleType) {
    return {
      'id': vehicleType.id,
      'name': vehicleType.name,
      'icon_class': vehicleType.iconClass,
      'is_default': vehicleType.isDefault,
      'sort_order': vehicleType.sortOrder,
    };
  }

  VehicleType _vehicleTypeFromMap(Map<String, dynamic> map) {
    return VehicleType.fromJson({
      'id': map['id'] as int,
      'name': map['name'] as String,
      'icon_class': map['icon_class'] as String?,
      'is_default': map['is_default'] == true || map['is_default'] == 1,
      'sort_order': map['sort_order'] as int,
    });
  }

  /// Close database (cleanup)
  Future<void> close() async {
    if (_initialized) {
      await Hive.close();
      _initialized = false;
      debugPrint('DatabaseService: Hive closed');
    }
  }
}
