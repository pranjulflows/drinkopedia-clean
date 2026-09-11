import 'package:dartz/dartz.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/core/presentation/view_state.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';
import 'package:drinkopedia/features/spirits/domain/repositories/spirit_repository.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_page.dart';
import 'package:drinkopedia/features/spirits/domain/usecases/get_spirits_page.dart';
import 'package:drinkopedia/features/spirits/presentation/providers/spirits_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements SpiritRepository {}

void main() {
  late _MockRepo repo;
  late SpiritsProvider provider;

  setUp(() {
    repo = _MockRepo();
    provider = SpiritsProvider(getSpiritsPage: GetSpiritsPage(repo));
  });

  /// A catalogue small enough to arrive as one final page — what most of the
  /// behaviour here is about, independent of paging.
  void stubSpirits(List<Spirit> spirits) {
    when(
      () => repo.getSpiritsPage(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, SpiritPage>(
        SpiritPage(
          items: spirits,
          nextOffset: spirits.length,
          total: spirits.length,
        ),
      ),
    );
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
      () => repo.getSpiritsPage(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer(
      (_) async => const Left<Failure, SpiritPage>(NetworkFailure('offline')),
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

  group('category filter', () {
    const List<Spirit> catalogue = <Spirit>[
      Spirit(id: '1', name: 'Absinthe', type: 'Spirit'),
      Spirit(id: '2', name: 'Bourbon', type: 'Whiskey'),
      Spirit(id: '3', name: 'Brandy', type: 'Spirit'),
      Spirit(id: '4', name: 'Cognac', type: 'Brandy'),
      Spirit(id: '5', name: 'Sloe Gin', type: 'Liqueur'),
      Spirit(id: '6', name: 'Gin', type: 'Gin'),
    ];

    test('narrows to one category', () async {
      stubSpirits(catalogue);
      await provider.load();

      provider.filterBy(SpiritCategory.brandy);

      expect(
        provider.visibleSpirits.map((Spirit s) => s.name),
        <String>['Brandy', 'Cognac'],
        reason: 'Brandy is included despite its catch-all upstream type',
      );
    });

    test('choosing the active category again clears it', () async {
      stubSpirits(catalogue);
      await provider.load();

      provider.filterBy(SpiritCategory.gin);
      expect(provider.category, SpiritCategory.gin);

      provider.filterBy(SpiritCategory.gin);
      expect(provider.category, isNull);
      expect(provider.visibleSpirits.length, catalogue.length);
    });

    test('composes with search rather than replacing it', () async {
      stubSpirits(catalogue);
      await provider.load();

      provider
        ..filterBy(SpiritCategory.liqueur)
        ..search('gin');

      expect(
        provider.visibleSpirits.map((Spirit s) => s.name),
        <String>['Sloe Gin'],
        reason: 'Gin matches the search but is not a liqueur',
      );
    });

    test('counts only categories that have something in them', () async {
      stubSpirits(catalogue);
      await provider.load();

      expect(provider.categoryCounts, <SpiritCategory, int>{
        SpiritCategory.whiskey: 1,
        SpiritCategory.gin: 1,
        SpiritCategory.brandy: 2,
        SpiritCategory.liqueur: 1,
        SpiritCategory.other: 1,
      });
    });

    test('counts ignore the search, so the row does not jump', () async {
      stubSpirits(catalogue);
      await provider.load();
      final Map<SpiritCategory, int> before = provider.categoryCounts;

      provider.search('bour');

      expect(provider.categoryCounts, before);
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

  group('paging', () {
    /// Ten spirits served two at a time, as a repository would page them.
    final List<Spirit> shelf = <Spirit>[
      for (int i = 0; i < 10; i++)
        Spirit(id: '$i', name: 'Spirit $i', type: i == 7 ? 'Whiskey' : 'Rum'),
    ];

    void stubPaged({List<Spirit>? items}) {
      final List<Spirit> all = items ?? shelf;
      when(
        () => repo.getSpiritsPage(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer((Invocation i) async {
        final int offset = i.namedArguments[#offset] as int;
        final int limit = i.namedArguments[#limit] as int;
        final int end = (offset + limit).clamp(0, all.length);
        return Right<Failure, SpiritPage>(
          SpiritPage(
            items: all.sublist(offset.clamp(0, all.length), end),
            nextOffset: end,
            total: all.length,
          ),
        );
      });
    }

    setUp(() {
      provider = SpiritsProvider(
        getSpiritsPage: GetSpiritsPage(repo),
        pageSize: 2,
      );
    });

    List<String> ids() =>
        provider.visibleSpirits.map((Spirit s) => s.id).toList();

    test('load fetches only the first page, and knows the total', () async {
      stubPaged();

      await provider.load();

      expect(ids(), <String>['0', '1']);
      expect(provider.hasMore, isTrue);
      expect(provider.total, 10);
    });

    test('loadMore appends the next page', () async {
      stubPaged();
      await provider.load();

      await provider.loadMore();

      expect(ids(), <String>['0', '1', '2', '3']);
    });

    test('loadMore stops once the catalogue runs out', () async {
      stubPaged(items: shelf.sublist(0, 3));
      await provider.load();
      await provider.loadMore();
      expect(provider.hasMore, isFalse);
      clearInteractions(repo);

      await provider.loadMore();

      verifyNever(
        () => repo.getSpiritsPage(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      );
    });

    test('calls made while a page is loading are ignored', () async {
      // The screen asks on every build and every scroll tick; without a guard
      // that is a burst of duplicate requests for the same page.
      stubPaged();
      await provider.load();
      clearInteractions(repo);

      await Future.wait(<Future<void>>[
        provider.loadMore(),
        provider.loadMore(),
        provider.loadMore(),
      ]);

      verify(
        () => repo.getSpiritsPage(
          offset: 2,
          limit: 2,
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).called(1);
      expect(ids(), <String>['0', '1', '2', '3']);
    });

    test('a failed page keeps what loaded, and waits for a retry', () async {
      stubPaged();
      await provider.load();
      when(
        () => repo.getSpiritsPage(
          offset: 2,
          limit: any(named: 'limit'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => const Left<Failure, SpiritPage>(NetworkFailure('offline')),
      );

      await provider.loadMore();

      expect(ids(), <String>['0', '1'], reason: 'nothing loaded is lost');
      expect(provider.loadMoreFailure, isA<NetworkFailure>());

      // Loading is driven by the end of the list being in view, which it
      // still is after a failure. Without this, offline means a request per
      // frame.
      clearInteractions(repo);
      await provider.loadMore();
      verifyNever(
        () => repo.getSpiritsPage(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      );

      stubPaged();
      await provider.retryLoadMore();
      expect(ids(), <String>['0', '1', '2', '3']);
      expect(provider.loadMoreFailure, isNull);
    });

    test('a page still in flight when a refresh starts is discarded', () async {
      stubPaged();
      await provider.load();

      final Future<void> stale = provider.loadMore();
      final Future<void> refreshed = provider.refresh();
      await Future.wait(<Future<void>>[stale, refreshed]);

      expect(ids(), <String>[
        '0',
        '1',
      ], reason: 'the old page two must not be appended to the new list');
    });

    test(
      'a refresh refreshes the pages after it, not only the first',
      () async {
        stubPaged();
        await provider.load();
        await provider.refresh();
        clearInteractions(repo);

        await provider.loadMore();

        verify(
          () => repo.getSpiritsPage(offset: 2, limit: 2, forceRefresh: true),
        ).called(1);
      },
    );

    test(
      'a picked spirit on a later page never moves above loaded ones',
      () async {
        // Spirit 7 is the only whiskey. Floated across the whole list it would
        // jump above cards already scrolled past as its page arrives.
        stubPaged();
        await provider.load();
        for (int i = 0; i < 4; i++) {
          await provider.loadMore();
        }

        final List<String> ordered = provider
            .visibleFor(<SpiritCategory>{SpiritCategory.whiskey})
            .map((Spirit s) => s.id)
            .toList();

        expect(ordered.indexOf('7'), 6, reason: 'first within its own page');
        expect(ordered.sublist(0, 6), <String>['0', '1', '2', '3', '4', '5']);
      },
    );
  });
}
