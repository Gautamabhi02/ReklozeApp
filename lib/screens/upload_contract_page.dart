import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api/ApplynxService.dart';
import '../api/api_service.dart';
import '../widgets/contract_progress_bar.dart';
import '../widgets/custom_navbar.dart';
import '../widgets/navbar_page.dart';
import 'review_page.dart';
import 'dart:isolate';

class UploadContractPage extends StatefulWidget {
  const UploadContractPage({super.key});

  @override
  State<UploadContractPage> createState() => _UploadContractPageState();
}

class _UploadContractPageState extends State<UploadContractPage> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String _uploadStatusText = '';
  DateTime? _selectedDate;

  void _selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (_isUploading) return;

      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to open date picker.")));
    }
  }

  void _pickFile() async {
    try {
      if (_isUploading) return;

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Ensure we get file bytes
      );

      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No file selected")));
        return;
      }

      final file = result.files.first;
      if (file.size > 10 * 1024 * 1024) {
        // 10MB limit
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File too large (max 10MB)")),
        );
        return;
      }

      if (file.bytes == null || file.bytes!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not read file contents")),
        );
        return;
      }

      setState(() => _selectedFile = file);

      showDialog(
        context: context,
        builder:
            (_) =>
            AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text("File Uploaded"),
                ],
              ),
              content: Text(
                "${file.name} was uploaded successfully (${(file.size / 1024 /
                    1024).toStringAsFixed(2)} MB)",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting file: ${e.toString()}")),
      );
    }
  }

  Future<void> _simulateUploadProgress() async {
    setState(() {
      _uploadProgress = 0;
      _uploadStatusText = "Starting Processing...";
    });

    // Phase 1: Initial Processing (0-30%)
    setState(() => _uploadStatusText = "Extracting Data...");
    for (int i = 0; i <= 30; i++) {
      await Future.delayed(const Duration(milliseconds: 350));
      setState(() => _uploadProgress = i.toDouble());
    }

    // Phase 2: Parsing (30-70%)
    setState(() => _uploadStatusText = "Parsing Dates...");
    for (int i = 31; i <= 70; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _uploadProgress = i.toDouble());
    }

    // Phase 3: Finalizing (70-100%)
    setState(() => _uploadStatusText = "Finalizing...");
    for (int i = 71; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _uploadProgress = i.toDouble());
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  // void _submitContract() async {
  //   setState(() => _isUploading = true);
  //   await _simulateUploadProgress();
  //
  //   try {
  //
  //     final testDataResponse = await ApiApplynxService().getTestData();
  //     debugPrint("Raw API Response:");
  //     debugPrint(testDataResponse.toString());
  //     final parsedData = parseTextToJson(testDataResponse['content']);
  //     // Print parsed data to console
  //     debugPrint("\nParsed Contract Data:");
  //     parsedData.forEach((key, value) {
  //       debugPrint('$key: $value');
  //     });
  //
  //     // Show verification dialog (same as before)
  //     showDialog(
  //       context: context,
  //       builder: (_) => AlertDialog(
  //         backgroundColor: Colors.white,
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //         title: const Row(
  //           children: [
  //             Icon(Icons.info, color: Colors.orange),
  //             SizedBox(width: 10),
  //             Text("Verify Data", style: TextStyle(color: Colors.black)),
  //           ],
  //         ),
  //         content: const Text(
  //           "The extracted data may not be 100% accurate.\n\nPlease verify all fields before saving to CRM.",
  //           style: TextStyle(fontSize: 15),
  //         ),
  //         actions: [
  //           TextButton(
  //             style: TextButton.styleFrom(foregroundColor: Colors.indigo),
  //             onPressed: () {
  //               Navigator.pop(context);
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (_) => ReviewPage(
  //                     pdfFile: _selectedFile?.bytes ?? Uint8List(0),
  //                     contractData: parsedData,
  //                     onProceed: () => print("Proceed clicked"),
  //                     onGoBack: () => Navigator.pop(context),
  //                   ),
  //                 ),
  //               );
  //             },
  //             child: const Text("Review"),
  //           ),
  //         ],
  //       ),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Error: $e")),
  //     );
  //   } finally {
  //     setState(() {
  //       _isUploading = false;
  //       _uploadProgress = 0;
  //     });
  //   }
  // }

  void _submitContract() async {
    if (_selectedFile == null || !_isValidPdf(_selectedFile!.bytes!)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select a valid PDF file")));
      return;
    }

    setState(() => _isUploading = true);

    final promptText =
        "Extract the following details from the contract in clean markdown format without any explanation: Seller, Buyer, Seller Agent Name, Buyer Agent Name, Listing Agent Name, Listing Agent Company Name, Listing Agent Phone, Listing Agent Email, Selling Agent Name, Selling Agent Company Name, Selling Agent Phone, Selling Agent Email, Escrow Agent Name, Escrow Agent Phone, Escrow Agent Email, Property Address, Property Tax ID, Contract Type (Cash or Finance),  Closing Date (use actual date if present in the contract, otherwise use relative format like '(35 days after Effective Date)'). For all other date fields — Initial Escrow Deposit Due Date, Loan Application Due Date, Additional Escrow Deposit Due Date, Inspection Period Deadline, Loan Approval Due Date, Title Evidence Due Date — return relative offsets like '(5 days after Effective Date)' or '(10 days before Closing Date)' only if actual dates are not present,if both are present that is good gave both of them. Do not include full calendar dates unless they are explicitly written in the contract.";

    final progressFuture = _simulateUploadProgress();

    // Launch API call in isolate
    final apiResponseBody = await compute(
      computeUpload,
      ComputeRequest(
        fileBytes: _selectedFile!.bytes!,
        fileName: _selectedFile!.name,
        prompt: promptText,
      ),
    );
    // Wait for progress to complete
    await progressFuture;

    setState(() {
      _isUploading = false;
      _uploadProgress = 0;
    });

    // Parse response and show modal
    if (apiResponseBody.isNotEmpty) {
      final parsedData = parseTextToJson(apiResponseBody);
      _showReviewDialog(parsedData);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Upload failed")));
    }
  }

  void _showReviewDialog(Map<String, String> contractData) {
    showDialog(
      context: context,
      builder:
          (_) =>
          AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.info, color: Colors.orange),
                SizedBox(width: 10),
                Text("Verify Data", style: TextStyle(color: Colors.black)),
              ],
            ),
            content: const Text(
              "The extracted data may not be 100% accurate.\n\n"
                  "Please verify all fields before saving to CRM.",
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.indigo),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                          ReviewPage(
                            pdfFile: _selectedFile!.bytes ?? Uint8List(0),
                            contractData: contractData,
                            effectiveDate: _selectedDate,
                            onProceed: () => print("Proceed clicked"),
                            onGoBack: () => Navigator.pop(context),
                          ),
                    ),
                  );
                },
                child: const Text("Review"),
              ),
            ],
          ),
    );
  }

  bool _isValidPdf(Uint8List bytes) {
    if (bytes.length >= 4) {
      return bytes[0] == 0x25 && // %
          bytes[1] == 0x50 && // P
          bytes[2] == 0x44 && // D
          bytes[3] == 0x46; // F
    }
    return false;
  }

  Map<String, String> parseTextToJson(String responseText) {
    final Map<String, String> data = {};

    // debugPrint("Raw response: $responseText");

    try {
      final Map<String, dynamic> parsed = json.decode(responseText);
      final content = parsed['choices']?[0]?['message']?['content'];

      if (content is String) {
        responseText = content;
        // debugPrint("====================Extracted markdown content==========================: $responseText");
      } else {
        debugPrint("No markdown content found.");
        return data;
      }
    } catch (e) {
      debugPrint("Failed to decode JSON, error: $e");
      return data;
    }

    // Clean markdown formatting
    responseText =
        responseText
            .replaceAll("```markdown", "")
            .replaceAll("```", "")
            .replaceAllMapped(
          RegExp(r'\*\*(.*?)\*\*'),
              (match) => match.group(1) ?? '',
        )
            .replaceAll(RegExp(r'^- ', multiLine: true), '')
            .trim();

    // debugPrint("=======================Cleaned markdown content===========================:\n$responseText");

    // Regex to extract key-value pairs
    final regex = RegExp(
      r'^([\w\s#&*\-()]+):\s*([\s\S]+?)(?=\n[\w\s#&*\-()]+:|\n?$)',
      multiLine: true,
    );

    final matches = regex.allMatches(responseText);
    for (final match in matches) {
      String key = match.group(1)?.trim() ?? '';
      String value = match.group(2)?.trim() ?? '';

      // Optional: clean up common unwanted characters
      key = key.replaceAll(RegExp(r'[*"\-0-9]'), '').trim();
      value = value.replaceFirst(RegExp(r'^["*\s]+'), '').trim();

      if (key.isNotEmpty) {
        data[key] = value;
      }
    }

    debugPrint(
      "=======================Parsed final key-value data=========================: $data",
    );
    return data;
  }

  Widget _buildFileCard() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Colors.indigo, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            const Icon(Icons.picture_as_pdf, size: 50, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              _selectedFile != null ? _selectedFile!.name : "No file selected",
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text(
                "Upload Contract",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: _isUploading ? null : _pickFile,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    bool isButtonEnabled =
        _selectedFile != null && _selectedDate != null && !_isUploading;

    return GestureDetector(
      onTap: () {
        if (!isButtonEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Please select both a PDF file and an Effective Date.",
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: AbsorbPointer(
        absorbing: !isButtonEnabled,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.cloud_upload),
          label: const Text("Upload & Extract"),
          onPressed: isButtonEnabled ? _submitContract : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
            isButtonEnabled ? Colors.deepPurpleAccent : Colors.grey,
            foregroundColor: Colors.white,
            elevation: 4,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _uploadProgress / 100,
          backgroundColor: Colors.grey.shade300,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          minHeight: 8,
        ),
        const SizedBox(height: 12),
        Text(
          _uploadStatusText,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Effective Date",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border.all(color: Colors.red.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "IMPORTANT: The effective date is the day the seller returns the fully executed contract (day 0). "
                "All deadlines count calendar days including weekends/holidays. "
                "If a deadline falls on a weekend/holiday, it moves to the next business day.",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _isUploading ? null : () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate == null
                      ? "Select a date"
                      : "${_selectedDate!.month}/${_selectedDate!
                      .day}/${_selectedDate!.year}",
                  style: TextStyle(
                    color: _selectedDate == null ? Colors.grey : Colors.black,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _currentStep = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const NavbarPage(),
      drawer: const CustomNavbar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      ContractProgressBar(currentStep: 1),
                      const SizedBox(height: 14),
                      _buildFileCard(),
                      const SizedBox(height: 14),
                      _buildDateSelector(),
                      const SizedBox(height: 18),
                      _isUploading ? _buildProgressBar() : _buildUploadButton(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}

//   class _IsolateRequest {
//   final SendPort sendPort;
//   final PlatformFile file;
//   final String prompt;
//   _IsolateRequest({
//     required this.sendPort,
//     required this.file,
//     required this.prompt,
//   });
// }
//
// Future<void> _isolateUploadEntry(_IsolateRequest req) async {
//   final response = await ApiService.uploadContractWithPrompt(
//     selectedFile: req.file,
//     promptText: req.prompt,
//   );
//   req.sendPort.send(response?.body ?? '');
// }


class ComputeRequest {
  final Uint8List fileBytes;
  final String fileName;
  final String prompt;

  ComputeRequest({
    required this.fileBytes,
    required this.fileName,
    required this.prompt,
  });
}

Future<String> computeUpload(ComputeRequest req) async{
  final file  = PlatformFile(name: req.fileName, size: req.fileBytes.length,bytes:req.fileBytes,);
  final response = await ApiService.uploadContractWithPrompt(selectedFile: file, promptText: req.prompt);
  return response?.body ?? '';
}

