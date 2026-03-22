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
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/admin/locations'),
        headers: {'Content-Type': 'application/json'},
      );
      print("response ${response}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List;
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

  // ============================================================
  // USER TYPES
  // ============================================================

  /// Fetch all user types from backend
  Future<List<UserType>> getUserTypes() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/admin/user-types/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List;
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
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/admin/vehicle-types/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List;
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
    final List<int> createdIds = [];

    for (final count in counts) {
      try {
        final id = await createCount(count);
        createdIds.add(id);
      } catch (e) {
        // Log error but continue with other counts
        debugPrint('Failed to sync count: $e');
      }
    }

    return createdIds;
  }

  /// Delete a count by ID (for undo functionality)
  Future<void> deleteCount(int countId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/api/counter/$countId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw ApiException('Failed to delete count: ${response.statusCode}');
      }
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
      final response = await _client.get(
        Uri.parse(
          '$_baseUrl/api/counters/$counterId?vehicle=$vehicle&user=$user',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
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
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List;
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
