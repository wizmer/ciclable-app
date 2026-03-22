import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/utils.dart';

/// Screen for selecting input/output roads in directed counting mode
class RoadSelectionScreen extends StatefulWidget {
  final Location location;
  final int userTypeId;
  final int vehicleTypeId;

  const RoadSelectionScreen({
    super.key,
    required this.location,
    required this.userTypeId,
    required this.vehicleTypeId,
  });

  @override
  State<RoadSelectionScreen> createState() => _RoadSelectionScreenState();
}

class _RoadSelectionScreenState extends State<RoadSelectionScreen> {
  String? _inputRoad;
  String? _outputRoad;
  List<String> _availableRoads = [];

  @override
  void initState() {
    super.initState();
    _parseRoads();
  }

  /// Parse roads from location.routes JSON
  void _parseRoads() {
    try {
      final routes = widget.location.routes;

      if (routes.isEmpty) {
        _availableRoads = [];
        return;
      }

      // Routes can be stored in different formats
      // Try to extract road names as a list
      if (routes.containsKey('roads')) {
        final roads = routes['roads'];
        if (roads is List) {
          _availableRoads = roads.map((e) => e.toString()).toList();
        }
      } else {
        // Use keys as road names
        _availableRoads = routes.keys.map((e) => e.toString()).toList();
      }

      // If only 2 roads, auto-populate will happen when input is selected
      if (_availableRoads.isEmpty) {
        _availableRoads = ['Road A', 'Road B']; // Fallback
      }
    } catch (e) {
      debugPrint('Error parsing roads: $e');
      _availableRoads = ['Road A', 'Road B']; // Fallback
    }
  }

  /// Handle input road selection
  void _onInputRoadSelected(String? road) {
    setState(() {
      _inputRoad = road;

      // Auto-select output road if only 2 roads available
      if (_availableRoads.length == 2 && road != null) {
        _outputRoad = _availableRoads.firstWhere(
          (r) => r != road,
          orElse: () => _availableRoads.first,
        );
      }
    });
  }

  /// Handle output road selection
  void _onOutputRoadSelected(String? road) {
    setState(() {
      _outputRoad = road;
    });
  }

  /// Confirm selection and return to counting screen
  void _confirmSelection() {
    if (_inputRoad == null || _outputRoad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both input and output roads'),
        ),
      );
      return;
    }

    // Return the selected roads
    Navigator.of(
      context,
    ).pop({'inputRoad': _inputRoad!, 'outputRoad': _outputRoad!});
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _inputRoad != null && _outputRoad != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Route Direction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select the road where the cyclist entered and exited',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Input road selection
            Text(
              'Input Road (Entry)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _availableRoads.length,
              (index) => RadioListTile<String>(
                title: Text(_availableRoads[index]),
                value: _availableRoads[index],
                groupValue: _inputRoad,
                onChanged: _onInputRoadSelected,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tileColor: AppTheme.surfaceColor,
              ),
            ),

            const SizedBox(height: 24),

            // Output road selection
            Text(
              'Output Road (Exit)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_availableRoads.length == 2)
              // Show auto-selected output road
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentColor, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _outputRoad ?? 'Select input road first',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Show radio buttons for multiple roads
              ...List.generate(
                _availableRoads.length,
                (index) => RadioListTile<String>(
                  title: Text(_availableRoads[index]),
                  value: _availableRoads[index],
                  groupValue: _outputRoad,
                  onChanged: _inputRoad != null ? _onOutputRoadSelected : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tileColor: AppTheme.surfaceColor,
                ),
              ),

            const Spacer(),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canConfirm ? _confirmSelection : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Confirm & Register Count',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
