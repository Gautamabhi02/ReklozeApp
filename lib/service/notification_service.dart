import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

    await _createNotificationChannel();
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

  static bool get _isAndroid {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
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
    // Only show notification if app is NOT foregrounded
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      debugPrint("App is in foreground. Skipping notification.");
      return;
    }

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
      UniqueKey().hashCode,
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
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      debugPrint("App is in foreground. Skipping failed notification.");
      return;
    }

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
      UniqueKey().hashCode,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
