import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../controllers/sales_controller.dart';
import '../../widgets/error_state.dart';

class SalesPage extends ConsumerWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(salesDateProvider);
    final summary = ref.watch(salesSummaryProvider);
    final recordsAsync = ref.watch(salesRecordsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TableCalendar(
                      locale: 'ko_KR',
                      focusedDay: selectedDate,
                      firstDay: DateTime(2020, 1, 1),
                      lastDay: DateTime(2100, 12, 31),
                      selectedDayPredicate: (day) =>
                          day.year == selectedDate.year &&
                          day.month == selectedDate.month &&
                          day.day == selectedDate.day,
                      onDaySelected: (selected, focused) {
                        ref.read(salesDateProvider.notifier).state = DateTime(
                          selected.year,
                          selected.month,
                          selected.day,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '총 매출: \u20a9${summary.formattedTotal}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text('결제 건수: ${summary.count}건'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '상세 매출 (${DateFormat('yyyy.MM.dd').format(selectedDate)})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: recordsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) => ErrorState(
                          message: '매출 데이터를 불러오지 못했습니다.',
                          error: error,
                        ),
                        data: (records) {
                          if (records.isEmpty) {
                            return const Center(child: Text('해당 날짜의 매출이 없습니다.'));
                          }
                          return ListView.separated(
                            itemCount: records.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final record = records[index];
                              return ListTile(
                                leading: const Icon(Icons.receipt_long),
                                title: Text('${record.tableName} - ₩${NumberFormat('#,###').format(record.total)}'),
                                subtitle: Text(
                                  '${DateFormat('HH:mm').format(record.closedDate)} · ${record.paymentMethod}',
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
