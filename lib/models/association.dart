/// Model for Association (organization managing locations and campaigns)
class Association {
  final int id;
  final String name;

  Association({
    required this.id,
    required this.name,
  });

  factory Association.fromJson(Map<String, dynamic> json) => Association(
    id: json['id'] as int,
    name: json['name'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  Association copyWith({
    int? id,
    String? name,
  }) {
    return Association(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  String toString() => 'Association(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Association && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
