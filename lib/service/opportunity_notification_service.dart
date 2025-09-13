import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rekloze/service/user_session_service.dart';
import 'package:rekloze/api/api_service.dart';
@pragma('vm:entry-point')
void dateNotificationCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('📨 WorkManager task received: $taskName');

    await _initializeNotificationsInBackground();

    if (taskName.startsWith('date_reminder_')) {
      try {
        final userId = inputData?['userId']?.toString();
        final currentUserId = await _getCurrentUserIdInBackground();

        if (userId != currentUserId) {
          debugPrint('🚫 Skipping notification - intended for user $userId, current user is $currentUserId');
          return Future.value(false);
        }

        final dateName = inputData?['dateName'] ?? 'Contract Date';
        final title = inputData?['title'] ?? 'Contract Date Reminder';
        final body = inputData?['body'] ?? 'You have an upcoming contract date';
        final notificationId = inputData?['notificationId'] ?? 0;
        final opportunityName = inputData?['opportunityName'] ?? 'Your Contract';

        debugPrint('📋 Processing date notification: $dateName for $opportunityName');

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
Future<String?> _getCurrentUserIdInBackground() async {
  try {
    final userSession = UserSessionService();
    await userSession.initialize();
    return userSession.userId?.toString();
  } catch (e) {
    debugPrint('❌ Error getting current user ID in background: $e');
    return null;
  }
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

}

class OpportunityNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const String dateChannelId = 'contract_date_channel';
  static const String dateChannelName = 'Contract Date Reminders';
  static const String dateChannelDescription = 'Notifications for contract date deadlines';

  static final OpportunityNotificationService _instance = OpportunityNotificationService._internal();
  factory OpportunityNotificationService() => _instance;
  OpportunityNotificationService._internal();

  //  store dates for each opportunity
  final Map<String, Map<String, DateTime?>> _opportunityDates = {};

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

    await _instance._loadAndScheduleUserOpportunities();
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

  }

  static Future<void> _requestPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return;

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    final granted = await androidPlugin?.requestNotificationsPermission();
    debugPrint('Notification permission granted: $granted');
  }

  // Load opportunities for current user from API
  Future<void> _loadAndScheduleUserOpportunities() async {
    try {
      final userSession = UserSessionService();
      await userSession.initialize();
      final userId = userSession.userId?.toString();

      if (userId == null) {

        await cancelAllDateNotifications();
        return;
      }

      final response = await ApiService.getOpportunitiesByUserId(userId);

      if (response?.statusCode == 200) {
        final responseData = json.decode(response!.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final opportunities = responseData['data'] as List<dynamic>;

          debugPrint('📊 Found ${opportunities.length} opportunities for user $userId');

          // Clear existing data and cancel all notifications
          _opportunityDates.clear();
          await Workmanager().cancelAll();

          for (final opportunity in opportunities) {
            await _processOpportunity(opportunity, userId);
          }

          await showTestNotification();
        } else {
          debugPrint('❌ API response indicates failure: ${responseData['message']}');
        }
      } else {
        debugPrint('❌ Failed to fetch opportunities: ${response?.statusCode}');
        await _showErrorNotification('Failed to load opportunities: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error loading user opportunities: $e');
      await _showErrorNotification('Error loading opportunities: $e');
    }
  }

  // Process a single opportunity and schedule notifications
  Future<void> _processOpportunity(Map<String, dynamic> opportunity, String userId) async {
    try {
      final opportunityId = opportunity['oppurtunityId']?.toString();
      final opportunityName = opportunity['oppurtunityName']?.toString();

      if (opportunityId == null) {
        debugPrint('❌ Opportunity missing ID: $opportunity');
        return;
      }

      debugPrint('📋 Processing opportunity: $opportunityName ($opportunityId)');

      // Extract dates from the opportunity
      final Map<String, DateTime?> dates = {
        'Effective Date': _parseDate(opportunity['effective_date']),
        'Initial Escrow Deposit Due Date': _parseDate(opportunity['initial_escrow_deposit_due_date']),
        'Loan Application Due Date': _parseDate(opportunity['loan_application_due_date']),
        'Additional Escrow Deposit Due Date': _parseDate(opportunity['additional_escrow_deposit_due_date']),
        'Inspection Period Deadline': _parseDate(opportunity['inspection_period_deadline']),
        'Loan Approval Due Date': _parseDate(opportunity['loan_approval_due_date']),
        'Title Evidence Due Date': _parseDate(opportunity['title_evidence_due_date']),
        'Closing Date': _parseDate(opportunity['closing_date']),
      };

      _opportunityDates[opportunityId] = dates;

      // Schedule notifications for all valid dates
      int scheduledCount = 0;
      int notificationId = _generateNotificationId(opportunityId);

      for (final entry in dates.entries) {
        final dateName = entry.key;
        final targetDate = entry.value;

        if (targetDate != null) {
          // Schedule notification 2 days before at 9:30 PM
          final wasScheduled2Days = await _scheduleSingleNotification(
            dateName,
            targetDate,
            15, // 9 PM
            00, // 30 minutes
            daysBefore: 2,
            notificationId: notificationId++,
            message: 'is coming in 2 days',
            opportunityName: opportunityName ?? 'Contract',
            userId: userId,
          );
          if (wasScheduled2Days) scheduledCount++;

          // Schedule notification on the actual date at 9:30 AM
          final wasScheduledSameDay = await _scheduleSingleNotification(
            dateName,
            targetDate,
            15,  // 9 AM
            04,  // 30 minutes
            daysBefore: 0,
            notificationId: notificationId++,
            message: 'is today',
            opportunityName: opportunityName ?? 'Contract',
            userId: userId,
          );
          if (wasScheduledSameDay) scheduledCount++;
        }
      }

      debugPrint('✅ Scheduled $scheduledCount notifications for $opportunityName');
    } catch (e) {
      debugPrint('❌ Error processing opportunity: $e');
    }
  }

  DateTime? _parseDate(dynamic dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.tryParse(dateString.toString());
    } catch (e) {
      debugPrint('❌ Error parsing date: $dateString - $e');
      return null;
    }
  }

  // Generate unique notification ID based on opportunity ID
  int _generateNotificationId(String opportunityId) {
    final hash = opportunityId.hashCode;
    return (hash % 100000).abs();
  }
  static Future<void> onUserLogin() async {
    try {
      // Cancel any existing notifications using the instance
      await _instance.cancelAllDateNotifications();

      await _instance._loadAndScheduleUserOpportunities();

    } catch (e) {
      debugPrint('❌ Error rescheduling notifications on login: $e');
    }
  }
  Future<bool> _scheduleSingleNotification(
      String dateName,
      DateTime targetDate,
      int hour,
      int minute, {
        int daysBefore = 2,
        int notificationId = 0,
        String message = 'is coming in 2 days',
        String? opportunityName,
        required String userId,
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

      debugPrint('---');
      debugPrint('Date: $dateName ($message)');
      debugPrint('Target date: $targetDate');
      debugPrint('Notification time: $scheduledDateTime');
      debugPrint('Current time: $now');
      debugPrint('Delay: $delay');

      // Skip if time already passed
      if (delay.isNegative) {
        debugPrint('⏩ Skipping $dateName - time has already passed');
        return false;
      }

      //if delay is more than 1 day, schedule a test in 30 seconds
      Duration actualDelay = delay;
      if (delay.inDays > 1 && kDebugMode) {
        actualDelay = Duration(seconds: 30 + (notificationId % 10) * 10);
        debugPrint('🧪 TEST MODE: Scheduling in ${actualDelay.inSeconds} seconds');
      }

      // Create user-friendly notification messages
      final String title;
      final String body;

      if (daysBefore == 2) {
        title = '⏰ $dateName Reminder';
        body = 'Your "$dateName" for "$opportunityName" is coming in 2 days (${_formatDate(targetDate)}). Get prepared!';
      } else {
        title = '✅ $dateName Today';
        body = 'Your "$dateName" for "$opportunityName" is today (${_formatDate(targetDate)})! Don\'t forget to complete it.';
      }

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
          'userId': userId,
          'opportunityName': opportunityName,
        },
        initialDelay: actualDelay,
        constraints: Constraints(
          networkType: NetworkType.not_required,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      debugPrint('✅ Scheduled: $dateName at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      debugPrint('Task will execute in: $actualDelay');
      debugPrint('Notification message: "$body"');

      return true;
    } catch (e) {
      debugPrint('❌ Error scheduling $dateName: $e');
      return false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _showErrorNotification(String error) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      dateChannelId,
      dateChannelName,
      channelDescription: dateChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);

    await _notificationsPlugin.show(
      998,
      'Error Loading Dates',
      error,
      notificationDetails,
    );
  }

  Future<void> cancelAllDateNotifications() async {
    if (kIsWeb) return;

    try {
      // Cancel all WorkManager tasks
      await Workmanager().cancelAll();

      // Clear local notifications
      await _notificationsPlugin.cancelAll();

      // Clear stored opportunity data
      _opportunityDates.clear();

    } catch (e) {
      debugPrint('❌ Error cancelling notifications: $e');
    }
  }
  static Future<void> onUserLogout() async {
    try {
      // Cancel all notifications when user logs out
      await _instance.cancelAllDateNotifications();
      debugPrint('✅ All notifications cancelled on logout');
    } catch (e) {
      debugPrint('❌ Error cancelling notifications on logout: $e');
    }
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
      'Date Notifications Scheduled',
      'Your contract date reminders have been scheduled successfully! You\'ll get notifications like:\n\n"Effective Date for Contract #0101 is coming in 2 days (09/13/2025)"',
      notificationDetails,
      payload: 'test_date_notification',
    );

    debugPrint('✅ Test notification sent - check your notification tray');
  }

  // Get dates for a specific opportunity
  Map<String, DateTime?>? getOpportunityDates(String opportunityId) {
    return _opportunityDates[opportunityId];
  }

  // Get all opportunities
  Map<String, Map<String, DateTime?>> getAllOpportunities() {
    return Map.from(_opportunityDates);
  }

  Future<void> scheduleAllDateNotifications() async {
    if (kIsWeb) return;

    debugPrint('🔄 Manual scheduling triggered - loading user opportunities');
    await _loadAndScheduleUserOpportunities();
  }

  // DEBUG METHOD: Force immediate notifications for testing
  Future<void> triggerImmediateTestNotifications() async {
    if (kIsWeb) return;

    debugPrint('🚀 Triggering immediate test notifications');

    // Show a test notification immediately
    await _notificationsPlugin.show(
      1000,
      'IMMEDIATE TEST: Notification System Working',
      'If you see this, notifications are working! Real date reminders will come at the scheduled times.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          dateChannelId,
          dateChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );

    // Schedule a test notification for 10 seconds from now
    await Workmanager().registerOneOffTask(
      'test_immediate_10s',
      'test_immediate_10s',
      inputData: {
        'dateName': 'Test Date',
        'title': 'TEST: Scheduled Notification',
        'body': 'This is a test notification scheduled for 10 seconds later',
        'notificationId': 1001,
      },
      initialDelay: Duration(seconds: 10),
    );

    debugPrint('✅ Immediate test notifications triggered');
  }

  Future<void> clearUserNotifications() async {
    await cancelAllDateNotifications();
    debugPrint('✅ Cleared all notifications for current user');
  }
}