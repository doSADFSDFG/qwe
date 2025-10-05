import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pos_database.dart';
import '../models/pos_table.dart';

final tableCardsProvider = FutureProvider<List<TableCardModel>>((ref) async {
  final database = ref.read(posDatabaseProvider);
  await database.open();
  final tables = await database.getTables();
  final results = <TableCardModel>[];
  for (final table in tables) {
    final snapshot = await database.getTableOrderSnapshot(table.id);
    results.add(TableCardModel(table: table, snapshot: snapshot));
  }
  return results;
});

final tableEditModeProvider = StateProvider<bool>((ref) => false);

class TableCardModel {
  TableCardModel({
    required this.table,
    required this.snapshot,
  });

  final PosTable table;
  final TableOrderSnapshot snapshot;
}
