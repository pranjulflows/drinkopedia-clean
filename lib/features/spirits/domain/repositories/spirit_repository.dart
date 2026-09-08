import 'package:dartz/dartz.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';

/// Contract the domain depends on. Implemented in the data layer, which is what
/// keeps the dependency arrow pointing inward.
abstract class SpiritRepository {
  /// The browsable catalogue, cache-first.
  ///
  /// [forceRefresh] bypasses the cache for pull-to-refresh.
  Future<Either<Failure, List<Spirit>>> getSpirits({bool forceRefresh = false});

  /// A single spirit, cache-first.
  Future<Either<Failure, Spirit>> getSpiritById(String id);

  /// Emits the cached catalogue and every subsequent change to it.
  Stream<List<Spirit>> watchSpirits();
}
