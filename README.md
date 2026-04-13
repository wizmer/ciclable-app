# Ciclable - Cyclist Counting App

A Flutter mobile application for counting cyclists and other road users at specific locations. Designed for volunteer organizations and municipalities conducting traffic studies to understand cyclist movement patterns and improve cycling infrastructure.

## Features

- **Interactive Map**: Google Maps interface with markers for counting locations
- **Offline-First**: All counts stored locally and synced when online
- **Dual Counting Modes**:
  - Non-directed: Simple count by vehicle/user type
  - Directed: Count with input/output road tracking
- **Multiple Categories**: Support for various vehicle types (bikes, e-bikes, scooters, etc.) and user types (commuters, students, tourists, etc.)
- **Undo Functionality**: Toast notifications to cancel recent counts
- **Auto-Sync**: Automatic synchronization with 2-second network stabilization
- **Responsive UI**: Adapts to different screen sizes
- **Visual Icons**: Font Awesome icons for better UX

## Tech Stack

- **Flutter** 3.24+ / **Dart** 3.11+
- **Google Maps** for location visualization
- **SQLite** for local data persistence
- **Provider** for state management
- **PostgreSQL** backend via Prisma (see backend repository)

## Getting Started

### Prerequisites

- Flutter SDK 3.24 or higher
- Android Studio or VS Code with Flutter extensions
- Android SDK (for Android development)
- Google Maps API key

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ciclable_app.git
   cd ciclable_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up Google Maps API key:
   - Get an API key from [Google Cloud Console](https://console.cloud.google.com/)
   - The key is already configured in `android/app/src/main/AndroidManifest.xml`
   - For production, replace with your own key

4. Run the app:
   ```bash
   flutter run
   ```

### Development

```bash
# Run in debug mode
flutter run

# Run tests
flutter test

# Build release APK
flutter build apk --release

# Build app bundle for Play Store
flutter build appbundle --release
```

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for comprehensive instructions on:
- Building release versions
- Setting up app signing
- Deploying to Google Play Store
- Deploying to F-Droid
- Setting up CI/CD with GitHub Actions

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── location.dart
│   ├── count.dart
│   ├── user_type.dart
│   └── vehicle_type.dart
├── screens/                  # UI screens
│   ├── map_screen.dart
│   ├── counting_screen.dart
│   └── road_selection_screen.dart
├── widgets/                  # Reusable components
│   ├── counting_table.dart
│   └── location_marker.dart
├── services/                 # Business logic
│   ├── database_service.dart
│   ├── api_service.dart
│   └── sync_service.dart
├── providers/                # State management
│   ├── location_provider.dart
│   ├── count_provider.dart
│   └── network_provider.dart
└── utils/
    ├── constants.dart
    ├── app_theme.dart
    └── icon_helper.dart
```

## Database Schema

The app uses a Prisma-based PostgreSQL database. Key models:

- **Location**: Counting locations with GPS coordinates and configuration
- **Count**: Individual count records with timestamps
- **UserType**: Types of users (commuter, student, tourist, etc.)
- **VehicleType**: Types of vehicles (bike, e-bike, scooter, etc.)
- **Association**: Organizations managing locations

See [schema.prisma](schema.prisma) for full schema definition.

## API Integration

The app communicates with a SvelteKit backend. Key endpoints:

- `POST /api/counter` - Submit counts
- `GET /api/counter` - Fetch counts with filters
- `DELETE /api/counter/[id]` - Delete count (undo)
- `GET /api/admin/user-types/all` - Get user types
- `GET /api/admin/vehicle-types/all` - Get vehicle types

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the GPL-3.0-or-later License - see the LICENSE file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/ciclable_app/issues)
- **Email**: contact@ciclable.org
- **Website**: [ciclable.org](https://ciclable.org)

## Roadmap

- [ ] iOS version
- [ ] Multi-language support (French, Spanish, German)
- [ ] CSV data export
- [ ] Dark mode
- [ ] Customizable counting categories
- [ ] Offline map caching
- [ ] Statistical dashboard

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.
