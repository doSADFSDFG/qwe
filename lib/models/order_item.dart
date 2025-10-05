class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.menuId,
    required this.quantity,
    required this.unitPrice,
    required this.menuName,
    required this.updatedAt,
  });

  final int id;
  final int orderId;
  final int menuId;
  final int quantity;
  final int unitPrice;
  final String menuName;
  final DateTime updatedAt;

  int get total => quantity * unitPrice;

  OrderItem copyWith({int? quantity, DateTime? updatedAt}) {
    return OrderItem(
      id: id,
      orderId: orderId,
      menuId: menuId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice,
      menuName: menuName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static OrderItem fromJoinedMap(Map<String, Object?> map) {
    final updatedAtRaw = map['updated_at'] as String?;
    return OrderItem(
      id: map['id'] as int,
      orderId: map['order_id'] as int,
      menuId: map['menu_id'] as int,
      quantity: map['quantity'] as int,
      unitPrice: map['unit_price'] as int,
      menuName: map['name'] as String,
      updatedAt: updatedAtRaw != null
          ? DateTime.parse(updatedAtRaw)
          : DateTime.now(),
    );
  }
}
