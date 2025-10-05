import 'package:flutter_test/flutter_test.dart';

import 'package:calut_pos/controllers/order_controller.dart';
import 'package:calut_pos/models/order_item.dart';
import 'package:calut_pos/models/pos_order.dart';

void main() {
  test('OrderState total sums order items', () {
    const order = PosOrder(
      id: 1,
      tableId: 1,
      openedAt: DateTime(2023, 1, 1),
    );
    final state = OrderState(
      tableId: 1,
      order: order,
      items: const [
        OrderItem(
          id: 1,
          orderId: 1,
          menuId: 1,
          quantity: 2,
          unitPrice: 5000,
          menuName: '생맥주',
          updatedAt: DateTime(2023, 1, 1, 20, 0),
        ),
        OrderItem(
          id: 2,
          orderId: 1,
          menuId: 2,
          quantity: 1,
          unitPrice: 15000,
          menuName: '안주',
          updatedAt: DateTime(2023, 1, 1, 20, 30),
        ),
      ],
    );

    expect(state.total, 25000);
  });
}
