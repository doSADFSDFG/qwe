import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/pos_database.dart';
import '../models/order_item.dart';
import '../models/sales_record.dart';
import '../utils/korean_time.dart';

final salesRecordEditorProvider = Provider<SalesRecordEditor>((ref) {
  return SalesRecordEditor(ref);
});
final salesDateProvider = StateProvider<DateTime>((ref) {
  return startOfKoreanDay();
});

final salesRecordsProvider = FutureProvider<List<SalesRecord>>((ref) async {
  final db = ref.read(posDatabaseProvider);
  final date = ref.watch(salesDateProvider);
  await db.open();
  return db.getSalesForDate(date);
});

final saleOrderItemsProvider = FutureProvider.family<List<OrderItem>, int>((ref, orderId) async {
  final db = ref.read(posDatabaseProvider);
  await db.open();
  return db.getOrderItems(orderId);
});

final salesSummaryProvider = Provider<SalesSummary>((ref) {
  final records = ref.watch(salesRecordsProvider).maybeWhen(
        data: (data) => data,
        orElse: () => const <SalesRecord>[],
      );
  final total = records.fold<int>(0, (sum, record) => sum + record.total);
  return SalesSummary(total: total, count: records.length);
});

class SalesSummary {
  const SalesSummary({required this.total, required this.count});

  final int total;
  final int count;

  String get formattedTotal => NumberFormat('#,###').format(total);
}

class SalesRecordEditor {
  SalesRecordEditor(this._ref);

  final Ref _ref;

  PosDatabase get _db => _ref.read(posDatabaseProvider);

  Future<void> updateRecord({
    required SalesRecord record,
    required int total,
    required String paymentMethod,
    required DateTime closedDate,
  }) async {
    await _db.updateSaleRecord(
      saleId: record.id,
      total: total,
      paymentMethod: paymentMethod,
      closedDate: closedDate,
    );
    _ref.invalidate(salesRecordsProvider);
  }

  Future<void> deleteRecord(SalesRecord record) async {
    await _db.deleteSaleRecord(record.id);
    _ref.invalidate(salesRecordsProvider);
  }
}
