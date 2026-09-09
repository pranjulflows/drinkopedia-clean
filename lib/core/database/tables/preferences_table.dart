import 'package:drift/drift.dart';

/// Small key/value store for on-device settings.
///
/// `shared_preferences` is not a dependency and `flutter_secure_storage` is for
/// secrets, so drift — already wired for the catalogue cache — carries this
/// too. Values are strings; callers own their own encoding.
@DataClassName('PreferenceRow')
class PreferencesTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
