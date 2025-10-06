import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/menu_controller.dart';
import '../../../controllers/order_controller.dart';
import '../../../models/menu_item.dart';
import '../../../models/order_activity_log.dart';
import '../../../models/order_item.dart';
import '../../../utils/time_ago.dart';

class OrderDialog extends ConsumerStatefulWidget {
  const OrderDialog({super.key, required this.tableId});

  final int tableId;

  @override
  ConsumerState<OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends ConsumerState<OrderDialog> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(menuCategoriesProvider);
    final orderAsync = ref.watch(orderEditorProvider(widget.tableId));

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
      child: SizedBox(
        width: 1280,
        height: 720,
        child: orderAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _buildError(context, error),
          data: (orderState) {
            return categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _buildError(context, error),
              data: (categories) {
                if (categories.isEmpty) {
                  return _buildEmptyCategories(context);
                }

                return DefaultTabController(
                  length: categories.length,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface.withOpacity(0.92),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// ✅ 상단: 테이블 번호 + 메뉴 카테고리 탭
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '테이블 ${orderState.tableId}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: TabBar(
                                  isScrollable: true,
                                  labelStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  tabs: [
                                    for (final category in categories)
                                      Tab(text: category.name),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          /// ✅ 본문: 주문내역 + 메뉴추가 + 활동기록
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                /// 왼쪽 - 주문 내역
                                Expanded(
                                  flex: 5,
                                  child: _OrderItemsPanel(
                                    state: orderState,
                                    onIncrement: (item) => ref
                                        .read(orderEditorProvider(widget.tableId).notifier)
                                        .incrementItem(item),
                                    onDecrement: (item) => ref
                                        .read(orderEditorProvider(widget.tableId).notifier)
                                        .decrementItem(item),
                                  ),
                                ),
                                const SizedBox(width: 24),

                                /// 중앙 - 메뉴 추가 (TabBarView만 남김)
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.75),
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: TabBarView(
                                        children: [
                                          for (final category in categories)
                                            _MenuGrid(
                                              categoryId: category.id,
                                              onAdd: (menu) => ref
                                                  .read(orderEditorProvider(widget.tableId).notifier)
                                                  .addMenuItem(menu),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),

                                /// 오른쪽 - 활동 기록
                                if (orderState.activityLogs.isNotEmpty)
                                  SizedBox(
                                    width: 150,
                                    child: _ActivityLogPanel(logs: orderState.activityLogs),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// 하단 버튼 영역
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FilledButton.tonal(
                                onPressed: () => Navigator.of(context).pop(),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(150, 64),
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: const Text('저장'),
                              ),
                              const SizedBox(width: 16),
                              FilledButton(
                                onPressed: orderState.items.isEmpty
                                    ? null
                                    : () => _showPaymentSheet(context, orderState.total),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(220, 64),
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                child: Text(
                                  '결제하기 (₩${NumberFormat('#,###').format(orderState.total)})',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text('데이터를 불러오는 중 문제가 발생했습니다\n$error', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCategories(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.category_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('등록된 메뉴 카테고리가 없습니다. 설정 탭에서 추가하세요.'),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentSheet(BuildContext context, int total) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '결제 수단을 선택하세요',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              for (final method in ['현금', '카드', '기타'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(method),
                    child: Text('$method (\u20a9${NumberFormat('#,###').format(total)})'),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (method != null) {
      await ref.read(orderEditorProvider(widget.tableId).notifier).closeOrder(paymentMethod: method);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _MenuGrid extends ConsumerWidget {
  const _MenuGrid({required this.categoryId, required this.onAdd});

  final int categoryId;
  final ValueChanged<MenuItem> onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(menuItemsProvider(categoryId));
    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const Center(child: Text('메뉴를 불러올 수 없습니다.')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('메뉴가 없습니다.'));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // ✅ 최소 2열은 유지되도록 수정
            final crossAxisCount = (constraints.maxWidth / 220).floor().clamp(2, 4);

            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.4,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final menu = items[index];
                return FilledButton(
                  onPressed: () => onAdd(menu),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          menu.name,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.visible,
                          softWrap: true,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₩${NumberFormat('#,###').format(menu.price)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// ✅ 주문 내역
class _OrderItemsPanel extends StatelessWidget {
  const _OrderItemsPanel({
    required this.state,
    required this.onIncrement,
    required this.onDecrement,
  });

  final OrderState state;
  final ValueChanged<OrderItem> onIncrement;
  final ValueChanged<OrderItem> onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: state.items.isEmpty
                  ? const Center(
                      child: Text(
                        '주문이 비어 있습니다.',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    )
                  : ScrollConfiguration(
                      behavior: const MaterialScrollBehavior().copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        },
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.8,
                          ),
                          itemCount: state.items.length,
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.menuName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '합계: \u20a9${NumberFormat('#,###').format(item.total)}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        _RoundIconButton(
                                          icon: Icons.remove,
                                          onPressed: () => onDecrement(item),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              item.quantity.toString(),
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                        _RoundIconButton(
                                          icon: Icons.add,
                                          onPressed: () => onIncrement(item),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ 활동 기록
class _ActivityLogPanel extends StatelessWidget {
  const _ActivityLogPanel({required this.logs});

  final List<OrderActivityLog> logs;

  @override
  Widget build(BuildContext context) {
    final reversedLogs = logs.reversed.toList();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          ),
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.builder(
              itemCount: reversedLogs.length,
              itemBuilder: (context, index) {
                final log = reversedLogs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${log.menuName} x${log.quantity}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            formatRelativeTime(log.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// ✅ 수량 조절 버튼
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }
}
