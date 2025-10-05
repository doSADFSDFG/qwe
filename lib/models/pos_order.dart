class PosOrder {
  const PosOrder({
    this.id,
    required this.tableId,
    required this.openedAt,
    this.closedAt,
    this.paymentMethod,
    this.total = 0,
  });

  final int? id;
  final int tableId;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String? paymentMethod;
  final int total;

  PosOrder copyWith({
    DateTime? closedAt,
    String? paymentMethod,
    int? total,
  }) {
    return PosOrder(
      id: id,
      tableId: tableId,
      openedAt: openedAt,
      closedAt: closedAt ?? this.closedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      total: total ?? this.total,
    );
  }

  static PosOrder fromMap(Map<String, Object?> map) {
    return PosOrder(
      id: map['id'] as int?,
      tableId: map['table_id'] as int,
      openedAt: DateTime.parse(map['opened_at'] as String),
      closedAt: map['closed_at'] != null
          ? DateTime.parse(map['closed_at'] as String)
          : null,
      paymentMethod: map['payment_method'] as String?,
      total: map['total'] != null ? map['total'] as int : 0,
    );
  }
}
