import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_response.dart';
import '../../../core/models/notification_models.dart';
import '../../../core/network/api_client.dart';

final clientNotificationsRepositoryProvider = Provider<ClientNotificationsRepository>((ref) {
  return ClientNotificationsRepository(ref.read(dioProvider));
});

class ClientNotificationsRepository {
  ClientNotificationsRepository(this._dio);

  final Dio _dio;

  Future<List<NotificationItem>> listNotifications() async {
    final response = await _dio.get<Map<String, dynamic>>('/notifications/me');
    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => _listFromJson<NotificationItem>(json, NotificationItem.fromJson),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudieron cargar las notificaciones.');
    }

    return envelope.data;
  }

  Future<int> unreadCount() async {
    final response = await _dio.get<Map<String, dynamic>>('/notifications/me/unread-count');
    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => NotificationUnreadCount.fromJson(Map<String, dynamic>.from(json as Map)),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudo consultar el conteo.');
    }

    return envelope.data.unreadCount;
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch<Map<String, dynamic>>('/notifications/$id/read', data: {});
  }

  Future<void> markAllAsRead() async {
    await _dio.patch<Map<String, dynamic>>('/notifications/me/read-all', data: {});
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
