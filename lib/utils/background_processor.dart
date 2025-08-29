import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:workmanager/workmanager.dart';
import '../api/api_service.dart';
import '../service/notification_service.dart';
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == 'uploadTask') {
      try {
        final filePath = inputData!['filePath'] ?? '';
        final fileName = inputData['fileName'] ?? '';
        final prompt = inputData['prompt'] ?? '';

        final file = File(filePath);
        if (!await file.exists()) {
          await NotificationService.showUploadFailedNotification();
          return Future.value(false);
        }

        final fileBytes = await file.readAsBytes();
        final platformFile = PlatformFile(
          name: fileName,
          size: fileBytes.length,
          bytes: fileBytes,
        );

        final response = await ApiService.uploadContractWithPrompt(
          selectedFile: platformFile,
          promptText: prompt,
        );

        if (response != null && response.body.isNotEmpty) {
          // ✅ Check if app is in foreground or background
          if (!kIsWeb) {
            final isForeground =
                WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
            if (!isForeground) {
              await NotificationService.showUploadCompleteNotification(
                title: 'Upload Complete',
                body: 'Your document upload is complete',
                payload: 'review_page',
              );
            }
          }
          return Future.value(true);
        } else {
          await NotificationService.showUploadFailedNotification();
          return Future.value(false);
        }
      } catch (e) {
        print('Background processing error: $e');
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
    final result = await runBackgroundProcessing(args);
    if (result.isNotEmpty) {
      await NotificationService.showUploadCompleteNotification(
        title: 'Upload Complete',
        body: 'Your upload document is complete',
        payload: 'review_page',
      );
    } else {
      await NotificationService.showUploadFailedNotification();
    }
    return;
  }

  await Workmanager().registerOneOffTask(
    'upload_${DateTime.now().millisecondsSinceEpoch}',
    'uploadTask',
    inputData: args.toMap(),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.replace,
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
  }

  static Future<String> processInBackground(BackgroundArgs args) async {
    try {
      if (kIsWeb) {
        return await runBackgroundProcessing(args);
      } else {
        // For Android, use WorkManager
        await scheduleBackgroundUpload(args);
        return ''; // WorkManager handles the processing asynchronously
      }
    } catch (e) {
      rethrow;
    }
  }
}