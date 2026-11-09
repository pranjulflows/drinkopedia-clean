import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:drinkopedia/core/database/app_database.dart';
import 'package:drinkopedia/core/database/daos/spirits_dao.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/features/spirits/data/datasources/spirit_remote_data_source.dart';
import 'package:drinkopedia/features/spirits/data/models/spirit_dto.dart';
import 'package:drinkopedia/features/spirits/data/repositories/spirit_repository_impl.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements SpiritRemoteDataSource {}

SpiritDto _dto(String name) =>
    SpiritDto(id: 'id-$name', name: name, description: 'A story about $name');

/// Five names, so a page size of two gives three pages: 2, 2, 1.
const List<String> _seed = <String>[
  'Absinthe',
  'Bourbon',
  'Gin',
  'Rum',
  'Wine',
];

DioException _offline() => DioException(
  requestOptions: RequestOptions(),
  type: DioExceptionType.connectionError,
);

DioException _throttled() => DioException(
  requestOptions: RequestOptions(),
  type: DioExceptionType.badResponse,
  response: Response<dynamic>(
    requestOptions: RequestOptions(),
    statusCode: 429,
  ),
);

void main() {
  late AppDatabase db;
  late SpiritsDao dao;
  late _MockRemote remote;
  late SpiritRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(<String>[]));

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SpiritsDao(db);
    remote = _MockRemote();
    repository = SpiritRepositoryImpl(remoteDataSource: remote, dao: dao);
    when(() => remote.loadSeedNames()).thenAnswer((_) async => _seed);
    // Upstream answers whatever names it is asked for.
    when(() => remote.fetchByNames(any())).thenAnswer(
      (Invocation i) async => Hydration(
        spirits: (i.positionalArguments.first as List<String>)
            .map(_dto)
            .toList(),
      ),
    );
  });

  tearDown(() => db.close());

  Future<SpiritPage> page(int offset, {bool forceRefresh = false}) async {
    final Either<Failure, SpiritPage> result = await repository.getSpiritsPage(
      offset: offset,
      limit: 2,
      forceRefresh: forceRefresh,
    );
    return result.getOrElse(() => throw StateError('expected a page'));
  }

  List<String> names(SpiritPage p) =>
      p.items.map((Spirit s) => s.name).toList();

  group('paging', () {
    test('fetches only the names on the requested page', () async {
      final SpiritPage first = await page(0);

      expect(names(first), <String>['Absinthe', 'Bourbon']);
      verify(() => remote.loadSeedNames()).called(1);
      verify(
        () => remote.fetchByNames(<String>['Absinthe', 'Bourbon']),
      ).called(1);
      verifyNoMoreInteractions(remote);
    });

    test('reports where the next page starts and the catalogue size', () async {
      final SpiritPage first = await page(0);

      expect(first.nextOffset, 2);
      expect(first.total, 5);
      expect(first.hasMore, isTrue);
    });

    test('the last page may be short, and has nothing after it', () async {
      final SpiritPage last = await page(4);

      expect(names(last), <String>['Wine']);
      expect(last.hasMore, isFalse);
    });

    test('an offset past the end is an empty, final page', () async {
      final SpiritPage beyond = await page(99);

      expect(beyond.items, isEmpty);
      expect(beyond.hasMore, isFalse);
      verifyNever(() => remote.fetchByNames(any()));
    });

    test('loading a page never throws away pages loaded before it', () async {
      // The trap a whole-catalogue cache sets: if writing page two replaced
      // the table, page one would have to be fetched again.
      await page(0);
      await page(2);

      expect(await dao.count(), 4);

      clearInteractions(remote);
      await page(0);
      verifyNever(() => remote.fetchByNames(any()));
    });

    test('returns a page in catalogue order, not database order', () async {
      // Upstream happens to answer in reverse.
      when(() => remote.fetchByNames(any())).thenAnswer(
        (Invocation i) async => Hydration(
          spirits: (i.positionalArguments.first as List<String>).reversed
              .map(_dto)
              .toList(),
        ),
      );

      expect(names(await page(0)), <String>['Absinthe', 'Bourbon']);
    });

    test(
      'an entry that no longer resolves still advances the offset',
      () async {
        // Paging on the count returned would ask for Bourbon's slot forever.
        when(() => remote.fetchByNames(any())).thenAnswer(
          (_) async => Hydration(spirits: <SpiritDto>[_dto('Absinthe')]),
        );

        final SpiritPage first = await page(0);

        expect(names(first), <String>['Absinthe']);
        expect(first.nextOffset, 2);
      },
    );
  });

  group('caching', () {
    test('serves a fresh page without touching the network', () async {
      await page(0);
      clearInteractions(remote);

      await page(0);

      verifyNever(() => remote.fetchByNames(any()));
    });

    test('refetches a page once it outlives the cache lifetime', () async {
      await dao.upsertAll(<SpiritsTableCompanion>[
        for (final String name in <String>['Absinthe', 'Bourbon'])
          SpiritsTableCompanion.insert(
            id: 'id-$name',
            name: name,
            story: const Value<String?>('old'),
            cachedAt: DateTime.now().subtract(
              SpiritRepositoryImpl.cacheTtl + const Duration(hours: 1),
            ),
          ),
      ]);

      await page(0);

      verify(
        () => remote.fetchByNames(<String>['Absinthe', 'Bourbon']),
      ).called(1);
    });

    test('force refresh ignores a fresh cache', () async {
      await page(0);
      clearInteractions(remote);

      await page(0, forceRefresh: true);

      verify(() => remote.fetchByNames(any())).called(1);
    });
  });

  group('failure', () {
    test('a failed refresh falls back to the stale page', () async {
      await page(0);
      when(() => remote.fetchByNames(any())).thenThrow(_offline());

      final SpiritPage stale = await page(0, forceRefresh: true);

      // Showing yesterday's shelf beats showing an error screen.
      expect(names(stale), <String>['Absinthe', 'Bourbon']);
    });

    test('network failure with nothing cached is a network failure', () async {
      when(() => remote.fetchByNames(any())).thenThrow(_offline());

      final Either<Failure, SpiritPage> result = await repository
          .getSpiritsPage(offset: 0, limit: 2);

      result.fold(
        (Failure f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected a failure'),
      );
    });

    test('a failed entry fails the page instead of vanishing from it', () async {
      // The 429 case: Absinthe arrives, Bourbon is throttled. Returning a page
      // of one would page past Bourbon and lose it — and a search for it would
      // then say "no match" for a spirit that exists.
      when(() => remote.fetchByNames(any())).thenAnswer(
        (_) async => Hydration(
          spirits: <SpiritDto>[_dto('Absinthe')],
          failed: <String>['Bourbon'],
          error: _throttled(),
        ),
      );

      final Either<Failure, SpiritPage> result = await repository
          .getSpiritsPage(offset: 0, limit: 2);

      result.fold(
        (Failure f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected a failure'),
      );
      // What did arrive is kept, so the retry has less to do.
      expect(await dao.count(), 1);
    });

    test('a retry asks only for the entries still missing', () async {
      when(() => remote.fetchByNames(any())).thenAnswer(
        (_) async => Hydration(
          spirits: <SpiritDto>[_dto('Absinthe')],
          failed: <String>['Bourbon'],
          error: _throttled(),
        ),
      );
      await repository.getSpiritsPage(offset: 0, limit: 2);

      when(() => remote.fetchByNames(any())).thenAnswer(
        (_) async => Hydration(spirits: <SpiritDto>[_dto('Bourbon')]),
      );
      final SpiritPage retried = await page(0);

      verify(() => remote.fetchByNames(<String>['Bourbon'])).called(1);
      expect(names(retried), <String>['Absinthe', 'Bourbon']);
    });

    test('a failed entry with a stale copy still shows the copy', () async {
      await page(0);
      when(() => remote.fetchByNames(any())).thenAnswer(
        (_) async => Hydration(
          spirits: <SpiritDto>[_dto('Absinthe')],
          failed: <String>['Bourbon'],
          error: _throttled(),
        ),
      );

      final SpiritPage refreshed = await page(0, forceRefresh: true);

      expect(names(refreshed), <String>['Absinthe', 'Bourbon']);
    });

    test('entries upstream no longer knows are skipped, not failed', () async {
      // An empty answer is an answer. Nothing failed, so there is nothing to
      // retry — the page is just empty.
      when(
        () => remote.fetchByNames(any()),
      ).thenAnswer((_) async => const Hydration());

      final SpiritPage empty = await page(0);

      expect(empty.items, isEmpty);
      expect(empty.nextOffset, 2);
    });
  });

  group('getSpiritById', () {
    test('a cold deep link fetches one spirit, not the catalogue', () async {
      when(
        () => remote.fetchById('42'),
      ).thenAnswer((_) async => const SpiritDto(id: '42', name: 'Mezcal'));

      final Either<Failure, Spirit> result = await repository.getSpiritById(
        '42',
      );

      expect(result.isRight(), isTrue);
      verify(() => remote.fetchById('42')).called(1);
      verifyNever(() => remote.fetchByNames(any()));
    });

    test('returns NotFoundFailure for an unknown id', () async {
      when(() => remote.fetchById('nope')).thenAnswer((_) async => null);

      final Either<Failure, Spirit> result = await repository.getSpiritById(
        'nope',
      );

      result.fold(
        (Failure f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('expected a failure'),
      );
    });

    test('a cached spirit is served without a request', () async {
      await page(0);
      clearInteractions(remote);

      final Either<Failure, Spirit> result = await repository.getSpiritById(
        'id-Absinthe',
      );

      expect(result.isRight(), isTrue);
      verifyNever(() => remote.fetchById(any()));
    });
  });
}
