import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/providers.dart';
import 'screens/map_screen.dart';
import 'services/services.dart';
import 'utils/utils.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  runApp(const CiclableApp());
}

class CiclableApp extends StatelessWidget {
  const CiclableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services (as singletons)
        Provider<ApiService>(
          create: (_) => ApiService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<DatabaseService>(create: (_) => DatabaseService()),

        // Network Provider
        ChangeNotifierProvider<NetworkProvider>(
          create: (_) => NetworkProvider(),
        ),

        // Sync Service and Provider
        ProxyProvider2<ApiService, DatabaseService, SyncService>(
          update: (_, apiService, databaseService, __) => SyncService(
            apiService: apiService,
            databaseService: databaseService,
          ),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProxyProvider<SyncService, SyncProvider>(
          create: (context) =>
              SyncProvider(syncService: context.read<SyncService>()),
          update: (_, syncService, previous) =>
              previous ?? SyncProvider(syncService: syncService),
        ),

        // Location Provider
        ChangeNotifierProxyProvider2<
          ApiService,
          DatabaseService,
          LocationProvider
        >(
          create: (context) => LocationProvider(
            apiService: context.read<ApiService>(),
            databaseService: context.read<DatabaseService>(),
          ),
          update: (_, apiService, databaseService, previous) =>
              previous ??
              LocationProvider(
                apiService: apiService,
                databaseService: databaseService,
              ),
        ),

        // Count Provider
        ChangeNotifierProxyProvider2<
          DatabaseService,
          ApiService,
          CountProvider
        >(
          create: (context) => CountProvider(
            databaseService: context.read<DatabaseService>(),
            apiService: context.read<ApiService>(),
          ),
          update: (_, databaseService, apiService, previous) =>
              previous ??
              CountProvider(
                databaseService: databaseService,
                apiService: apiService,
              ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        home: const AppInitializer(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Widget to handle app initialization
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize database first
      final databaseService = context.read<DatabaseService>();
      await databaseService.database; // This triggers database initialization

      // Initialize sync service
      final syncService = context.read<SyncService>();
      await syncService.initialize();

      // Initialize sync provider (now that database is ready)
      final syncProvider = context.read<SyncProvider>();
      await syncProvider.initialize();

      // Load locations
      final locationProvider = context.read<LocationProvider>();
      await locationProvider.loadLocations();

      // Sync reference data in background
      syncProvider.syncReferenceData();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isInitialized = true; // Continue anyway with cached data
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Initializing ${AppConstants.appName}...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Initialization Warning',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Starting in offline mode',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MapScreen()),
                    );
                  },
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Navigate to main screen
    return const MapScreen();
  }
}
