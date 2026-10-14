import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth_repository.dart';
import '../api/push_repository.dart';
import '../firebase_options.dart';

typedef PushOpenHandler = void Function(Map<String, dynamic> data);

/// Registers the FCM token with the Laravel portal after login.
/// No-ops until Firebase options / google-services are configured.
class PushService {
  PushService._();

  static final PushService instance = PushService._();
  static const _tokenPrefsKey = 'fcm_token';

  bool _ready = false;
  PushOpenHandler? onOpened;
  final _local = FlutterLocalNotificationsPlugin();

  bool get isReady => _ready;

  Future<void> initialize({PushOpenHandler? onOpened}) async {
    this.onOpened = onOpened;
    if (!DefaultFirebaseOptions.isConfigured) {
      debugPrint('PushService: Firebase options not configured yet.');
      return;
    }

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await _initLocalNotifications();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _handleOpened(initial);
      }

      messaging.onTokenRefresh.listen((token) async {
        await _persistToken(token);
        // Caller should re-sync after login; refresh alone stores locally.
      });

      _ready = true;
    } catch (error, stack) {
      debugPrint('PushService: init failed: $error\n$stack');
      _ready = false;
    }
  }

  Future<void> syncToken(AuthRepository auth) async {
    if (!_ready) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _persistToken(token);
      await PushRepository(auth.client).register(token);
    } catch (error) {
      debugPrint('PushService: token sync failed: $error');
    }
  }

  Future<void> clearToken(AuthRepository auth) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenPrefsKey);
    if (token == null || token.isEmpty) return;
    try {
      await PushRepository(auth.client).unregister(token);
    } catch (_) {
      // Best-effort on logout.
    }
    await prefs.remove(_tokenPrefsKey);
  }

  Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefsKey, token);
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        final parts = payload.split('|');
        final type = parts.first;
        final id = parts.length > 1 ? parts[1] : null;
        final data = <String, dynamic>{'type': type};
        if (id != null && id.isNotEmpty) {
          if (type.startsWith('appointment')) {
            data['appointment_id'] = id;
          } else if (type == 'payment_request' || type == 'payment_received' || type == 'payment_refunded' || type == 'billing') {
            data['request_id'] = id;
          } else {
            data['thread_id'] = id;
          }
        }
        onOpened?.call(data);
      },
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'clinic_messages',
        'Clinic messages',
        description: 'New secure messages from your clinic',
        importance: Importance.high,
      );
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'Patient portal';
    final body = notification?.body ?? 'You have a new clinic update.';
    final type = message.data['type']?.toString() ?? message.data['category']?.toString() ?? 'message';
    final deepLinkId = message.data['appointment_id']?.toString()
        ?? message.data['thread_id']?.toString()
        ?? message.data['request_id']?.toString();

    await _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'clinic_messages',
          'Clinic messages',
          channelDescription: 'New secure messages from your clinic',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: deepLinkId == null ? type : '$type|$deepLinkId',
    );
  }

  void _handleOpened(RemoteMessage message) {
    onOpened?.call(Map<String, dynamic>.from(message.data));
  }
}
