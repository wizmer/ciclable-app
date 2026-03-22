import 'dart:convert';

/// Location model representing a counting location with GPS coordinates
/// In API/backend often referred to as "counter"
class Location {
  final int id;
  final double lng;
  final double lat;
  final String title;
  final int associationId;
  final String description;
  final String nom;
  final bool comptageDirectionnel;
  final Map<String, dynamic> routes;
  final Map<String, dynamic> history;
  final int? parentId;
  final String uiOption; // 'form' or 'tables'

  const Location({
    required this.id,
    required this.lng,
    required this.lat,
    required this.title,
    required this.associationId,
    this.description = '',
    this.nom = '',
    this.comptageDirectionnel = false,
    this.routes = const {},
    this.history = const {},
    this.parentId,
    this.uiOption = 'form',
  });

  /// Create Location from JSON (from API or local DB)
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as int,
      lng: (json['lng'] as num).toDouble(),
      lat: (json['lat'] as num).toDouble(),
      title: json['title'] as String,
      associationId: json['association_id'] as int,
      description: json['description'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      comptageDirectionnel: json['comptage_directionnel'] as bool? ?? false,
      routes: json['routes'] is String
          ? jsonDecode(json['routes'] as String) as Map<String, dynamic>
          : (json['routes'] as Map<String, dynamic>? ?? {}),
      history: json['history'] is String
          ? jsonDecode(json['history'] as String) as Map<String, dynamic>
          : (json['history'] as Map<String, dynamic>? ?? {}),
      // Handle both API format (parentId) and DB format (parent_id)
      parentId: (json['parentId'] ?? json['parent_id']) as int?,
      uiOption: json['ui_option'] as String? ?? 'form',
    );
  }

  /// Convert Location to JSON for API or local DB
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lng': lng,
      'lat': lat,
      'title': title,
      'association_id': associationId,
      'description': description,
      'nom': nom,
      'comptage_directionnel': comptageDirectionnel,
      // Encode maps to JSON strings for SQLite storage
      'routes': jsonEncode(routes),
      'history': jsonEncode(history),
      'parent_id': parentId,
      'ui_option': uiOption,
    };
  }

  /// Create a copy with updated fields
  Location copyWith({
    int? id,
    double? lng,
    double? lat,
    String? title,
    int? associationId,
    String? description,
    String? nom,
    bool? comptageDirectionnel,
    Map<String, dynamic>? routes,
    Map<String, dynamic>? history,
    int? parentId,
    String? uiOption,
  }) {
    return Location(
      id: id ?? this.id,
      lng: lng ?? this.lng,
      lat: lat ?? this.lat,
      title: title ?? this.title,
      associationId: associationId ?? this.associationId,
      description: description ?? this.description,
      nom: nom ?? this.nom,
      comptageDirectionnel: comptageDirectionnel ?? this.comptageDirectionnel,
      routes: routes ?? this.routes,
      history: history ?? this.history,
      parentId: parentId ?? this.parentId,
      uiOption: uiOption ?? this.uiOption,
    );
  }

  @override
  String toString() {
    return 'Location(id: $id, title: $title, lat: $lat, lng: $lng)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
