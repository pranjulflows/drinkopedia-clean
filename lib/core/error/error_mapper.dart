import 'package:dio/dio.dart';
import 'package:drinkopedia/core/error/failure.dart';

/// Translates transport-level errors into domain [Failure]s.
///
/// This is the only place `DioException` is allowed to be understood; keeping it
/// here is what lets the domain layer stay free of Dio.
Failure mapErrorToFailure(Object error) {
  if (error is DioException) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => const NetworkFailure(
        'The connection timed out. Please try again.',
      ),
      DioExceptionType.connectionError => const NetworkFailure(),
      DioExceptionType.badResponse => _mapStatusCode(
        error.response?.statusCode,
      ),
      DioExceptionType.cancel => const ServerFailure('Request cancelled'),
      DioExceptionType.badCertificate => const ServerFailure(
        'Could not verify the server certificate',
      ),
      DioExceptionType.unknown => const NetworkFailure(),
    };
  }
  if (error is FormatException || error is TypeError) {
    return const ParsingFailure();
  }
  return ServerFailure(error.toString());
}

Failure _mapStatusCode(int? statusCode) => switch (statusCode) {
  404 => const NotFoundFailure(),
  429 => const ServerFailure('Too many requests. Please slow down.', 429),
  final int code when code >= 500 => ServerFailure(
    'The service is unavailable right now.',
    code,
  ),
  final int code => ServerFailure('Request failed ($code)', code),
  null => const ServerFailure(),
};
