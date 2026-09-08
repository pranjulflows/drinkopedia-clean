
import 'package:dartz/dartz.dart';
import 'package:drinkopedia/core/network/failure.dart';

abstract class UseCase<T, P>{
  Future<Either<Failure?, T>> call(P params);
}

class NoParams{}