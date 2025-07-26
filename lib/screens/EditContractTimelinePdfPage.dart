import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../api/api_service.dart' show ApiService;
import '../service/user_session_service.dart';
import '../widgets/custom_navbar.dart';
import '../widgets/navbar_page.dart';

import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;


class EditContractTimelinePdfPage extends StatefulWidget {
  @override
  _EditContractTimelinePdfPageState createState() => _EditContractTimelinePdfPageState();
}

class _EditContractTimelinePdfPageState extends State<EditContractTimelinePdfPage> {
  String headerLogo = '';
  String footerLogo = '';

  bool _isLoadingImages = false;
  bool _isLoadingFooterImage = false;
  Uint8List? _headerImageBytes;
  Uint8List? _footerImageBytes;
  bool _isLoadingText = false;
  Timer? _debounceTimer;
  final Duration _debounceDelay = Duration(seconds: 1);

  final TextEditingController _propertyAddressController = TextEditingController();
  final TextEditingController _introTextController = TextEditingController();
  final TextEditingController _middleTextController = TextEditingController();
  final TextEditingController _afterMilestoneController = TextEditingController();
  final List<TextEditingController> _milestoneControllers = [];
  final List<TextEditingController> _milestoneNameControllers = [];

  Map<String, String> header = {
    'title': 'Contract Timeline',
    'logo': '',
    'date': '',
    'propertyAddress': ''
  };

  String introText = 'We are pleased to announce that we have successfully entered into a contract for the property. While significant milestones have been achieved, there is still work to be done to reach closing. Enclosed, please find a comprehensive timeline and contact details for all parties involved in this transaction.';
  String middleText = 'Successfully closing on this property will require a focused effort and careful attention to a number of details. To help guide us through this process, there are specific dates that we should all be aware of. Please keep these important milestones in mind as we continue to move forward in this transaction.';
  String afterMilestoneText = 'TIME: Time is of the essence in this Contract. Calendar days, based on where the Property is located, shall be used in computing time periods. Other than time for acceptance and Effective Date as set forth in Paragraph 3, any time periods provided for or dates specified in this Contract, whether preprinted, handwritten, typewritten or inserted herein, which shall end or occur on a Saturday, Sunday, national legal public holiday (as defined in 5 U.S.C. Sec. 6103(a)), or a day on which a national legal public holiday is observed because it fell on a Saturday or Sunday, shall extend to the next calendar day which is not a Saturday, Sunday, national legal public holiday, or a day on which a national legal public holiday is observed.';
  List<Map<String, String>> contactDetails = [];
  List<Map<String, String>> milestones = [];

  Map<String, String> footer = {
    'footerText': 'Florida Realty Of Miami',
    'logo': '',
    'footerSubText': '786-486-6082',
    'footerAddress': '9415 Sunset Dr #236\nMiami, FL 33173'
  };

  List<String> contactTableHeaders = [
    'Title/Escrow Agent:',
    'MLO\\Lender',
    'Listing Agent',
    'Selling Agent'
  ];

  Map<String, String> milestoneTableHeaders = {
    'milestone': 'Milestone',
    'buyer': 'Date'
  };
  List<Map<String, TextEditingController>> contactControllers = [];
  List<Map<String, String>> dropdownOptions = [];
  String selectedOptionValue = '';
  final String locationID = 'cyI1tRyaF0oYq5jaPVOP';
  final String apiToken = 'pit-283031da-ffca-40fc-8303-4b8400ce6dab';

  @override
  void initState() {
    super.initState();
    header['date'] = _getTodayDate();
    _initializeEmptyMilestones();
    _initializeEmptyContactDetails();
    fetchOpportunityValue().then((_) {
      // Auto-select first contract if available
      if (dropdownOptions.isNotEmpty) {
        setState(() {
          selectedOptionValue = dropdownOptions.first['value'] ?? '';
        });
        onContractSelect(); // Load the contract data
      }
    });
    _loadSavedTextBlocks().then((_) {
      // Update controllers after text is loaded
      // _propertyAddressController.text = header['propertyAddress'] ?? '';
      _introTextController.text = introText;
      _middleTextController.text = middleText;
      _afterMilestoneController.text = afterMilestoneText;
    });

    contactControllers = List.generate(4, (_) => {
      'company': TextEditingController(),
      'name': TextEditingController(),
      'phone': TextEditingController(),
      'email': TextEditingController(),
    });
    _loadImagesFromApi();
    _getLocationDetails();
    fetchOpportunityValue();

    _propertyAddressController.text = header['propertyAddress'] ?? '';
    _introTextController.text = introText;
    _middleTextController.text = middleText;

    // Initialize milestone controllers
    _milestoneControllers.addAll(
      milestones.map((m) => TextEditingController(text: m['buyer'] ?? '')).toList(),
    );
    _milestoneNameControllers.addAll(
      milestones.map((m) => TextEditingController(text: m['milestone'] ?? '')).toList(),
    );
  }
  void _initializeEmptyContactDetails() {
    setState(() {
      contactDetails = List.generate(4, (_) => {
        'name': '',
        'phone': '',
        'email': '',
        'company': ''
      });

      // Reset all controllers
      for (var controller in contactControllers) {
        controller['company']?.text = '';
        controller['name']?.text = '';
        controller['phone']?.text = '';
        controller['email']?.text = '';
      }
    });
  }


