import 'package:dio/dio.dart';
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
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/login')) {
      await _storage.removeSecure(AppConstants.keyAccessToken);
      await _storage.removeSecure(AppConstants.keyRefreshToken);
      if (Get.key.currentState != null) {
        Get.offAllNamed(AppRoutes.pilihPeran);
      }
    }
    handler.next(err);
  }
}
