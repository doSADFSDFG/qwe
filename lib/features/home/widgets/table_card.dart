import 'dart:async';
import 'package:flutter/gestures.dart';
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
  OverlayEntry? _overlayEntry;
  Timer? _hoverTimer;

  static const _drinkCategoryName = '주류';

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
    _hoverTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedTotal = NumberFormat('#,###').format(widget.model.snapshot.total);
    final items = widget.model.snapshot.items;
    final drinkItems = _drinkItems(items);

    final summary = () {
      if (items.isEmpty) return '주문 없음';
      if (drinkItems.isEmpty) return '주류 주문 없음';
      return drinkItems.map((item) => '${item.name} x${item.quantity}').join('\n');
    }();

    final card = MouseRegion(
      onEnter: _handleHoverStart,
      onExit: _handleHoverEnd,
      child: GestureDetector(
        onTap: widget.editable ? null : widget.onOrderRequested,
        onLongPress: widget.editable ? null : _toggleOverlay,
        onPanUpdate: widget.editable ? _handlePanUpdate : null,
        onPanEnd: widget.editable ? _handlePanEnd : null,
        child: Card(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 200,
              maxWidth: 260,
              maxHeight: 420,
            ),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.9),
                  Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 내용에 따라 카드 높이 자동 조정
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
                        Icons.local_bar,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      summary,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            height: 1.4,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            fontSize: 17,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.model.snapshot.hasOpenOrder
                      ? '합계: \u20a9$formattedTotal'
                      : '대기 중',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
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

  void _toggleOverlay() {
    if (_overlayEntry == null) {
      _hoverTimer?.cancel();
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _handleHoverStart(PointerEnterEvent event) {
    if (widget.editable || !widget.model.snapshot.hasOpenOrder) return;
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _showOverlay();
    });
  }

  void _handleHoverEnd(PointerExitEvent event) {
    _hoverTimer?.cancel();
    _hoverTimer = null;
    _hideOverlay();
  }

  void _showOverlay() {
    // 🔸 주문이 없거나 편집 모드일 때는 표시 안 함
    if (!widget.model.snapshot.hasOpenOrder || widget.editable) return;
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    // ✅ 이제 전체 주문을 가져옴 (주류만이 아니라)
    final allItems = widget.model.snapshot.items;
    final numberFormat = NumberFormat('#,###');

    _overlayEntry = OverlayEntry(builder: (context) {
      return IgnorePointer(
        child: Container(
          alignment: Alignment.center,
          color: Colors.black.withOpacity(0.08),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 680, maxHeight: 520),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '전체 주문 내역',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: allItems.isEmpty
                          ? const Center(
                              child: Text(
                                '주문 항목이 없습니다.',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.25),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: ScrollConfiguration(
                                behavior: const MaterialScrollBehavior().copyWith(
                                  dragDevices: {
                                    PointerDeviceKind.touch,
                                    PointerDeviceKind.mouse,
                                  },
                                ),
                                child: Scrollbar(
                                  thumbVisibility: true,
                                  child: GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childAspectRatio: 1.9,
                                    ),
                                    itemCount: allItems.length,
                                    itemBuilder: (context, index) {
                                      final item = allItems[index];
                                      return DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(22),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.04),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
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
                                                '\u20a9${numberFormat.format(item.total)}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
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
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '총 결제금액: \u20a9${numberFormat.format(widget.model.snapshot.total)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
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

  List<TableOrderItem> _drinkItems(List<TableOrderItem> items) {
    return items.where((item) => item.categoryName == _drinkCategoryName).toList();
  }
}
