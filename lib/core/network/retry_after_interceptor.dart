import 'package:dio/dio.dart';

/// Waits out a `429 Too Many Requests` and tries again.
///
/// TheCocktailDB's free key sits behind Cloudflare, which starts answering 429
/// with `Retry-After: 10` about ninety requests into a burst. Browsing
/// normally never gets there, but a search or filter that pages through the
/// whole catalogue does. Passing that 429 straight up would turn "slow down
/// for ten seconds" into "failed", so the request is held and repeated here,
/// below anything that would have to know about it.
class RetryAfterInterceptor extends Interceptor {
  RetryAfterInterceptor(
    this._dio, {
    this.maxRetries = 2,
    this.maxWait = const Duration(seconds: 30),
    Future<void> Function(Duration delay)? wait,
  }) : _wait = wait ?? _sleep;

  /// Used when a 429 names no delay, or one this cannot read.
  static const Duration fallbackWait = Duration(seconds: 10);

  static const String _attemptKey = 'retryAfterAttempt';

  final Dio _dio;
  final int maxRetries;

  /// Longest delay worth holding a request for. Past this the caller is
  /// better off failing and offering a retry than showing a skeleton forever.
  final Duration maxWait;

  final Future<void> Function(Duration delay) _wait;

  static Future<void> _sleep(Duration delay) => Future<void>.delayed(delay);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final Response<dynamic>? response = err.response;
    if (response?.statusCode != 429) return handler.next(err);

    final RequestOptions options = err.requestOptions;
    final int attempt = (options.extra[_attemptKey] as int?) ?? 0;
    final Duration delay = _retryAfter(response!);
    if (attempt >= maxRetries || delay > maxWait) return handler.next(err);

    await _wait(delay);
    options.extra[_attemptKey] = attempt + 1;
    try {
      // Goes back through the interceptors, so a second 429 lands here again
      // with the attempt count already raised.
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// `Retry-After` in its delay-seconds form. The HTTP-date form is legal but
  /// not what Cloudflare sends, so it falls back rather than being parsed.
  Duration _retryAfter(Response<dynamic> response) {
    final int? seconds = int.tryParse(
      response.headers.value('retry-after')?.trim() ?? '',
    );
    if (seconds == null || seconds < 0) return fallbackWait;
    return Duration(seconds: seconds);
  }
}
