---
description: "Flutter cyclist counting app with offline/online sync, Google Maps integration, and Prisma PostgreSQL database. Use when: working with counting features, location management, database models, offline sync, or app architecture."
applyTo: '**'
---

# Ciclable - Cyclist Counting App

## Project Overview

Ciclable is a Flutter mobile app for counting cyclists and other road users at specific locations. It supports both online and offline modes with local storage synchronization.

### Core Features
- **Location Management**: Google Maps interface with markers for counting locations
- **Two Counting Modes**:
  - **Non-directed**: Simple count registration by vehicle/user type
  - **Directed**: Count with input/output road tracking for crossings
- **Offline-First**: All counts stored locally and synced when online
- **Undo Capability**: Toast notifications to cancel recent counts

## Architecture

### Tech Stack
- **Frontend**: Flutter/Dart for cross-platform mobile app
- **Database**: PostgreSQL via Prisma schema (see `schema.prisma`)
- **Maps**: Google Maps SDK for Flutter
- **Local Storage**: SQLite or Hive for offline persistence

### Database Models (Prisma)

Key models from `schema.prisma`:
- **Location**: Counting locations with GPS coordinates, association, and configuration
  - In API/backend often referred to as "counter" (e.g., `counter_id` refers to location ID)
  - `comptage_directionnel`: Boolean flag for directed/non-directed mode
  - `routes`: JSON field storing available roads for directed counting
  - `ui_option`: Enum (form/tables) determining counting interface
- **Count**: Individual count records
  - Links to Location, UserType, and VehicleType via foreign keys
  - `input_road` / `output_road`: Optional fields for directed counting
  - Note: `age_class` field exists in schema but is not used in the mobile app
- **UserType**: Types of users (e.g., commuter, student, tourist)
- **VehicleType**: Types of vehicles (e.g., bike, e-bike, scooter, cargo bike)
- **Asso**: Associations managing locations and campaigns

## UI/UX Flow

### 1. Main Screen (Map View)
- Display Google Map centered on user location or last viewed area
- Show markers for all counting locations from the database (no filtering required)
- Marker interaction:
  - Tap marker → Navigate to counting screen for that location
  - Marker color/icon should indicate location status (active, has pending counts, etc.)
- No authentication required - app is open-access

### 2. Counting Screen

**Layout**:
- Header: Location name and description
- Body: Counting table (vehicle types × user types)
- Footer: Sync status indicator, back button

**Table Structure**:
- **Rows**: VehicleType (from database, filtered by location/association defaults)
- **Columns**: UserType (from database, filtered by location/association defaults)
- **Cells**: Tappable buttons showing current count for that combination

**Behavior**:
- **Non-directed mode** (`comptage_directionnel = false`):
  1. User taps cell
  2. Count immediately stored in local DB
  3. Toast appears: "Count registered. Tap to undo."
  4. Toast auto-dismisses after 3-5 seconds
  
- **Directed mode** (`comptage_directionnel = true`):
  1. User taps cell
  2. Navigate to road selection screen
  3. Road selection screen behavior (see below)

### 3. Road Selection Screen (Directed Mode Only)

**Display**:
- Title: "Select route direction"
- Input road selector (buttons or dropdown from `routes` JSON)
- Output road selector (auto-selected if only 2 roads, otherwise manual)
- Confirm button

**Logic**:
- Parse `routes` JSON from Location model
- If `routes` contains exactly 2 paths: auto-fill output road when input selected
- If more than 2 paths: require both input and output selection
- On confirm:
  1. Store count with `input_road` and `output_road` fields
  2. Navigate back to counting screen
  3. Show undo toast

### 4. Undo Toast Pattern

After every count registration:
```dart
// Show snackbar/toast with undo action
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Count registered'),
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () => _deleteLastCount(),
    ),
    duration: Duration(seconds: 4),
  ),
);
```

## Offline/Online Sync Strategy

### Local Storage
- Use **sqflite** or **Hive** for local count persistence
- Store counts with `synced` boolean flag (default: false)
- Schema should mirror Prisma Count model

