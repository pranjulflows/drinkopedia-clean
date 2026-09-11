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

  /// The cached rows for [names], in no particular order.
  ///
  /// The catalogue is paged by seed name, not by id, so this is how a page
  /// finds out which of its entries it already has.
  Future<List<SpiritRow>> getByNames(List<String> names) {
    if (names.isEmpty) return Future<List<SpiritRow>>.value(<SpiritRow>[]);
    return (select(
      spiritsTable,
    )..where(($SpiritsTableTable t) => t.name.isIn(names))).get();
  }

  /// Inserts or refreshes [rows] in one transaction, leaving every other row
  /// alone.
  ///
  /// Deliberately not a replace. The catalogue arrives a page at a time, and
  /// clearing the table on each write would throw away every page but the one
  /// just loaded.
  Future<void> upsertAll(Iterable<SpiritsTableCompanion> rows) {
    return batch(
      (Batch batch) => batch.insertAllOnConflictUpdate(spiritsTable, rows),
    );
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