  @override
  void dispose() {
    _propertyAddressController.dispose();
    _introTextController.dispose();
    _middleTextController.dispose();
    _afterMilestoneController.dispose();
    for (var c in _milestoneControllers) { c.dispose(); }
    for (var c in _milestoneNameControllers) { c.dispose(); }
    for (var controllerMap in contactControllers) {
      controllerMap.forEach((key, controller) => controller.dispose());
    }
    _debounceTimer?.cancel();
    super.dispose();
  }
  String _getTodayDate() {
    final today = DateTime.now();
    return 'Date: ${today.month}/${today.day}/${today.year}';
  }

  void _initializeEmptyMilestones() {
    setState(() {
      milestones = [
        {'milestone': 'Effective Contract Date', 'buyer': ''},
        {'milestone': 'Initial escrow deposit Due Date', 'buyer': ''},
        {'milestone': 'Loan Application Due Date', 'buyer': ''},
        {'milestone': 'Additional Escrow Deposit Due Date', 'buyer': ''},
        {'milestone': 'Inspection Period Ends', 'buyer': ''},
        {'milestone': 'Title Evidence Due Date', 'buyer': ''},
        {'milestone': 'Loan Approval Period Ends', 'buyer': ''},
        {'milestone': 'Closing Date', 'buyer': ''}
      ];
    });
  }

  Future<void> fetchOpportunityValue() async {
    const apiUrl = 'https://services.leadconnectorhq.com/contacts/?locationId=cyI1tRyaF0oYq5jaPVOP';
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $apiToken',
      'Version': '2021-07-28'
    };

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final contacts = data['contacts'] as List? ?? [];

