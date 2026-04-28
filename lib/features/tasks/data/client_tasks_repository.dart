import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_response.dart';
import '../../../core/models/client_task_models.dart';
import '../../../core/network/api_client.dart';

final clientTasksRepositoryProvider = Provider<ClientTasksRepository>((ref) {
  return ClientTasksRepository(ref.read(dioProvider));
});

class ClientTasksRepository {
  ClientTasksRepository(this._dio);

  final Dio _dio;

  Future<List<ClientTaskListItem>> listTasks() async {
    final response = await _dio.get<Map<String, dynamic>>('/client/tasks');
    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => _listFromJson<ClientTaskListItem>(json, ClientTaskListItem.fromJson),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudieron cargar las tareas.');
    }

    return envelope.data;
  }

  Future<ClientTaskFormResponse> getForm(String taskId) async {
    final response = await _dio.get<Map<String, dynamic>>('/client/tasks/$taskId/form');
    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => ClientTaskFormResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudo abrir el formulario.');
    }

    return envelope.data;
  }

  Future<ClientTaskCompleteResponse> completeTask(String taskId, FormData payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/client/tasks/$taskId/complete',
      data: payload,
      options: Options(contentType: 'multipart/form-data'),
    );

    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => ClientTaskCompleteResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudo completar la tarea.');
    }

    return envelope.data;
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
