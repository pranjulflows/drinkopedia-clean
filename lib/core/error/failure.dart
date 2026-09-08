import 'package:equatable/equatable.dart';

/// A failure that has already been translated out of the data layer.
///
/// Use cases and providers deal in these; they never see a `DioException`.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// No usable connection, or the request timed out.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// The server answered, but not with success.
class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Something went wrong',
    this.statusCode,
  ]);

  final int? statusCode;

  @override
  List<Object?> get props => <Object?>[message, statusCode];
}

/// The response parsed but did not match the expected shape.
class ParsingFailure extends Failure {
  const ParsingFailure([super.message = 'Unexpected response format']);
}

/// Nothing cached and nothing reachable.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'No offline data available']);
}

/// The request succeeded but matched nothing.
///
/// Distinct from a failure state on purpose: TheCocktailDB answers
/// `{"drinks": null}` for a miss, which is an empty result, not an error.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found']);
}
