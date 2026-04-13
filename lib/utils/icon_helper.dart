import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Helper class to map icon_class strings to Flutter/Font Awesome icons
class IconHelper {
  /// Get icon data from icon_class string
  /// Supports both Material Icons and Font Awesome icons
  static IconData getIconFromClass(String? iconClass) {
    if (iconClass == null || iconClass.isEmpty) {
      return Icons.location_on;
    }

    // Normalize: lowercase, trim, and remove 'fa-solid', 'fa-regular', etc.
    String normalized = iconClass.toLowerCase().trim();
    normalized = normalized
        .replaceAll('fa-solid ', '')
        .replaceAll('fa-regular ', '')
        .replaceAll('fa-light ', '')
        .replaceAll('fa-brands ', '');
    normalized = normalized.trim();

    // Material Icons mapping
    switch (normalized) {
      // Bikes & vehicles
      case 'bike':
      case 'bicycle':
      case 'pedal_bike':
        return Icons.pedal_bike;
      case 'ebike':
      case 'electric_bike':
      case 'electric-bike':
        return Icons.electric_bike;
      case 'scooter':
      case 'electric_scooter':
      case 'electric-scooter':
        return Icons.electric_scooter;
      case 'cargo':
      case 'cargo_bike':
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'motorcycle':
      case 'moped':
        return Icons.two_wheeler;

      // User types
      case 'person':
      case 'user':
        return Icons.person;
      case 'commuter':
      case 'work':
      case 'briefcase':
        return Icons.work;
      case 'student':
      case 'school':
        return Icons.school;
      case 'tourist':
      case 'camera':
      case 'camera_alt':
        return Icons.camera_alt;
      case 'family':
      case 'group':
        return Icons.family_restroom;

      // Locations
      case 'location':
      case 'place':
      case 'marker':
        return Icons.location_on;
      case 'home':
        return Icons.home;
      case 'business':
      case 'office':
        return Icons.business;

      // Default fallback
      default:
        // Try Font Awesome icons for common cases
        return _getFontAwesomeIcon(normalized);
    }
  }

  /// Map to Font Awesome icons
  static IconData _getFontAwesomeIcon(String iconClass) {
    switch (iconClass) {
      // Font Awesome bike icons
      case 'fa-bicycle':
      case 'fa-bike':
        return FontAwesomeIcons.bicycle;

      // Font Awesome person icons
      case 'fa-user':
      case 'fa-person':
        return FontAwesomeIcons.person;
      case 'fa-person-dress':
        return FontAwesomeIcons.personDress;
      case 'fa-users':
      case 'fa-group':
        return FontAwesomeIcons.users;
      case 'fa-briefcase':
        return FontAwesomeIcons.briefcase;
      case 'fa-graduation-cap':
        return FontAwesomeIcons.graduationCap;
      case 'fa-camera':
        return FontAwesomeIcons.camera;
      case 'fa-child':
        return FontAwesomeIcons.child;

      // Font Awesome vehicle icons
      case 'fa-motorcycle':
        return FontAwesomeIcons.motorcycle;
      case 'fa-car':
        return FontAwesomeIcons.car;
      case 'fa-truck':
        return FontAwesomeIcons.truck;
      case 'fa-bus':
        return FontAwesomeIcons.bus;
      case 'fa-bolt':
      case 'fa-bolt-lightning':
        return FontAwesomeIcons.bolt;
      case 'fa-wheelchair':
        return FontAwesomeIcons.wheelchair;
      case 'fa-baby':
        return FontAwesomeIcons.baby;
      case 'fa-person-walking':
        return FontAwesomeIcons.personWalking;

      // Font Awesome location icons
      case 'fa-location-dot':
      case 'fa-map-marker':
      case 'fa-marker':
        return FontAwesomeIcons.locationDot;
      case 'fa-map-pin':
        return FontAwesomeIcons.mapPin;
      case 'fa-home':
        return FontAwesomeIcons.house;
      case 'fa-building':
        return FontAwesomeIcons.building;

      // Fallback to Material Icons location
      default:
        return Icons.circle;
    }
  }

  /// Check if an icon class is from Font Awesome
  static bool isFontAwesomeIcon(String? iconClass) {
    if (iconClass == null) return false;
    return iconClass.toLowerCase().startsWith('fa-');
  }
}
