import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/tables_controller.dart';
import '../../widgets/error_state.dart';
import 'dialogs/order_dialog.dart';
import 'widgets/table_card.dart';

class MainTab extends ConsumerWidget {
  const MainTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tableCardsProvider);
    final editMode = ref.watch(tableEditModeProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '테이블 현황',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () {
                  ref.read(tableEditModeProvider.notifier).state = !editMode;
                },
                child: Text(editMode ? '편집 종료' : '배치 편집'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: tablesAsync.when(
              data: (data) => DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox.expand(
                  child: Stack(
                    children: [
                      for (final card in data)
                        TableCard(
                          model: card,
                          editable: editMode,
                          onOrderRequested: () {
                            _openOrderDialog(context, card.table.id);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => ErrorState(
                message: '테이블 정보를 불러오지 못했습니다.',
                error: error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openOrderDialog(BuildContext context, int tableId) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrderDialog(tableId: tableId),
    );
  }
}
