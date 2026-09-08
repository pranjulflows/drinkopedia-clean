import 'package:dartz/dartz.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/core/usecase/usecase.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/repositories/spirit_repository.dart';

class GetSpiritsParams {
  const GetSpiritsParams({this.forceRefresh = false});

  final bool forceRefresh;
}

/// Loads the catalogue, ordered so the entries with real stories surface first —
/// an incomplete record makes a poor first impression on a browse screen.
class GetSpirits implements UseCase<List<Spirit>, GetSpiritsParams> {
  const GetSpirits(this._repository);

  final SpiritRepository _repository;

  @override
  Future<Either<Failure?, List<Spirit>>> call(GetSpiritsParams params) async {
    final Either<Failure, List<Spirit>> result = await _repository.getSpirits(
      forceRefresh: params.forceRefresh,
    );
    return result.map((List<Spirit> spirits) {
      final List<Spirit> sorted = List<Spirit>.of(spirits);
      sorted.sort((Spirit a, Spirit b) {
        if (a.hasStory != b.hasStory) return a.hasStory ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return sorted;
    });
  }
}
