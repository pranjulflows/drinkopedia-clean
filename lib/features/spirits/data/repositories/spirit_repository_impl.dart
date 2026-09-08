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
import 'package:drinkopedia/features/spirits/domain/repositories/spirit_repository.dart';

/// Cache-first [SpiritRepository].
///
/// Reads come from drift so browsing works offline and screens paint without
/// waiting on the network. The network is consulted only when the cache is
/// empty or stale, which also keeps traffic off a rate-limited free key.
class SpiritRepositoryImpl implements SpiritRepository {
  SpiritRepositoryImpl({required this.remoteDataSource, required this.dao});

  /// How long a cached catalogue is trusted. The upstream data is reference
  /// material that changes rarely, so this is generous on purpose.
  static const Duration cacheTtl = Duration(days: 7);

  final SpiritRemoteDataSource remoteDataSource;
  final SpiritsDao dao;

  @override
  Future<Either<Failure, List<Spirit>>> getSpirits({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh && !await _isCacheStale()) {
        return Right<Failure, List<Spirit>>(await _readCache());
      }

      try {
        final List<SpiritDto> dtos = await remoteDataSource.fetchCatalogue();
        if (dtos.isNotEmpty) {
          await _writeCache(dtos);
          return Right<Failure, List<Spirit>>(await _readCache());
        }
      } catch (error) {
        // Network refresh failed. Stale data beats an error screen, so fall
        // back to whatever is cached and only surface the failure if the cache
        // is empty too.
        final List<Spirit> cached = await _readCache();
        if (cached.isNotEmpty) {
          return Right<Failure, List<Spirit>>(cached);
        }
        return Left<Failure, List<Spirit>>(mapErrorToFailure(error));
      }

      final List<Spirit> cached = await _readCache();
      return cached.isEmpty
          ? const Left<Failure, List<Spirit>>(CacheFailure())
          : Right<Failure, List<Spirit>>(cached);
    } catch (error) {
      return Left<Failure, List<Spirit>>(mapErrorToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Spirit>> getSpiritById(String id) async {
    try {
      final SpiritRow? row = await dao.getById(id);
      if (row != null) return Right<Failure, Spirit>(_toEntity(row));

      // Nothing cached — most likely a deep link opened before the catalogue
      // was ever hydrated. Fill the cache, then read through.
      final List<SpiritDto> dtos = await remoteDataSource.fetchCatalogue();
      if (dtos.isNotEmpty) await _writeCache(dtos);

      final SpiritRow? refreshed = await dao.getById(id);
      return refreshed == null
          ? const Left<Failure, Spirit>(NotFoundFailure('Spirit not found'))
          : Right<Failure, Spirit>(_toEntity(refreshed));
    } catch (error) {
      return Left<Failure, Spirit>(mapErrorToFailure(error));
    }
  }

  @override
  Stream<List<Spirit>> watchSpirits() => dao.watchAll().map(
    (List<SpiritRow> rows) => rows.map(_toEntity).toList(),
  );

  Future<bool> _isCacheStale() async {
    if (await dao.count() == 0) return true;
    final DateTime? oldest = await dao.oldestCachedAt();
    if (oldest == null) return true;
    return DateTime.now().difference(oldest) > cacheTtl;
  }

  Future<List<Spirit>> _readCache() async =>
      (await dao.getAll()).map(_toEntity).toList();

  Future<void> _writeCache(List<SpiritDto> dtos) {
    final DateTime now = DateTime.now();
    return dao.replaceAll(
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