        setState(() {
          dropdownOptions = contacts.map((contact) {
            try {
              final fields = (contact['customFields'] as List? ?? [])
                  .whereType<Map<String, dynamic>>()
                  .toList();

              if (fields.length >= 2) {
                return {
                  'value': fields[0]['value']?.toString() ?? '',
                  'label': fields[1]['value']?.toString() ?? '',
                };
              }
            } catch (e) {
              print('Error processing contact: $e');
            }
            return {'value': '', 'label': ''};
          }).where((item) => item['value']?.isNotEmpty ?? false).toList();
        });
      }
    } catch (error) {
      print('Error fetching dropdown data: $error');
    }
  }

  Future<void> _getLocationDetails() async {
    final apiUrl = 'https://services.leadconnectorhq.com/locations/$locationID';
    final headers = {
      'Authorization': 'Bearer $apiToken',
      'version': '2021-07-28'
    };

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          headerLogo = data['location']['logoUrl'] ?? '';
          // footerLogo = data['location']['logoUrl'] ?? '';
          footerLogo = 'https://storage.googleapis.com/msgsndr/cyI1tRyaF0oYq5jaPVOP/media/67ec33c8e519ed016331cbfd.png';

          footer['footerAddress'] = data['location']['name'] + '\n' +
              (data['location']['address1'] ?? '') + '\n' +
              (data['location']['city'] ?? '') + ', ' +
              (data['location']['state'] ?? '') + ' ' +
              (data['location']['postalCode'] ?? '');
        });
      }
    } catch (error) {
      print('Error fetching location details: $error');
    }
  }

  Future<void> _loadImagesFromApi() async {
    setState(() => _isLoadingImages = true);

    try {
      final userId = UserSessionService().userId;
      if (userId == null) return;

      final response = await ApiService().getContractTimelineImages(userId);

      if (response['success'] == true && response['data'] != null && response['data'].isNotEmpty) {
        final imageData = response['data'][0];

        // Helper function to handle both base64 and URL images
        Future<Uint8List?> _getImageBytes(dynamic imageData) async {
          if (imageData == null || imageData.toString().isEmpty) return null;

          try {
            // Try to decode as base64 first
            if (imageData is String && base64.decode(imageData) is Uint8List) {
              return base64.decode(imageData);
            }
            // If not base64, try as URL
            else if (imageData is String && Uri.tryParse(imageData)?.hasAbsolutePath == true) {
              final imageResponse = await http.get(Uri.parse(imageData));
              if (imageResponse.statusCode == 200) {
                return imageResponse.bodyBytes;
              }
            }
          } catch (e) {
            return null;
          }
          return null;
        }

        // Clear existing images first
        setState(() {
          _headerImageBytes = null;
          _footerImageBytes = null;
        });

        // Load header image
        if (imageData['headerImage'] != null && imageData['headerImage'].toString().isNotEmpty) {
          final headerBytes = await _getImageBytes(imageData['headerImage']);
          if (headerBytes != null) {
            setState(() {
              _headerImageBytes = headerBytes;
              header['logo'] = base64.encode(headerBytes);
            });
          }
        }

        // Load footer image
        if (imageData['footerImage'] != null && imageData['footerImage'].toString().isNotEmpty) {
          final footerBytes = await _getImageBytes(imageData['footerImage']);
          if (footerBytes != null) {
            setState(() {
              _footerImageBytes = footerBytes;
              footer['logo'] = base64.encode(footerBytes);
            });
          }
        }
      }
    } catch (e) {
      print('Error loading images: $e');
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Failed to load images: ${e.toString()}')),
        // );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingImages = false);
      }
    }
  }
  bool _showUploadSuccess = false;

  Future<void> _pickAndUploadImage(bool isHeader) async {
    setState(() => _showUploadSuccess = false);

    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      final bytes = await pickedFile.readAsBytes();

      // Update UI immediately
      setState(() {
        if (isHeader) {
          _headerImageBytes = bytes;
          header['logo'] = base64.encode(bytes);
        } else {
          _footerImageBytes = bytes;
          footer['logo'] = base64.encode(bytes);
        }
      });

      // Upload in background
      _uploadImageInBackground(isHeader, bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process image: ${e.toString()}')),
      );
    }
  }

  Future<void> _uploadImageInBackground(bool isHeader, Uint8List bytes) async {
    try {
      final base64Image = base64.encode(bytes);
      final userId = UserSessionService().userId;
      if (userId == null) throw Exception('User ID not available');

      final requestBody = {
        'userId': userId,
        if (isHeader) 'headerImage': base64Image,
        if (!isHeader) 'footerImage': base64Image,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };

      final success = await ApiService().uploadContractImages(requestBody);

      if (success) {
        setState(() => _showUploadSuccess = true);
        Future.delayed(Duration(seconds: 3), () {
          if (mounted) setState(() => _showUploadSuccess = false);
        });
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
        );
      }
    }
  }
  Future<void> _loadSavedTextBlocks() async {
    final userId = UserSessionService().userId;
    if (userId == null) return;

    setState(() => _isLoadingText = true);

    try {
      final textBlocks = await ApiService().getContractTextBlocks(userId);
      if (textBlocks != null) {
        setState(() {
          introText = textBlocks['introductionText'] ?? introText;
          middleText = textBlocks['middleContentText'] ?? middleText;
          // header['propertyAddress'] = textBlocks['propertyAddress'] ?? header['propertyAddress'];
          afterMilestoneText = textBlocks['afterMilestoneText'] ??
              'TIME: Time is of the essence in this Contract. Calendar days, based on where the Property is located, shall be used in computing time periods. Other than time for acceptance and Effective Date as set forth in Paragraph 3, any time periods provided for or dates specified in this Contract, whether preprinted, handwritten, typewritten or inserted herein, which shall end or occur on a Saturday, Sunday, national legal public holiday (as defined in 5 U.S.C. Sec. 6103(a)), or a day on which a national legal public holiday is observed because it fell on a Saturday or Sunday, shall extend to the next calendar day which is not a Saturday, Sunday, national legal public holiday, or a day on which a national legal public holiday is observed.';
          _introTextController.text = introText;
          _middleTextController.text = middleText;
          _afterMilestoneController.text = afterMilestoneText;
          _propertyAddressController.text = header['propertyAddress'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading text blocks: $e');
    } finally {
      setState(() => _isLoadingText = false);
    }
  }

  Future<void> _saveTextBlocks() async {
    final userId = UserSessionService().userId;
    if (userId == null) return;

    try {
      await ApiService().saveContractTextBlocks(
        userId: userId,
        introductionText: introText,
        middleContentText: middleText,
        afterMilestoneText: _afterMilestoneController.text,
      );
      // Optionally show a brief success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Changes saved'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error saving text blocks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes')),
      );
    }
  }

  void onContractSelect() async {
    if (selectedOptionValue.isNotEmpty) {
      print('Selected Opportunity ID: $selectedOptionValue');
      await fetchOpportunityDates(selectedOptionValue);
    }
  }

  String formatDateToMDY(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void updatePropertyAddress(String newAddress) {
    setState(() {
      header['propertyAddress'] = newAddress;
      introText = 'We are pleased to announce that we have successfully entered into a contract for the property located at $newAddress. While significant milestones have been achieved, there is still work to be done to reach closing.';
    });
  }

  Future<void> fetchOpportunityDates(String opportunityId) async {
    final apiUrl = 'https://services.leadconnectorhq.com/opportunities/$opportunityId';
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $apiToken',
      'Version': '2021-07-28'
    };

    const propertyAddressFieldId = 'koDEDgbRUE3CK1tVCuFo';

    // Initialize contact fields
    String escrowName = '', escrowPhone = '', escrowEmail = '', escrowCompany = '';
    String mloName = '', mloPhone = '', mloEmail = '', mloCompany = '';
    String listingName = '', listingPhone = '', listingEmail = '', listingCompany = '';
    String sellingName = '', sellingPhone = '', sellingEmail = '', sellingCompany = '';

    final dateMapping = {
      'UQOtoJHeY1ikdNMOtOP8': 'Effective Contract Date',
      'lNjUhxgyjvPE93VOom0D': 'Initial escrow deposit Due Date',
      'q8rFDRTqcCN8HuTUnVvr': 'Loan Application Due Date',
      'dihbH6mRnD9Nn55HbJw7': 'Additional Escrow Deposit Due Date',
      'Z6d5wDjRcZndCWb4ivvS': 'Inspection Period Ends',
      'AKOW6LsV6AzD1ckux7e5': 'Loan Approval Period Ends',
      'N9kjRvTu52WE2sL2BPmQ': 'Title Evidence Due Date',
      '64mrgnBSraTKciXBaPzf': 'Closing Date'
    };

    final fieldMap = {
      // Escrow
      'HHIMdBiwipRZ60Zo2KDo': (val) => escrowName = val ?? '',
      'XjF3IzgkWZDye9xAXVxG': (val) => escrowPhone = val ?? '',
      'YQ2eWIN69geMOFofbw0s': (val) => escrowEmail = val ?? '',
      'dJ7oh1ytObhOGptVBs7u': (val) => escrowCompany = val ?? '',

      // MLO
      'FYtD4Jfj0rkHSnxR4jsRasdasd': (val) => mloName = val ?? '',
      'FYtD4Jfj0rkHSnxR4jsRasdad': (val) => mloCompany = val ?? '',
      'FYtD4Jfj0rkHSnxR4jsRsdas': (val) => mloPhone = val ?? '',
      'fadfaFYtD4Jfj0rkHSnxR4jsRsds': (val) => mloEmail = val ?? '',

      // Listing
      'dVjg1Yk9AMLybs5Mktyl': (val) => listingName = val ?? '',
      'NN1izNSxk7hMzyjhgrKO': (val) => listingCompany = val ?? '',
      'dVjg1Yk9AMLyasdMktyl': (val) => listingPhone = val ?? '',
      'dVjg1Yk9AMLybs5Mktylfasda': (val) => listingEmail = val ?? '',

      // Selling
      'FYtD4Jfj0rkHSnxR4jsR': (val) => sellingName = val ?? '',
      'iVSm25VMhk9wTj4GhsZD': (val) => sellingCompany = val ?? '',
      'FYtD4Jfj0rkHSnxR4jsRsdad': (val) => sellingPhone = val ?? '',
      'FYtD4Jfj0rkasdasdHSnxR4jsRasdasd': (val) => sellingEmail = val ?? ''
    };

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fields = data['opportunity']['customFields'] as List? ?? [];

        for (final field in fields) {
          final fieldId = field['id']?.toString() ?? '';
          final fieldValue = field['fieldValue']?.toString() ?? '';

          final milestoneLabel = dateMapping[fieldId];
          if (milestoneLabel != null) {
            final index = milestones.indexWhere((m) => m['milestone'] == milestoneLabel);
            if (index != -1) {
              milestones[index]['buyer'] = formatDateToMDY(fieldValue);
            }
          }

          if (fieldMap.containsKey(fieldId)) {
            fieldMap[fieldId]!(fieldValue);
          }

          if (fieldId == propertyAddressFieldId) {
            updatePropertyAddress(fieldValue);
          }
        }

        setState(() {
          // Update contactDetails
          contactDetails = [
            {
              'name': escrowName,
              'phone': escrowPhone,
              'email': escrowEmail,
              'company': escrowCompany
            },
            {
              'name': mloName,
              'phone': mloPhone,
              'email': mloEmail,
              'company': mloCompany
            },
            {
              'name': listingName,
              'phone': listingPhone,
              'email': listingEmail,
              'company': listingCompany
            },
            {
              'name': sellingName,
              'phone': sellingPhone,
              'email': sellingEmail,
              'company': sellingCompany
            }
          ];

          // Update controllers
          for (int i = 0; i < 4; i++) {
            contactControllers[i]['company']?.text = contactDetails[i]['company'] ?? '';
            contactControllers[i]['name']?.text = contactDetails[i]['name'] ?? '';
            contactControllers[i]['phone']?.text = contactDetails[i]['phone'] ?? '';
            contactControllers[i]['email']?.text = contactDetails[i]['email'] ?? '';
          }
        });
      }
    } catch (error) {
      print('Error fetching opportunity details: $error');
    }
  }

  void deleteMilestone(int index) {
    setState(() {
      milestones.removeAt(index);
    });
  }

  Future<void> generatePDF() async {
    try {
      final currentIntroText = _introTextController.text;
      final currentMiddleText = _middleTextController.text;
      final currentPropertyAddress = _propertyAddressController.text;
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );

      final pdf = pw.Document();

      // Define styles
      final defaultStyle = pw.TextStyle(
        font: pw.Font.helvetica(),
        fontSize: 10,
        color: PdfColors.black,
      );

      final boldStyle = pw.TextStyle(
        font: pw.Font.helveticaBold(),
        fontSize: 10,
        color: PdfColors.black,
      );

      final titleStyle = pw.TextStyle(
        font: pw.Font.helveticaBold(),
        fontSize: 12,
        color: PdfColors.black,
      );

      pw.MemoryImage? headerLogoImage;
      if (_headerImageBytes != null) {
        headerLogoImage = pw.MemoryImage(_headerImageBytes!);
      } else if (headerLogo.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(headerLogo));
          if (response.statusCode == 200) {
            headerLogoImage = pw.MemoryImage(response.bodyBytes);
          }
        } catch (e) {
          print('Error loading header logo: $e');
        }
      }

      pw.MemoryImage? footerLogoImage;
      if (_footerImageBytes != null) {
        footerLogoImage = pw.MemoryImage(_footerImageBytes!);
      } else if (footerLogo.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(footerLogo));
          if (response.statusCode == 200) {
            footerLogoImage = pw.MemoryImage(response.bodyBytes);
          }
        } catch (e) {
          print('Error loading footer logo: $e');
        }
      }

      try {
        if (headerLogo.isNotEmpty) {
          final response = await http.get(Uri.parse(headerLogo));
          if (response.statusCode == 200) {
            pw.MemoryImage? headerLogoImage = _headerImageBytes != null
                ? pw.MemoryImage(_headerImageBytes!)
                : null;

          }
        }
        if (footerLogo.isNotEmpty) {
          final response = await http.get(Uri.parse(footerLogo));
          if (response.statusCode == 200) {
            pw.MemoryImage? footerLogoImage = _footerImageBytes != null
                ? pw.MemoryImage(_footerImageBytes!)
                : null;
          }
        }
      } catch (e) {
        print('Error loading images: $e');
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginLeft: 36,
            marginRight: 36,
            marginTop: 36,
            marginBottom: 40,
          ),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with logo
                if (headerLogoImage != null)
                  pw.Center(
                    child: pw.Container(
                      height: 60,
                      child: pw.Image(headerLogoImage),
                      margin: const pw.EdgeInsets.only(bottom: 10),
                    ),
                  ),

                // Date and property info
                pw.Text(header['date'] ?? '', style: defaultStyle),
                pw.SizedBox(height: 4),
                pw.Text('RE: Timeline', style: titleStyle),
                pw.SizedBox(height: 8),
                pw.Row(children: [
                  pw.Text('Property Address: ', style: boldStyle),
                  pw.Text(header['propertyAddress'] ?? 'Not specified', style: defaultStyle),
                ]),
                pw.SizedBox(height: 8),

                // Intro paragraph
                pw.Text(currentIntroText, style: defaultStyle),
                pw.SizedBox(height: 8),

                // Contacts table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  columnWidths: {
                    0: pw.FlexColumnWidth(1.5),
                    1: pw.FlexColumnWidth(1.5),
                    2: pw.FlexColumnWidth(1.5),
                    3: pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFD9E6F2)),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text('Title/Escrow Agent:', style: boldStyle),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text('MLO/Lender', style: boldStyle),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text('Listing Agent', style: boldStyle),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text('Selling Agent', style: boldStyle),
                        ),
                      ],
                    ),
                    // Data rows
                    pw.TableRow(
                      children: [
                        for (var i = 0; i < 4; i++)
                          pw.Padding(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(contactDetails[i]['company'] ?? '', style: defaultStyle),
                                pw.Text(contactDetails[i]['name'] ?? '', style: defaultStyle),
                                pw.Text(contactDetails[i]['phone'] ?? '', style: defaultStyle),
                                pw.Text(contactDetails[i]['email'] ?? '', style: defaultStyle.copyWith(color: PdfColors.blue)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Middle paragraph
                pw.Text(currentMiddleText, style: defaultStyle),
                pw.SizedBox(height: 16),

                // Milestones table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  columnWidths: {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFD9E6F2)),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text('Milestone', style: boldStyle),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text('Date', style: boldStyle),
                        ),
                      ],
                    ),
                    // Milestone rows
                    for (var i = 0; i < milestones.length; i++)
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: i == 0
                              ? PdfColor.fromInt(0xFFFFF2CC)
                              : (i % 2 == 0 ? PdfColors.white : PdfColor.fromInt(0xFFF5F5F5)),
                        ),
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(milestones[i]['milestone'] ?? '', style: defaultStyle),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(milestones[i]['buyer'] ?? '', style: defaultStyle),
                          ),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 16),

                pw.Text(_afterMilestoneController.text, style: defaultStyle),
                pw.SizedBox(height: 16),

                // Footer
                pw.Container(
                  width: double.infinity,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      if (footerLogoImage != null)
                        pw.Container(
                          height: 60,
                          width: 150,
                          margin: const pw.EdgeInsets.only(right: 20),
                          child: pw.Image(footerLogoImage),
                        ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            footer['footerText'] ?? 'Florida Realty Of Miami',
                            style: boldStyle.copyWith(fontSize: 11),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            footer['footerAddress']?.split('\n').first ?? '9415 Sunset Dr #236',
                            style: defaultStyle.copyWith(fontSize: 9),
                          ),
                          pw.Text(
                            footer['footerAddress']?.split('\n').last ?? 'Miami, FL 33173',
                            style: defaultStyle.copyWith(fontSize: 9),
                          ),
                          pw.Text(
                            footer['footerSubText'] ?? '786-486-6082',
                            style: defaultStyle.copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final propertyAddress = header['propertyAddress'] ?? 'contract';
      final formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
      final fileName = '${propertyAddress.replaceAll(' ', '_')}_$formattedDate.pdf';

      if (kIsWeb) {
        // Web download
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Mobile (Android/iOS) download
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // Open the file after saving
        final result = await OpenFile.open(file.path);

        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open PDF: ${result.message}')),
          );
        }
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved as $fileName'),
          action: kIsWeb ? null : SnackBarAction(
            label: 'Share',
            onPressed: () => _sharePDF(fileName),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: ${e.toString()}')),
      );
    }
  }

  Future<void> _sharePDF(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        // Updated share method for share_plus 4.0.0+
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Contract Timeline PDF',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF file not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share PDF: ${e.toString()}')),
      );
    }
  }
