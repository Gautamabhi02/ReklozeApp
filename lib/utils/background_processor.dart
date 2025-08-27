import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import '../api/api_service.dart';
import '../service/notification_service.dart';


@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == 'uploadTask') {
      try {
        final args = BackgroundArgs(
          inputData!['filePath'] ?? '',
          inputData['fileName'] ?? '',
          inputData['prompt'] ?? '',
        );

        final result = await runBackgroundProcessing(args);

        if (result.isNotEmpty) {
          // Show notification only when successful
          await NotificationService.showUploadCompleteNotification(
            title: 'Upload Complete',
            body: 'Your document upload is complete',
            payload: 'review_page',
          );
          return Future.value(true);
        } else {
          // Show failure notification
          await NotificationService.showUploadFailedNotification();
          return Future.value(false);
        }
      } catch (e) {
        // Show failure notification on error
        await NotificationService.showUploadFailedNotification();
        return Future.value(false);
      }
    }
    return Future.value(false);
  });
}


class BackgroundArgs {
  final String filePath;
  final String fileName;
  final String prompt;
  final Uint8List? fileBytes;

  BackgroundArgs(
      this.filePath,
      this.fileName,
      this.prompt, {
        this.fileBytes,
      });

  Map<String, dynamic> toMap() {
    return {
      'filePath': filePath,
      'fileName': fileName,
      'prompt': prompt,
    };
  }
}

// Initialize workmanager
Future<void> initializeBackgroundProcessing() async {
  if (kIsWeb) return;

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
}

// Schedule background upload
Future<void> scheduleBackgroundUpload(BackgroundArgs args) async {
  if (kIsWeb) {
    // Process immediately for web
    await runBackgroundProcessing(args);
    await NotificationService.showUploadCompleteNotification(
      title: 'Upload Complete',
      body: 'Your upload document is complete',
      payload: 'review_page',
    );
    return;
  }

  await Workmanager().registerOneOffTask(
    'upload_${DateTime.now().millisecondsSinceEpoch}',
    'uploadTask',
    inputData: args.toMap(),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
}

// Background processing function
Future<String> runBackgroundProcessing(BackgroundArgs args) async {
  try {
    final platformFile = PlatformFile(
      name: args.fileName,
      size: args.fileBytes?.length ?? 0,
      bytes: args.fileBytes,
    );

    final response = await ApiService.uploadContractWithPrompt(
      selectedFile: platformFile,
      promptText: args.prompt,
    );

    return response?.body ?? '';
  } catch (e) {
    print('Background processing error: $e');
    rethrow;
  }
}


class BackgroundTaskManager {
  static Future<void> initialize() async {
    await initializeBackgroundProcessing();
    await NotificationService.initialize();
  }

  static Future<String> processInBackground(BackgroundArgs args) async {
    try {
      final result = await runBackgroundProcessing(args);

      if (result.isNotEmpty) {
        // Show notification only when successful
        await NotificationService.showUploadCompleteNotification(
          title: 'Upload Complete',
          body: 'Your document upload is complete',
          payload: 'review_page',
        );
        return result;
      } else {
        // Show failure notification
        await NotificationService.showUploadFailedNotification();
        return '';
      }
    } catch (e) {
      // Show failure notification
      await NotificationService.showUploadFailedNotification();
      rethrow;
    }
  }
}