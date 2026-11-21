import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/auth_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/push/client_push_service.dart';
import '../../../core/push/push_providers.dart';
import '../../../core/storage/session_storage.dart';
import '../data/auth_repository.dart';

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(
    sessionStorage: ref.read(sessionStorageProvider),
    repository: ref.read(authRepositoryProvider),
    pushService: ref.read(clientPushServiceProvider),
  );
});

class AuthState {
  const AuthState({
    required this.bootstrapping,
    required this.loading,
    required this.user,
    required this.errorMessage,
  });

  final bool bootstrapping;
  final bool loading;
  final AppUser? user;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? bootstrapping,
    bool? loading,
    AppUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      bootstrapping: bootstrapping ?? this.bootstrapping,
      loading: loading ?? this.loading,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  factory AuthState.initial() {
    return const AuthState(
      bootstrapping: true,
      loading: false,
      user: null,
      errorMessage: null,
    );
  }
}

class AuthController extends ChangeNotifier {
  AuthController({
    required SessionStorage sessionStorage,
    required AuthRepository repository,
    required ClientPushService pushService,
  })  : _sessionStorage = sessionStorage,
        _repository = repository,
        _pushService = pushService,
        _state = AuthState.initial() {
    _sessionStorage.addListener(_handleStorageChanged);
  }

  final SessionStorage _sessionStorage;
  final AuthRepository _repository;
  final ClientPushService _pushService;
  AuthState _state;
  bool _bootstrapped = false;

  AuthState get state => _state;

  void _emit(AuthState next) {
    _state = next;
    notifyListeners();
  }

  Future<void> bootstrap() async {
    if (_bootstrapped) {
      return;
    }

    _bootstrapped = true;
    _emit(_state.copyWith(bootstrapping: true, errorMessage: null));

    try {
      final session = await _sessionStorage.readSession();
      if (session == null) {
        _emit(AuthState(
          bootstrapping: false,
          loading: false,
          user: null,
          errorMessage: null,
        ));
        return;
      }

      final currentUser = await _repository.me();
      if (!currentUser.isClient) {
        await _pushService.unregisterAuthenticatedUser();
        await _sessionStorage.clearSession();
        _emit(AuthState(
          bootstrapping: false,
          loading: false,
          user: null,
          errorMessage: 'Esta aplicacion es solo para clientes.',
        ));
        return;
      }

      await _sessionStorage.saveSession(
        AuthSession(
          token: session.token,
          tokenType: session.tokenType,
          expiresIn: session.expiresIn,
          user: currentUser,
        ),
      );
      await _pushService.syncAuthenticatedUser(currentUser);

      _emit(AuthState(
        bootstrapping: false,
        loading: false,
        user: currentUser,
        errorMessage: null,
      ));
    } catch (_) {
      await _sessionStorage.clearSession();
      _emit(AuthState(
        bootstrapping: false,
        loading: false,
        user: null,
        errorMessage: null,
      ));
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _emit(_state.copyWith(loading: true, errorMessage: null));

    try {
      final session = await _repository.login(email: email, password: password);
      if (!session.user.isClient) {
        await _pushService.unregisterAuthenticatedUser();
        await _sessionStorage.clearSession();
        _emit(AuthState(
          bootstrapping: false,
          loading: false,
          user: null,
          errorMessage: 'Esta aplicacion es solo para clientes.',
        ));
        return;
      }

      await _sessionStorage.saveSession(session);
      await _pushService.syncAuthenticatedUser(session.user);
      _emit(AuthState(
        bootstrapping: false,
        loading: false,
        user: session.user,
        errorMessage: null,
      ));
    } catch (error) {
      await _sessionStorage.clearSession();
      _emit(AuthState(
        bootstrapping: false,
        loading: false,
        user: null,
        errorMessage: _extractMessage(error),
      ));
    }
  }

  Future<void> logout({bool remote = true}) async {
    _emit(_state.copyWith(loading: true, errorMessage: null));

    await _pushService.unregisterAuthenticatedUser();

    if (remote) {
      await _repository.logout();
    }

    await _sessionStorage.clearSession();
    _emit(AuthState(
      bootstrapping: false,
      loading: false,
      user: null,
      errorMessage: null,
    ));
  }

  void clearError() {
    if (_state.errorMessage == null) {
      return;
    }

    _emit(_state.copyWith(errorMessage: null));
  }

  void _handleStorageChanged() async {
    final session = await _sessionStorage.readSession();
    if (session == null && _state.isAuthenticated) {
      _emit(AuthState(
        bootstrapping: false,
        loading: false,
        user: null,
        errorMessage: null,
      ));
      return;
    }

    if (session != null && _state.user?.id != session.user.id) {
      _emit(AuthState(
        bootstrapping: false,
        loading: false,
        user: session.user,
        errorMessage: null,
      ));
    }
  }

  String _extractMessage(Object error) {
    final text = error.toString();
    if (text.trim().isNotEmpty) {
      return text;
    }

    return 'No se pudo iniciar sesion.';
  }

  @override
  void dispose() {
    _sessionStorage.removeListener(_handleStorageChanged);
    super.dispose();
  }
}
