import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pos_database.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';
import '../models/pos_table.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.read(posDatabaseProvider));
});

class SettingsRepository {
  SettingsRepository(this._database);

  final PosDatabase _database;

  Future<void> ensureOpen() => _database.open();

  Future<List<MenuCategory>> getCategories() => _database.getCategories();

  Future<List<MenuItem>> getMenuItems(int categoryId) =>
      _database.getMenuItemsByCategory(categoryId);

  Future<List<PosTable>> getTables() => _database.getTables();
}
