import 'package:dartz/dartz.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/core/usecase/usecase.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/repositories/spirit_repository.dart';

class GetSpiritDetailParams {
  const GetSpiritDetailParams(this.id);

  final String id;
}

class GetSpiritDetail implements UseCase<Spirit, GetSpiritDetailParams> {
  const GetSpiritDetail(this._repository);

  final SpiritRepository _repository;

  @override
  Future<Either<Failure?, Spirit>> call(GetSpiritDetailParams params) =>
      _repository.getSpiritById(params.id);
}
