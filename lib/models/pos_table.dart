class PosTable {
  const PosTable({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
  });

  final int id;
  final String name;
  final double x;
  final double y;

  PosTable copyWith({String? name, double? x, double? y}) {
    return PosTable(
      id: id,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'x': x,
        'y': y,
      };

  static PosTable fromMap(Map<String, Object?> map) {
    return PosTable(
      id: map['id'] as int,
      name: map['name'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
    );
  }
}
