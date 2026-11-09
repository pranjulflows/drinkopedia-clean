import 'package:drinkopedia/features/spirits/data/models/spirit_dto.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:flutter_test/flutter_test.dart';

/// The upstream payload is genuinely messy, so the DTO and its converters are
/// where most of the real risk in the data layer lives.
void main() {
  group('SpiritDto.fromJson', () {
    test('maps a complete record', () {
      final Spirit spirit = SpiritDto.fromJson(<String, dynamic>{
        'idIngredient': '1',
        'strIngredient': 'Vodka',
        'strType': 'Vodka',
        'strABV': '40',
        'strDescription': 'Vodka is a distilled beverage...',
        'strAlcohol': 'Yes',
      }).toEntity();

      expect(spirit.id, '1');
      expect(spirit.name, 'Vodka');
      expect(spirit.abv, 40.0);
      expect(spirit.isAlcoholic, isTrue);
      expect(spirit.hasStory, isTrue);
      expect(spirit.imageUrl, contains('Vodka-Medium.png'));
    });

    test('treats JSON null, the string "null" and "" as absent', () {
      // All three spellings of "no value" appear in real responses.
      final Spirit spirit = SpiritDto.fromJson(<String, dynamic>{
        'idIngredient': '552',
        'strIngredient': 'Mezcal',
        'strType': null,
        'strABV': 'null',
        'strDescription': '',
        'strAlcohol': 'Yes',
      }).toEntity();

      expect(spirit.type, isNull);
      expect(spirit.abv, isNull);
      expect(spirit.story, isNull);
      expect(spirit.hasStory, isFalse);
      expect(spirit.hasAbv, isFalse);
    });

    test('does not throw on an unparseable ABV', () {
      final Spirit spirit = SpiritDto.fromJson(<String, dynamic>{
        'idIngredient': '9',
        'strIngredient': 'Mystery',
        'strABV': 'about 40',
      }).toEntity();

      expect(spirit.abv, isNull);
    });

    test('corrects upstream\'s "Liquer" spelling, and nothing else', () {
      String? typeOf(Object? raw) => SpiritDto.fromJson(<String, dynamic>{
        'idIngredient': '9',
        'strIngredient': 'Pernod',
        'strType': raw,
      }).type;

      expect(typeOf('Liquer'), 'Liqueur');
      expect(typeOf('liquer'), 'Liqueur');
      expect(typeOf('Liqueur'), 'Liqueur');
      expect(typeOf('Fortified Wine'), 'Fortified Wine');
      expect(typeOf('null'), isNull);
    });

    test('accepts a numeric ABV as well as a string one', () {
      expect(
        SpiritDto.fromJson(<String, dynamic>{
          'idIngredient': '9',
          'strIngredient': 'X',
          'strABV': 37.5,
        }).abv,
        37.5,
      );
    });

    test('only an explicit "No" marks an entry non-alcoholic', () {
      Spirit build(Object? flag) => SpiritDto.fromJson(<String, dynamic>{
        'idIngredient': '1',
        'strIngredient': 'X',
        'strAlcohol': flag,
      }).toEntity();

      expect(build('No').isAlcoholic, isFalse);
      expect(build('Yes').isAlcoholic, isTrue);
      expect(build(null).isAlcoholic, isTrue);
    });

    test('records missing an id or name are not usable', () {
      expect(
        SpiritDto.fromJson(<String, dynamic>{
          'idIngredient': '',
          'strIngredient': '',
        }).isUsable,
        isFalse,
      );
    });
  });

  group('IngredientResponse', () {
    test('a null collection is an empty result, not an error', () {
      // TheCocktailDB signals a miss with {"ingredients": null} rather than a
      // 404. Treating that as an error was the bug in the old envelope model.
      final IngredientResponse response = IngredientResponse.fromJson(
        <String, dynamic>{'ingredients': null},
      );

      expect(response.items, isEmpty);
    });

    test('filters out unusable rows', () {
      final IngredientResponse response = IngredientResponse.fromJson(
        <String, dynamic>{
          'ingredients': <Map<String, dynamic>>[
            <String, dynamic>{'idIngredient': '1', 'strIngredient': 'Gin'},
            <String, dynamic>{'idIngredient': '', 'strIngredient': ''},
          ],
        },
      );

      expect(response.items.length, 1);
      expect(response.items.single.name, 'Gin');
    });
  });

  group('Spirit.storyExcerpt', () {
    test('returns null when there is no story', () {
      const Spirit spirit = Spirit(id: '1', name: 'X');
      expect(spirit.storyExcerpt, isNull);
    });

    test('cuts at the first paragraph break', () {
      const Spirit spirit = Spirit(
        id: '1',
        name: 'X',
        story: 'First paragraph.\n\nSecond paragraph.',
      );
      expect(spirit.storyExcerpt, 'First paragraph.');
    });

    test('truncates a long single paragraph with an ellipsis', () {
      final Spirit spirit = Spirit(id: '1', name: 'X', story: 'a' * 500);
      expect(spirit.storyExcerpt!.length, lessThanOrEqualTo(240));
      expect(spirit.storyExcerpt, endsWith('…'));
    });
  });
}
