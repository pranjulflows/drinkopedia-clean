import 'package:dartz/dartz.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_page.dart';

/// Contract the domain depends on. Implemented in the data layer, which is what
/// keeps the dependency arrow pointing inward.
abstract class SpiritRepository {
  /// One page of the catalogue, cache-first, starting at [offset].
  ///
  /// Paged because hydrating the catalogue means one request per entry: doing
  /// all of them before showing anything leaves a first launch staring at a
  /// skeleton for as long as the slowest request takes.
  ///
  /// [forceRefresh] bypasses the cache for pull-to-refresh.
  Future<Either<Failure, SpiritPage>> getSpiritsPage({
    required int offset,
    required int limit,
    bool forceRefresh = false,
  });

  /// A single spirit, cache-first.
  Future<Either<Failure, Spirit>> getSpiritById(String id);

  /// Emits the cached catalogue and every subsequent change to it.
  Stream<List<Spirit>> watchSpirits();
}
