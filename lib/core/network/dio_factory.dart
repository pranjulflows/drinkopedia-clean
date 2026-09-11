import 'package:dio/dio.dart';
import 'package:drinkopedia/core/network/retry_after_interceptor.dart';

/// Builds the configured [Dio] instances the retrofit clients are driven by.
///
/// One per upstream source: each has its own base URL and header requirements,
/// and sharing a single instance would leak one source's headers into another.
class DioFactory {
  DioFactory._();

  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 30);

  static Dio create({
    required String baseUrl,
    Map<String, dynamic>? headers,
    List<Interceptor> interceptors = const <Interceptor>[],
  }) {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        headers: headers,
        // TheCocktailDB answers a miss with 200 + a null collection rather than
        // a 404, so status handling stays conventional here.
        responseType: ResponseType.json,
        // An error's body is never read — failures are mapped on status code
        // alone — and decoding one can destroy the error. Cloudflare's 429 in
        // front of TheCocktailDB claims to be JSON but is plain text; parsing
        // it throws a FormatException that Dio reports *instead of* the 429,
        // with no status and no Retry-After, and the throttle becomes an
        // unexplained failure nothing can wait out.
        receiveDataWhenStatusError: false,
      ),
    );
    dio.interceptors
      ..addAll(interceptors)
      // Every source here is a free public API; waiting out a 429 is the
      // right answer for all of them.
      ..add(RetryAfterInterceptor(dio));
    return dio;
  }
}
