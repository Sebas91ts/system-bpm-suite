import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_response.dart';
import '../../../core/models/process_models.dart';
import '../../../core/network/offline_support.dart';

final clientInstancesRepositoryProvider = Provider<ClientInstancesRepository>((ref) {
  return ClientInstancesRepository(ref.read(offlineAwareGetClientProvider));
});

class ClientInstancesRepository {
  ClientInstancesRepository(this._reader);

  final OfflineAwareGetClient _reader;

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
