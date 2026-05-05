import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';

/// Service for handling all backend API calls
/// Communicates with the SvelteKit backend
class ApiService {
  late final String _baseUrl;
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client() {
    _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5173';
  }

  // ============================================================
  // LOCATIONS
  // ============================================================

  /// Fetch all locations from backend
  /// Note: Backend doesn't have GET /api/locations endpoint yet
  /// This is a placeholder - you may need to fetch from associations instead
  Future<List<Location>> getLocations() async {
    try {
      debugPrint(
        'ApiService: Fetching locations from $_baseUrl/api/admin/locations',
      );
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/admin/locations'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint(
        'ApiService: Locations response status: ${response.statusCode}',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List;
        debugPrint('ApiService: Fetched ${data.length} locations');
        return data
            .map((json) => Location.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error fetching locations: $e');
    }
  }

  /// Fetch detailed location data including counters, types, and child markers
  /// This is the primary endpoint for loading counting screen data
  ///
  /// Returns:
  /// - parentLocation: Main location with association and campaigns
  /// - childMarkers: Array of child locations
  /// - counters: Map of locationId -> counter totals
  /// - locationTypes: Map of locationId -> {vehicleTypes, userTypes}
  /// - nextCampaign: Next upcoming campaign for the association
  Future<Map<String, dynamic>> getLocationData(int counterId) async {
    try {
      debugPrint(
        "ApiService: Fetching location data from $_baseUrl/api/locations/$counterId",
      );
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/locations/$counterId'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint(
        'ApiService: Location data response status: ${response.statusCode}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('ApiService: Location data keys: ${data.keys.toList()}');
        return data;
      } else if (response.statusCode == 404) {
        throw ApiException('Location not found');
      } else {
        throw ApiException(
          'Failed to load location data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ApiException('Error fetching location data: $e');
    }
  }

  // ============================================================
  // ASSOCIATIONS
  // ============================================================

  /// Fetch all associations from backend
  Future<List<Association>> getAssociations() async {
    try {
      debugPrint(
        'ApiService: Fetching associations from $_baseUrl/api/associations',
      );
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/associations'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint(
        'ApiService: Associations response status: ${response.statusCode}',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List;
        debugPrint('ApiService: Fetched ${data.length} associations');
        return data
            .map((json) => Association.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Failed to load associations: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ApiException('Error fetching associations: $e');
    }
  }

  // ============================================================
  // USER TYPES
  // ============================================================

  /// Fetch all user types from backend
  Future<List<UserType>> getUserTypes() async {
    try {
      debugPrint(
        'ApiService: Fetching user types from $_baseUrl/api/admin/user-types/all',
      );
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/admin/user-types/all'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint(
        'ApiService: User types response status: ${response.statusCode}',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List;
        debugPrint('ApiService: Fetched ${data.length} user types');
        return data
            .map((json) => UserType.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException('Failed to load user types: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error fetching user types: $e');
    }
  }

  // ============================================================
  // VEHICLE TYPES
  // ============================================================

  /// Fetch all vehicle types from backend
  Future<List<VehicleType>> getVehicleTypes() async {
    try {
      debugPrint(
        'ApiService: Fetching vehicle types from $_baseUrl/api/admin/vehicle-types/all',
      );
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/admin/vehicle-types/all'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint(
        'ApiService: Vehicle types response status: ${response.statusCode}',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List;
        debugPrint('ApiService: Fetched ${data.length} vehicle types');
        return data
            .map((json) => VehicleType.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Failed to load vehicle types: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ApiException('Error fetching vehicle types: $e');
    }
  }

  // ============================================================
  // COUNTS
  // ============================================================

  /// Create a single count on the backend
  /// Returns the count ID from the server
  Future<int> createCount(Count count) async {
    try {
      final body = count.toApiJson();
      debugPrint('ApiService: Creating count - Body: ${jsonEncode(body)}');

      final response = await _client.post(
        Uri.parse('$_baseUrl/api/counter'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('ApiService: Response status: ${response.statusCode}');
      debugPrint('ApiService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Backend returns just the ID
        return jsonDecode(response.body) as int;
      } else {
        throw ApiException(
          'Failed to create count: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw ApiException('Error creating count: $e');
    }
  }

  /// Create multiple counts (batch sync)
  /// Returns list of created count IDs
  Future<List<int>> createCounts(List<Count> counts) async {
    debugPrint('ApiService: Starting batch sync of ${counts.length} counts');
    final List<int> createdIds = [];

    for (final count in counts) {
      try {
        final id = await createCount(count);
        createdIds.add(id);
        debugPrint(
          'ApiService: Synced count ${createdIds.length}/${counts.length}',
        );
      } catch (e) {
        // Log error but continue with other counts
        debugPrint('ApiService: Failed to sync count: $e');
      }
    }

    debugPrint(
      'ApiService: Batch sync completed: ${createdIds.length}/${counts.length} successful',
    );
    return createdIds;
  }

  /// Delete a count by ID (for undo functionality)
  Future<void> deleteCount(int countId) async {
    try {
      debugPrint(
        'ApiService: Deleting count $countId from $_baseUrl/api/counter/$countId',
      );
      final response = await _client.delete(
        Uri.parse('$_baseUrl/api/counter/$countId'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint(
        'ApiService: Delete count response status: ${response.statusCode}',
      );
      if (response.statusCode != 200) {
        throw ApiException('Failed to delete count: ${response.statusCode}');
      }
      debugPrint('ApiService: Count $countId deleted successfully');
    } catch (e) {
      throw ApiException('Error deleting count: $e');
    }
  }

  /// Get counter totals for a specific location
  Future<Map<String, dynamic>> getCounterTotals(
    int counterId,
    String vehicle,
    String user,
  ) async {
    try {
      final url =
          '$_baseUrl/api/counters/$counterId?vehicle=$vehicle&user=$user';
      debugPrint('ApiService: Fetching counter totals from $url');
      final response = await _client.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint(
        'ApiService: Counter totals response status: ${response.statusCode}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('ApiService: Counter totals: $data');
        return data;
      } else {
        throw ApiException(
          'Failed to get counter totals: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ApiException('Error fetching counter totals: $e');
    }
  }

  /// Fetch counts with filters
  Future<List<Count>> getCounts({
    List<int>? counterIds,
    bool? last24h,
    int? associationId,
    String? vehicleType,
    String? userType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (counterIds != null && counterIds.isNotEmpty) {
        queryParams['counter_ids'] = counterIds.join(',');
      }
      if (last24h != null && last24h) {
        queryParams['last_24h'] = 'true';
      }
      if (associationId != null) {
        queryParams['association_id'] = associationId.toString();
      }
      if (vehicleType != null) {
        queryParams['vehicle_type'] = vehicleType;
      }
      if (userType != null) {
        queryParams['user_type'] = userType;
      }
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final uri = Uri.parse(
        '$_baseUrl/api/counter',
      ).replace(queryParameters: queryParams);

      debugPrint('ApiService: Fetching counts from $uri');
      debugPrint('ApiService: Query params: $queryParams');

      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('ApiService: Counts response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List;
        debugPrint('ApiService: Fetched ${data.length} counts');
        return data
            .map((json) => Count.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException('Failed to load counts: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error fetching counts: $e');
    }
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
