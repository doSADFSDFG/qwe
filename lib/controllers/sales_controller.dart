import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/pos_database.dart';
import '../models/sales_record.dart';
import '../utils/korean_time.dart';
final salesDateProvider = StateProvider<DateTime>((ref) {
  return startOfKoreanDay();
});

final salesRecordsProvider = FutureProvider<List<SalesRecord>>((ref) async {
  final db = ref.read(posDatabaseProvider);
  final date = ref.watch(salesDateProvider);
  await db.open();
  return db.getSalesForDate(date);
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
