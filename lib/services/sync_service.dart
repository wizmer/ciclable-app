import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'database_service.dart';

/// Service for synchronizing offline counts with the backend
/// Monitors network connectivity and syncs when online
class SyncService {
  final ApiService _apiService;
  final DatabaseService _databaseService;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;

  bool _isSyncing = false;
  bool _isOnline = false;

  /// Callback to notify when automatic sync completes
  Function()? onSyncComplete;

  SyncService({
    required ApiService apiService,
    required DatabaseService databaseService,
    Connectivity? connectivity,
  }) : _apiService = apiService,
       _databaseService = databaseService,
       _connectivity = connectivity ?? Connectivity();

  /// Initialize sync service and start monitoring connectivity
  Future<void> initialize() async {
    // Check initial connectivity
    _isOnline = await _checkConnectivity();
    debugPrint('SyncService: Initialized with online status: $_isOnline');

    // Listen to connectivity changes
    debugPrint('SyncService: Setting up connectivity listener...');
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        debugPrint(
          'SyncService: Connectivity listener fired! Results: $results',
        );
        final wasOnline = _isOnline;
        _isOnline = results.any(
          (result) =>
              result == ConnectivityResult.wifi ||
              result == ConnectivityResult.mobile ||
              result == ConnectivityResult.ethernet,
        );

        debugPrint(
          'SyncService: Connectivity changed - Online: $_isOnline (was: $wasOnline)',
        );

        // If just came online, trigger sync after delay to allow network to stabilize
        if (!wasOnline && _isOnline) {
          debugPrint(
            'SyncService: Device came online, waiting for network to stabilize...',
          );
          // Wait 2 seconds for network to be fully ready
          await Future.delayed(const Duration(seconds: 2));
          // Check if still online after delay
          if (_isOnline) {
            debugPrint('SyncService: Network stable, triggering sync...');
            await syncPendingCounts();
          } else {
            debugPrint('SyncService: Network lost during stabilization delay');
          }
        }
      },
      onError: (error) {
        debugPrint('SyncService: Connectivity listener error: $error');
      },
    );
    debugPrint('SyncService: Connectivity listener setup complete');

    // Set up periodic sync (every 5 minutes when online)
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (_isOnline && !_isSyncing) {
        await syncPendingCounts();
      }
    });

    // Initial sync if online
    if (_isOnline) {
      await syncPendingCounts();
    }
  }

  /// Check current connectivity status
  Future<bool> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );
  }

  /// Get current online status
  bool get isOnline => _isOnline;

  /// Sync all pending counts with backend
  Future<SyncResult> syncPendingCounts() async {
    if (_isSyncing) {
      debugPrint('SyncService: Already syncing, skipping...');
      return SyncResult(
        success: false,
        syncedCount: 0,
        failedCount: 0,
        message: 'Sync already in progress',
      );
    }

    if (!_isOnline) {
      debugPrint('SyncService: Offline, cannot sync');
      return SyncResult(
        success: false,
        syncedCount: 0,
        failedCount: 0,
        message: 'No internet connection',
      );
    }

    _isSyncing = true;
    debugPrint('SyncService: Starting sync of pending counts...');
    int syncedCount = 0;
    int failedCount = 0;

    try {
      // Get all unsynced counts
      final unsyncedCounts = await _databaseService.getUnsyncedCounts();

      debugPrint('SyncService: Found ${unsyncedCounts.length} pending counts');

      if (unsyncedCounts.isEmpty) {
        return SyncResult(
          success: true,
          syncedCount: 0,
          failedCount: 0,
          message: 'No pending counts to sync',
        );
      }

      // Sync each count
      for (final count in unsyncedCounts) {
        try {
          debugPrint(
            'SyncService: Syncing count ${count.id}: counter=${count.counterId}, user=${count.userTypeId}, vehicle=${count.vehicleTypeId}',
          );
          // Send to backend
          final serverId = await _apiService.createCount(count);

          // Mark as synced in local DB
          await _databaseService.markCountSynced(count.id!, serverId);
          syncedCount++;
          debugPrint(
            'SyncService: Successfully synced count ${count.id} -> server ID: $serverId',
          );
        } catch (e, stackTrace) {
          debugPrint('SyncService: Failed to sync count ${count.id}: $e');
          debugPrint('SyncService: Stack trace: $stackTrace');
          failedCount++;
          // Continue with other counts
        }
      }

      return SyncResult(
        success: failedCount == 0,
        syncedCount: syncedCount,
        failedCount: failedCount,
        message: failedCount == 0
            ? 'Successfully synced $syncedCount counts'
            : 'Synced $syncedCount counts, $failedCount failed',
      );
    } catch (e) {
      debugPrint('SyncService: Error during sync: $e');
      return SyncResult(
        success: false,
        syncedCount: syncedCount,
        failedCount: failedCount,
        message: 'Sync error: $e',
      );
    } finally {
      _isSyncing = false;
      debugPrint(
        'SyncService: Sync completed (synced: $syncedCount, failed: $failedCount)',
      );
      // Notify listeners that sync completed
      if (onSyncComplete != null) {
        debugPrint('SyncService: Calling onSyncComplete callback');
        onSyncComplete!();
      } else {
        debugPrint('SyncService: No onSyncComplete callback registered');
      }
    }
  }

  /// Sync reference data (locations, user types, vehicle types)
  /// Should be called on app start and periodically
  Future<void> syncReferenceData() async {
    if (!_isOnline) return;

    try {
      // Fetch and cache locations
      final locations = await _apiService.getLocations();
      await _databaseService.cacheLocations(locations);

      // Fetch and cache user types
      final userTypes = await _apiService.getUserTypes();
      await _databaseService.cacheUserTypes(userTypes);

      // Fetch and cache vehicle types
      final vehicleTypes = await _apiService.getVehicleTypes();
      await _databaseService.cacheVehicleTypes(vehicleTypes);
    } catch (e) {
      debugPrint('Failed to sync reference data: $e');
      // Don't throw - offline mode should still work with cached data
    }
  }

  /// Force sync immediately (for manual sync button)
  Future<SyncResult> forceSyncNow() async {
    _isOnline = await _checkConnectivity();
    return await syncPendingCounts();
  }

  /// Get count of pending syncs
  Future<int> getPendingSyncCount() async {
    final unsyncedCounts = await _databaseService.getUnsyncedCounts();
    debugPrint('SyncService: getPendingSyncCount = ${unsyncedCounts.length}');
    return unsyncedCounts.length;
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final String message;

  SyncResult({
    required this.success,
    required this.syncedCount,
    required this.failedCount,
    required this.message,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, synced: $syncedCount, failed: $failedCount, message: $message)';
  }
}
