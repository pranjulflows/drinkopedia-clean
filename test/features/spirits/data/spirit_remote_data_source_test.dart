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

  test('hydrates the catalogue from the seed list', () async {
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

    final List<SpiritDto> result = await dataSource.fetchCatalogue();

    expect(result.map((SpiritDto d) => d.name), <String>[
      'Vodka',
      'Gin',
      'Rum',
    ]);
  });

  test('one failing name does not sink the whole catalogue', () async {
    when(() => api.searchIngredient(any())).thenAnswer((Invocation call) async {
      final String name = call.positionalArguments.first as String;
      if (name == 'Grappa') throw Exception('upstream removed this entry');
      return _response(<Map<String, dynamic>>[
        <String, dynamic>{'idIngredient': name, 'strIngredient': name},
      ]);
    });

    final CocktailDbSpiritDataSource dataSource = CocktailDbSpiritDataSource(
      api: api,
      assetBundle: _SeedBundle(<String>['Vodka', 'Grappa', 'Rum']),
    );

    final List<SpiritDto> result = await dataSource.fetchCatalogue();

    expect(result.map((SpiritDto d) => d.name), <String>['Vodka', 'Rum']);
  });
}
