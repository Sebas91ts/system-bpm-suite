import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import 'client_push_service.dart';
import 'push_token_repository.dart';

final clientPushServiceProvider = Provider<ClientPushService>((ref) {
  return ClientPushService(
    sessionStorage: ref.read(sessionStorageProvider),
    repository: ref.read(pushTokenRepositoryProvider),
  );
});
