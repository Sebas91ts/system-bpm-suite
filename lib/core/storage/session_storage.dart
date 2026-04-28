import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_models.dart';

class SessionStorage extends ChangeNotifier {
  SessionStorage(this._storage);

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final FlutterSecureStorage _storage;

  Future<AuthSession?> readSession() async {
    final token = await _storage.read(key: _tokenKey);
    final userRaw = await _storage.read(key: _userKey);

    if (token == null || token.isEmpty || userRaw == null || userRaw.isEmpty) {
      return null;
    }

    try {
      final userJson = jsonDecode(userRaw);
      if (userJson is! Map<String, dynamic>) {
        return null;
      }

      return AuthSession(
        token: token,
        tokenType: 'Bearer',
        expiresIn: 0,
        user: AppUser.fromJson(userJson),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveSession(AuthSession session) async {
    await _storage.write(key: _tokenKey, value: session.token);
    await _storage.write(key: _userKey, value: jsonEncode(session.user.toJson()));
    notifyListeners();
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    notifyListeners();
  }

  Future<AppUser?> readUser() async {
    final session = await readSession();
    return session?.user;
  }
}
