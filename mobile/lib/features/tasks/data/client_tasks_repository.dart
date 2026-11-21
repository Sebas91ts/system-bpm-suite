import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_response.dart';
import '../../../core/models/client_task_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/offline_support.dart';

final clientTasksRepositoryProvider = Provider<ClientTasksRepository>((ref) {
  return ClientTasksRepository(
    ref.read(offlineAwareGetClientProvider),
    ref.read(dioProvider),
  );
});

class ClientTasksRepository {
  ClientTasksRepository(this._reader, this._dio);

  final OfflineAwareGetClient _reader;
  final Dio _dio;

  Future<List<ClientTaskListItem>> listTasks() async {
    final body = await _reader.getJson(
      '/client/tasks',
      cacheKey: 'client_tasks',
    );
    final envelope = ApiResponse.fromJson(
      body,
      (json) => _listFromJson<ClientTaskListItem>(json, ClientTaskListItem.fromJson),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudieron cargar las tareas.');
    }

    return envelope.data;
  }

  Future<ClientTaskFormResponse> getForm(String taskId) async {
    final body = await _reader.getJson(
      '/client/tasks/$taskId/form',
      cacheKey: 'client_task_form:$taskId',
    );
    final envelope = ApiResponse.fromJson(
      body,
      (json) => ClientTaskFormResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudo abrir el formulario.');
    }

    return envelope.data;
  }

  Future<ClientTaskCompleteResponse> completeTask(String taskId, FormData payload) async {
    late final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        '/client/tasks/$taskId/complete',
        data: payload,
        options: Options(contentType: 'multipart/form-data'),
      );
    } catch (error) {
      throw Exception(friendlyOfflineMessage(error));
    }

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
