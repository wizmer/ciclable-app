# Changelog

All notable changes to Ciclable will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- iOS version
- Multi-language support (French, Spanish, German)
- Export counting data to CSV
- Dark mode support
- Customizable counting categories

## [1.0.0] - 2026-03-22

### Added
- Initial release
- Interactive Google Maps interface with counting location markers
- Manual location selector with association and location dropdowns
- Offline-first architecture with local SQLite storage
- Automatic synchronization when online (with 2-second network stabilization delay)
- Two counting modes:
  - Non-directed: Simple count by vehicle and user type
  - Directed: Count with input/output road selection
- Support for multiple vehicle types:
  - Bicycle
  - E-bike
  - Scooter
  - Cargo bike
  - Motorcycle
  - Car
  - Wheelchair
  - Pedestrian
- Support for multiple user types:
  - Commuter
  - Student
  - Tourist
  - Child
  - Other
- Undo functionality with toast notifications
- Responsive counting table (adapts to screen size)
- Font Awesome icons for vehicle and user types
- Real-time location tracking
- Count badge showing pending sync items
- Network connectivity monitoring

### Technical
- Flutter 3.24+ with Dart 3.11+
- Provider state management
- SQLite local database
- HTTP client for API communication
- Google Maps Flutter plugin
- Geolocator for location services
- Font Awesome Flutter for icons

[Unreleased]: https://github.com/yourusername/ciclable_app/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/ciclable_app/releases/tag/v1.0.0
