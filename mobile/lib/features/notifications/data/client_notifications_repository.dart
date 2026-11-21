import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_response.dart';
import '../../../core/models/notification_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/offline_support.dart';

final clientNotificationsRepositoryProvider = Provider<ClientNotificationsRepository>((ref) {
  return ClientNotificationsRepository(
    ref.read(offlineAwareGetClientProvider),
    ref.read(dioProvider),
  );
});

class ClientNotificationsRepository {
  ClientNotificationsRepository(this._reader, this._dio);

  final OfflineAwareGetClient _reader;
  final Dio _dio;

  Future<List<NotificationItem>> listNotifications() async {
    final body = await _reader.getJson(
      '/notifications/me',
      cacheKey: 'client_notifications',
    );
    final envelope = ApiResponse.fromJson(
      body,
      (json) => _listFromJson<NotificationItem>(json, NotificationItem.fromJson),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudieron cargar las notificaciones.');
    }

    return envelope.data;
  }

  Future<int> unreadCount() async {
    final body = await _reader.getJson(
      '/notifications/me/unread-count',
      cacheKey: 'client_notifications_unread_count',
    );
    final envelope = ApiResponse.fromJson(
      body,
      (json) => NotificationUnreadCount.fromJson(Map<String, dynamic>.from(json as Map)),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudo consultar el conteo.');
    }

    return envelope.data.unreadCount;
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch<Map<String, dynamic>>('/notifications/$id/read', data: {});
    } catch (error) {
      throw Exception(friendlyOfflineMessage(error));
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch<Map<String, dynamic>>('/notifications/me/read-all', data: {});
    } catch (error) {
      throw Exception(friendlyOfflineMessage(error));
    }
  }

  List<T> _listFromJson<T>(dynamic json, T Function(Map<String, dynamic>) parser) {
    if (json is! List) {
      return <T>[];
    }

    return json
        .whereType<Map>()
        .map((item) => parser(Map<String, dynamic>.from(item)))
        .toList();
  }
}
