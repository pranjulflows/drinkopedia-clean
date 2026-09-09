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
import 'package:drinkopedia/core/database/daos/preferences_dao.dart';
import 'package:drinkopedia/features/onboarding/data/repositories/taste_repository_impl.dart';
import 'package:drinkopedia/features/onboarding/domain/entities/taste_preference.dart';
import 'package:drinkopedia/features/onboarding/presentation/screens/onboarding_screen.dart';
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

/// Matches a [Text] by its content, ignoring case.
///
/// Names and headings are set in caps as a styling decision, and Flutter has no
/// text-transform — the string itself is uppercased at the call site. Asserting
/// on exact case would tie these tests to the current visual direction, which
/// is not what they are here to catch.
Finder findLabel(String text) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is Text &&
      (widget.data ?? '').toLowerCase().contains(text.toLowerCase()),
  description: 'Text containing "$text" (case-insensitive)',
);

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

  Future<void> pumpApp(
    WidgetTester tester, {
    String? initialLocation,
    bool onboarded = true,
  }) async {
    // The first frame schedules a post-frame callback that kicks off the
    // catalogue load. That chain ends in drift I/O, which is genuinely
    // asynchronous and does not advance under the tester's fake clock — so the
    // mount has to happen inside runAsync for those futures to complete.
    await tester.runAsync(() async {
      // Default: pretend the taste intro has already been through. Every test
      // below is about the catalogue, and a fresh in-memory database would
      // otherwise open on the intro instead.
      if (onboarded) {
        await TasteRepositoryImpl(
          dao: PreferencesDao(db),
        ).save(const TastePreference(completed: true));
      }
      await tester.pumpWidget(
        DrinkopediaApp(
          database: db,
          initialLocation: initialLocation,
          cocktailDbApi: api,
        ),
      );
      // Startup is two async hops, not one, and both are real I/O that only
      // advances inside runAsync. First the app reads whether the taste intro
      // has been through and only then builds the router; the catalogue screen
      // it mounts *then* schedules its own load.
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await settle(tester);
  }

  testWidgets('a first launch opens the taste intro, not the catalogue', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, onboarded: false);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(SpiritsScreen), findsNothing);
  });

  testWidgets('a later launch goes straight to the catalogue', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(SpiritsScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('a deep link on a first launch still goes through the intro', (
    WidgetTester tester,
  ) async {
    // The router guards every route, so an unanswered intro wins over the
    // requested location rather than being skipped past.
    await pumpApp(tester, initialLocation: '/spirits/1', onboarded: false);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(SpiritDetailScreen), findsNothing);
  });

  testWidgets('skipping the intro records it, so it does not come back', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, onboarded: false);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.tap(findLabel('Skip'));
    await pumpUntil(tester, find.byType(SpiritsScreen));
    await settle(tester);

    expect(find.byType(SpiritsScreen), findsOneWidget);

    // Skipping is an answer, not an absence of one: relaunching against the
    // same database must not ask again.
    await pumpApp(tester, onboarded: false);
    expect(find.byType(SpiritsScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('the intro walks its three steps and lands on the catalogue', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, onboarded: false);

    // Step 1 → 2.
    await tester.tap(findLabel('Start'));
    await settle(tester);
    expect(findLabel('What are you into'), findsOneWidget);

    // A raw upstream type never appears as a choice; the normalised name does.
    expect(findLabel('Whiskey'), findsOneWidget);
    expect(findLabel('Rice wine'), findsNothing);

    await tester.tap(findLabel('Whiskey'));
    await settle(tester);

    // Step 2 → 3, then out.
    await tester.tap(findLabel('Keep going'));
    await settle(tester);
    await tester.tap(findLabel('Start browsing'));
    await pumpUntil(tester, find.byType(SpiritsScreen));
    await settle(tester);

    expect(find.byType(SpiritsScreen), findsOneWidget);
  });

  testWidgets('catalogue loads and renders cards', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.byType(SpiritsScreen), findsOneWidget);
    expect(find.byType(SpiritCard), findsNWidgets(2));
    expect(findLabel('Vodka'), findsWidgets);
    expect(findLabel('Mezcal'), findsWidgets);
  });

  testWidgets('tapping a card opens its detail and story', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(findLabel('Vodka').first);
    await pumpUntil(tester, find.byType(SpiritDetailScreen));
    await settle(tester);

    expect(find.byType(SpiritDetailScreen), findsOneWidget);
    expect(findLabel('The Story'), findsOneWidget);
    expect(
      find.textContaining('distilled beverage from Eastern Europe'),
      findsOneWidget,
    );
  });

  testWidgets('a spirit with no story says so instead of rendering blank', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(findLabel('Mezcal').first);
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

    await tester.enterText(find.byType(TextField), 'mez');
    await settle(tester);

    expect(find.byType(SpiritCard), findsOneWidget);
    expect(findLabel('Mezcal'), findsWidgets);
  });

  testWidgets('the search field can be cleared and gives up focus', (
    WidgetTester tester,
  ) async {
    // There is no form to submit here, so without a way out the keyboard
    // covers half the catalogue with no route back.
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'mez');
    await settle(tester);
    expect(find.byType(SpiritCard), findsOneWidget);

    final Finder clear = find.byIcon(Icons.close);
    expect(clear, findsOneWidget, reason: 'a clear button appears once typed');

    await tester.tap(clear);
    await settle(tester);

    expect(find.byType(SpiritCard), findsNWidgets(2));
    expect(clear, findsNothing, reason: 'and goes away once empty');
    expect(
      tester.testTextInput.isVisible,
      isFalse,
      reason: 'clearing must also dismiss the keyboard',
    );
  });

  testWidgets('scrolling the catalogue dismisses the keyboard', (
    WidgetTester tester,
  ) async {
    // The two-spirit fixture does not fill a phone, and a scroll view with
    // nothing to scroll never reports a drag — so the viewport is squeezed
    // until the grid genuinely overflows it.
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpApp(tester);

    await tester.tap(find.byType(TextField));
    await settle(tester);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -150));
    await settle(tester);

    expect(tester.testTextInput.isVisible, isFalse);
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
