import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drinkopedia/core/network/retry_after_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers each request with the next scripted status, then 200 forever.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.statuses, {this.retryAfter = '10'});

  final List<int> statuses;
  final String? retryAfter;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final int status = calls < statuses.length ? statuses[calls] : 200;
    calls++;
    return ResponseBody.fromString(
      jsonEncode(<String, dynamic>{'status': status}),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        if (status == 429 && retryAfter != null)
          'retry-after': <String>[retryAfter!],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late List<Duration> waits;

  Dio build(_ScriptedAdapter adapter, {int maxRetries = 2}) {
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      RetryAfterInterceptor(
        dio,
        maxRetries: maxRetries,
        wait: (Duration d) async => waits.add(d),
      ),
    );
    return dio;
  }

  setUp(() => waits = <Duration>[]);

  test('waits out a 429 for as long as it asks, then succeeds', () async {
    final _ScriptedAdapter adapter = _ScriptedAdapter(<int>[429]);

    final Response<dynamic> response = await build(adapter).get<dynamic>('/x');

    expect(response.statusCode, 200);
    expect(adapter.calls, 2);
    expect(waits, <Duration>[const Duration(seconds: 10)]);
  });

  test('gives up after its retries and passes the 429 on', () async {
    final _ScriptedAdapter adapter = _ScriptedAdapter(<int>[429, 429, 429]);

    await expectLater(
      build(adapter).get<dynamic>('/x'),
      throwsA(
        isA<DioException>().having(
          (DioException e) => e.response?.statusCode,
          'status',
          429,
        ),
      ),
    );
    // The first try and two retries: the count survives the retry going back
    // through the interceptors, or this would loop for as long as upstream
    // kept saying no.
    expect(adapter.calls, 3);
  });

  test('falls back to a default wait when no delay is named', () async {
    final _ScriptedAdapter adapter = _ScriptedAdapter(<int>[
      429,
    ], retryAfter: null);

    await build(adapter).get<dynamic>('/x');

    expect(waits, <Duration>[RetryAfterInterceptor.fallbackWait]);
  });

  test('does not hold a request for an unreasonable wait', () async {
    final _ScriptedAdapter adapter = _ScriptedAdapter(<int>[
      429,
    ], retryAfter: '3600');

    await expectLater(
      build(adapter).get<dynamic>('/x'),
      throwsA(isA<DioException>()),
    );
    expect(waits, isEmpty);
  });

  test('leaves every other error alone', () async {
    final _ScriptedAdapter adapter = _ScriptedAdapter(<int>[503]);

    await expectLater(
      build(adapter).get<dynamic>('/x'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.calls, 1);
    expect(waits, isEmpty);
  });
}
