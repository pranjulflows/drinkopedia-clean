import 'package:drift/drift.dart';
import 'package:drinkopedia/core/database/app_database.dart';
import 'package:drinkopedia/core/database/tables/preferences_table.dart';

part 'preferences_dao.g.dart';

@DriftAccessor(tables: [PreferencesTable])
class PreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$PreferencesDaoMixin {
  PreferencesDao(super.db);

  Future<String?> read(String key) async {
    final PreferenceRow? row =
        await (select(preferencesTable)
              ..where(($PreferencesTableTable t) => t.key.equals(key)))
            .getSingleOrNull();
    return row?.value;
  }

  Future<void> write(String key, String value) =>
      into(preferencesTable).insertOnConflictUpdate(
        PreferencesTableCompanion.insert(key: key, value: value),
      );
}
