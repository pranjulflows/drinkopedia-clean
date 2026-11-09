import 'package:drinkopedia/core/database/daos/preferences_dao.dart';
import 'package:drinkopedia/features/onboarding/domain/entities/taste_preference.dart';
import 'package:drinkopedia/features/onboarding/domain/repositories/taste_repository.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';

/// Drift-backed taste preference.
///
/// Categories are stored as a comma-separated list of enum names. A name that
/// no longer exists — a category renamed or dropped in a later version — is
/// skipped rather than throwing, so an old row can never wedge the app on the
/// intro screen.
class TasteRepositoryImpl implements TasteRepository {
  TasteRepositoryImpl({required this.dao});

  final PreferencesDao dao;

  static const String completedKey = 'taste.completed';
  static const String categoriesKey = 'taste.categories';

  @override
  Future<TastePreference> load() async {
    final String? completed = await dao.read(completedKey);
    if (completed != 'true') return const TastePreference.untouched();

    final String raw = await dao.read(categoriesKey) ?? '';
    final Set<SpiritCategory> categories = raw
        .split(',')
        .map((String name) => name.trim())
        .where((String name) => name.isNotEmpty)
        .map(_categoryOrNull)
        .nonNulls
        .toSet();

    return TastePreference(completed: true, categories: categories);
  }

  @override
  Future<void> save(TastePreference preference) async {
    await dao.write(completedKey, preference.completed ? 'true' : 'false');
    await dao.write(
      categoriesKey,
      preference.categories.map((SpiritCategory c) => c.name).join(','),
    );
  }

  static SpiritCategory? _categoryOrNull(String name) {
    for (final SpiritCategory category in SpiritCategory.values) {
      if (category.name == name) return category;
    }
    return null;
  }
}
