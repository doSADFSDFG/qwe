import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/menu_controller.dart';
import '../../../controllers/order_controller.dart';
import '../../../models/menu_item.dart';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: SizedBox(
        width: 920,
        height: 620,
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
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '테이블 ${orderState.tableId}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
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
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TabBar(
                                      isScrollable: true,
                                      labelStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      tabs: [
                                        for (final category in categories)
                                          Tab(text: category.name),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FilledButton.tonal(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  '저장',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            FilledButton(
                              onPressed: orderState.items.isEmpty
                                  ? null
                                  : () => _showPaymentSheet(context, orderState.total),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  '결제하기 (\u20a9${NumberFormat('#,###').format(orderState.total)})',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
      await ref.read(orderEditorProvider(widget.tableId).notifier).closeOrder(
            paymentMethod: method,
          );
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
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.4,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final menu = items[index];
            return ElevatedButton(
              onPressed: () => onAdd(menu),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(menu.name),
                  const SizedBox(height: 6),
                  Text('₩${NumberFormat('#,###').format(menu.price)}',
                      style: const TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

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
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '주문 내역',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: state.items.isEmpty
                  ? const Center(child: Text('주문이 비어 있습니다.'))
                  : ListView.separated(
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.menuName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18,
                                          )),
                                      const SizedBox(height: 6),
                                      Text(
                                        '합계: \u20a9${NumberFormat('#,###').format(item.total)}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatRelativeTime(item.updatedAt.toLocal()),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    _RoundIconButton(
                                      icon: Icons.remove,
                                      onPressed: () => onDecrement(item),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        item.quantity.toString(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }
}

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
