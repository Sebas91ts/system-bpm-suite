import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_response.dart';
import '../../../core/models/process_models.dart';
import '../../../core/network/api_client.dart';

final clientProcessRepositoryProvider = Provider<ClientProcessRepository>((ref) {
  return ClientProcessRepository(ref.read(dioProvider));
});

class ClientProcessRepository {
  ClientProcessRepository(this._dio);

  final Dio _dio;

  Future<List<ClientProcessListItem>> listProcesses() async {
    final response = await _dio.get<Map<String, dynamic>>('/client/processes');
    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => _listFromJson<ClientProcessListItem>(json, ClientProcessListItem.fromJson),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudieron cargar los tramites.');
    }

    return envelope.data;
  }

  Future<ClientProcessStartPreview> startPreview(String processId) async {
    final response = await _dio.get<Map<String, dynamic>>('/client/processes/$processId/start-preview');
    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => ClientProcessStartPreview.fromJson(Map<String, dynamic>.from(json as Map)),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudo cargar el formulario inicial.');
    }

    return envelope.data;
  }

  Future<ClientProcessStartResult> startProcess(
    String processId, {
    required Map<String, dynamic> variables,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/client/processes/$processId/start',
      data: {'variables': variables},
    );

    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => ClientProcessStartResult.fromJson(Map<String, dynamic>.from(json as Map)),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudo iniciar el tramite.');
    }

    if (envelope.message.trim().isNotEmpty && envelope.data.message.trim().isEmpty) {
      return ClientProcessStartResult(
        id: envelope.data.id,
        clientUserId: envelope.data.clientUserId,
        clientEmail: envelope.data.clientEmail,
        processId: envelope.data.processId,
        processKey: envelope.data.processKey,
        processVersion: envelope.data.processVersion,
        processName: envelope.data.processName,
        processInstanceId: envelope.data.processInstanceId,
        estado: envelope.data.estado,
        startedAt: envelope.data.startedAt,
        message: envelope.message,
        finishedAt: envelope.data.finishedAt,
      );
    }

    return envelope.data;
  }

  Future<List<ClientProcessInstanceItem>> listInstances() async {
    final response = await _dio.get<Map<String, dynamic>>('/client/instances');
    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => _listFromJson<ClientProcessInstanceItem>(json, ClientProcessInstanceItem.fromJson),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudieron cargar tus tramites.');
    }

    return envelope.data;
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
