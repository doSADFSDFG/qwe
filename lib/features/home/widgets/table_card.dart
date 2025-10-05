import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/tables_controller.dart';
import '../../../data/pos_database.dart';

class TableCard extends ConsumerStatefulWidget {
  const TableCard({
    super.key,
    required this.model,
    required this.editable,
    required this.onOrderRequested,
  });

  final TableCardModel model;
  final bool editable;
  final VoidCallback onOrderRequested;

  @override
  ConsumerState<TableCard> createState() => _TableCardState();
}

class _TableCardState extends ConsumerState<TableCard> {
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _position = Offset(widget.model.table.x, widget.model.table.y);
  }

  @override
  void didUpdateWidget(covariant TableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.table.x != widget.model.table.x ||
        oldWidget.model.table.y != widget.model.table.y) {
      _position = Offset(widget.model.table.x, widget.model.table.y);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTotal = NumberFormat('#,###').format(widget.model.snapshot.total);
    final items = widget.model.snapshot.items;
    final summary = items.isEmpty
        ? '주문 없음'
        : items
            .take(2)
            .map((item) => '${item.name} x${item.quantity}')
            .join('\n');

    final card = GestureDetector(
      onTap: widget.editable ? null : widget.onOrderRequested,
      onPanUpdate: widget.editable ? _handlePanUpdate : null,
      onPanEnd: widget.editable ? _handlePanEnd : null,
      child: SizedBox(
        width: 160,
        height: 140,
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        widget.model.table.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    if (widget.model.snapshot.hasOpenOrder)
                      Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.3,
                          color: Colors.black87,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.model.snapshot.hasOpenOrder
                      ? '합계: \u20a9$formattedTotal'
                      : '대기 중',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.model.snapshot.hasOpenOrder
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black45,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: card,
    );
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
    });
  }

  Future<void> _handlePanEnd(DragEndDetails details) async {
    final database = ref.read(posDatabaseProvider);
    await database.updateTablePosition(
      tableId: widget.model.table.id,
      x: _position.dx,
      y: _position.dy,
    );
    ref.invalidate(tableCardsProvider);
  }
}
