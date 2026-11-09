import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';
import 'package:drinkopedia/l10n/app_localizations.dart';

/// The user-facing name of a category.
///
/// Lives in presentation, not on the enum: [SpiritCategory] is domain and stays
/// pure Dart, and these names are translated copy rather than data.
String categoryLabel(AppLocalizations l10n, SpiritCategory category) {
  return switch (category) {
    SpiritCategory.whiskey => l10n.categoryWhiskey,
    SpiritCategory.rum => l10n.categoryRum,
    SpiritCategory.gin => l10n.categoryGin,
    SpiritCategory.vodka => l10n.categoryVodka,
    SpiritCategory.tequila => l10n.categoryTequila,
    SpiritCategory.brandy => l10n.categoryBrandy,
    SpiritCategory.liqueur => l10n.categoryLiqueur,
    SpiritCategory.wine => l10n.categoryWine,
    SpiritCategory.beerAndCider => l10n.categoryBeerAndCider,
    SpiritCategory.aperitif => l10n.categoryAperitif,
    SpiritCategory.other => l10n.categoryOther,
  };
}
