import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// Service for handling local SQLite database operations
/// Stores counts offline for later synchronization
class DatabaseService {
  static Database? _database;
  static const String _dbName = 'ciclable.db';
  static const int _dbVersion = 1;

  // Table names
  static const String _countsTable = 'counts';
  static const String _locationsTable = 'locations';
  static const String _userTypesTable = 'user_types';
  static const String _vehicleTypesTable = 'vehicle_types';

  /// Get database instance (singleton pattern)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Counts table
    await db.execute('''
      CREATE TABLE $_countsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dt TEXT NOT NULL,
        counter_id INTEGER NOT NULL,
        user_type_id INTEGER NOT NULL,
        vehicle_type_id INTEGER NOT NULL,
        input_road TEXT,
        output_road TEXT,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Locations table (cached from API)
    await db.execute('''
      CREATE TABLE $_locationsTable (
        id INTEGER PRIMARY KEY,
        lng REAL NOT NULL,
        lat REAL NOT NULL,
        title TEXT NOT NULL,
        association_id INTEGER NOT NULL,
        description TEXT,
        nom TEXT,
        comptage_directionnel INTEGER NOT NULL DEFAULT 0,
        routes TEXT,
        history TEXT,
        parent_id INTEGER,
        ui_option TEXT
      )
    ''');

    // User types table (cached from API)
    await db.execute('''
      CREATE TABLE $_userTypesTable (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        icon_class TEXT,
        is_default INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Vehicle types table (cached from API)
    await db.execute('''
      CREATE TABLE $_vehicleTypesTable (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        icon_class TEXT,
        is_default INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_counts_synced ON $_countsTable(synced)');
    await db.execute(
      'CREATE INDEX idx_counts_counter_id ON $_countsTable(counter_id)',
    );
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
  }

  // ============================================================
  // COUNTS
  // ============================================================

  /// Insert a new count
  Future<int> insertCount(Count count) async {
    final db = await database;
    return await db.insert(_countsTable, _countToMap(count));
  }

  /// Get all unsynced counts
  Future<List<Count>> getUnsyncedCounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _countsTable,
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'dt ASC',
    );

    return maps.map((map) => _countFromMap(map)).toList();
  }

  /// Mark a count as synced
  Future<void> markCountSynced(int localId, int? serverId) async {
    final db = await database;
    await db.update(
      _countsTable,
      {'synced': 1, if (serverId != null) 'id': serverId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Delete a count by local ID
  Future<void> deleteCount(int localId) async {
    final db = await database;
    await db.delete(_countsTable, where: 'id = ?', whereArgs: [localId]);
  }

  /// Get counts for a specific location
  Future<List<Count>> getCountsByLocation(int counterId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _countsTable,
      where: 'counter_id = ?',
      whereArgs: [counterId],
      orderBy: 'dt DESC',
    );

    return maps.map((map) => _countFromMap(map)).toList();
  }

  /// Get the most recent count (for undo functionality)
  Future<Count?> getLastCount() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _countsTable,
      orderBy: 'id DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _countFromMap(maps.first);
  }

  // ============================================================
  // LOCATIONS (Cache)
  // ============================================================

  /// Cache locations from API
  Future<void> cacheLocations(List<Location> locations) async {
    final db = await database;
    final batch = db.batch();

    // Clear existing cache
    batch.delete(_locationsTable);

    // Insert new data
    for (final location in locations) {
      batch.insert(_locationsTable, _locationToMap(location));
    }

    await batch.commit(noResult: true);
  }

  /// Get all cached locations
  Future<List<Location>> getCachedLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_locationsTable);
    return maps.map((map) => _locationFromMap(map)).toList();
  }

  // ============================================================
  // USER TYPES (Cache)
  // ============================================================

  /// Cache user types from API
  Future<void> cacheUserTypes(List<UserType> userTypes) async {
    final db = await database;
    final batch = db.batch();

    batch.delete(_userTypesTable);
    for (final userType in userTypes) {
      batch.insert(_userTypesTable, _userTypeToMap(userType));
    }

    await batch.commit(noResult: true);
  }

  /// Get all cached user types
  Future<List<UserType>> getCachedUserTypes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _userTypesTable,
      orderBy: 'is_default DESC, sort_order ASC, name ASC',
    );
    return maps.map((map) => _userTypeFromMap(map)).toList();
  }

  // ============================================================
  // VEHICLE TYPES (Cache)
  // ============================================================

  /// Cache vehicle types from API
  Future<void> cacheVehicleTypes(List<VehicleType> vehicleTypes) async {
    final db = await database;
    final batch = db.batch();

    batch.delete(_vehicleTypesTable);
    for (final vehicleType in vehicleTypes) {
      batch.insert(_vehicleTypesTable, _vehicleTypeToMap(vehicleType));
    }

    await batch.commit(noResult: true);
  }

  /// Get all cached vehicle types
  Future<List<VehicleType>> getCachedVehicleTypes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _vehicleTypesTable,
      orderBy: 'is_default DESC, sort_order ASC, name ASC',
    );
    return maps.map((map) => _vehicleTypeFromMap(map)).toList();
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
      'synced': count.synced ? 1 : 0,
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
      'synced': (map['synced'] as int) == 1,
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
      'comptage_directionnel': location.comptageDirectionnel ? 1 : 0,
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
      'comptage_directionnel': (map['comptage_directionnel'] as int) == 1,
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
      'is_default': userType.isDefault ? 1 : 0,
      'sort_order': userType.sortOrder,
    };
  }

  UserType _userTypeFromMap(Map<String, dynamic> map) {
    return UserType.fromJson({
      'id': map['id'] as int,
      'name': map['name'] as String,
      'icon_class': map['icon_class'] as String?,
      'is_default': (map['is_default'] as int) == 1,
      'sort_order': map['sort_order'] as int,
    });
  }

  Map<String, dynamic> _vehicleTypeToMap(VehicleType vehicleType) {
    return {
      'id': vehicleType.id,
      'name': vehicleType.name,
      'icon_class': vehicleType.iconClass,
      'is_default': vehicleType.isDefault ? 1 : 0,
      'sort_order': vehicleType.sortOrder,
    };
  }

  VehicleType _vehicleTypeFromMap(Map<String, dynamic> map) {
    return VehicleType.fromJson({
      'id': map['id'] as int,
      'name': map['name'] as String,
      'icon_class': map['icon_class'] as String?,
      'is_default': (map['is_default'] as int) == 1,
      'sort_order': map['sort_order'] as int,
    });
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
