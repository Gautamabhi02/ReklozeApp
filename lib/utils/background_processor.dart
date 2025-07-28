import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../api/api_service.dart';

class BackgroundArgs {
  final PlatformFile file;
  final String prompt;
  BackgroundArgs(this.file, this.prompt);
}

Future<String?> runBackgroundProcessing(BackgroundArgs args) async {
  final response = await ApiService.uploadContractWithPrompt(
    selectedFile: args.file,
    promptText: args.prompt,
  );

  return response?.body;
}
