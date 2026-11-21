import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

final pushTokenRepositoryProvider = Provider<PushTokenRepository>((ref) {
  return PushTokenRepository(ref.read(dioProvider));
});

class PushTokenRepository {
  PushTokenRepository(this._dio);

  final Dio _dio;

  Future<void> registerToken(String token) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/notifications/me/push-token',
      data: {'token': token},
    );
    _ensureSuccess(response.data, fallbackMessage: 'No se pudo registrar el token push.');
  }

  Future<void> removeToken(String token) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/notifications/me/push-token',
      queryParameters: {'token': token},
    );
    _ensureSuccess(response.data, fallbackMessage: 'No se pudo eliminar el token push.');
  }

  void _ensureSuccess(dynamic data, {required String fallbackMessage}) {
    final body = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    if (body['success'] == true) {
      return;
    }

    final message = (body['message'] as String?)?.trim();
    throw Exception(message != null && message.isNotEmpty ? message : fallbackMessage);
  }
}
