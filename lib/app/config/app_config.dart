import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../firebase_options.dart';

class AppConfig {
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get apiBaseUrl {
    final envBaseUrl = dotenv.env['API_BASE_URL']?.trim() ?? '';
    if (envBaseUrl.isNotEmpty) {
      return _normalize(envBaseUrl);
    }

    if (_overrideBaseUrl.isNotEmpty) {
      return _normalize(_overrideBaseUrl);
    }

    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }

    return 'http://10.0.2.2:8080/api';
  }

  static bool get firebasePushEnabled {
    final raw = dotenv.env['FIREBASE_ENABLED']?.trim().toLowerCase() ?? 'false';
    return raw == 'true' || raw == '1' || raw == 'yes';
  }

  static FirebaseOptions? get firebaseOptions {
    try {
      return DefaultFirebaseOptions.currentPlatform;
    } catch (_) {
      final apiKey = dotenv.env['FIREBASE_API_KEY']?.trim() ?? '';
      final appId = dotenv.env['FIREBASE_APP_ID']?.trim() ?? '';
      final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID']?.trim() ?? '';
      final projectId = dotenv.env['FIREBASE_PROJECT_ID']?.trim() ?? '';

      if ([apiKey, appId, messagingSenderId, projectId].any((value) => value.isEmpty)) {
        return null;
      }

      return FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
      );
    }
  }

  static String _normalize(String value) {
    final trimmed = value.trim();
    final withScheme = trimmed.startsWith('http://') || trimmed.startsWith('https://') ? trimmed : 'http://$trimmed';
    final uri = Uri.tryParse(withScheme);

    if (uri != null && uri.hasAuthority) {
      final normalizedUri = uri.port == 0 ? uri.replace(port: 8080) : uri;
      final path = normalizedUri.path.endsWith('/api')
          ? normalizedUri.path
          : normalizedUri.path.endsWith('/')
              ? '${normalizedUri.path}api'
              : '${normalizedUri.path}/api';

      return normalizedUri.replace(path: path).toString();
    }

    if (withScheme.endsWith('/api')) {
      return withScheme;
    }

    return withScheme.endsWith('/') ? '${withScheme}api' : '$withScheme/api';
  }
}
