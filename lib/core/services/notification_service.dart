import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

const String kFcmVapidKey =
    'BDHxcL871mjFTP7qgVFEVaEdyQgGeSEir3q4Dfvod5s9FKOUSu8xvU1K33104KzYZ6nI0gX1HuK2-esqhWMTX5g';

class NotificationState {
  final bool isPermissionGranted;
  final bool isLoading;
  final String? token;
  final String? errorMessage;
  final RemoteMessage? lastForegroundMessage;

  const NotificationState({
    this.isPermissionGranted = false,
    this.isLoading = false,
    this.token,
    this.errorMessage,
    this.lastForegroundMessage,
  });

  NotificationState copyWith({
    bool? isPermissionGranted,
    bool? isLoading,
    String? token,
    String? errorMessage,
    RemoteMessage? lastForegroundMessage,
  }) {
    return NotificationState(
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      errorMessage: errorMessage,
      lastForegroundMessage: lastForegroundMessage ?? this.lastForegroundMessage,
    );
  }
}

/// Pure Flutter ChangeNotifier for FCM push notifications
class NotificationProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  NotificationState _state = const NotificationState();
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;

  NotificationProvider({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService.instance {
    _checkInitialStatus();
  }

  NotificationState get state => _state;
  bool get isPermissionGranted => _state.isPermissionGranted;
  bool get isLoading => _state.isLoading;
  String? get token => _state.token;
  String? get errorMessage => _state.errorMessage;
  RemoteMessage? get lastForegroundMessage => _state.lastForegroundMessage;

  FirebaseMessaging? get _messaging {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkInitialStatus() async {
    try {
      final messaging = _messaging;
      if (messaging == null) return;
      final settings = await messaging.getNotificationSettings();
      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      _state = _state.copyWith(isPermissionGranted: isGranted);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> init() async {
    if (_initialized) return;
    final messaging = _messaging;
    if (messaging == null) return;

    try {
      // Foreground message listener
      _messageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] Received: ${message.notification?.title} - ${message.notification?.body}');
        _state = _state.copyWith(lastForegroundMessage: message);
        notifyListeners();
      });

      // Token refresh listener
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((String newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        _state = _state.copyWith(token: newToken);
        notifyListeners();
        final currentUid = _firebaseService.auth?.currentUser?.uid;
        if (currentUid != null) {
          _firebaseService.saveUserFcmToken(currentUid, newToken);
        }
      });

      _initialized = true;
    } catch (e) {
      debugPrint('[FCM] Init error: $e');
    }
  }

  Future<bool> enableAlerts(String? uid) async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final token = await requestPermissionAndToken(uid: uid);
      if (token != null) {
        _state = _state.copyWith(
          isPermissionGranted: true,
          isLoading: false,
          token: token,
        );
        notifyListeners();
        return true;
      } else {
        _state = _state.copyWith(
          isPermissionGranted: false,
          isLoading: false,
          errorMessage: 'Permission not granted or token unavailable.',
        );
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  Future<String?> requestPermissionAndToken({String? uid}) async {
    final messaging = _messaging;
    if (messaging == null) return null;

    try {
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!granted) return null;

      final fcmToken = await messaging.getToken(vapidKey: kFcmVapidKey);
      if (fcmToken != null) {
        _state = _state.copyWith(
          isPermissionGranted: true,
          token: fcmToken,
        );
        notifyListeners();

        final targetUid = uid ?? _firebaseService.auth?.currentUser?.uid;
        if (targetUid != null) {
          await _firebaseService.saveUserFcmToken(targetUid, fcmToken);
        }
      }
      return fcmToken;
    } catch (e) {
      debugPrint('[FCM] Token acquisition error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }
}
