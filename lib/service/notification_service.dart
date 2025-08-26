import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Create a static navigator key that can be accessed from anywhere
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onNotificationTap(response);
      },
    );

    // Request notification permissions (only on Android/iOS, not web)
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    if (!_isAndroid) return;

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  static bool get _isAndroid {
    if (kIsWeb) return false;
    try {
      return defaultTargetPlatform == TargetPlatform.android;
    } catch (_) {
      return false;
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload == 'review_page') {
      // Navigate to review page using the global navigator key
      navigatorKey.currentState?.pushNamed('/review');
    }
  }

  static Future<void> showUploadCompleteNotification({
    String title = 'Upload Complete',
    String body = 'Your document upload is complete',
    String payload = 'review_page',
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'upload_channel',
      'Upload Notifications',
      channelDescription: 'Notifications for document upload completion',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      showWhen: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);

    await _notificationsPlugin.show(
      Random().nextInt(1000), 
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