// Helper methods for building sections
  pw.Widget _buildContentSection(String text) {
    return pw.Column(
      children: [
        pw.Text(text, style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10)),
        pw.SizedBox(height: 16),
      ],
    );
  }


  Future<pw.MemoryImage?> _loadImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url));
      return response.statusCode == 200 ? pw.MemoryImage(response.bodyBytes) : null;
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context, int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        milestones[index]['buyer'] = '${picked.month}/${picked.day}/${picked.year}';
        _milestoneControllers[index].text = '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }

  Widget _buildIntroTextField() {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          // Save when focus is lost
          _saveTextBlocks();
        }
      },
      child: TextFormField(
        controller: _introTextController,
        maxLines: 5,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'Click here to edit introduction text...',
          labelText: 'Introduction Text',
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: 'Helvetica, Arial',
          color: Colors.black,
        ),
        onChanged: (value) {
          setState(() => introText = value);
        },
      ),
    );
  }

  Widget _buildMiddleTextField() {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          // Save when focus is lost
          _saveTextBlocks();
        }
      },
      child: TextFormField(
        controller: _middleTextController,
        maxLines: 5,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          labelText: 'Middle Content Text',
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: 'Helvetica, Arial',
          color: Colors.black,
        ),
        onChanged: (value) {
          setState(() => middleText = value);
        },
      ),
    );
  }

  Widget _buildAfterMilestoneTextField() {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          _saveTextBlocks();
        }
      },
      child: TextFormField(
        controller: _afterMilestoneController,
        maxLines: 5,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          labelText: 'After Milestone Text',
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: 'Helvetica, Arial',
          color: Colors.black,
        ),
        onChanged: (value) {
          setState(() => afterMilestoneText = value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double horizontalPadding = isMobile ? 16.0 : 100.0;
    final double tableWidth = isMobile ? MediaQuery.of(context).size.width * 0.9 : 600;
    final double headerImageWidth = isMobile ? MediaQuery.of(context).size.width * 0.5 : 450;
    final double headerImageHeight = 180;
    final double footerImageWidth = isMobile ? MediaQuery.of(context).size.width * 0.4 : 300;
    final double footerImageHeight = 120;
    final TextStyle bodyTextStyle = TextStyle(
      fontFamily: 'Helvetica, Arial',
      fontSize: isMobile ? 14 : 16,
      color: Colors.black,
    );

    final TextStyle tableHeaderTextStyle = TextStyle(
      fontSize: isMobile ? 13 : 14,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    );

    final TextStyle tableCellTextStyle = TextStyle(
      fontSize: isMobile ? 12 : 13,
      color: Colors.black,
    );

    final TextStyle textAreaTextStyle = TextStyle(
      fontSize: isMobile ? 14 : 16,
      fontWeight: FontWeight.normal,
      fontFamily: 'Helvetica, Arial',
      color: Colors.black,
    );

    final TextStyle footerTextStyle = TextStyle(
      fontSize: isMobile ? 11 : 12,
      color: Color(0xFF666666),
    );


    return Scaffold(
      appBar: const NavbarPage(),
      drawer: const CustomNavbar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showUploadSuccess)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Image uploaded successfully!'),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        setState(() => _showUploadSuccess = false);
                      },
                      child: Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            Container(
              margin: EdgeInsets.only(bottom: 20, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingImages)
                    Center(child: CircularProgressIndicator())
                  else
                    Center(
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => _pickAndUploadImage(true),
                            splashColor: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: headerImageWidth,
                              height: headerImageHeight,
                              margin: EdgeInsets.only(bottom: 10),
                              child: _isLoadingImages
                                  ? Center(child: CircularProgressIndicator()) // Show loading while fetching
                                  : _headerImageBytes != null
                                  ? Image.memory(_headerImageBytes!, fit: BoxFit.contain) // Show API image first
                                  : headerLogo.isNotEmpty
                                  ? Image.network(headerLogo, fit: BoxFit.contain) // Fallback to GHL logo
                                  : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 40),
                                  Text('Click to add header image'),
                                ],
                              ),
                            ),
                          ),
                          Text('Click to change header image',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  Text(header['date'] ?? '',
                      style: bodyTextStyle.copyWith(fontSize: isMobile ? 14 : 16)),
                  SizedBox(height: 8),
                  Text('RE: Timeline',
                      style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Property Address: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      // Property Address Dropdown
                      Text(
                        header['propertyAddress']?.isEmpty ?? true
                            ? 'Not specified'
                            : header['propertyAddress']!,
                        style: bodyTextStyle.copyWith(fontSize: isMobile ? 14 : 16),
                      ),
                      SizedBox(height: 16),
                      Text('Select Contract: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedOptionValue.isNotEmpty ? selectedOptionValue : null,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          filled: true,
                          fillColor: Colors.grey.withOpacity(0.1),
                          hintText: dropdownOptions.isEmpty ? 'Loading contracts...' : 'Select Contract',
                        ),
                        items: dropdownOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option['value'],
                            child: Text(
                              option['label'] ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedOptionValue = value);
                            onContractSelect();
                          }
                        },
                      ),
                      SizedBox(height: 8),
                      // Text(
                      //   header['propertyAddress']?.isEmpty ?? true
                      //       ? 'Not specified'
                      //       : header['propertyAddress']!,
                      //   style: bodyTextStyle.copyWith(fontSize: isMobile ? 14 : 16),
                      // ),
                    ],
                  ),
                ],
              ),
            ),

            // Intro text
            Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 12 : 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildIntroTextField(),
              ),
            ),
            Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 12 : 15),
                decoration: BoxDecoration(
                  color: Color(0xFFE6F2FF),
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contacts Information',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 16 : 18,
                            color: Colors.black87)),
                    SizedBox(height: 12),
                    // Contacts table - editable
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        constraints: BoxConstraints(minWidth: tableWidth),
                        child: Table(
                          defaultColumnWidth: FixedColumnWidth(isMobile ? 120 : 400),
                          border: TableBorder.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          children: [
                            // Header row
                            TableRow(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                              ),
                              children: contactTableHeaders.map((header) =>
                                  Padding(
                                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                                    child: Text(header,
                                        style: tableHeaderTextStyle),
                                  )
                              ).toList(),
                            ),
                            // Company row - editable
                            TableRow(
                              children: [
                                for (var i = 0; i < 4; i++)
                                  Padding(
                                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                                    child: TextFormField(
                                      controller: contactControllers[i]['company'],
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(8),
                                        border: InputBorder.none,
                                      ),
                                      style: tableCellTextStyle,
                                      onChanged: (value) {
                                        setState(() {
                                          contactDetails[i]['company'] = value;
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            // Name row - editable
                            TableRow(
                              children: [
                                for (var i = 0; i < 4; i++)
                                  Padding(
                                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                                    child: TextFormField(
                                      controller: contactControllers[i]['name'],
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(8),
                                        border: InputBorder.none,
                                      ),
                                      style: tableCellTextStyle,
                                      onChanged: (value) {
                                        setState(() {
                                          contactDetails[i]['name'] = value;
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            // Phone row - editable
                            TableRow(
                              children: [
                                for (var i = 0; i < 4; i++)
                                  Padding(
                                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                                    child: TextFormField(
                                      controller: contactControllers[i]['phone'],
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(8),
                                        border: InputBorder.none,
                                      ),
                                      style: tableCellTextStyle,
                                      onChanged: (value) {
                                        setState(() {
                                          contactDetails[i]['phone'] = value;
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            // Email row - editable
                            TableRow(
                              children: [
                                for (var i = 0; i < 4; i++)
                                  Padding(
                                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                                    child: TextFormField(
                                      controller: contactControllers[i]['email'],
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(8),
                                        border: InputBorder.none,
                                      ),
                                      style: tableCellTextStyle.copyWith(
                                        color: Colors.blue,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          contactDetails[i]['email'] = value;
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Middle text
            Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 12 : 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildMiddleTextField(),
              ),
            ),

            // Milestones table - responsive
            Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 12 : 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    // Text(
                    //   'Contract Dates',
                    //   style: TextStyle(
                    //     fontWeight: FontWeight.bold,
                    //     fontSize: isMobile ? 16 : 18,
                    //     color: Colors.black87,
                    //   ),
                    // ),
                    // SizedBox(height: 12),

                    // // Property Address (editable)
                    // TextFormField(
                    //   decoration: InputDecoration(
                    //     border: InputBorder.none,
                    //     isDense: true,
                    //     contentPadding: EdgeInsets.all(0),
                    //   ),
                    //   style: tableCellTextStyle,
                    //   onChanged: (value) {
                    //     setState(() {
                    //       introText = 'We are pleased to announce... $value...';
                    //     });
                    //   },
                    // ),

                    SizedBox(height: 10),

                    // Timeline Table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        constraints: BoxConstraints(minWidth: tableWidth),
                        child: Table(
                          defaultColumnWidth: isMobile ? FlexColumnWidth(1) : FixedColumnWidth(450),
                          border: TableBorder.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          children: [
                            // Table Header
                            TableRow(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                                  child: Text('Milestone', style: tableHeaderTextStyle),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                                  child: Text('Date', style: tableHeaderTextStyle),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                                  child: Text('Actions', style: tableHeaderTextStyle),
                                ),
                              ],
                            ),

                            // Table Rows (all editable)
                            ...milestones.asMap().entries.map((entry) {
                              final index = entry.key;
                              final milestone = entry.value;

                              return TableRow(
                                decoration: BoxDecoration(
                                  color: index == 0
                                      ? Color(0xFFFFF2CC)
                                      : (index % 2 == 0 ? Colors.grey.shade50 : Colors.white),
                                ),
                                children: [
                                  // Editable Milestone Name
                                  Padding(
                                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                                    child: TextFormField(
                                      controller: TextEditingController(text: milestone['milestone'] ?? ''),
                                      style: tableCellTextStyle,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(8),
                                        border: InputBorder.none,
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.blue),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          milestones[index]['milestone'] = value;
                                        });
                                      },
                                    ),
                                  ),

                                  // Editable Date Field
                                  Padding(
                                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                                    child: SizedBox(
                                    height: 48,
                                    child: InkWell(
                                      onTap: () => _selectDate(context, index),
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          controller: TextEditingController(text: milestone['buyer'] ?? ''),
                                          style: tableCellTextStyle,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.all(8),
                                            border: InputBorder.none,
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.blue),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  ),

                                  // Delete Button
                                  Padding(
                                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                                    child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: IconButton(
                                      iconSize: 24,
                                      icon: Icon(Icons.delete,
                                          size: isMobile ? 18 : 20,
                                          color: Colors.red),
                                      onPressed: () => deleteMilestone(index),
                                    ),
                                  ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Legal text
            Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 12 : 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildAfterMilestoneTextField(),
              ),
            ),

            // Footer
            Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 12 : 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        InkWell(
                          onTap: () => _pickAndUploadImage(false),
                          child: Container(
                            width: footerImageWidth,
                            height: footerImageHeight,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _isLoadingFooterImage
                                ? Center(child: CircularProgressIndicator())
                                : _footerImageBytes != null
                                ? Image.memory(
                              _footerImageBytes!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error displaying memory image: $error');
                                return Icon(Icons.error);
                              },
                            )
                                : footerLogo.isNotEmpty
                                ? Image.network(
                              footerLogo,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading network image: $error');
                                return Icon(Icons.error);
                              },
                            )
                                : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 30, color: Colors.grey),
                                Text('Add footer image', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text('Click to change footer',
                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Florida Realty Of Miami',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '9415 Sunset Dr #236\nMiami, FL 33173',
                            style: footerTextStyle,
                            textAlign: TextAlign.right,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '786-486-6082',
                            style: footerTextStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Generate PDF button
            Container(
              padding: EdgeInsets.only(bottom: 20),
              child: ElevatedButton(

                onPressed: generatePDF,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Color(0xFF1976D2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                  shadowColor: Colors.black.withOpacity(0.16),
                ),
                child: Text(
                  'Download Timeline PDF',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  }