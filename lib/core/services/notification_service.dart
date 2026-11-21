import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return NotificationService(firebaseService: firebaseService, ref: ref);
});

final notificationStateProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref _ref;

  NotificationNotifier(this._ref) : super(const NotificationState()) {
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      state = state.copyWith(isPermissionGranted: isGranted);
    } catch (_) {}
  }

  void updateState({
    bool? isPermissionGranted,
    bool? isLoading,
    String? token,
    String? errorMessage,
    RemoteMessage? lastForegroundMessage,
  }) {
    state = state.copyWith(
      isPermissionGranted: isPermissionGranted,
      isLoading: isLoading,
      token: token,
      errorMessage: errorMessage,
      lastForegroundMessage: lastForegroundMessage,
    );
  }

  Future<bool> enableAlerts(String? uid) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final service = _ref.read(notificationServiceProvider);
      final token = await service.requestPermissionAndToken(uid: uid);
      if (token != null) {
        state = state.copyWith(
          isPermissionGranted: true,
          isLoading: false,
          token: token,
        );
        return true;
      } else {
        state = state.copyWith(
          isPermissionGranted: false,
          isLoading: false,
          errorMessage: 'Permission not granted or token unavailable.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

class NotificationService {
  final FirebaseService firebaseService;
  final Ref ref;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;

  NotificationService({
    required this.firebaseService,
    required this.ref,
  });

  FirebaseMessaging? get _messaging {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    final messaging = _messaging;
    if (messaging == null) return;

    try {
      // Foreground message listener
      _messageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] Received: ${message.notification?.title} - ${message.notification?.body}');
        ref.read(notificationStateProvider.notifier).updateState(
              lastForegroundMessage: message,
            );
      });

      // Token refresh listener
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((String newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        ref.read(notificationStateProvider.notifier).updateState(token: newToken);
        final currentUid = firebaseService.auth?.currentUser?.uid;
        if (currentUid != null) {
          firebaseService.saveUserFcmToken(currentUid, newToken);
        }
      });

      _initialized = true;
    } catch (e) {
      debugPrint('[FCM init error]: $e');
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
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!isGranted) {
        debugPrint('[FCM] User declined or has not accepted permission');
        return null;
      }

      final token = await messaging.getToken(vapidKey: kFcmVapidKey);
      debugPrint('[FCM] Token retrieved successfully: $token');

      final effectiveUid = uid ?? firebaseService.auth?.currentUser?.uid;
      if (effectiveUid != null && token != null) {
        await firebaseService.saveUserFcmToken(effectiveUid, token);
      }

      return token;
    } catch (e) {
      debugPrint('[FCM requestPermissionAndToken error]: $e');
      return null;
    }
  }

  void dispose() {
    _messageSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
  }
}
