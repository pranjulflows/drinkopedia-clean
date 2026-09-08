import 'package:dio/dio.dart';

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
      ),
    );
    dio.interceptors.addAll(interceptors);
    return dio;
  }
}
