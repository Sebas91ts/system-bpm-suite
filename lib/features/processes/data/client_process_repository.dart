import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_response.dart';
import '../../../core/models/process_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/offline_support.dart';

final clientProcessRepositoryProvider = Provider<ClientProcessRepository>((ref) {
  return ClientProcessRepository(
    ref.read(offlineAwareGetClientProvider),
    ref.read(dioProvider),
  );
});

class ClientProcessRepository {
  ClientProcessRepository(this._reader, this._dio);

  final OfflineAwareGetClient _reader;
  final Dio _dio;

  Future<List<ClientProcessListItem>> listProcesses() async {
    final body = await _reader.getJson(
      '/client/processes',
      cacheKey: 'client_processes',
    );
    final envelope = ApiResponse.fromJson(
      body,
      (json) => _listFromJson<ClientProcessListItem>(json, ClientProcessListItem.fromJson),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudieron cargar los tramites.');
    }

    return envelope.data;
  }

  Future<ClientProcessStartPreview> startPreview(String processId) async {
    final body = await _reader.getJson(
      '/client/processes/$processId/start-preview',
      cacheKey: 'client_process_start_preview:$processId',
    );
    final envelope = ApiResponse.fromJson(
      body,
      (json) => ClientProcessStartPreview.fromJson(_requireMapData(json, fallbackMessage: body['message'] as String?)),
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
    late final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        '/client/processes/$processId/start',
        data: {'variables': variables},
      );
    } catch (error) {
      throw Exception(friendlyOfflineMessage(error));
    }

    final body = Map<String, dynamic>.from(response.data ?? const {});
    final envelope = ApiResponse.fromJson(
      body,
      (json) => ClientProcessStartResult.fromJson(_requireMapData(json, fallbackMessage: body['message'] as String?)),
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
    final body = await _reader.getJson(
      '/client/instances',
      cacheKey: 'client_instances',
    );
    final envelope = ApiResponse.fromJson(
      body,
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

Map<String, dynamic> _requireMapData(dynamic json, {String? fallbackMessage}) {
  if (json is Map<String, dynamic>) {
    return json;
  }

  if (json is Map) {
    return Map<String, dynamic>.from(json);
  }

  final normalizedMessage = fallbackMessage?.trim();
  throw Exception(
    normalizedMessage != null && normalizedMessage.isNotEmpty
        ? normalizedMessage
        : 'El servidor no devolvio la informacion esperada.',
  );
}
