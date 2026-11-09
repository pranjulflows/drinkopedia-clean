import 'package:dartz/dartz.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/core/usecase/usecase.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_page.dart';
import 'package:drinkopedia/features/spirits/domain/repositories/spirit_repository.dart';

class GetSpiritsPageParams {
  const GetSpiritsPageParams({
    required this.offset,
    required this.limit,
    this.forceRefresh = false,
  });

  final int offset;
  final int limit;
  final bool forceRefresh;
}

/// One page of the catalogue.
///
/// Does no sorting of its own. This used to put storied entries first, but a
/// per-page sort restarts that ordering on every page, so it now lives in the
/// seed list, which is ordered that way before anything is fetched.
class GetSpiritsPage implements UseCase<SpiritPage, GetSpiritsPageParams> {
  const GetSpiritsPage(this._repository);

  final SpiritRepository _repository;

  @override
  Future<Either<Failure?, SpiritPage>> call(GetSpiritsPageParams params) =>
      _repository.getSpiritsPage(
        offset: params.offset,
        limit: params.limit,
        forceRefresh: params.forceRefresh,
      );
}
