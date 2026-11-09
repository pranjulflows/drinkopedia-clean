import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drinkopedia/core/network/dio_factory.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with Cloudflare's rate-limit page, exactly as it
/// arrives in front of TheCocktailDB: a 429 labelled JSON whose body is not.
class _CloudflareThrottle implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    'error code: 1015',
    429,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      // Longer than the retry interceptor will wait, so it passes the 429
      // straight on and this test does not sit through a real delay.
      'retry-after': <String>['3600'],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  test('a 429 with a non-JSON body still arrives as a 429', () async {
    // Decoding that body used to throw a FormatException that Dio reported
    // in place of the 429 — no status, no Retry-After — so the throttle could
    // be neither waited out nor told apart from any other failure.
    final Dio dio = DioFactory.create(baseUrl: 'https://example.test')
      ..httpClientAdapter = _CloudflareThrottle();

    await expectLater(
      dio.get<dynamic>('/search.php'),
      throwsA(
        isA<DioException>()
            .having(
              (DioException e) => e.type,
              'type',
              DioExceptionType.badResponse,
            )
            .having((DioException e) => e.response?.statusCode, 'status', 429)
            .having(
              (DioException e) => e.response?.headers.value('retry-after'),
              'retry-after',
              '3600',
            ),
      ),
    );
  });
}
