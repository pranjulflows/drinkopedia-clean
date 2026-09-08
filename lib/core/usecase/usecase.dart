import 'package:dartz/dartz.dart';
import 'package:drinkopedia/core/error/failure.dart';

abstract class UseCase<T, P> {
  Future<Either<Failure?, T>> call(P params);
}

class NoParams {}
