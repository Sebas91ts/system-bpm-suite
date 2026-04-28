import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_response.dart';
import '../../../core/models/process_tracking_models.dart';
import '../../../core/network/api_client.dart';

final clientTrackingRepositoryProvider = Provider<ClientTrackingRepository>((ref) {
  return ClientTrackingRepository(ref.read(dioProvider));
});

class ClientTrackingRepository {
  ClientTrackingRepository(this._dio);

  final Dio _dio;

  Future<ClientInstanceTracking> getTracking(String processInstanceId) async {
    final response = await _dio.get<Map<String, dynamic>>('/client/instances/$processInstanceId/tracking');
    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => ClientInstanceTracking.fromJson(Map<String, dynamic>.from(json as Map)),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudo cargar el seguimiento.');
    }

    return envelope.data;
  }
}
