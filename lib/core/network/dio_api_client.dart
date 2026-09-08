
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:drinkopedia/core/network/api_request_manager.dart';
import 'package:get/get.dart' as platform;


/*
This class is used to make Network calls.
 We are using DioHttpClient here, to call the Rest APIs.
 */

class DioHttpClient extends IHttpClient {

  final _connectionTimeout = Duration(seconds: 60);
  final _receiveTimeout = Duration(seconds: 60);
  late Dio _dio;
  BaseOptions? options;
  final String baseUrl =
      "https://fakestoreapi.com/";


  DioHttpClient() {
    options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: _connectionTimeout,
      receiveTimeout: _receiveTimeout,
    );
    _dio = Dio(options);
  }


  @override
  Future deleteRequest({
    required String path,
    data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data;
    } on DioError {
      rethrow;
    }
  }

  @override
  Future getRequest(
      {required String path,
        Map<String, dynamic>? queryParameters,
        Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data;
    } on DioError {
      rethrow;
    }
  }

  @override
  Future patchRequest(
      {required String path,
        data,
        Map<String, String>? queryParameters,
        Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data;
    } on DioError {
      rethrow;
    }
  }

  @override
  Future postRequest(
      {required String path,
        data,
        Map<String, dynamic>? queryParameters,
        Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data;
    } on DioError {
      rethrow;
    }
  }

  @override
  Future uploadRequest(
      {required String path,
        data,
        Map<String, String>? queryParameters,
        Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          receiveTimeout: _connectionTimeout,
          sendTimeout: _receiveTimeout,
        ),
      );
      return response.data;
    } on DioError {
      rethrow;
    }
  }

  @override
  Future putRequest(
      {required String path,
        data,
        Map<String, String>? queryParameters,
        Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          receiveTimeout: _connectionTimeout,
          sendTimeout: _receiveTimeout,
        ),
      );
      return response.data;
    } on DioError {
      rethrow;
    }
  }
}
