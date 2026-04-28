import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_response.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/network/api_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => AuthSession.fromJson(Map<String, dynamic>.from(json as Map)),
    );

    if (!envelope.success) {
      throw _messageException(envelope.message);
    }

    return envelope.data;
  }

  Future<AppUser> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => AppUser.fromJson(Map<String, dynamic>.from(json as Map)),
    );

    if (!envelope.success) {
      throw _messageException(envelope.message);
    }

    return envelope.data;
  }

  Future<void> logout() async {
    try {
      await _dio.delete<Map<String, dynamic>>('/auth/logout');
    } catch (_) {
      // Se limpia localmente igual.
    }
  }

  Exception _messageException(String message) {
    return Exception(message.trim().isNotEmpty ? message.trim() : 'Operacion no permitida.');
  }
}
