import 'package:flutter/foundation.dart';

import '../services/services.dart';

/// Provider for managing offline/online synchronization
/// Tracks sync status and provides sync controls
class SyncProvider with ChangeNotifier {
  final SyncService _syncService;

  bool _isSyncing = false;
  int _pendingSyncCount = 0;
  String? _lastSyncMessage;
  DateTime? _lastSyncTime;
  SyncResult? _lastSyncResult;

  SyncProvider({required SyncService syncService})
    : _syncService = syncService {
    // Register callback for automatic sync completion
    debugPrint('SyncProvider: Registering onSyncComplete callback');
    _syncService.onSyncComplete = () {
      debugPrint(
        'SyncProvider: onSyncComplete callback fired, updating pending count',
      );
      updatePendingCount();
    };
  }

  /// Get syncing state
  bool get isSyncing => _isSyncing;

  /// Get pending sync count
  int get pendingSyncCount => _pendingSyncCount;

  /// Get last sync message
  String? get lastSyncMessage => _lastSyncMessage;

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Get last sync result
  SyncResult? get lastSyncResult => _lastSyncResult;

  /// Get online status from sync service
  bool get isOnline => _syncService.isOnline;

  /// Initialize sync provider (call after database is ready)
  Future<void> initialize() async {
    await updatePendingCount();
  }

  /// Update pending sync count (public method for manual refresh)
  Future<void> updatePendingCount() async {
    try {
      final oldCount = _pendingSyncCount;
      _pendingSyncCount = await _syncService.getPendingSyncCount();
      debugPrint(
        'SyncProvider: Pending count updated from $oldCount to $_pendingSyncCount',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating pending sync count: $e');
    }
  }

  /// Trigger manual sync
  Future<void> syncNow() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _lastSyncMessage = 'Syncing...';
    notifyListeners();

    try {
      _lastSyncResult = await _syncService.forceSyncNow();
      _lastSyncTime = DateTime.now();
      _lastSyncMessage = _lastSyncResult!.message;

      // Update pending count after sync
      await updatePendingCount();
    } catch (e) {
      debugPrint('Error during sync: $e');
      _lastSyncMessage = 'Sync failed: $e';
      _lastSyncResult = SyncResult(
        success: false,
        syncedCount: 0,
        failedCount: 0,
        message: 'Sync failed: $e',
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Sync reference data (locations, types)
  Future<void> syncReferenceData() async {
    try {
      await _syncService.syncReferenceData();
      _lastSyncMessage = 'Reference data updated';
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing reference data: $e');
    }
  }

  /// Increment pending count (called when new count is created)
  void incrementPendingCount() {
    _pendingSyncCount++;
    notifyListeners();
  }

  /// Decrement pending count (called when count is synced or deleted)
  void decrementPendingCount() {
    if (_pendingSyncCount > 0) {
      _pendingSyncCount--;
      notifyListeners();
    }
  }

  /// Clear sync status
  void clearSyncStatus() {
    _lastSyncMessage = null;
    _lastSyncResult = null;
    notifyListeners();
  }

  /// Get sync status text for UI
  String getSyncStatusText() {
    if (_isSyncing) {
      return 'Syncing...';
    }

    if (_pendingSyncCount > 0) {
      return '$_pendingSyncCount count${_pendingSyncCount == 1 ? '' : 's'} pending';
    }

    if (_lastSyncTime != null) {
      final diff = DateTime.now().difference(_lastSyncTime!);
      if (diff.inMinutes < 1) {
        return 'Synced just now';
      } else if (diff.inHours < 1) {
        return 'Synced ${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        return 'Synced ${diff.inHours}h ago';
      } else {
        return 'Synced ${diff.inDays}d ago';
      }
    }

    return 'No pending syncs';
  }
}
