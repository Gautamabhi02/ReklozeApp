import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import 'package:workmanager/workmanager.dart';

// Global callback dispatcher
@pragma('vm:entry-point')
void dateNotificationCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('📨 WorkManager task received: $taskName');

    // Initialize notifications in background
    await _initializeNotificationsInBackground();

    if (taskName.startsWith('date_reminder_')) {
      try {
        final dateName = inputData?['dateName'] ?? '';
        final title = inputData?['title'] ?? '';
        final body = inputData?['body'] ?? '';
        final notificationId = inputData?['notificationId'] ?? 0;

        debugPrint('📋 Processing date notification: $dateName');
        await _showBackgroundNotification(title, body, notificationId, dateName);
        return Future.value(true);
      } catch (e) {
        debugPrint('❌ Error in background notification: $e');
        return Future.value(false);
      }
    }
    return Future.value(false);
  });
}

Future<void> _initializeNotificationsInBackground() async {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await notificationsPlugin.initialize(initializationSettings);
}

// Helper function to show notification in background
Future<void> _showBackgroundNotification(
    String title, String body, int id, String dateName) async {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  const AndroidNotificationDetails androidNotificationDetails =
  AndroidNotificationDetails(
    'contract_date_channel',
    'Contract Date Reminders',
    channelDescription: 'Notifications for contract date deadlines',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    sound: RawResourceAndroidNotificationSound('notification_ringtone'),
  );

  const NotificationDetails notificationDetails =
  NotificationDetails(android: androidNotificationDetails);

  await notificationsPlugin.show(
    id,
    title,
    body,
    notificationDetails,
    payload: 'date_reminder:$dateName',
  );

  debugPrint('✅ Background notification shown: $title');
}

class OpportunityNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const String dateChannelId = 'contract_date_channel';
  static const String dateChannelName = 'Contract Date Reminders';
  static const String dateChannelDescription = 'Notifications for contract date deadlines';

  // Instance for accessing hardcoded dates
  static final OpportunityNotificationService _instance = OpportunityNotificationService._internal();
  factory OpportunityNotificationService() => _instance;
  OpportunityNotificationService._internal();


  final Map<String, DateTime> hardcodedDates = {
    'Effective Contract Date': DateTime(2025, 9, 11),
    'Initial escrow deposit Due Date': DateTime(2025, 9, 13),
    'Loan Application Due Date': DateTime(2025, 9, 12),
    'Additional Escrow Deposit Due Date': DateTime(2025, 9, 14),
    'Inspection Period Ends': DateTime(2025, 9, 21),
    'Loan Approval Period Ends': DateTime(2025, 10, 11),
    'Title Evidence Due Date': DateTime(2025, 10, 6),
    'Closing Date': DateTime(2025, 9, 10),
  };

  static Future<void> initialize() async {
    if (kIsWeb) return;

    // Initialize timezone
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    await _createDateNotificationChannel();
    await _requestPermissions();

    // Initialize WorkManager with the global callback
    await Workmanager().initialize(
      dateNotificationCallbackDispatcher,
      isInDebugMode: true,
    );

    debugPrint('✅ OpportunityNotificationService initialized successfully');

    // Schedule notifications immediately after initialization
    await _instance.scheduleAllDateNotifications();
  }

  static Future<void> _createDateNotificationChannel() async {
    if (kIsWeb || !Platform.isAndroid) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      dateChannelId,
      dateChannelName,
      description: dateChannelDescription,
      importance: Importance.high,
      playSound: true,
       sound: RawResourceAndroidNotificationSound('notification_ringtone'),
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    debugPrint('Date notification channel created');
  }

  static Future<void> _requestPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return;

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    final granted = await androidPlugin?.requestNotificationsPermission();
    debugPrint('Notification permission granted: $granted');
  }

  Future<void> scheduleAllDateNotifications() async {
    if (kIsWeb) return;

    // Cancel all existing tasks first
    await Workmanager().cancelAll();

    debugPrint(' Starting to schedule date notifications...');
    debugPrint('Current time: ${DateTime.now()}');

    int scheduledCount = 0;
    int notificationId = 1000;

    for (var entry in hardcodedDates.entries) {
      final dateName = entry.key;
      final targetDate = entry.value;

      debugPrint('Processing: $dateName - Target: $targetDate');

      // Schedule notification 2 days before at 9:30 PM
      final wasScheduled2Days = await _scheduleSingleNotification(
          dateName,
          targetDate,
          1, // 9 PM
          05, // 30 minutes
          daysBefore: 2,
          notificationId: notificationId++,
          message: 'is coming in 2 days'
      );
      if (wasScheduled2Days) scheduledCount++;

      // Schedule notification on the actual date at 9:30 AM
      final wasScheduledSameDay = await _scheduleSingleNotification(
          dateName,
          targetDate,
          1,  // 9 AM
          07, // 30 minutes
          daysBefore: 0,
          notificationId: notificationId++,
          message: 'is today'
      );
      if (wasScheduledSameDay) scheduledCount++;
    }

    debugPrint('✅ Scheduled $scheduledCount date notifications total');

    await showTestNotification();
  }

  Future<bool> _scheduleSingleNotification(
      String dateName,
      DateTime targetDate,
      int hour,
      int minute, {
        int daysBefore = 2,
        int notificationId = 0,
        String message = 'is coming in 2 days'
      }) async {
    try {
      // Calculate the notification date
      final notificationDate = targetDate.subtract(Duration(days: daysBefore));

      // Create the scheduled time
      final scheduledDateTime = DateTime(
        notificationDate.year,
        notificationDate.month,
        notificationDate.day,
        hour,
        minute,
      );

      final now = DateTime.now();
      final delay = scheduledDateTime.difference(now);

      debugPrint('Date: $dateName ($message)');
      debugPrint('Target date: $targetDate');
      debugPrint('Notification time: $scheduledDateTime');
      debugPrint('Current time: $now');
      debugPrint('Delay: $delay');

      debugPrint('---------Delay:----------------------------');

      // Skip if time already passed
      if (delay.isNegative) {
        debugPrint('⏩ Skipping $dateName - time has already passed');
        return false;
      }

      Duration actualDelay = delay;
      if (delay.inDays > 1 && kDebugMode) {
        actualDelay = Duration(seconds: 30 + (notificationId % 10) * 10);
        debugPrint('🧪 TEST MODE: Scheduling in ${actualDelay.inSeconds} seconds');
      }

      final title = '$dateName Reminder';
      final body = 'Your $dateName $message (${_formatDate(targetDate)}). Please check and be prepared!';

      // Create unique task name
      final taskName = 'date_reminder_${dateName}_${daysBefore}d_${notificationId}';

      await Workmanager().registerOneOffTask(
        taskName,
        taskName,
        inputData: {
          'dateName': dateName,
          'title': title,
          'body': body,
          'notificationId': notificationId,
        },
        initialDelay: actualDelay,
        constraints: Constraints(
          networkType: NetworkType.not_required,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      debugPrint('✅ Scheduled: $dateName at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      debugPrint('Task will execute in: $actualDelay');

      return true;
    } catch (e) {
      debugPrint('❌ Error scheduling $dateName: $e');
      return false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> cancelAllDateNotifications() async {
    if (kIsWeb) return;
    await Workmanager().cancelAll();
    debugPrint('All date notifications cancelled');
  }

  Future<void> showTestNotification() async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      dateChannelId,
      dateChannelName,
      channelDescription: dateChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);

    await _notificationsPlugin.show(
      999,
      'Test Date Reminder',
      'Notifications are working! Your date reminders will appear as scheduled.',
      notificationDetails,
      payload: 'test_date_notification',
    );

    debugPrint('✅ Test notification sent - check your notification tray');
  }
}