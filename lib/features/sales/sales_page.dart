import 'package:flutter/gestures.dart';
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
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '결제 건수: ${summary.count}건',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                            return const Center(
                              child: Text(
                                '해당 날짜의 매출이 없습니다.',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: records.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.receipt_long, color: Colors.white),
        ),
        title: Text(
          '${record.tableName} · ₩$formattedTotal',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        subtitle: Text(
          '$time · ${record.paymentMethod}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Wrap(
          spacing: 12,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => _openEditDialog(context, ref),
              icon: const Icon(Icons.edit),
              label: const Text('수정'),
            ),
            IconButton.filledTonal(
              onPressed: () => _confirmDelete(context, ref),
              style: IconButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.15),
                foregroundColor: Colors.redAccent,
              ),
              icon: const Icon(Icons.delete_outline),
              tooltip: '삭제',
            ),
          ],
        ),
        onTap: () => _openEditDialog(context, ref),
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => SalesRecordEditDialog(record: record),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('매출 삭제'),
          content: Text('${record.tableName} 매출을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(salesRecordEditorProvider).deleteRecord(record);
    }
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
    final orderItemsAsync = ref.watch(saleOrderItemsProvider(widget.record.orderId));
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '주문 메뉴 내역',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: orderItemsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => const Center(
                    child: Text(
                      '주문 내역을 불러오지 못했습니다.',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                          '주문된 메뉴가 없습니다.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      );
                    }
                    return ScrollConfiguration(
                      behavior: const MaterialScrollBehavior().copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        },
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.3,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.45),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.menuName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Text(
                                      'x${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₩${NumberFormat('#,###').format(item.total)}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _handleDelete(context),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    label: const Text(
                      '삭제',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Row(
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

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('매출 삭제'),
          content: const Text('해당 매출 내역을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(salesRecordEditorProvider).deleteRecord(widget.record);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
