import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Create a static navigator key that can be accessed from anywhere
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Notification channel IDs
  static const String uploadChannelId = 'upload_channel';
  static const String uploadChannelName = 'Upload Notifications';
  static const String uploadChannelDescription = 'Notifications for document upload completion';

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

    // Create notification channel with sound
    await _createNotificationChannel();

    // Request notification permissions (only on Android/iOS, not web)
    await _requestPermissions();
  }

  static Future<void> _createNotificationChannel() async {
    if (!_isAndroid) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      uploadChannelId,
      uploadChannelName,
      description: uploadChannelDescription,
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_ringtone'),
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  static Future<void> _requestPermissions() async {
    if (!_isAndroid) return;

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Safe check: works on Web + Android + iOS
  static bool get _isAndroid {
    if (kIsWeb) return false; // Web fallback
    try {
      return defaultTargetPlatform == TargetPlatform.android;
    } catch (_) {
      return false;
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload == 'review_page') {

      navigatorKey.currentState?.pushNamed('/review');
    }
  }

  static Future<void> showUploadCompleteNotification({
    String title = 'Upload Complete',
    String body = 'Your document upload is complete',
    String payload = 'review_page',
  }) async {
    // Android notification details with sound
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      uploadChannelId,
      uploadChannelName,
      channelDescription: uploadChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true, // Enable sound
      sound: RawResourceAndroidNotificationSound('notification_ringtone'),
      enableVibration: true,
      showWhen: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);

    await _notificationsPlugin.show(
      Random().nextInt(1000), // Random ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
  static Future<void> showUploadFailedNotification({
    String title = 'Upload Failed',
    String body = 'Your document upload failed',
    String payload = 'upload_failed',
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      uploadChannelId,
      uploadChannelName,
      channelDescription: uploadChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_ringtone'),
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
  static Future<void> showImportantNotification({
    String title = 'Important',
    String body = 'You have an important notification',
    String payload = 'important',
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'important_channel',
      'Important Notifications',
      channelDescription: 'Important notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_ringtone'),
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