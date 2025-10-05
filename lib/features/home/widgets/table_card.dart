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
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

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
    if (widget.editable && !oldWidget.editable) {
      _hideOverlay();
    }
    _overlayEntry?.markNeedsBuild();
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedTotal = NumberFormat('#,###').format(widget.model.snapshot.total);
    final items = widget.model.snapshot.items;
    final summary = items.isEmpty
        ? '주문 없음'
        : items
            .take(3)
            .map((item) => '${item.name} x${item.quantity}')
            .join('\n');

    final card = MouseRegion(
      onEnter: (_) => _showOverlay(),
      onExit: (_) => _hideOverlay(),
      child: GestureDetector(
        onTap: widget.editable ? null : widget.onOrderRequested,
        onLongPress: widget.editable ? null : _toggleOverlay,
        onPanUpdate: widget.editable ? _handlePanUpdate : null,
        onPanEnd: widget.editable ? _handlePanEnd : null,
        child: CompositedTransformTarget(
          link: _layerLink,
          child: SizedBox(
            width: 200,
            height: 180,
            child: Card(
              elevation: 6,
              shadowColor: Colors.black.withOpacity(0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            widget.model.table.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (widget.model.snapshot.hasOpenOrder)
                          Icon(
                            Icons.receipt_long,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Text(
                        summary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.model.snapshot.hasOpenOrder
                          ? '합계: \u20a9$formattedTotal'
                          : '대기 중',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  void _toggleOverlay() {
    if (_overlayEntry == null) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    if (!widget.model.snapshot.hasOpenOrder || widget.editable) {
      return;
    }
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    final overlay = Overlay.of(context);
    if (overlay == null) {
      return;
    }

    _overlayEntry = OverlayEntry(builder: (context) {
      final items = widget.model.snapshot.items;
      return CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 190),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '상세 주문',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 12),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            'x${item.quantity}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
