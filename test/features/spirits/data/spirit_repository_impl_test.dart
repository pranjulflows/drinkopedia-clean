import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:drinkopedia/core/database/app_database.dart';
import 'package:drinkopedia/core/database/daos/spirits_dao.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/features/spirits/data/datasources/spirit_remote_data_source.dart';
import 'package:drinkopedia/features/spirits/data/models/spirit_dto.dart';
import 'package:drinkopedia/features/spirits/data/repositories/spirit_repository_impl.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements SpiritRemoteDataSource {}

SpiritDto _dto(String id, String name) =>
    SpiritDto(id: id, name: name, description: 'A story about $name');

void main() {
  late AppDatabase db;
  late SpiritsDao dao;
  late _MockRemote remote;
  late SpiritRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SpiritsDao(db);
    remote = _MockRemote();
    repository = SpiritRepositoryImpl(remoteDataSource: remote, dao: dao);
  });

  tearDown(() => db.close());

  test('fetches from network and caches when the cache is empty', () async {
    when(() => remote.fetchCatalogue()).thenAnswer(
      (_) async => <SpiritDto>[_dto('1', 'Vodka'), _dto('2', 'Gin')],
    );

    final Either<Failure, List<Spirit>> result = await repository.getSpirits();

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => <Spirit>[]).length, 2);
    expect(await dao.count(), 2, reason: 'results should be written back');
  });

  test('serves the cache without touching the network when fresh', () async {
    when(
      () => remote.fetchCatalogue(),
    ).thenAnswer((_) async => <SpiritDto>[_dto('1', 'Vodka')]);
    await repository.getSpirits();

    await repository.getSpirits();

    verify(() => remote.fetchCatalogue()).called(1);
  });

  test('falls back to stale cache when a refresh fails', () async {
    when(
      () => remote.fetchCatalogue(),
    ).thenAnswer((_) async => <SpiritDto>[_dto('1', 'Vodka')]);
    await repository.getSpirits();

    when(() => remote.fetchCatalogue()).thenThrow(
      DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      ),
    );

    final Either<Failure, List<Spirit>> result = await repository.getSpirits(
      forceRefresh: true,
    );

    // Showing yesterday's catalogue beats showing an error screen.
    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => <Spirit>[]).single.name, 'Vodka');
  });

  test('surfaces a failure when both network and cache are empty', () async {
    when(() => remote.fetchCatalogue()).thenThrow(
      DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      ),
    );

    final Either<Failure, List<Spirit>> result = await repository.getSpirits();

    expect(result.isLeft(), isTrue);
    result.fold(
      (Failure f) => expect(f, isA<NetworkFailure>()),
      (_) => fail('expected a failure'),
    );
  });

  test('a replaced catalogue does not leave orphaned rows', () async {
    when(() => remote.fetchCatalogue()).thenAnswer(
      (_) async => <SpiritDto>[_dto('1', 'Vodka'), _dto('2', 'Gin')],
    );
    await repository.getSpirits();

    when(
      () => remote.fetchCatalogue(),
    ).thenAnswer((_) async => <SpiritDto>[_dto('1', 'Vodka')]);
    await repository.getSpirits(forceRefresh: true);

    expect(await dao.count(), 1);
  });

  group('getSpiritById', () {
    test('reads through to the network on a cold cache', () async {
      // The deep-link path: nothing cached, only an id.
      when(
        () => remote.fetchCatalogue(),
      ).thenAnswer((_) async => <SpiritDto>[_dto('42', 'Mezcal')]);

      final Either<Failure, Spirit> result = await repository.getSpiritById(
        '42',
      );

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => throw StateError('none')).name, 'Mezcal');
    });

    test('returns NotFoundFailure for an unknown id', () async {
      when(
        () => remote.fetchCatalogue(),
      ).thenAnswer((_) async => <SpiritDto>[_dto('1', 'Vodka')]);

      final Either<Failure, Spirit> result = await repository.getSpiritById(
        'nope',
      );

      result.fold(
        (Failure f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('expected a failure'),
      );
    });
  });
}
