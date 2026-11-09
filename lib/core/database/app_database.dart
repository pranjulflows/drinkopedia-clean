import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drinkopedia/core/database/daos/preferences_dao.dart';
import 'package:drinkopedia/core/database/daos/spirits_dao.dart';
import 'package:drinkopedia/core/database/tables/preferences_table.dart';
import 'package:drinkopedia/core/database/tables/spirits_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [SpiritsTable, PreferencesTable],
  daos: [SpiritsDao, PreferencesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test seam: lets suites run against an in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    // v2 added the preferences store. Existing installs keep their cached
    // catalogue; only the new table is created.
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) await m.createTable(preferencesTable);
    },
  );
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    return NativeDatabase.createInBackground(
      File(p.join(dir.path, 'drinkopedia.sqlite')),
    );
  });
}
