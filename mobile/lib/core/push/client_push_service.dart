import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../app/config/app_config.dart';
import '../models/auth_models.dart';
import '../storage/session_storage.dart';
import 'push_token_repository.dart';

class ClientPushService {
  ClientPushService({
    required SessionStorage sessionStorage,
    required PushTokenRepository repository,
  })  : _sessionStorage = sessionStorage,
        _repository = repository;

  final SessionStorage _sessionStorage;
  final PushTokenRepository _repository;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AndroidNotificationChannel _androidChannel = const AndroidNotificationChannel(
    'client_push_notifications',
    'Notificaciones de clientes',
    description: 'Avisos del sistema para clientes',
    importance: Importance.high,
  );

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  bool _initialized = false;
  bool _firebaseReady = false;
  String? _currentToken;
  Future<void>? _initializationFuture;

  Future<void> initialize() async {
    if (_initialized && _initializationFuture == null) {
      return;
    }

    if (_initializationFuture != null) {
      await _initializationFuture;
      return;
    }

    _initialized = true;
    _initializationFuture = _doInitialize();
    try {
      await _initializationFuture;
    } finally {
      _initializationFuture = null;
    }
  }

  Future<void> _doInitialize() async {
    if (!AppConfig.firebasePushEnabled) {
      if (kDebugMode) {
        debugPrint('Push deshabilitado: FIREBASE_ENABLED=false');
      }
      return;
    }

    final firebaseOptions = AppConfig.firebaseOptions;
    if (firebaseOptions == null) {
      if (kDebugMode) {
        debugPrint('Push deshabilitado: faltan credenciales de Firebase en .env');
      }
      return;
    }

    try {
      await Firebase.initializeApp(options: firebaseOptions);
      await _initializeLocalNotifications();
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

      _foregroundSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(_handleTokenRefresh);

      _currentToken = await FirebaseMessaging.instance.getToken();
      _firebaseReady = true;

      if (kDebugMode) {
        debugPrint('Firebase push inicializado');
        debugPrint('FCM token inicial: $_currentToken');
      }
    } catch (error) {
      _firebaseReady = false;
      if (kDebugMode) {
        debugPrint('No se pudo inicializar Firebase push: $error');
      }
    }
  }

  Future<void> syncAuthenticatedUser(AppUser user) async {
    if (user == null || !user.isClient) {
      return;
    }

    await initialize();
    if (!_firebaseReady) {
      return;
    }

    final token = await _ensureDeviceToken();
    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        debugPrint('No se obtuvo token FCM para registrar push');
      }
      return;
    }

    _currentToken = token;
    try {
      if (kDebugMode) {
        debugPrint('Registrando token push en backend: $_currentToken');
      }
      await _repository.registerToken(token);
      if (kDebugMode) {
        debugPrint('Token push registrado correctamente en backend');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('No se pudo registrar el token push: $error');
      }
    }
  }

  Future<void> unregisterAuthenticatedUser() async {
    if (!_firebaseReady) {
      return;
    }

    final token = _currentToken ?? await FirebaseMessaging.instance.getToken();
    if (token != null && token.trim().isNotEmpty) {
      try {
        if (kDebugMode) {
          debugPrint('Eliminando token push del backend');
        }
        await _repository.removeToken(token.trim());
      } catch (error) {
        if (kDebugMode) {
          debugPrint('No se pudo eliminar el token push: $error');
        }
      }
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // No bloqueamos logout si Firebase no puede borrar el token local.
    }

    _currentToken = null;
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _localNotifications.initialize(initializationSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<String?> _ensureDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.trim().isNotEmpty) {
        return token.trim();
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('No se pudo obtener FCM token: $error');
      }
    }
    return null;
  }

  Future<void> _handleTokenRefresh(String token) async {
    _currentToken = token.trim();
    final session = await _sessionStorage.readSession();
    final user = session?.user;
    if (user == null || !user.isClient) {
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('Sincronizando token push refrescado');
      }
      await _repository.registerToken(_currentToken!);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('No se pudo sincronizar token refrescado: $error');
      }
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title']?.toString() ?? 'Sistema BPM';
    final body = message.notification?.body ?? message.data['message']?.toString() ?? 'Tienes una nueva notificacion';

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
  }
}
