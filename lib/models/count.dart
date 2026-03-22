/// Count model representing a single counting record
/// Note: age_class field omitted - not used in mobile app context
class Count {
  final int? id; // Nullable for new counts before sync
  final DateTime dt;
  final int counterId; // References Location.id (called counter_id in backend)
  final int userTypeId;
  final int vehicleTypeId;
  final String? inputRoad;
  final String? outputRoad;
  final bool synced; // For offline sync tracking

  const Count({
    this.id,
    required this.dt,
    required this.counterId,
    required this.userTypeId,
    required this.vehicleTypeId,
    this.inputRoad,
    this.outputRoad,
    this.synced = false,
  });

  /// Create Count from JSON (from API or local DB)
  factory Count.fromJson(Map<String, dynamic> json) {
    return Count(
      id: json['id'] as int?,
      dt: json['dt'] is String
          ? DateTime.parse(json['dt'] as String)
          : json['dt'] as DateTime,
      counterId: json['counter_id'] as int,
      userTypeId: json['user_type_id'] as int,
      vehicleTypeId: json['vehicle_type_id'] as int,
      inputRoad: json['input_road'] as String?,
      outputRoad: json['output_road'] as String?,
      synced: json['synced'] as bool? ?? false,
    );
  }

  /// Convert Count to JSON for API or local DB
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'dt': dt.toIso8601String(),
      'counter_id': counterId,
      'user_type_id': userTypeId,
      'vehicle_type_id': vehicleTypeId,
      if (inputRoad != null) 'input_road': inputRoad,
      if (outputRoad != null) 'output_road': outputRoad,
      'synced': synced,
    };
  }

  /// Convert Count to API format (for backend POST)
  /// Backend still uses deprecated 'user' and 'vehicle' string fields
  Map<String, dynamic> toApiJson() {
    return {
      'counter_id': counterId,
      'user_type_id': userTypeId,
      'vehicle_type_id': vehicleTypeId,
      if (inputRoad != null) 'input_road': inputRoad,
      if (outputRoad != null) 'output_road': outputRoad,
      'dt': dt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Count copyWith({
    int? id,
    DateTime? dt,
    int? counterId,
    int? userTypeId,
    int? vehicleTypeId,
    String? inputRoad,
    String? outputRoad,
    bool? synced,
  }) {
    return Count(
      id: id ?? this.id,
      dt: dt ?? this.dt,
      counterId: counterId ?? this.counterId,
      userTypeId: userTypeId ?? this.userTypeId,
      vehicleTypeId: vehicleTypeId ?? this.vehicleTypeId,
      inputRoad: inputRoad ?? this.inputRoad,
      outputRoad: outputRoad ?? this.outputRoad,
      synced: synced ?? this.synced,
    );
  }

  @override
  String toString() {
    return 'Count(id: $id, counterId: $counterId, userTypeId: $userTypeId, vehicleTypeId: $vehicleTypeId, synced: $synced)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Count && other.id == id && id != null;
  }

  @override
  int get hashCode => id.hashCode;
}
