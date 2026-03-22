import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // App Info
  static const String appName = 'Ciclable';
  static const String appVersion = '1.0.0';

  // Undo Toast Duration
  static const Duration undoToastDuration = Duration(seconds: 4);

  // Sync Settings
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration cacheRefreshInterval = Duration(hours: 1);

  // Map Settings
  static const double defaultMapZoom = 14.0;
  static const double markerZoom = 16.0;

  // Error Messages
  static const String errorNoInternet = 'No internet connection';
  static const String errorLoadingData = 'Failed to load data';
  static const String errorSavingCount = 'Failed to save count';
  static const String errorSyncing = 'Sync failed. Will retry when online.';

  // Success Messages
  static const String successCountRegistered = 'Count registered';
  static const String successCountUndone = 'Count removed';
  static const String successSynced = 'All counts synced';
}

/// App theme colors and styling
class AppTheme {
  AppTheme._();

  // Brand Colors
  static const Color primaryColor = Color(0xFF2196F3); // Blue
  static const Color accentColor = Color(0xFF4CAF50); // Green
  static const Color errorColor = Color(0xFFE53935); // Red
  static const Color warningColor = Color(0xFFFFA726); // Orange

  // Status Colors
  static const Color onlineColor = Color(0xFF4CAF50); // Green
  static const Color offlineColor = Color(0xFF9E9E9E); // Grey
  static const Color syncingColor = Color(0xFF2196F3); // Blue

  // Marker Colors
  static const Color markerActiveColor = Color(0xFF4CAF50);
  static const Color markerInactiveColor = Color(0xFF9E9E9E);
  static const Color markerSelectedColor = Color(0xFF2196F3);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Background Colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;

  // Create Material Theme
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
        surface: surfaceColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Database table names (for reference)
class DbTables {
  DbTables._();

  static const String counts = 'counts';
  static const String locations = 'locations';
  static const String userTypes = 'user_types';
  static const String vehicleTypes = 'vehicle_types';
}

/// API endpoint paths
class ApiEndpoints {
  ApiEndpoints._();

  // Counting
  static const String counter = '/api/counter';
  static const String click = '/api/click';
  
  // Types
  static const String userTypes = '/api/admin/user-types/all';
  static const String vehicleTypes = '/api/admin/vehicle-types/all';
  
  // Admin
  static const String locations = '/api/admin/locations';
  static const String associations = '/api/admin/associations';
}
