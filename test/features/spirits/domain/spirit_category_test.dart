import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('collapses the spellings upstream actually returns', () {
    // Both of these appear in the 44-name seed catalogue.
    expect(SpiritCategory.fromType('Whiskey'), SpiritCategory.whiskey);
    expect(SpiritCategory.fromType('Whisky'), SpiritCategory.whiskey);

    // As do both of these, which differ only in casing.
    expect(SpiritCategory.fromType('Fortified wine'), SpiritCategory.wine);
    expect(SpiritCategory.fromType('Fortified Wine'), SpiritCategory.wine);

    // Liqueur and Liquor are genuinely both present and mean the same thing
    // here, however unfortunate the pair is.
    expect(SpiritCategory.fromType('Liqueur'), SpiritCategory.liqueur);
    expect(SpiritCategory.fromType('Liquor'), SpiritCategory.liqueur);
  });

  test('folds one-off wine and beer variants into their group', () {
    expect(SpiritCategory.fromType('Rice wine'), SpiritCategory.wine);
    expect(SpiritCategory.fromType('Cider'), SpiritCategory.beerAndCider);
    expect(SpiritCategory.fromType('Beer'), SpiritCategory.beerAndCider);
  });

  test('is insensitive to case and stray whitespace', () {
    expect(SpiritCategory.fromType('  gIn '), SpiritCategory.gin);
  });

  test('upstream catch-alls, unknowns and null all become other', () {
    // 'Spirit' and 'Beverage' are real values, but they cover everything from
    // Absinthe to Tequila — there is nothing to infer from them.
    expect(SpiritCategory.fromType('Spirit'), SpiritCategory.other);
    expect(SpiritCategory.fromType('Beverage'), SpiritCategory.other);
    // New values appear upstream without warning; that must not throw.
    expect(SpiritCategory.fromType('Mead'), SpiritCategory.other);
    expect(SpiritCategory.fromType(null), SpiritCategory.other);
  });
}
