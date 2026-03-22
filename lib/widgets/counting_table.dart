import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/utils.dart';

/// Counting table widget showing vehicle types × user types
class CountingTable extends StatelessWidget {
  final List<UserType> userTypes;
  final List<VehicleType> vehicleTypes;
  final Function(int userTypeId, int vehicleTypeId) onCountTap;

  const CountingTable({
    super.key,
    required this.userTypes,
    required this.vehicleTypes,
    required this.onCountTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              // Header row with user types
              TableRow(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
                children: [
                  // Top-left corner cell (empty)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(width: 80, height: 60),
                  ),
                  // User type headers
                  ...userTypes.map(
                    (userType) => Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 100,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (userType.iconClass != null)
                              Icon(
                                _getIconData(userType.iconClass!),
                                size: 24,
                                color: AppTheme.primaryColor,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              userType.name,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Data rows (one per vehicle type)
              ...vehicleTypes.map(
                (vehicleType) => TableRow(
                  children: [
                    // Vehicle type label
                    Container(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          if (vehicleType.iconClass != null)
                            Icon(
                              _getIconData(vehicleType.iconClass!),
                              size: 20,
                              color: AppTheme.accentColor,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            vehicleType.name,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    // Count buttons for each user type
                    ...userTypes.map(
                      (userType) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _CountButton(
                          onTap: () => onCountTap(userType.id, vehicleType.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get icon data from icon class string
  /// This is a simplified version - you may need to map your icon classes
  IconData _getIconData(String iconClass) {
    // Map common icon class names to Flutter icons
    switch (iconClass.toLowerCase()) {
      case 'bike':
      case 'bicycle':
        return Icons.pedal_bike;
      case 'ebike':
      case 'electric_bike':
        return Icons.electric_bike;
      case 'scooter':
        return Icons.electric_scooter;
      case 'cargo':
        return Icons.shopping_cart;
      case 'person':
      case 'user':
        return Icons.person;
      case 'commuter':
        return Icons.work;
      case 'student':
        return Icons.school;
      case 'tourist':
        return Icons.camera_alt;
      default:
        return Icons.circle;
    }
  }
}

/// Individual count button widget
class _CountButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CountButton({required this.onTap});

  @override
  State<_CountButton> createState() => _CountButtonState();
}

class _CountButtonState extends State<_CountButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 100,
            height: 60,
            alignment: Alignment.center,
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
