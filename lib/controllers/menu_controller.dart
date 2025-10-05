import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pos_database.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';

final menuCategoriesProvider = FutureProvider<List<MenuCategory>>((ref) async {
  final db = ref.read(posDatabaseProvider);
  await db.open();
  return db.getCategories();
});

final menuItemsProvider = FutureProvider.family<List<MenuItem>, int>((ref, categoryId) async {
  final db = ref.read(posDatabaseProvider);
  await db.open();
  return db.getMenuItemsByCategory(categoryId);
});
