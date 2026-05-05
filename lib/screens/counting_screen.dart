import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';
import '../widgets/counting_table.dart';
import 'road_selection_screen.dart';

/// Screen for counting cyclists at a specific location
/// Shows a table of vehicle types × user types
class CountingScreen extends StatefulWidget {
  final Location location;

  const CountingScreen({super.key, required this.location});

  @override
  State<CountingScreen> createState() => _CountingScreenState();
}

class _CountingScreenState extends State<CountingScreen> {
  late CountProvider _countProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save reference to CountProvider for safe use in dispose()
    _countProvider = context.read<CountProvider>();
  }

  @override
  void initState() {
    super.initState();
    // Initialize counting for this location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CountProvider>().initializeForLocation(widget.location);
    });
  }

  /// Handle count registration
  Future<void> _onCountTap(int userTypeId, int vehicleTypeId) async {
    final countProvider = context.read<CountProvider>();
    final syncProvider = context.read<SyncProvider>();

    // Check if directed counting is required
    if (widget.location.comptageDirectionnel) {
      // Navigate to road selection screen
      final result = await Navigator.of(context).push<Map<String, String>>(
        MaterialPageRoute(
          builder: (_) => RoadSelectionScreen(
            location: widget.location,
            userTypeId: userTypeId,
            vehicleTypeId: vehicleTypeId,
          ),
        ),
      );

      if (result == null) return; // User cancelled

      // Create count with roads (will sync immediately if online)
      final success = await countProvider.createCount(
        userTypeId: userTypeId,
        vehicleTypeId: vehicleTypeId,
        inputRoad: result['inputRoad'],
        outputRoad: result['outputRoad'],
      );

      if (success) {
        _showUndoToast();
        // Refresh pending count (will be 0 if synced, >0 if offline)
        await syncProvider.updatePendingCount();
      }
    } else {
      // Non-directed counting - create count immediately (will sync if online)
      final success = await countProvider.createCount(
        userTypeId: userTypeId,
        vehicleTypeId: vehicleTypeId,
      );

      if (success) {
        _showUndoToast();
        // Refresh pending count (will be 0 if synced, >0 if offline)
        await syncProvider.updatePendingCount();
      }
    }
  }

  /// Show undo toast after count registration
  void _showUndoToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(AppConstants.successCountRegistered),
        duration: AppConstants.undoToastDuration,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final countProvider = context.read<CountProvider>();
            final syncProvider = context.read<SyncProvider>();

            final success = await countProvider.undoLastCount();
            if (success) {
              // Refresh pending count after undo
              await syncProvider.updatePendingCount();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppConstants.successCountUndone),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.location.title),
        actions: [
          // Network status
          Consumer<NetworkProvider>(
            builder: (context, networkProvider, _) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(
                  networkProvider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: networkProvider.isOnline
                      ? AppTheme.onlineColor
                      : AppTheme.offlineColor,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CountProvider>(
        builder: (context, countProvider, _) {
          if (countProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (countProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    countProvider.error!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        countProvider.loadTypesForLocation(widget.location.id),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (countProvider.userTypes.isEmpty ||
              countProvider.vehicleTypes.isEmpty) {
            return const Center(child: Text('No counting types available'));
          }

          return Column(
            children: [
              // Location info
              Container(
                width: double.infinity,
                color: AppTheme.primaryColor.withOpacity(0.1),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.location.description.isNotEmpty)
                      Text(
                        widget.location.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          widget.location.comptageDirectionnel
                              ? Icons.alt_route
                              : Icons.location_on,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.location.comptageDirectionnel
                              ? 'Directed counting (with roads)'
                              : 'Non-directed counting',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Counting table
              Expanded(
                child: CountingTable(
                  userTypes: countProvider.userTypes,
                  vehicleTypes: countProvider.vehicleTypes,
                  onCountTap: _onCountTap,
                ),
              ),

              // Sync status footer
              Consumer<SyncProvider>(
                builder: (context, syncProvider, _) {
                  if (syncProvider.pendingSyncCount == 0) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    width: double.infinity,
                    color: AppTheme.warningColor.withOpacity(0.1),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_upload,
                          size: 16,
                          color: AppTheme.warningColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            syncProvider.getSyncStatusText(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        if (context.watch<NetworkProvider>().isOnline)
                          TextButton(
                            onPressed: () => syncProvider.syncNow(),
                            child: const Text('Sync Now'),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // Clear the counting session using saved reference (no notification needed)
    _countProvider.clearSession(notify: false);
    super.dispose();
  }
}
