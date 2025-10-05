class OrderActivityLog {
  const OrderActivityLog({
    required this.id,
    required this.orderId,
    required this.menuName,
    required this.quantity,
    required this.createdAt,
  });

  final int id;
  final int orderId;
  final String menuName;
  final int quantity;
  final DateTime createdAt;

  OrderActivityLog copyWith({
    int? id,
    int? orderId,
    String? menuName,
    int? quantity,
    DateTime? createdAt,
  }) {
    return OrderActivityLog(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      menuName: menuName ?? this.menuName,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static OrderActivityLog fromMap(Map<String, Object?> map) {
    return OrderActivityLog(
      id: map['id'] as int,
      orderId: map['order_id'] as int,
      menuName: map['menu_name'] as String,
      quantity: map['quantity'] as int,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_name': menuName,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
