import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../app/config/app_config.dart';
import '../storage/session_storage.dart';
import '../errors/app_exception.dart';

final sessionStorageProvider = ChangeNotifierProvider<SessionStorage>((ref) {
  return SessionStorage(const FlutterSecureStorage());
});

final dioProvider = Provider<Dio>((ref) {
  final sessionStorage = ref.watch(sessionStorageProvider);
  if (kDebugMode) {
    debugPrint('API base url: ${AppConfig.apiBaseUrl}');
  }
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await sessionStorage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          await sessionStorage.clearSession();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

class ApiClientException extends AppException {
  ApiClientException(super.message, {super.statusCode});
}
