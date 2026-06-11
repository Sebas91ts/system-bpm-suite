import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

final offlineCacheProvider = Provider<OfflineCache>((ref) {
  return OfflineCache(const FlutterSecureStorage());
});

final offlineAwareGetClientProvider = Provider<OfflineAwareGetClient>((ref) {
  return OfflineAwareGetClient(
    dio: ref.read(dioProvider),
    cache: ref.read(offlineCacheProvider),
  );
});

class OfflineCache {
  const OfflineCache(this._storage);

  static const _prefix = 'offline_cache:';

  final FlutterSecureStorage _storage;

  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = await _storage.read(key: '$_prefix$key');
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(decoded);
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    await _storage.write(
      key: '$_prefix$key',
      value: jsonEncode(value),
    );
  }
}

class OfflineAwareGetClient {
  const OfflineAwareGetClient({
    required Dio dio,
    required OfflineCache cache,
  })  : _dio = dio,
        _cache = cache;

  final Dio _dio;
  final OfflineCache _cache;

  Future<Map<String, dynamic>> getJson(
    String path, {
    required String cacheKey,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      final body = Map<String, dynamic>.from(response.data ?? const {});
      if (body['success'] != false) {
        await _cache.writeJson(cacheKey, body);
      }
      return body;
    } catch (error) {
      if (!isOfflineError(error)) {
        rethrow;
      }

      final cached = await _cache.readJson(cacheKey);
      if (cached != null) {
        return cached;
      }

      throw ApiClientException(
        'Sin conexion a internet y sin datos guardados para mostrar. Conectate una vez y vuelve a intentar.',
      );
    }
  }
}

bool isOfflineError(Object error) {
  if (error is! DioException) {
    return false;
  }

  if (error.response != null) {
    return false;
  }

  return switch (error.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout =>
      true,
    DioExceptionType.unknown => true,
    _ => false,
  };
}

String friendlyOfflineMessage(Object error) {
  if (isOfflineError(error)) {
    return 'No hay conexion a internet. Esta accion necesita conectarse al servidor.';
  }
  return error.toString().replaceFirst('Exception: ', '').trim();
}
