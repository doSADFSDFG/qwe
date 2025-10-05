class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
  });

  final int id;
  final String name;
  final int price;
  final int categoryId;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'category_id': categoryId,
      };

  static MenuItem fromMap(Map<String, Object?> map) {
    return MenuItem(
      id: map['id'] as int,
      name: map['name'] as String,
      price: map['price'] as int,
      categoryId: map['category_id'] as int,
    );
  }
}
