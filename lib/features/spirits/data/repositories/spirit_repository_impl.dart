import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drinkopedia/core/database/app_database.dart';
import 'package:drinkopedia/core/database/daos/spirits_dao.dart';
import 'package:drinkopedia/core/error/error_mapper.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/core/network/endpoints/api_sources.dart';
import 'package:drinkopedia/features/spirits/data/datasources/spirit_remote_data_source.dart';
import 'package:drinkopedia/features/spirits/data/models/spirit_dto.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_page.dart';
import 'package:drinkopedia/features/spirits/domain/repositories/spirit_repository.dart';

/// Cache-first, paged [SpiritRepository].
///
/// Reads come from drift so browsing works offline and screens paint without
/// waiting on the network. The network is consulted only for the page being
/// asked for, and only when that page is missing or stale, which also keeps
/// traffic off a rate-limited free key.
class SpiritRepositoryImpl implements SpiritRepository {
  SpiritRepositoryImpl({required this.remoteDataSource, required this.dao});

  /// How long a cached catalogue is trusted. The upstream data is reference
  /// material that changes rarely, so this is generous on purpose.
  static const Duration cacheTtl = Duration(days: 7);

  final SpiritRemoteDataSource remoteDataSource;
  final SpiritsDao dao;

  @override
  Future<Either<Failure, SpiritPage>> getSpiritsPage({
    required int offset,
    required int limit,
    bool forceRefresh = false,
  }) async {
    try {
      final List<String> seed = await remoteDataSource.loadSeedNames();
      final int total = seed.length;
      if (offset >= total) {
        return Right<Failure, SpiritPage>(
          SpiritPage(items: const <Spirit>[], nextOffset: total, total: total),
        );
      }

      final int end = (offset + limit).clamp(0, total);
      final List<String> names = seed.sublist(offset, end);

      final List<SpiritRow> cached = await dao.getByNames(names);
      if (!forceRefresh && _isPageFresh(cached, expected: names.length)) {
        return Right<Failure, SpiritPage>(_toPage(cached, names, end, total));
      }

      // Only what the page lacks goes over the wire, so retrying a page that
      // was throttled half way asks again for the entries that failed, not
      // for the ones that already made it.
      final Set<String> fresh = forceRefresh
          ? const <String>{}
          : <String>{
              for (final SpiritRow row in cached)
                if (_isFresh(row)) row.name,
            };
      final List<String> wanted = <String>[
        for (final String name in names)
          if (!fresh.contains(name)) name,
      ];

      Hydration hydration;
      try {
        hydration = await remoteDataSource.fetchByNames(wanted);
      } catch (error) {
        hydration = Hydration(failed: wanted, error: error);
      }
      if (hydration.spirits.isNotEmpty) await _writeCache(hydration.spirits);

      final List<SpiritRow> rows = await dao.getByNames(names);

      // An entry whose request failed, with no copy cached, is not absent —
      // it is unknown. Returning the page without it would advance the offset
      // past it and lose it for the session, and a search would then report
      // "no match" for a spirit that exists. So the page fails and is retried.
      // A stale copy does count: yesterday's shelf beats an error screen.
      final Set<String> have = <String>{
        for (final SpiritRow row in rows) row.name,
      };
      if (hydration.failed.any((String name) => !have.contains(name))) {
        final Object? error = hydration.error;
        return Left<Failure, SpiritPage>(
          error == null ? const ServerFailure() : mapErrorToFailure(error),
        );
      }
      return Right<Failure, SpiritPage>(_toPage(rows, names, end, total));
    } catch (error) {
      return Left<Failure, SpiritPage>(mapErrorToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Spirit>> getSpiritById(String id) async {
    try {
      final SpiritRow? row = await dao.getById(id);
      if (row != null) return Right<Failure, Spirit>(_toEntity(row));

      // Nothing cached — most likely a deep link into a page nobody has
      // scrolled to yet. Fetch this one spirit by id rather than hydrating the
      // catalogue to find it, which would cost a request per entry.
      final SpiritDto? dto = await remoteDataSource.fetchById(id);
      if (dto == null) {
        return const Left<Failure, Spirit>(NotFoundFailure('Spirit not found'));
      }
      await _writeCache(<SpiritDto>[dto]);

      final SpiritRow? fetched = await dao.getById(id);
      return fetched == null
          ? const Left<Failure, Spirit>(NotFoundFailure('Spirit not found'))
          : Right<Failure, Spirit>(_toEntity(fetched));
    } catch (error) {
      return Left<Failure, Spirit>(mapErrorToFailure(error));
    }
  }

  @override
  Stream<List<Spirit>> watchSpirits() => dao.watchAll().map(
    (List<SpiritRow> rows) => rows.map(_toEntity).toList(),
  );

  /// A page is fresh when every entry it asked for is cached and none of them
  /// has outlived [cacheTtl].
  ///
  /// Judged per page rather than across the whole table: pages are cached at
  /// different times, so one old page must not force every page to refetch.
  bool _isPageFresh(List<SpiritRow> rows, {required int expected}) =>
      rows.length >= expected && rows.every(_isFresh);

  bool _isFresh(SpiritRow row) =>
      DateTime.now().difference(row.cachedAt) <= cacheTtl;

  /// Rows come back from the database in no particular order; this puts them
  /// back in catalogue order so a page reads the same every time.
  SpiritPage _toPage(
    List<SpiritRow> rows,
    List<String> names,
    int nextOffset,
    int total,
  ) {
    final Map<String, int> position = <String, int>{
      for (int i = 0; i < names.length; i++) names[i]: i,
    };
    final List<SpiritRow> ordered = List<SpiritRow>.of(rows)
      ..sort(
        (SpiritRow a, SpiritRow b) => (position[a.name] ?? names.length)
            .compareTo(position[b.name] ?? names.length),
      );
    return SpiritPage(
      items: ordered.map(_toEntity).toList(),
      nextOffset: nextOffset,
      total: total,
    );
  }

  Future<void> _writeCache(List<SpiritDto> dtos) {
    final DateTime now = DateTime.now();
    return dao.upsertAll(
      dtos.map((SpiritDto dto) {
        final Spirit spirit = dto.toEntity();
        return SpiritsTableCompanion.insert(
          id: spirit.id,
          name: spirit.name,
          type: Value<String?>(spirit.type),
          abv: Value<double?>(spirit.abv),
          story: Value<String?>(spirit.story),
          imageUrl: Value<String?>(spirit.imageUrl),
          isAlcoholic: Value<bool>(spirit.isAlcoholic),
          cachedAt: now,
        );
      }),
    );
  }

  Spirit _toEntity(SpiritRow row) => Spirit(
    id: row.id,
    name: row.name,
    type: row.type,
    abv: row.abv,
    story: row.story,
    imageUrl: row.imageUrl ?? CocktailDbEndpoints.ingredientImage(row.name),
    isAlcoholic: row.isAlcoholic,
  );
}