### Sync Logic
1. **On count creation**: Save to local DB with `synced = false`
2. **Background sync**:
   - Monitor network connectivity
   - When online, query all counts where `synced = false`
   - POST to backend API in batches
   - On successful backend confirmation, mark `synced = true`
3. **Conflict resolution**: Server timestamp wins (counts are append-only)

### State Management
- Use **Provider** package for state management
- Separate providers for:
  - Network status (`ConnectivityProvider`)
  - Location list (`LocationProvider`)
  - Current counting session (`CountingSessionProvider`)
  - Pending sync queue (`SyncProvider`)

## Code Organization

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models (mirror Prisma schema)
│   ├── location.dart
│   ├── count.dart
│   ├── user_type.dart
│   └── vehicle_type.dart
├── screens/                  # UI screens
│   ├── map_screen.dart       # Main Google Maps view
│   ├── counting_screen.dart  # Counting table interface
│   └── road_selection_screen.dart
├── widgets/                  # Reusable components
│   ├── counting_table.dart
│   ├── location_marker.dart
│   └── undo_toast.dart
├── services/                 # Business logic
│   ├── database_service.dart # Local DB operations
│   ├── api_service.dart      # Backend API calls
│   └── sync_service.dart     # Offline/online sync
├── providers/                # State management
│   ├── location_provider.dart
│   ├── count_provider.dart
│   └── network_provider.dart
└── utils/
    ├── constants.dart
    └── helpers.dart
```

## Coding Guidelines

### Flutter Best Practices
- Use **const** constructors wherever possible for performance
- Prefer **StatelessWidget** over StatefulWidget when state is managed externally
- Use **async/await** for asynchronous operations (DB, API calls)
- Implement **error handling** for all network and DB operations

### Naming Conventions
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/functions: `camelCase`
- Constants: `kConstantName` or `SCREAMING_SNAKE_CASE`

### Data Model Mapping
When creating Dart models from Prisma schema:
- Use `freezed` or manual `copyWith` for immutability
- Include `toJson()` / `fromJson()` for serialization
- Match field names exactly (use snake_case to match DB)
- Use `DateTime` for timestamp fields

Example:
```dart
class Count {
  final int id;
  final DateTime dt;
  final int counterId;
  final int userTypeId;
  final int vehicleTypeId;
  final String? inputRoad;
  final String? outputRoad;
  // Note: age_class field omitted - not used in mobile app context
  final bool synced;

  Count({
    required this.id,
    required this.dt,
    required this.counterId,
    required this.userTypeId,
    required this.vehicleTypeId,
    this.inputRoad,
    this.outputRoad,
    this.synced = false,
  });

  factory Count.fromJson(Map<String, dynamic> json) => Count(
    id: json['id'],
    dt: DateTime.parse(json['dt']),
    counterId: json['counter_id'],
    userTypeId: json['user_type_id'],
    vehicleTypeId: json['vehicle_type_id'],
    inputRoad: json['input_road'],
    outputRoad: json['output_road'],
    synced: json['synced'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'dt': dt.toIso8601String(),
    'counter_id': counterId,
    'user_type_id': userTypeId,
    'vehicle_type_id': vehicleTypeId,
    'input_road': inputRoad,
    'output_road': outputRoad,
    'synced': synced,
  };
}
```

### Error Handling
Always wrap network and DB operations in try-catch:
```dart
try {
  await syncService.syncPendingCounts();
} on NetworkException catch (e) {
  // Show user-friendly error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Sync failed. Will retry when online.')),
  );
  logger.error('Sync failed', error: e);
} catch (e) {
  // Unexpected errors
  logger.error('Unexpected error during sync', error: e);
}
```

## Testing Strategy
- **Unit tests**: Services, models, utilities
- **Widget tests**: Individual components (counting table, markers)
- **Integration tests**: Full user flows (map → count → sync)
- Test offline scenarios explicitly

## Dependencies to Add

Essential packages for `pubspec.yaml`:
```yaml
dependencies:
  google_maps_flutter: ^2.x.x
  geolocator: ^10.x.x          # User location
  provider: ^6.x.x              # State management
  sqflite: ^2.x.x               # Local database
  connectivity_plus: ^5.x.x     # Network status
  http: ^1.x.x                  # API calls
  intl: ^0.19.x                 # Date formatting
  flutter_dotenv: ^5.x.x        # Environment variables (for API URLs)
  
