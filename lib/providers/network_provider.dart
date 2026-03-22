import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Provider for managing network connectivity status
/// Monitors online/offline state for the app
class NetworkProvider with ChangeNotifier {
  final Connectivity _connectivity;
  bool _isOnline = false;
  List<ConnectivityResult> _connectionStatus = [];

  NetworkProvider({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity() {
    _initConnectivity();
  }

  /// Get current online status
  bool get isOnline => _isOnline;

  /// Get current connection type(s)
  List<ConnectivityResult> get connectionStatus => _connectionStatus;

  /// Initialize connectivity monitoring
  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _connectionStatus = [ConnectivityResult.none];
      _isOnline = false;
    }

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// Update connection status when connectivity changes
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    _connectionStatus = results;
    _isOnline = results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );

    debugPrint('Network status changed: ${_isOnline ? "Online" : "Offline"}');

    // Schedule notification after current frame to avoid build errors
    scheduleMicrotask(() {
      notifyListeners();
    });
  }

  /// Check if connected via WiFi
  bool get isWifi => _connectionStatus.contains(ConnectivityResult.wifi);

  /// Check if connected via mobile data
  bool get isMobile => _connectionStatus.contains(ConnectivityResult.mobile);
}
