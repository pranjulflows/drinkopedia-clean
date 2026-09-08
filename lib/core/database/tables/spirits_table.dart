import 'package:drift/drift.dart';

/// Local cache of the alcohol catalogue.
///
/// Every column except [name] is nullable on purpose: TheCocktailDB frequently
/// omits `strABV` and returns an empty `strDescription` (Mezcal, for one), so
/// the schema mirrors the source rather than pretending the data is complete.
@DataClassName('SpiritRow')
class SpiritsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text().nullable()();
  RealColumn get abv => real().nullable()();
  TextColumn get story => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get isAlcoholic => boolean().withDefault(const Constant(true))();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
