import 'package:dartz/dartz.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/core/presentation/view_state.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';
import 'package:drinkopedia/features/spirits/domain/repositories/spirit_repository.dart';
import 'package:drinkopedia/features/spirits/domain/usecases/get_spirits.dart';
import 'package:drinkopedia/features/spirits/presentation/providers/spirits_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements SpiritRepository {}

void main() {
  late _MockRepo repo;
  late SpiritsProvider provider;

  setUp(() {
    repo = _MockRepo();
    provider = SpiritsProvider(getSpirits: GetSpirits(repo));
  });

  void stubSpirits(List<Spirit> spirits) {
    when(
      () => repo.getSpirits(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => Right<Failure, List<Spirit>>(spirits));
  }

  test('load moves to a success state', () async {
    stubSpirits(const <Spirit>[Spirit(id: '1', name: 'Vodka')]);

    await provider.load();

    expect(provider.state, isA<SuccessState<List<Spirit>>>());
    expect(provider.visibleSpirits.single.name, 'Vodka');
  });

  test('an empty catalogue is Empty, not Success', () async {
    stubSpirits(const <Spirit>[]);

    await provider.load();

    expect(provider.state, isA<EmptyState<List<Spirit>>>());
  });

  test('a failure moves to an error state', () async {
    when(
      () => repo.getSpirits(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer(
      (_) async => const Left<Failure, List<Spirit>>(NetworkFailure('offline')),
    );

    await provider.load();

    expect(provider.state, isA<ErrorState<List<Spirit>>>());
  });

  test('search filters on name and type, case-insensitively', () async {
    stubSpirits(const <Spirit>[
      Spirit(id: '1', name: 'Vodka', type: 'Vodka'),
      Spirit(id: '2', name: 'Bourbon', type: 'Whiskey'),
      Spirit(id: '3', name: 'Scotch', type: 'Whiskey'),
    ]);
    await provider.load();

    provider.search('whis');
    expect(
      provider.visibleSpirits.map((Spirit s) => s.name),
      containsAll(<String>['Bourbon', 'Scotch']),
    );

    provider.search('VODKA');
    expect(provider.visibleSpirits.single.name, 'Vodka');

    provider.search('');
    expect(provider.visibleSpirits.length, 3);
  });

  group('taste ordering', () {
    const List<Spirit> catalogue = <Spirit>[
      Spirit(id: '1', name: 'Absinthe', type: 'Spirit'),
      Spirit(id: '2', name: 'Bourbon', type: 'Whiskey'),
      Spirit(id: '3', name: 'Cachaca', type: 'Spirit'),
      Spirit(id: '4', name: 'Scotch', type: 'Whisky'),
    ];

    test('floats picked categories to the top, keeping the rest', () async {
      stubSpirits(catalogue);
      await provider.load();

      final List<Spirit> ordered = provider.visibleFor(<SpiritCategory>{
        SpiritCategory.whiskey,
      });

      expect(
        ordered.map((Spirit s) => s.name),
        <String>['Bourbon', 'Scotch', 'Absinthe', 'Cachaca'],
        reason:
            'Whiskey and Whisky both normalise to whiskey and come first; '
            'nothing is dropped, and each group stays alphabetical',
      );
    });

    test('an empty pick leaves the order alone', () async {
      stubSpirits(catalogue);
      await provider.load();

      expect(
        provider.visibleFor(const <SpiritCategory>{}).map((Spirit s) => s.name),
        provider.visibleSpirits.map((Spirit s) => s.name),
      );
    });

    test('ordering composes with the search filter', () async {
      stubSpirits(catalogue);
      await provider.load();
      provider.search('c');

      final List<Spirit> ordered = provider.visibleFor(<SpiritCategory>{
        SpiritCategory.whiskey,
      });

      // Only the search hits — Absinthe and Bourbon match neither on name nor
      // type — and Scotch, being a Whisky, floats above Cachaca.
      expect(ordered.map((Spirit s) => s.name), <String>['Scotch', 'Cachaca']);
    });
  });

  test('keeps previous data visible while refreshing', () async {
    stubSpirits(const <Spirit>[Spirit(id: '1', name: 'Vodka')]);
    await provider.load();

    final Future<void> pending = provider.refresh();
    expect(provider.state, isA<LoadingState<List<Spirit>>>());
    expect(
      (provider.state as LoadingState<List<Spirit>>).previous,
      isNotNull,
      reason: 'a refresh must not blank the screen',
    );
    await pending;
  });
}
