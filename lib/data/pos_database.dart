import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/menu_category.dart';
import '../models/menu_item.dart';
import '../models/order_item.dart';
import '../models/pos_order.dart';
import '../models/pos_table.dart';
import '../models/sales_record.dart';
import '../utils/korean_time.dart';

final posDatabaseProvider = Provider<PosDatabase>((ref) {
  return PosDatabase();
});

class PosDatabase {
  Database? _db;

  Future<Database> open() async {
    if (_db != null) {
      return _db!;
    }

    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'pos.sqlite3');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE menus (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        FOREIGN KEY(category_id) REFERENCES categories(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE tables (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        x REAL NOT NULL,
        y REAL NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_id INTEGER NOT NULL,
        opened_at TEXT NOT NULL,
        closed_at TEXT,
        payment_method TEXT,
        total INTEGER DEFAULT 0,
        FOREIGN KEY(table_id) REFERENCES tables(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        menu_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(order_id) REFERENCES orders(id),
        FOREIGN KEY(menu_id) REFERENCES menus(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        closed_date TEXT NOT NULL,
        total INTEGER NOT NULL,
        payment_method TEXT NOT NULL,
        FOREIGN KEY(order_id) REFERENCES orders(id)
      );
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE order_items ADD COLUMN updated_at TEXT');
      final now = koreanIsoString(nowInKoreanTime());
      await db.rawUpdate(
        'UPDATE order_items SET updated_at = ? WHERE updated_at IS NULL',
        [now],
      );
    }
  }

  // ---------- Categories ----------
  Future<void> insertCategories(List<MenuCategory> categories) async {
    final db = await open();
    final batch = db.batch();
    for (final category in categories) {
      batch.insert('categories', category.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<int> addCategory(String name) async {
    final db = await open();
    return db.insert('categories', {'name': name});
  }

  Future<void> updateCategory(MenuCategory category) async {
    final db = await open();
    await db.update(
      'categories',
      {'name': category.name},
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int categoryId) async {
    final db = await open();
    await db.delete('menus', where: 'category_id = ?', whereArgs: [categoryId]);
    await db.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
  }

  Future<List<MenuCategory>> getCategories() async {
    final db = await open();
    final rows = await db.query('categories', orderBy: 'id');
    return rows.map(MenuCategory.fromMap).toList();
  }

  // ---------- Menus ----------
  Future<void> insertMenuItems(List<MenuItem> items) async {
    final db = await open();
    final batch = db.batch();
    for (final item in items) {
      batch.insert('menus', item.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<int> addMenu({
    required String name,
    required int price,
    required int categoryId,
  }) async {
    final db = await open();
    return db.insert('menus', {
      'name': name,
      'price': price,
      'category_id': categoryId,
    });
  }

  Future<void> updateMenu(MenuItem item) async {
    final db = await open();
    await db.update(
      'menus',
      {'name': item.name, 'price': item.price, 'category_id': item.categoryId},
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteMenu(int menuId) async {
    final db = await open();
    await db.delete('order_items', where: 'menu_id = ?', whereArgs: [menuId]);
    await db.delete('menus', where: 'id = ?', whereArgs: [menuId]);
  }

  Future<List<MenuItem>> getMenuItemsByCategory(int categoryId) async {
    final db = await open();
    final rows = await db.query(
      'menus',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name',
    );
    return rows.map(MenuItem.fromMap).toList();
  }

  // ---------- Tables ----------
  Future<void> insertTables(List<PosTable> tables) async {
    final db = await open();
    final batch = db.batch();
    for (final table in tables) {
      batch.insert('tables', table.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<int> addTable({
    required String name,
    required double x,
    required double y,
  }) async {
    final db = await open();
    return db.insert('tables', {'name': name, 'x': x, 'y': y});
  }

  Future<void> updateTable(PosTable table) async {
    final db = await open();
    await db.update(
      'tables',
      {'name': table.name, 'x': table.x, 'y': table.y},
      where: 'id = ?',
      whereArgs: [table.id],
    );
  }

  Future<void> deleteTable(int tableId) async {
    final db = await open();
    final orderRows = await db.query(
      'orders',
      columns: ['id'],
      where: 'table_id = ?',
      whereArgs: [tableId],
    );
    for (final row in orderRows) {
      final orderId = row['id'] as int;
      await db.delete('order_items', where: 'order_id = ?', whereArgs: [orderId]);
      await db.delete('sales', where: 'order_id = ?', whereArgs: [orderId]);
    }
    await db.delete('orders', where: 'table_id = ?', whereArgs: [tableId]);
    await db.delete('tables', where: 'id = ?', whereArgs: [tableId]);
  }

  Future<List<PosTable>> getTables() async {
    final db = await open();
    final rows = await db.query('tables', orderBy: 'id');
    return rows.map(PosTable.fromMap).toList();
  }

  Future<void> updateTablePosition({
    required int tableId,
    required double x,
    required double y,
  }) async {
    final db = await open();
    await db.update('tables', {'x': x, 'y': y}, where: 'id = ?', whereArgs: [tableId]);
  }

  // ---------- Orders ----------
  Future<PosOrder?> getOpenOrderForTable(int tableId) async {
    final db = await open();
    final rows = await db.query(
      'orders',
      where: 'table_id = ? AND closed_at IS NULL',
      whereArgs: [tableId],
      orderBy: 'opened_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PosOrder.fromMap(rows.first);
  }

  Future<int> createOrder(int tableId) async {
    final db = await open();
    final openedAt = koreanIsoString(nowInKoreanTime());
    return db.insert('orders', {
      'table_id': tableId,
      'opened_at': openedAt,
    });
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await open();
    final rows = await db.rawQuery('''
      SELECT order_items.id, order_items.order_id, order_items.menu_id,
             order_items.quantity, order_items.unit_price, order_items.updated_at,
             menus.name
      FROM order_items
      JOIN menus ON menus.id = order_items.menu_id
      WHERE order_items.order_id = ?
      ORDER BY order_items.id ASC
    ''', [orderId]);

    return rows.map(OrderItem.fromJoinedMap).toList();
  }

  Future<void> upsertOrderItem({
    required int orderId,
    required MenuItem menu,
    int quantity = 1,
  }) async {
    final db = await open();
    final existing = await db.query(
      'order_items',
      where: 'order_id = ? AND menu_id = ?',
      whereArgs: [orderId, menu.id],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('order_items', {
        'order_id': orderId,
        'menu_id': menu.id,
        'quantity': quantity,
        'unit_price': menu.price,
        'updated_at': koreanIsoString(nowInKoreanTime()),
      });
    } else {
      final currentQty = existing.first['quantity'] as int;
      await db.update(
        'order_items',
        {
          'quantity': currentQty + quantity,
          'updated_at': koreanIsoString(nowInKoreanTime()),
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  Future<void> updateOrderItemQuantity({
    required int orderItemId,
    required int quantity,
  }) async {
    final db = await open();
    if (quantity <= 0) {
      await db.delete('order_items', where: 'id = ?', whereArgs: [orderItemId]);
    } else {
      await db.update(
        'order_items',
        {
          'quantity': quantity,
          'updated_at': koreanIsoString(nowInKoreanTime()),
        },
        where: 'id = ?',
        whereArgs: [orderItemId],
      );
    }
  }

  Future<void> closeOrder({
    required int orderId,
    required int total,
    required String paymentMethod,
  }) async {
    final db = await open();
    final closedAt = koreanIsoString(nowInKoreanTime());

    await db.update(
      'orders',
      {
        'closed_at': closedAt,
        'payment_method': paymentMethod,
        'total': total,
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );

    await db.insert('sales', {
      'order_id': orderId,
      'closed_date': closedAt,
      'total': total,
      'payment_method': paymentMethod,
    });
  }

  Future<void> updateSaleRecord({
    required int saleId,
    required int total,
    required String paymentMethod,
    required DateTime closedDate,
  }) async {
    final db = await open();
    final rows = await db.query(
      'sales',
      columns: ['order_id'],
      where: 'id = ?',
      whereArgs: [saleId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return;
    }

    final orderId = rows.first['order_id'] as int;
    final closedIso = koreanIsoString(closedDate);

    await db.update(
      'sales',
      {
        'total': total,
        'payment_method': paymentMethod,
        'closed_date': closedIso,
      },
      where: 'id = ?',
      whereArgs: [saleId],
    );

    await db.update(
      'orders',
      {
        'total': total,
        'payment_method': paymentMethod,
        'closed_at': closedIso,
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // ---------- Sales ----------
  Future<List<SalesRecord>> getSalesForDate(DateTime date) async {
    final db = await open();
    final start = koreanIsoString(startOfKoreanDay(date));
    final end = koreanIsoString(startOfKoreanDay(date).add(const Duration(days: 1)));

    final rows = await db.rawQuery('''
      SELECT sales.id, sales.order_id, sales.total, sales.payment_method,
             sales.closed_date, tables.name AS table_name
      FROM sales
      JOIN orders ON orders.id = sales.order_id
      JOIN tables ON tables.id = orders.table_id
      WHERE sales.closed_date >= ? AND sales.closed_date < ?
      ORDER BY sales.closed_date DESC
    ''', [start, end]);

    return rows.map(SalesRecord.fromJoinedMap).toList();
  }

  Future<TableOrderSnapshot> getTableOrderSnapshot(int tableId) async {
    final db = await open();
    final order = await getOpenOrderForTable(tableId);
    if (order == null) {
      return const TableOrderSnapshot.empty();
    }

    final rows = await db.rawQuery('''
      SELECT menus.name, order_items.quantity, order_items.unit_price
      FROM order_items
      JOIN menus ON menus.id = order_items.menu_id
      WHERE order_items.order_id = ?
    ''', [order.id]);

    final items = rows
        .map((row) => TableOrderItem(
              name: row['name'] as String,
              quantity: row['quantity'] as int,
              total: (row['quantity'] as int) * (row['unit_price'] as int),
            ))
        .toList();
    final total = items.fold<int>(0, (sum, item) => sum + item.total);
    return TableOrderSnapshot(
      orderId: order.id!,
      total: total,
      items: items,
    );
  }
}

class TableOrderSnapshot {
  const TableOrderSnapshot({
    required this.orderId,
    required this.total,
    required this.items,
  });

  const TableOrderSnapshot.empty()
      : orderId = null,
        total = 0,
        items = const [];

  final int? orderId;
  final int total;
  final List<TableOrderItem> items;

  bool get hasOpenOrder => orderId != null;
}

class TableOrderItem {
  const TableOrderItem({
    required this.name,
    required this.quantity,
    required this.total,
  });

  final String name;
  final int quantity;
  final int total;
}
