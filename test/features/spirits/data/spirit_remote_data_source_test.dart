import 'dart:convert';

import 'package:drinkopedia/features/spirits/data/datasources/cocktail_db_api.dart';
import 'package:drinkopedia/features/spirits/data/datasources/spirit_remote_data_source.dart';
import 'package:drinkopedia/features/spirits/data/models/spirit_dto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements CocktailDbApi {}

/// Serves the seed list from memory instead of the real asset bundle.
class _SeedBundle extends CachingAssetBundle {
  _SeedBundle(this.names);

  final List<String> names;

  @override
  Future<ByteData> load(String key) async {
    final Uint8List bytes = Uint8List.fromList(
      utf8.encode(jsonEncode(<String, dynamic>{'spirits': names})),
    );
    return ByteData.view(bytes.buffer);
  }
}

IngredientResponse _response(List<Map<String, dynamic>>? rows) =>
    IngredientResponse.fromJson(<String, dynamic>{'ingredients': rows});

void main() {
  late _MockApi api;

  setUp(() => api = _MockApi());

  test('returns the first usable ingredient', () async {
    when(() => api.searchIngredient('Vodka')).thenAnswer(
      (_) async => _response(<Map<String, dynamic>>[
        <String, dynamic>{'idIngredient': '1', 'strIngredient': 'Vodka'},
      ]),
    );

    final CocktailDbSpiritDataSource dataSource = CocktailDbSpiritDataSource(
      api: api,
    );

    expect((await dataSource.fetchByName('Vodka'))?.name, 'Vodka');
  });

  test('a null collection yields null rather than throwing', () async {
    when(
      () => api.searchIngredient(any()),
    ).thenAnswer((_) async => _response(null));

    final CocktailDbSpiritDataSource dataSource = CocktailDbSpiritDataSource(
      api: api,
    );

    await expectLater(
      dataSource.fetchByName('Nonexistent'),
      completion(isNull),
    );
  });

  test('reads the seed list in order', () async {
    final CocktailDbSpiritDataSource dataSource = CocktailDbSpiritDataSource(
      api: api,
      assetBundle: _SeedBundle(<String>['Vodka', 'Gin', 'Rum']),
    );

    expect(await dataSource.loadSeedNames(), <String>['Vodka', 'Gin', 'Rum']);
  });

  test('hydrates exactly the names it is given', () async {
    when(() => api.searchIngredient(any())).thenAnswer((Invocation call) async {
      final String name = call.positionalArguments.first as String;
      return _response(<Map<String, dynamic>>[
        <String, dynamic>{'idIngredient': name, 'strIngredient': name},
      ]);
    });

    final CocktailDbSpiritDataSource dataSource = CocktailDbSpiritDataSource(
      api: api,
      assetBundle: _SeedBundle(<String>['Vodka', 'Gin', 'Rum']),
    );

    final Hydration result = await dataSource.fetchByNames(<String>[
      'Gin',
      'Rum',
    ]);

    expect(result.spirits.map((SpiritDto d) => d.name), <String>['Gin', 'Rum']);
    expect(result.failed, isEmpty);
    // A page asks for its own names and nothing else.
    verifyNever(() => api.searchIngredient('Vodka'));
  });

  test('a failing name is reported, and does not sink the page', () async {
    final Exception throttled = Exception('429');
    when(() => api.searchIngredient(any())).thenAnswer((Invocation call) async {
      final String name = call.positionalArguments.first as String;
      if (name == 'Grappa') throw throttled;
      return _response(<Map<String, dynamic>>[
        <String, dynamic>{'idIngredient': name, 'strIngredient': name},
      ]);
    });

    final CocktailDbSpiritDataSource dataSource = CocktailDbSpiritDataSource(
      api: api,
      assetBundle: _SeedBundle(<String>[]),
    );

    final Hydration result = await dataSource.fetchByNames(<String>[
      'Vodka',
      'Grappa',
      'Rum',
    ]);

    expect(result.spirits.map((SpiritDto d) => d.name), <String>[
      'Vodka',
      'Rum',
    ]);
    // Reported, not dropped: a failed request says nothing about whether
    // Grappa exists.
    expect(result.failed, <String>['Grappa']);
    expect(result.error, same(throttled));
  });

  test('a name upstream does not know is absent, not failed', () async {
    when(
      () => api.searchIngredient(any()),
    ).thenAnswer((_) async => _response(null));

    final CocktailDbSpiritDataSource dataSource = CocktailDbSpiritDataSource(
      api: api,
      assetBundle: _SeedBundle(<String>[]),
    );

    final Hydration result = await dataSource.fetchByNames(<String>['Soju']);

    expect(result.spirits, isEmpty);
    expect(result.failed, isEmpty);
  });

  test('looks a single spirit up by id', () async {
    when(() => api.lookupIngredient('42')).thenAnswer(
      (_) async => _response(<Map<String, dynamic>>[
        <String, dynamic>{'idIngredient': '42', 'strIngredient': 'Mezcal'},
      ]),
    );

    final CocktailDbSpiritDataSource dataSource = CocktailDbSpiritDataSource(
      api: api,
      assetBundle: _SeedBundle(<String>[]),
    );

    final SpiritDto? dto = await dataSource.fetchById('42');

    expect(dto?.name, 'Mezcal');
    verifyNever(() => api.searchIngredient(any()));
  });
}
