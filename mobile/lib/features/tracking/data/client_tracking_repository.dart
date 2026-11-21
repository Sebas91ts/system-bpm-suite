import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_response.dart';
import '../../../core/models/process_tracking_models.dart';
import '../../../core/network/offline_support.dart';

final clientTrackingRepositoryProvider = Provider<ClientTrackingRepository>((ref) {
  return ClientTrackingRepository(ref.read(offlineAwareGetClientProvider));
});

class ClientTrackingRepository {
  ClientTrackingRepository(this._reader);

  final OfflineAwareGetClient _reader;

  Future<ClientInstanceTracking> getTracking(String processInstanceId) async {
    final body = await _reader.getJson(
      '/client/instances/$processInstanceId/tracking',
      cacheKey: 'client_tracking:$processInstanceId',
    );
    final envelope = ApiResponse.fromJson(
      body,
      (json) => ClientInstanceTracking.fromJson(Map<String, dynamic>.from(json as Map)),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudo cargar el seguimiento.');
    }

    return envelope.data;
  }
}
