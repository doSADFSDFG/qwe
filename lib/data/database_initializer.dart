import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'pos_database.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';
import '../models/pos_table.dart';

final databaseInitializerProvider = Provider<DatabaseInitializer>((ref) {
  return DatabaseInitializer(ref);
});

class DatabaseInitializer {
  DatabaseInitializer(this._ref);

  final Ref _ref;
  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final posDb = _ref.read(posDatabaseProvider);
    await posDb.open();
    await _seedIfNeeded(posDb);
    _initialized = true;
  }

  Future<void> _seedIfNeeded(PosDatabase db) async {
    final categories = await db.getCategories();
    if (categories.isNotEmpty) {
      return;
    }

    await db.insertCategories([
      const MenuCategory(id: 1, name: '주류'),
      const MenuCategory(id: 2, name: '안주'),
      const MenuCategory(id: 3, name: '과일'),
    ]);

    await db.insertMenuItems([
      const MenuItem(
        id: 1,
        name: '생맥주',
        price: 5000,
        categoryId: 1,
      ),
      const MenuItem(
        id: 2,
        name: '소주',
        price: 4500,
        categoryId: 1,
      ),
      const MenuItem(
        id: 3,
        name: '골뱅이 무침',
        price: 15000,
        categoryId: 2,
      ),
      const MenuItem(
        id: 4,
        name: '치즈 플래터',
        price: 18000,
        categoryId: 2,
      ),
      const MenuItem(
        id: 5,
        name: '계절 과일',
        price: 12000,
        categoryId: 3,
      ),
    ]);

    await db.insertTables(const [
      PosTable(id: 1, name: '1번', x: 80, y: 60),
      PosTable(id: 2, name: '2번', x: 260, y: 60),
      PosTable(id: 3, name: '3번', x: 440, y: 60),
      PosTable(id: 4, name: '4번', x: 80, y: 200),
      PosTable(id: 5, name: '5번', x: 440, y: 200),
      PosTable(id: 6, name: '6번', x: 200, y: 320),
      PosTable(id: 7, name: '7번', x: 360, y: 320),
      PosTable(id: 8, name: '8번', x: 540, y: 220),
    ]);
  }
}
