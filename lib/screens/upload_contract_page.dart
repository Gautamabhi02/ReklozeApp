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


  Future<void> _selectDate(BuildContext context) async{
    final DateTime? picked  = await showDatePicker(context: context,
        initialDate:DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child){
      return Theme(
        data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: Colors.deepPurpleAccent,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        dialogBackgroundColor: Colors.white,
      ),
        child: child!,
      );
      }
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }

  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text("File Uploaded", style: TextStyle(color: Colors.black)),
            ],
          ),
          content: const Text("Your PDF file was uploaded successfully."),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.indigo),
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
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

    // Final completion pause
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
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a file")));
      return;
    }

    setState(() => _isUploading = true);
    // await _simulateUploadProgress();

    // String promptText = "Extract the following details from the contract: Seller, Buyer, Seller Agent Name, Buyer Agent Name, Listing Agent Name, Listing Agent Company Name, Listing Agent Phone, Listing Agent Email, Selling Agent Name, Selling Agent Company Name, Selling Agent Phone, Selling Agent Email, Escrow Agent Name, Escrow Agent Phone, Escrow Agent Email, Property Address, Effective Date (Extract the actual date, NOT a description), Initial Escrow Deposit Due Date, Loan Application Due Date, Additional Escrow Deposit Due Date, Property Tax ID, Inspection Period Deadline, Loan Approval Due Date, Title Evidence Due Date, and Closing Date. Also, clearly state whether the contract is Cash or Finance. IMPORTANT: For all date-based fields, calculate and include the number of days from the Effective Date in parentheses, like '(3 days after Effective Date)' or '(15 days before Closing Date)'. Ensure the response is clean, in structured markdown format, and avoid any introductory or explanatory text — only return the extracted details.";
    // String promptText = "Extract the following details from the contract in clean markdown format without any explanation: Seller, Buyer, Seller Agent Name, Buyer Agent Name, Listing Agent Name, Listing Agent Company Name, Listing Agent Phone, Listing Agent Email, Selling Agent Name, Selling Agent Company Name, Selling Agent Phone, Selling Agent Email, Escrow Agent Name, Escrow Agent Phone, Escrow Agent Email, Property Address, Property Tax ID, Contract Type (Cash or Finance), and Effective Date (actual date only). For all other date fields — Initial Escrow Deposit Due Date, Loan Application Due Date, Additional Escrow Deposit Due Date, Inspection Period Deadline, Loan Approval Due Date, Title Evidence Due Date, Closing Date — return only the number of days offset from Effective Date, using phrases like '(5 days after Effective Date)' or '(10 days before Closing Date)'. Do not include full calendar dates anywhere.";
    String promptText = "Extract the following details from the contract in clean markdown format without any explanation: Seller, Buyer, Seller Agent Name, Buyer Agent Name, Listing Agent Name, Listing Agent Company Name, Listing Agent Phone, Listing Agent Email, Selling Agent Name, Selling Agent Company Name, Selling Agent Phone, Selling Agent Email, Escrow Agent Name, Escrow Agent Phone, Escrow Agent Email, Property Address, Property Tax ID, Contract Type (Cash or Finance),  Closing Date (use actual date if present in the contract, otherwise use relative format like '(35 days after Effective Date)'). For all other date fields — Initial Escrow Deposit Due Date, Loan Application Due Date, Additional Escrow Deposit Due Date, Inspection Period Deadline, Loan Approval Due Date, Title Evidence Due Date — return relative offsets like '(5 days after Effective Date)' or '(10 days before Closing Date)' only if actual dates are not present,if both are present that is good gave both of them. Do not include full calendar dates unless they are explicitly written in the contract.";


    final simulation = _simulateUploadProgress();

    final response = await ApiService.uploadContractWithPrompt(
      selectedFile: _selectedFile!,
      promptText: promptText,
    );
    await simulation;
    setState(() {
      _isUploading = false;
      _uploadProgress = 0;
    });

    if (response != null && response.statusCode == 200) {
      final parsedData = parseTextToJson(response.body);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.orange),
              SizedBox(width: 10),
              Text("Verify Data", style: TextStyle(color: Colors.black)),
            ],
          ),
          content: const Text(
            "The extracted data may not be 100% accurate.\n\nPlease verify all fields before saving to CRM.",
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.indigo),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewPage(
                      pdfFile: _selectedFile!.bytes!,
                      contractData: parsedData,
                      effectiveDate: _selectedDate,
                      onProceed: () {
                        // handle proceed action here
                        print("Proceed clicked");
                      },
                      onGoBack: () {
                        // handle go back action here
                        Navigator.pop(context);
                      },
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
    else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload failed")));
    }
  }


  Map<String, String> parseTextToJson(String responseText) {
    final Map<String, String> data = {};

    // debugPrint("Raw response: $responseText");

    // Try direct JSON decoding and extract markdown string
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
    responseText = responseText
        .replaceAll("```markdown", "")
        .replaceAll("```", "")
        .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (match) => match.group(1) ?? '')
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

    debugPrint("=======================Parsed final key-value data=========================: $data");
    return data;
  }

  // Map<String, String> parseTextToJson(String responseText) {
  //   final Map<String, String> data = {};
  //
  //   // Try direct JSON parsing
  //   try {
  //     if (responseText.trim().startsWith("{")) {
  //       final parsed = Map<String, dynamic>.from(json.decode(responseText));
  //       parsed.forEach((key, value) {
  //         data[key] = value.toString();
  //       });
  //       print("Final Parsed Data (JSON detected): $data");
  //       return data;
  //     }
  //   } catch (e) {
  //     print("JSON parsing failed, falling back to regex parsing.");
  //   }
  //
  //   // Remove introductory text
  //   responseText = responseText.replaceFirst(
  //     RegExp(
  //       r'''^(Here is the information you requested from the contract:|I can help you extract.*?|Let's start with the details you mentioned:|Based on the provided information)\n?''',
  //       caseSensitive: false,
  //     ),
  //     '',
  //   ).trim();
  //
  //
  //   // Remove markdown-style bold
  //   responseText = responseText.replaceAllMapped(
  //     RegExp(r'\*\*(.*?)\*\*'),
  //         (match) => match.group(1) ?? '',
  //   );
  //
  //   // Remove leading dashes and numbers
  //   responseText = responseText
  //       .replaceAll(RegExp(r'^- ', multiLine: true), '')
  //       .replaceAll(RegExp(r'^\d+\.\s*', multiLine: true), '')
  //       .trim();
  //
  //   // Regex to match key-value pairs
  //   final regex = RegExp(
  //   r'^([\w\s#&*\-]+):\s*([\s\S]+?)(?=\n[\w\s#&*\-]+:|\n\d+\.\s*[\w\s#&*\-]+:|\n?$)',
  //   multiLine: true,
  //   );
  //
  //   for (final match in regex.allMatches(responseText)) {
  //   String key = match.group(1)?.trim() ?? '';
  //   String value = match.group(2)?.trim() ?? '';
  //
  //   // Clean up key
  //   key = key.replaceAll(RegExp(r'[*"\-0-9]'), '').trim();
  //
  //   // Clean up value
  //   value = value.replaceFirst(RegExp(r'^["*\s]+'), '').trim();
  //
  //   if (key.isNotEmpty &&
  //   !RegExp(r'^Here is the information you requested from the contract$', caseSensitive: false)
  //       .hasMatch(key)) {
  //   data[key] = value;
  //   }
  //   }
  //
  //   print("Final Parsed Data: $data");
  //   return data;
  // }



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
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
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
              label: const Text("Choose PDF", style: TextStyle(color: Colors.white)),
              onPressed: _pickFile,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    bool isButtonEnabled = _selectedFile != null && _selectedDate != null && !_isUploading;

    return ElevatedButton.icon(
      icon: const Icon(Icons.cloud_upload),
      label: const Text("Upload & Extract"),
      // onPressed: _selectedFile != null && !_isUploading ? _submitContract : null,
      onPressed: isButtonEnabled ? _submitContract : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        disabledBackgroundColor: Colors.grey,
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
          onTap: () => _selectDate(context),
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
                      : "${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}",
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
      appBar: const NavbarPage(),
      drawer: const CustomNavbar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ContractProgressBar(currentStep: 1),
                  const SizedBox(height: 20),
                  _buildFileCard(),
                  const SizedBox(height: 20),
                  _buildDateSelector(),
                  const SizedBox(height: 30),
                  _isUploading ? _buildProgressBar() : _buildUploadButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
