/// VehicleType model representing types of vehicles
/// Examples: bike, e-bike, scooter, cargo bike, etc.
class VehicleType {
  final int id;
  final String name;
  final String? iconClass;
  final bool isDefault;
  final int sortOrder;

  const VehicleType({
    required this.id,
    required this.name,
    this.iconClass,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  /// Create VehicleType from JSON (from API or local DB)
  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'] as int,
      name: json['name'] as String,
      iconClass: json['icon_class'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Convert VehicleType to JSON for API or local DB
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (iconClass != null) 'icon_class': iconClass,
      'is_default': isDefault,
      'sort_order': sortOrder,
    };
  }

  /// Create a copy with updated fields
  VehicleType copyWith({
    int? id,
    String? name,
    String? iconClass,
    bool? isDefault,
    int? sortOrder,
  }) {
    return VehicleType(
      id: id ?? this.id,
      name: name ?? this.name,
      iconClass: iconClass ?? this.iconClass,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'VehicleType(id: $id, name: $name, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehicleType && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
