import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_response.dart';
import '../../../core/models/process_models.dart';
import '../../../core/network/api_client.dart';

final clientInstancesRepositoryProvider = Provider<ClientInstancesRepository>((ref) {
  return ClientInstancesRepository(ref.read(dioProvider));
});

class ClientInstancesRepository {
  ClientInstancesRepository(this._dio);

  final Dio _dio;

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