dev_dependencies:
  freezed: ^2.x.x               # Immutable models (optional)
  build_runner: ^2.x.x
  json_serializable: ^6.x.x
```

## Environment Setup
Create `.env` file (not committed):
```
DATABASE_URL=postgresql://user:pass@host:5432/dbname
API_BASE_URL=https://api.ciclable.com
GOOGLE_MAPS_API_KEY=your_key_here
```

## Backend API Expectations

The backend is a SvelteKit application with the following API endpoints:

### Counting Endpoints
- **POST** `/api/counter` - Create a single count
  - Body: `{ counter_id, user, vehicle, input_road?, output_road? }`
  - Returns: count ID
  - Note: `user` and `vehicle` refer to the deprecated string fields; should use `user_type_id` and `vehicle_type_id` for new implementations

- **GET** `/api/counter` - Fetch counts with optional filters
  - Query params: `counter_ids`, `last_24h`, `association_id`, `vehicle_type`, `user_type`, `start_date`, `end_date`
  - Returns: array of count records with timestamps

- **DELETE** `/api/counter/[id]` - Delete a specific count (for undo functionality)

### Alternative Counting Endpoint (Alias)
- **POST** `/api/click` - Create a count (generic payload)
  - Body: full count object matching Prisma schema
  - Returns: count ID

- **DELETE** `/api/click/[id]` - Delete a count

### Counter Totals
- **GET** `/api/counters/[counter_id]` - Get current totals for a location
  - Query params: `vehicle`, `user`
  - Returns: current count for that vehicle/user combination plus all totals

### Type Definitions
- **GET** `/api/admin/user-types/all` - Fetch all user types
  - Returns: array ordered by `is_default DESC, sort_order ASC, name ASC`

- **GET** `/api/admin/vehicle-types/all` - Fetch all vehicle types
  - Returns: array ordered by `is_default DESC, sort_order ASC, name ASC`

### Location Management (Admin)
- **POST** `/api/admin/locations` - Create multiple locations
  - Body: array of location objects
  - Returns: array of created locations

- **PUT** `/api/admin/locations/[id]` - Update a specific location
  - Body: location data object
  - Returns: updated location

- **DELETE** `/api/admin/locations/[id]` - Delete a location
  - Returns: success status or constraint error if location has counts

### Association Management (Admin)
- **GET** `/api/admin/associations` - Fetch all associations with campaigns
  - Returns: array of associations with nested campaign data

- **POST** `/api/admin/associations` - Create association with type defaults
- **PUT** `/api/admin/associations/[id]` - Update association
- **DELETE** `/api/admin/associations/[id]` - Delete association

### Important Notes for Mobile App

1. **No dedicated GET locations endpoint**: The backend currently loads locations via SvelteKit's server load functions, not REST API. You'll need to either:
   - Add a `GET /api/admin/locations` endpoint to the backend
   - Fetch from the root page's data endpoint
   - Have the mobile app query associations and their nested locations

2. **Field naming**: The backend still uses deprecated `user_type` and `vehicle_type` string fields in some endpoints. Mobile app should use `user_type_id` and `vehicle_type_id` (integer foreign keys) for consistency with the schema.

3. **Batch sync**: For offline sync, use `POST /api/counter` or `POST /api/click` in a loop. Consider adding a batch endpoint to the backend for efficiency.

4. **Undo functionality**: Use `DELETE /api/counter/[id]` to remove the most recently created count.

All endpoints use JSON and follow the Prisma schema structure.

# MISC
GCP project id: "ciclable"