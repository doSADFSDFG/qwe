class SalesRecord {
  const SalesRecord({
    required this.id,
    required this.orderId,
    required this.closedDate,
    required this.total,
    required this.paymentMethod,
    required this.tableName,
  });

  final int id;
  final int orderId;
  final DateTime closedDate;
  final int total;
  final String paymentMethod;
  final String tableName;

  static SalesRecord fromJoinedMap(Map<String, Object?> map) {
    return SalesRecord(
      id: map['id'] as int,
      orderId: map['order_id'] as int,
      closedDate: DateTime.parse(map['closed_date'] as String),
      total: map['total'] as int,
      paymentMethod: map['payment_method'] as String,
      tableName: map['table_name'] as String,
    );
  }
}
