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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use compact mode (icons only) if width is less than 600px
        final isCompact = constraints.maxWidth < 600;
        final cellWidth = isCompact ? 60.0 : 100.0;

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
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: isCompact ? 60 : 80,
                          height: isCompact ? 40 : 60,
                        ),
                      ),
                      // User type headers
                      ...userTypes.map(
                        (userType) => Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: cellWidth,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (userType.iconClass != null)
                                  Icon(
                                    IconHelper.getIconFromClass(
                                      userType.iconClass,
                                    ),
                                    size: 24,
                                    color: AppTheme.primaryColor,
                                  ),
                                if (!isCompact) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    userType.name,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
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
                          child: isCompact
                              ? Center(
                                  child: vehicleType.iconClass != null
                                      ? Icon(
                                          IconHelper.getIconFromClass(
                                            vehicleType.iconClass,
                                          ),
                                          size: 20,
                                          color: AppTheme.accentColor,
                                        )
                                      : Text(
                                          vehicleType.name[0].toUpperCase(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                )
                              : Row(
                                  children: [
                                    if (vehicleType.iconClass != null)
                                      Icon(
                                        IconHelper.getIconFromClass(
                                          vehicleType.iconClass,
                                        ),
                                        size: 20,
                                        color: AppTheme.accentColor,
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      vehicleType.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                        ),

                        // Count buttons for each user type
                        ...userTypes.map(
                          (userType) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _CountButton(
                              onTap: () =>
                                  onCountTap(userType.id, vehicleType.id),
                              userType: userType,
                              vehicleType: vehicleType,
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
      },
    );
  }
}

/// Individual count button widget
class _CountButton extends StatefulWidget {
  final VoidCallback onTap;
  final UserType userType;
  final VehicleType vehicleType;

  const _CountButton({
    required this.onTap,
    required this.userType,
    required this.vehicleType,
  });

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
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.vehicleType.iconClass != null)
                      Icon(
                        IconHelper.getIconFromClass(
                          widget.vehicleType.iconClass,
                        ),
                        color: Colors.white,
                        size: 16,
                      ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    if (widget.userType.iconClass != null)
                      Icon(
                        IconHelper.getIconFromClass(widget.userType.iconClass),
                        color: Colors.white,
                        size: 16,
                      ),
                  ],
                ),
              ],
            ),
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
