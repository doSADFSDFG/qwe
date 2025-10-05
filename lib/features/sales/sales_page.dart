import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../controllers/sales_controller.dart';
import '../../widgets/error_state.dart';
import '../../models/sales_record.dart';

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
                              return _SalesRecordTile(record: record);
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

class _SalesRecordTile extends ConsumerWidget {
  const _SalesRecordTile({required this.record});

  final SalesRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedTotal = NumberFormat('#,###').format(record.total);
    final time = DateFormat('HH:mm').format(record.closedDate.toLocal());
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        child: Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(
        '${record.tableName} · ₩$formattedTotal',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      subtitle: Text('$time · ${record.paymentMethod}'),
      trailing: FilledButton.tonalIcon(
        onPressed: () => _openEditDialog(context, ref),
        icon: const Icon(Icons.edit),
        label: const Text('수정'),
      ),
      onTap: () => _openEditDialog(context, ref),
    );
  }

  Future<void> _openEditDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => SalesRecordEditDialog(record: record),
    );
  }
}

class SalesRecordEditDialog extends ConsumerStatefulWidget {
  const SalesRecordEditDialog({super.key, required this.record});

  final SalesRecord record;

  @override
  ConsumerState<SalesRecordEditDialog> createState() => _SalesRecordEditDialogState();
}

class _SalesRecordEditDialogState extends ConsumerState<SalesRecordEditDialog> {
  late final TextEditingController _totalController;
  late DateTime _closedDate;
  late String _paymentMethod;
  String? _error;

  static const _paymentOptions = ['현금', '카드', '기타'];

  @override
  void initState() {
    super.initState();
    _totalController = TextEditingController(text: widget.record.total.toString());
    _closedDate = widget.record.closedDate.toLocal();
    _paymentMethod = widget.record.paymentMethod;
  }

  @override
  void dispose() {
    _totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${widget.record.tableName} 매출 수정',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _totalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '총액 (원)',
                  prefixText: '₩',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentOptions.contains(_paymentMethod) ? _paymentMethod : _paymentOptions.first,
                items: [
                  for (final option in _paymentOptions)
                    DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _paymentMethod = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: '결제 수단'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('yyyy.MM.dd HH:mm').format(_closedDate),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('날짜 선택'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _pickTime,
                    child: const Text('시간 선택'),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _handleSave,
                    child: const Text('저장'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _closedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() {
        _closedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _closedDate.hour,
          _closedDate.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_closedDate),
    );
    if (picked != null) {
      setState(() {
        _closedDate = DateTime(
          _closedDate.year,
          _closedDate.month,
          _closedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _handleSave() async {
    final parsed = int.tryParse(_totalController.text.replaceAll(',', ''));
    if (parsed == null || parsed <= 0) {
      setState(() {
        _error = '유효한 금액을 입력해주세요.';
      });
      return;
    }

    setState(() {
      _error = null;
    });

    await ref.read(salesRecordEditorProvider).updateRecord(
          record: widget.record,
          total: parsed,
          paymentMethod: _paymentMethod,
          closedDate: _closedDate,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
