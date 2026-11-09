import 'package:drinkopedia/features/onboarding/domain/entities/taste_preference.dart';

/// Reads and writes the taste intro's answer.
///
/// Local only — there is no account and nothing is sent anywhere, which is what
/// the intro screen promises the user.
abstract class TasteRepository {
  Future<TastePreference> load();

  Future<void> save(TastePreference preference);
}
