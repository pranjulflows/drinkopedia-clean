import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Spirit _spirit(String name, {String? type, double? abv, bool story = true}) =>
    Spirit(
      id: name,
      name: name,
      type: type,
      abv: abv,
      story: story ? 'The story of $name.' : null,
    );

List<String> _names(List<Spirit> spirits) =>
    spirits.map((Spirit s) => s.name).toList();

void main() {
  group('Strength.of', () {
    test('an unknown ABV has no band', () {
      expect(Strength.of(null), isNull);
    });

    test('bands meet exactly at 20% and 37.5%', () {
      expect(Strength.of(19.9), Strength.light);
      expect(Strength.of(20), Strength.medium);
      expect(Strength.of(37.4), Strength.medium);
      expect(Strength.of(37.5), Strength.strong);
      expect(Strength.of(0), Strength.light);
    });
  });

  group('matches', () {
    final Spirit gin = _spirit('Gin', type: 'Gin', abv: 40);
    final Spirit amaretto = _spirit('Amaretto', type: 'Liqueur', abv: 28);
    final Spirit ale = _spirit('Ale', type: 'Beer', abv: 4);
    final Spirit tuaca = _spirit('Tuaca', type: 'Liqueur', story: false);

    test('the default filter lets everything through', () {
      const SpiritFilter filter = SpiritFilter();

      expect(<Spirit>[gin, amaretto, ale, tuaca].every(filter.matches), isTrue);
      expect(filter.isDefault, isTrue);
    });

    test('several categories keep any of them', () {
      const SpiritFilter filter = SpiritFilter(
        categories: <SpiritCategory>{
          SpiritCategory.gin,
          SpiritCategory.beerAndCider,
        },
      );

      expect(filter.matches(gin), isTrue);
      expect(filter.matches(ale), isTrue);
      expect(filter.matches(amaretto), isFalse);
    });

    test('a strength band keeps spirits in it', () {
      const SpiritFilter filter = SpiritFilter(
        strengths: <Strength>{Strength.medium, Strength.strong},
      );

      expect(filter.matches(gin), isTrue);
      expect(filter.matches(amaretto), isTrue);
      expect(filter.matches(ale), isFalse);
    });

    test('an unknown ABV only drops out once a band is chosen', () {
      // Tuaca has no ABV upstream. With no band chosen it must still show;
      // with any band chosen it cannot be placed in one, so it goes.
      expect(const SpiritFilter().matches(tuaca), isTrue);
      expect(
        const SpiritFilter(
          strengths: <Strength>{Strength.medium},
        ).matches(tuaca),
        isFalse,
      );
    });

    test('stories only drops spirits without one', () {
      const SpiritFilter filter = SpiritFilter(storiesOnly: true);

      expect(filter.matches(gin), isTrue);
      expect(filter.matches(tuaca), isFalse);
    });

    test('every part must pass', () {
      const SpiritFilter filter = SpiritFilter(
        categories: <SpiritCategory>{SpiritCategory.liqueur},
        strengths: <Strength>{Strength.medium},
        storiesOnly: true,
      );

      expect(filter.matches(amaretto), isTrue);
      expect(filter.matches(tuaca), isFalse, reason: 'no ABV and no story');
      expect(filter.matches(gin), isFalse, reason: 'not a liqueur');
    });
  });

  group('apply', () {
    final List<Spirit> catalogue = <Spirit>[
      _spirit('Bourbon', abv: 45),
      _spirit('Amaretto', abv: 28),
      _spirit('Tuaca'),
      _spirit('Cognac', abv: 40),
      _spirit('Absinthe'),
    ];

    test('the catalogue sort keeps the order it was given', () {
      expect(_names(const SpiritFilter().apply(catalogue)), <String>[
        'Bourbon',
        'Amaretto',
        'Tuaca',
        'Cognac',
        'Absinthe',
      ]);
    });

    test('A to Z sorts by name, ignoring case', () {
      final List<Spirit> mixed = <Spirit>[
        _spirit('bourbon'),
        _spirit('Amaretto'),
        _spirit('absinthe'),
      ];

      expect(
        _names(const SpiritFilter(sort: SpiritSort.aToZ).apply(mixed)),
        <String>['absinthe', 'Amaretto', 'bourbon'],
      );
    });

    test('strongest first puts unknown ABVs last, in catalogue order', () {
      expect(
        _names(const SpiritFilter(sort: SpiritSort.strongest).apply(catalogue)),
        <String>['Bourbon', 'Cognac', 'Amaretto', 'Tuaca', 'Absinthe'],
      );
    });

    test('filters before sorting', () {
      const SpiritFilter filter = SpiritFilter(
        strengths: <Strength>{Strength.strong},
        sort: SpiritSort.aToZ,
      );

      expect(_names(filter.apply(catalogue)), <String>['Bourbon', 'Cognac']);
    });

    test('does not change the list it was given', () {
      final List<String> before = _names(catalogue);

      const SpiritFilter(sort: SpiritSort.aToZ).apply(catalogue);

      expect(_names(catalogue), before);
    });
  });

  group('activeCount', () {
    test('counts each choice a person would have ticked', () {
      const SpiritFilter filter = SpiritFilter(
        categories: <SpiritCategory>{SpiritCategory.gin, SpiritCategory.rum},
        strengths: <Strength>{Strength.strong},
        storiesOnly: true,
        sort: SpiritSort.aToZ,
      );

      expect(filter.activeCount, 5);
      expect(filter.isDefault, isFalse);
    });

    test('the catalogue sort is not a choice', () {
      expect(const SpiritFilter(sort: SpiritSort.catalogue).activeCount, 0);
      expect(const SpiritFilter(sort: SpiritSort.strongest).activeCount, 1);
    });

    test('a sort reorders without narrowing', () {
      expect(const SpiritFilter(sort: SpiritSort.aToZ).narrows, isFalse);
      expect(const SpiritFilter(storiesOnly: true).narrows, isTrue);
    });
  });

  group('withOnlyCategory', () {
    test('narrows to exactly that one, keeping the rest of the filter', () {
      const SpiritFilter filter = SpiritFilter(
        categories: <SpiritCategory>{SpiritCategory.gin, SpiritCategory.rum},
        storiesOnly: true,
      );

      final SpiritFilter next = filter.withOnlyCategory(SpiritCategory.vodka);

      expect(next.categories, <SpiritCategory>{SpiritCategory.vodka});
      expect(next.storiesOnly, isTrue);
    });

    test('tapping the only selected category clears it', () {
      const SpiritFilter filter = SpiritFilter(
        categories: <SpiritCategory>{SpiritCategory.gin},
      );

      expect(filter.withOnlyCategory(SpiritCategory.gin).categories, isEmpty);
    });

    test('tapping one of several narrows rather than clears', () {
      const SpiritFilter filter = SpiritFilter(
        categories: <SpiritCategory>{SpiritCategory.gin, SpiritCategory.rum},
      );

      expect(
        filter.withOnlyCategory(SpiritCategory.gin).categories,
        <SpiritCategory>{SpiritCategory.gin},
      );
    });

    test('null clears', () {
      const SpiritFilter filter = SpiritFilter(
        categories: <SpiritCategory>{SpiritCategory.gin},
      );

      expect(filter.withOnlyCategory(null).categories, isEmpty);
    });
  });

  test('equal filters are equal whatever order their sets were built in', () {
    expect(
      const SpiritFilter(
        categories: <SpiritCategory>{SpiritCategory.gin, SpiritCategory.rum},
      ),
      const SpiritFilter(
        categories: <SpiritCategory>{SpiritCategory.rum, SpiritCategory.gin},
      ),
    );
  });
}
