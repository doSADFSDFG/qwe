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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '테이블 현황',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
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
          const SizedBox(height: 20),
          Expanded(
            child: tablesAsync.when(
              data: (data) => LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 520),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.08),
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _GridBackgroundPainter(color: Colors.black12),
                            ),
                          ),
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
                  );
                },
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

class _GridBackgroundPainter extends CustomPainter {
  _GridBackgroundPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const spacing = 60.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
