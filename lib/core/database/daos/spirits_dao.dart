import 'package:drift/drift.dart';
import 'package:drinkopedia/core/database/app_database.dart';
import 'package:drinkopedia/core/database/tables/spirits_table.dart';

part 'spirits_dao.g.dart';

@DriftAccessor(tables: [SpiritsTable])
class SpiritsDao extends DatabaseAccessor<AppDatabase> with _$SpiritsDaoMixin {
  SpiritsDao(super.db);

  Future<List<SpiritRow>> getAll() => select(spiritsTable).get();

  Stream<List<SpiritRow>> watchAll() => select(spiritsTable).watch();

  Future<SpiritRow?> getById(String id) => (select(
    spiritsTable,
  )..where(($SpiritsTableTable t) => t.id.equals(id))).getSingleOrNull();

  /// Replaces the catalogue in one transaction, so a failed refresh can never
  /// leave a half-populated cache behind.
  Future<void> replaceAll(Iterable<SpiritsTableCompanion> rows) {
    return transaction(() async {
      await delete(spiritsTable).go();
      await batch((Batch batch) => batch.insertAll(spiritsTable, rows));
    });
  }

  Future<void> upsert(SpiritsTableCompanion row) =>
      into(spiritsTable).insertOnConflictUpdate(row);

  Future<int> count() async {
    final Expression<int> countExp = spiritsTable.id.count();
    final TypedResult row = await (selectOnly(
      spiritsTable,
    )..addColumns(<Expression<Object>>[countExp])).getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Age of the cache, used to decide whether a background refresh is due.
  Future<DateTime?> oldestCachedAt() async {
    final Expression<DateTime> minExp = spiritsTable.cachedAt.min();
    final TypedResult row = await (selectOnly(
      spiritsTable,
    )..addColumns(<Expression<Object>>[minExp])).getSingle();
    return row.read(minExp);
  }
}
