import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pos_database.dart';
import '../models/menu_item.dart';
import '../models/order_item.dart';
import '../models/pos_order.dart';
import '../utils/korean_time.dart';
import 'tables_controller.dart';

final orderEditorProvider = AutoDisposeAsyncNotifierProviderFamily<OrderEditor, OrderState, int>(
  OrderEditor.new,
);

class OrderState {
  const OrderState({
    required this.tableId,
    this.order,
    this.items = const [],
  });

  final int tableId;
  final PosOrder? order;
  final List<OrderItem> items;

  int get total => items.fold<int>(0, (sum, item) => sum + item.total);

  OrderState copyWith({PosOrder? order, List<OrderItem>? items}) {
    return OrderState(
      tableId: tableId,
      order: order ?? this.order,
      items: items ?? this.items,
    );
  }
}

class OrderEditor extends AutoDisposeFamilyAsyncNotifier<OrderState, int> {
  OrderEditor();

  PosDatabase get _database => ref.read(posDatabaseProvider);

  @override
  Future<OrderState> build(int tableId) async {
    await _database.open();
    final existing = await _database.getOpenOrderForTable(tableId);
    if (existing != null) {
      final items = await _database.getOrderItems(existing.id!);
      return OrderState(tableId: tableId, order: existing, items: items);
    }
    return OrderState(tableId: tableId, order: null, items: const []);
  }

  Future<void> addMenuItem(MenuItem menu) async {
    final order = state.value?.order ?? await _createOrder();
    if (order == null) {
      throw StateError('Failed to create order');
    }
    await _database.upsertOrderItem(orderId: order.id!, menu: menu);
    final items = await _database.getOrderItems(order.id!);
    state = AsyncData(OrderState(tableId: order.tableId, order: order, items: items));
    ref.invalidate(tableCardsProvider);
  }

  Future<void> incrementItem(OrderItem item) async {
    await _database.updateOrderItemQuantity(
      orderItemId: item.id,
      quantity: item.quantity + 1,
    );
    await _refresh();
    ref.invalidate(tableCardsProvider);
  }

  Future<void> decrementItem(OrderItem item) async {
    await _database.updateOrderItemQuantity(
      orderItemId: item.id,
      quantity: item.quantity - 1,
    );
    await _refresh();
    ref.invalidate(tableCardsProvider);
  }

  Future<void> closeOrder({required String paymentMethod}) async {
    final current = state.value;
    if (current?.order == null) {
      return;
    }
    final total = current!.total;
    await _database.closeOrder(
      orderId: current.order!.id!,
      total: total,
      paymentMethod: paymentMethod,
    );
    state = AsyncData(OrderState(tableId: current.tableId));
    ref.invalidate(tableCardsProvider);
  }

  Future<PosOrder?> _createOrder() async {
    final current = state.value;
    final tableId = current?.tableId ?? arg;
    final orderId = await _database.createOrder(tableId);
    final order = PosOrder(
      id: orderId,
      tableId: tableId,
      openedAt: nowInKoreanTime(),
    );
    state = AsyncData(OrderState(tableId: tableId, order: order, items: const []));
    return order;
  }

  Future<void> _refresh() async {
    final current = state.value;
    if (current?.order == null) {
      return;
    }
    final items = await _database.getOrderItems(current!.order!.id!);
    state = AsyncData(current.copyWith(items: items));
  }
}
