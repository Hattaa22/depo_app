import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../config/constants.dart';
import '../config/routes.dart';
import 'local_storage.dart';

/// Menyisipkan Bearer token & menangani 401.
class ApiInterceptor extends Interceptor {
  final LocalStorage _storage;

  ApiInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getSecure(AppConstants.keyAccessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    _logRequest(options);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[API] RESPONSE ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.uri}',
      );
      debugPrint('[API] RESPONSE BODY ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (kDebugMode) {
      debugPrint(
        '[API] ERROR ${err.response?.statusCode ?? '-'} '
        '${err.requestOptions.method} ${err.requestOptions.uri}',
      );
      debugPrint('[API] ERROR BODY ${err.response?.data}');
      debugPrint('[API] ERROR MESSAGE ${err.message}');
    }
    if (err.response?.statusCode == 401 &&
        !_isAuthRequest(err.requestOptions.path)) {
      final refreshed = await _refreshAccessToken();
      if (refreshed != null) {
        try {
          err.requestOptions.headers['Authorization'] = 'Bearer $refreshed';
          final retryDio = Dio();
          final retryResponse = await retryDio.fetch(err.requestOptions);
          handler.resolve(retryResponse);
          return;
        } catch (retryError) {
          if (kDebugMode) {
            debugPrint('[API] RETRY AFTER REFRESH FAILED $retryError');
          }
        }
      }

      await _clearSessionAndRedirect();
    }
    handler.next(err);
  }

  bool _isAuthRequest(String path) {
    return path.contains('/auth/login') || path.contains('/auth/refresh');
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await _storage.getSecure(AppConstants.keyRefreshToken);
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
      ));
      final response = await dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      final data = response.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String? ?? '';
      final nextRefreshToken = data['refresh_token'] as String? ?? '';
      if (accessToken.isEmpty || nextRefreshToken.isEmpty) return null;

      await Future.wait([
        _storage.setSecure(AppConstants.keyAccessToken, accessToken),
        _storage.setSecure(AppConstants.keyRefreshToken, nextRefreshToken),
        if (data['role'] != null)
          _storage.setString(AppConstants.keyUserRole, data['role'].toString()),
        if (data['user_data'] is Map &&
            (data['user_data'] as Map)['id'] != null)
          _storage.setString(
            AppConstants.keyUserId,
            (data['user_data'] as Map)['id'].toString(),
          ),
        if (data['user_data'] is Map)
          _storage.setString(
            AppConstants.userDataKey,
            jsonEncode(data['user_data']),
          ),
      ]);

      return accessToken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[API] REFRESH TOKEN FAILED $e');
      }
      return null;
    }
  }

  Future<void> _clearSessionAndRedirect() async {
    await _storage.removeSecure(AppConstants.keyAccessToken);
    await _storage.removeSecure(AppConstants.keyRefreshToken);
    if (Get.key.currentState != null) {
      Get.offAllNamed(AppRoutes.pilihPeran);
    }
  }

  void _logRequest(RequestOptions options) {
    if (!kDebugMode) return;

    final headers = Map<String, dynamic>.from(options.headers);
    if (headers.containsKey('Authorization')) {
      headers['Authorization'] = 'Bearer ***';
    }

    debugPrint('[API] REQUEST ${options.method} ${options.uri}');
    debugPrint('[API] HEADERS $headers');
    if (options.queryParameters.isNotEmpty) {
      debugPrint('[API] QUERY ${options.queryParameters}');
    }
    debugPrint('[API] BODY ${_maskSensitiveData(options.data)}');
  }

  Object? _maskSensitiveData(Object? data) {
    if (data is Map) {
      return data.map((key, value) {
        final name = key.toString().toLowerCase();
        if (name.contains('password') ||
            name.contains('pin') ||
            name.contains('token')) {
          return MapEntry(key, '***');
        }
        return MapEntry(key, _maskSensitiveData(value));
      });
    }
    if (data is List) {
      return data.map(_maskSensitiveData).toList();
    }
    return data;
  }
}
