// End-to-end tests for the spirits slice.
//
// These drive the real widget tree — DI graph, go_router, drift (in memory) and
// the screens — with only the retrofit API stubbed. That is deliberate: each
// layer is unit-tested on its own, so the value here is in how they fit
// together.

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:drinkopedia/app/app.dart';
import 'package:drinkopedia/core/database/app_database.dart';
import 'package:drinkopedia/features/spirits/data/datasources/cocktail_db_api.dart';
import 'package:drinkopedia/features/spirits/data/datasources/spirit_remote_data_source.dart';
import 'package:drinkopedia/features/spirits/data/models/spirit_dto.dart';
import 'package:drinkopedia/features/spirits/presentation/screens/spirit_detail_screen.dart';
import 'package:drinkopedia/features/spirits/presentation/screens/spirits_screen.dart';
import 'package:drinkopedia/features/spirits/presentation/widgets/spirit_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Canned TheCocktailDB client — no test touches the network.
class _FakeCocktailDbApi implements CocktailDbApi {
  _FakeCocktailDbApi(this.byName);

  final Map<String, Map<String, dynamic>> byName;
  int requestCount = 0;

  IngredientResponse _lookup(bool Function(Map<String, dynamic>) matches) {
    requestCount++;
    final Iterable<Map<String, dynamic>> hits = byName.values.where(matches);
    return IngredientResponse.fromJson(<String, dynamic>{
      // A miss is `{"ingredients": null}` upstream, not a 404.
      'ingredients': hits.isEmpty ? null : hits.toList(),
    });
  }

  @override
  Future<IngredientResponse> searchIngredient(String name) async =>
      _lookup((Map<String, dynamic> r) => r['strIngredient'] == name);

  @override
  Future<IngredientResponse> lookupIngredient(String id) async =>
      _lookup((Map<String, dynamic> r) => r['idIngredient'] == id);
}

Map<String, dynamic> _ingredient(
  String id,
  String name, {
  String? type,
  String? abv,
  String? description,
}) => <String, dynamic>{
  'idIngredient': id,
  'strIngredient': name,
  'strType': type,
  'strABV': abv,
  'strDescription': description,
  'strAlcohol': 'Yes',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, Map<String, dynamic>> catalogue =
      <String, Map<String, dynamic>>{
        'Vodka': _ingredient(
          '1',
          'Vodka',
          type: 'Vodka',
          abv: '40',
          description: 'Vodka is a distilled beverage from Eastern Europe.',
        ),
        // No description upstream — exercises the graceful-degradation path.
        'Mezcal': _ingredient('2', 'Mezcal', type: 'Spirit'),
      };

  late AppDatabase db;
  late _FakeCocktailDbApi api;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    api = _FakeCocktailDbApi(catalogue);

    // Shrink the shipped seed list to the two fixtures above.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final String key = utf8.decode(
            message!.buffer.asUint8List(
              message.offsetInBytes,
              message.lengthInBytes,
            ),
          );
          if (key != CocktailDbSpiritDataSource.seedAssetPath) return null;
          final Uint8List bytes = Uint8List.fromList(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'spirits': <String>['Vodka', 'Mezcal'],
              }),
            ),
          );
          return ByteData.view(bytes.buffer);
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    await db.close();
  });

  /// Pumps until [finder] matches, letting real async work progress in between.
  ///
  /// Two things rule out [WidgetTester.pumpAndSettle] here. The loading
  /// skeleton shimmers on an indefinitely repeating controller, so the tree
  /// never goes quiescent. More importantly, drift performs genuine
  /// asynchronous I/O, which does not advance under the tester's fake clock —
  /// [WidgetTester.runAsync] is what lets those futures actually complete.
  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int maxAttempts = 60,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Advances a few frames so in-flight transitions land.
  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpApp(WidgetTester tester, {String? initialLocation}) async {
    // The first frame schedules a post-frame callback that kicks off the
    // catalogue load. That chain ends in drift I/O, which is genuinely
    // asynchronous and does not advance under the tester's fake clock — so the
    // mount has to happen inside runAsync for those futures to complete.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        DrinkopediaApp(
          database: db,
          initialLocation: initialLocation,
          cocktailDbApi: api,
        ),
      );
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await settle(tester);
  }

  testWidgets('catalogue loads and renders cards', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.byType(SpiritsScreen), findsOneWidget);
    expect(find.byType(SpiritCard), findsNWidgets(2));
    expect(find.text('Vodka'), findsWidgets);
    expect(find.text('Mezcal'), findsWidgets);
  });

  testWidgets('tapping a card opens its detail and story', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Vodka').first);
    await pumpUntil(tester, find.byType(SpiritDetailScreen));
    await settle(tester);

    expect(find.byType(SpiritDetailScreen), findsOneWidget);
    expect(find.text('The Story'), findsOneWidget);
    expect(
      find.textContaining('distilled beverage from Eastern Europe'),
      findsOneWidget,
    );
  });

  testWidgets('a spirit with no story says so instead of rendering blank', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Mezcal').first);
    await pumpUntil(tester, find.byType(SpiritDetailScreen));
    await settle(tester);

    expect(find.textContaining("don't have the story"), findsOneWidget);
  });

  testWidgets('deep link to /spirits/:id resolves with no preloaded entity', (
    WidgetTester tester,
  ) async {
    // The path that actually breaks in the wild: `$extra` never survives a
    // link or a cold start, so the screen must resolve from the id alone.
    await pumpApp(tester, initialLocation: '/spirits/1');
    await settle(tester);

    expect(find.byType(SpiritDetailScreen), findsOneWidget);
    expect(
      find.textContaining('distilled beverage from Eastern Europe'),
      findsOneWidget,
    );
  });

  testWidgets('an unknown route shows the error screen', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, initialLocation: '/does-not-exist');
    await pumpUntil(tester, find.text('That page does not exist'));

    expect(find.text('That page does not exist'), findsOneWidget);
  });

  testWidgets('search filters the catalogue', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(SearchBar), 'mez');
    await settle(tester);

    expect(find.byType(SpiritCard), findsOneWidget);
    expect(find.text('Mezcal'), findsWidgets);
  });

  testWidgets('a warm cache does not refetch on relaunch', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    final int afterFirstLaunch = api.requestCount;
    expect(afterFirstLaunch, greaterThan(0));

    await pumpApp(tester);

    expect(
      api.requestCount,
      afterFirstLaunch,
      reason: 'a fresh cache must not hit the network again',
    );
  });
}
