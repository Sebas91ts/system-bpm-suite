import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
