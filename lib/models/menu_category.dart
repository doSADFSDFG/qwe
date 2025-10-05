class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  MenuCategory copyWith({String? name}) {
    return MenuCategory(id: id, name: name ?? this.name);
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
      };

  static MenuCategory fromMap(Map<String, Object?> map) {
    return MenuCategory(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }
}
