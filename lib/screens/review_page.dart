import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:flutter_reta/screens/submit_page.dart';
import 'package:intl/intl.dart';
import '../api/ApplynxService.dart';
import 'package:pdfx/pdfx.dart';

import '../widgets/contract_progress_bar.dart';



class ReviewPage extends StatefulWidget {
  final Uint8List? pdfFile;
  final Map<String, dynamic> contractData;
  final DateTime? effectiveDate;
  final VoidCallback onProceed;
  final VoidCallback onGoBack;

  const ReviewPage({
    Key? key,
    required this.pdfFile,
    required this.contractData,
    this.effectiveDate,
    required this.onProceed,
    required this.onGoBack,
  }) : super(key: key);

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  String? pdfUrl;
  late PdfControllerPinch pdfController;
  bool _isPdfReady = false;
  String selectedContractType = 'Select';
  Map<String, DateTime?> dateFields = {
    'Effective Date': null,
    'Initial Escrow Deposit Due Date': null,
    'Loan Application Due Date': null,
    'Additional Escrow Deposit Due Date': null,
    'Inspection Period Deadline': null,
    'Loan Approval Due Date': null,
    'Title Evidence Due Date': null,
    'Closing Date': null,
  };
  Map<String, int> dateOffsets = {};

  final TextEditingController buyerAgentController = TextEditingController();
  final TextEditingController escrowAgentController = TextEditingController();
  final TextEditingController propertyAddressController = TextEditingController();

  String sellerName = '';
  String sellerAgentName = '';
  String buyerName = '';
  String firstName = '';
  String lastName = '';
  String email = '';

  String newFirstName = '';
  String newLastName = '';
  String newEmail = '';
  String newBuyerName = '';
  List<String> buyerNames = [];
  List<String> sellerNames = [];

  bool loading = false;
  double progress = 0;
  bool isMobile = false;

  int totalApiCalls = 0;
  int completedApiCalls = 0;
  List<String> processingErrors = [];
  List<Map<String, String>> words = [];

  ApiApplynxService apiService = ApiApplynxService();
  bool oppCreated = false;
  String? firstBuyerName;
  String? newContractNumber;
  List<Map<String, dynamic>> opportunityCustomFields = [];

  String? escrowAgentEmail;
  String? escrowAgentPhone;
  String? propertyTaxId;

  bool showNameFields = false;
  bool firstNameError = false;
  bool lastNameError = false;
  bool buyerNameError = false;
  bool emailError = false;
  bool firstNameTouched = false;
  bool lastNameTouched = false;
  bool emailTouched = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Define contract type fields
  final List<String> financeFields = [
    'Effective Date',
    'Initial Escrow Deposit Due Date',
    'Loan Application Due Date',
    'Additional Escrow Deposit Due Date',
    'Inspection Period Deadline',
    'Loan Approval Due Date',
    'Title Evidence Due Date',
    'Closing Date'
  ];

  final List<String> cashFields = [
    'Effective Date',
    'Initial Escrow Deposit Due Date',
    'Additional Escrow Deposit Due Date',
    'Inspection Period Deadline',
    'Title Evidence Due Date',
    'Closing Date'
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isMobile = MediaQuery
        .of(context)
        .size
        .width <= 768;
  }

  // void _initializeData() {
  //   if (widget.pdfFile != null) {
  //     pdfUrl = 'data:application/pdf;base64,${base64Encode(widget.pdfFile!)}';
  //   }
  //   _processContractData();
  // }
  void _initializeData() {
    if (widget.pdfFile != null) {
      _loadPdf();
    }
    _processContractData();
  }

  Future<void> _loadPdf() async {
    try {
      pdfController = PdfControllerPinch(
        document: PdfDocument.openData(widget.pdfFile!),
      );
      setState(() {
        _isPdfReady = true;
      });
    } catch (e) {
      debugPrint('Error loading PDF: $e');
      setState(() {
        _isPdfReady = false;
      });
    }
  }


  @override
  void dispose() {
    pdfController.dispose();
    super.dispose();
  }


  DateTime? _tryParseDate(String input) {
    if (input.isEmpty) return null;

    final cleanInput = input
        .replaceAll(
        RegExp(r'\(|\)|On or before|Within', caseSensitive: false), '')
        .trim();

    final formats = [
      DateFormat('MMMM d, yyyy'),
      DateFormat('MMM d, yyyy'),
      DateFormat('M/d/yyyy'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('MMMM d yyyy'),
      DateFormat('MMM d yyyy'),
    ];

    for (final format in formats) {
      try {
        return format.parseStrict(cleanInput);
      } catch (_) {}
    }


    return null;
  }

  void _processContractData() {
    // debugPrint('Complete contractData: ${widget.contractData}');
    // debugPrint('All keys: ${widget.contractData.keys.join(', ')}');

    final contractType = widget.contractData['Contract Type']
        ?.toString()
        .toLowerCase() ?? '';
    selectedContractType = contractType.contains('finance') ? 'Finance'
        : contractType.contains('cash') ? 'Cash'
        : 'Select';

    sellerName = widget.contractData['Seller']?.toString() ??
        widget.contractData['SellerName']?.toString() ??
        widget.contractData['Seller Name']?.toString() ??
        _extractSellerFromRawData(widget.contractData) ??
        '';

    sellerName = sellerName.replaceFirst(RegExp(r'^-\s*'), '').trim();
    buyerName = widget.contractData['Buyer']?.toString() ?? '';
    buyerName = buyerName.replaceFirst(RegExp(r'^-\s*'), '').trim();




    _extractAdditionalInfo();
    buyerNames = _splitNames(buyerName);
    sellerNames = _splitNames(sellerName);
    if (buyerNames.isNotEmpty) {
      final parts = buyerNames[0].split(' ');
      newFirstName = parts.first;
      newLastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      newEmail = _generateEmail(newFirstName, newLastName);

      // Also set the old variables if you're using them elsewhere
      firstName = newFirstName;
      lastName = newLastName;
      email = newEmail;
    }
    _parseDatesFromContract();
    _validateFields();
  }

  String? _extractSellerFromRawData(Map<String, dynamic> contractData) {
    final rawString = contractData.toString();
    final sellerPattern = RegExp(
      r'Seller[:\s]+([^,]+)',
      caseSensitive: false,
    );
    final match = sellerPattern.firstMatch(rawString);
    return match?.group(1)?.trim();
  }

  List<String> _splitNames(String names) {
    if (names.isEmpty) return [];
    names = names
        .replaceAll(RegExp(r'^[-\s]+|[-\s]+$'), '')
        .trim();

    if (names.contains(RegExp(
        r'\b(Inc|LLC|L\.L\.C|Co|Corp|Ltd|Agency)\.?$', caseSensitive: false))) {
      return [names];
    }

    return names
        .split(RegExp(r',\s*(?![^()]*\))'))
        .expand((part) => part.split(RegExp(r'\s*&\s*')))
        .expand((part) =>
        part.split(RegExp(r'\s+and\s+', caseSensitive: false)))
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  void _extractAdditionalInfo() {
    sellerAgentName = widget.contractData['Seller Agent Name']?.toString() ??
        widget.contractData['Listing Agent Name']?.toString() ??
        '';

    buyerAgentController.text =
        widget.contractData['Buyer Agent Name']?.toString() ?? '';
    escrowAgentController.text =
        widget.contractData['Escrow Agent Name']?.toString() ?? '';
    escrowAgentEmail = widget.contractData['Escrow Agent Email']?.toString();
    escrowAgentPhone = widget.contractData['Escrow Agent Phone']?.toString();
    propertyAddressController.text =
        widget.contractData['Property Address']?.toString() ?? '';
    propertyTaxId = widget.contractData['Property Tax ID']?.toString();
  }

  void _parseDatesFromContract() {
    if (widget.effectiveDate != null) {
      dateFields['Effective Date'] = widget.effectiveDate;
    }
    else {
      final value = widget.contractData['Effective Date']?.toString();
      if (value != null && value.isNotEmpty) {
        final date = _tryParseDate(value);
        if (date != null) {
          dateFields['Effective Date'] = date;
          debugPrint('Parsed effective date from contract: $date');
        } else {
          debugPrint('Could not parse effective date from: $value');
        }
      }
    }

    final fieldsToProcess = selectedContractType == "Cash"
        ? cashFields
        : financeFields;
    for (final field in fieldsToProcess) {
      if (field == 'Effective Date') continue;

      final value = widget.contractData[field]?.toString();
      if (value == null || value.isEmpty) continue;

      final date = _tryParseDate(value);
      if (date != null) {
        dateFields[field] = date;
        continue;
      }

      final offset = _extractDaysOffset(value);
      if (offset != null) {
        dateOffsets[field] = offset;
        debugPrint('Found offset for $field: $offset days');
      } else {
        debugPrint('Could not parse date or offset for $field: $value');
      }
    }
    final closingDateValue = widget.contractData['Closing Date']?.toString();
    if (closingDateValue != null && closingDateValue.isNotEmpty) {
      final closingOffset = _extractDaysOffset(closingDateValue);
      if (closingOffset != null) {
        dateOffsets['Closing Date'] = closingOffset;
      }
    }
    _calculateRelativeDates();
  }

  void _calculateRelativeDates() {
    final effectiveDate = dateFields['Effective Date'];

    // Calculate Closing Date if it has an offset and isn't manually set
    if (effectiveDate != null &&
        dateOffsets.containsKey('Closing Date') &&
        manuallySetDates['Closing Date'] != true) {
      final closingOffset = dateOffsets['Closing Date']!;
      final calculatedClosingDate = effectiveDate.add(
          Duration(days: closingOffset));
      setState(() {
        dateFields['Closing Date'] = calculatedClosingDate;
      });
    }

    // Calculate other dates based on offsets
    dateOffsets.forEach((key, offset) {
      if (key != 'Closing Date' && manuallySetDates[key] != true) {
        if (effectiveDate != null && offset > 0) {
          final calculatedDate = effectiveDate.add(Duration(days: offset));
          setState(() {
            dateFields[key] = calculatedDate;
          });
        }

        final closingDate = dateFields['Closing Date'];
        if (closingDate != null && offset < 0) {
          final calculatedDate = closingDate.add(Duration(days: offset));
          setState(() {
            dateFields[key] = calculatedDate;
          });
        }
      }
    });
  }

  // Add this to your state class
  Map<String, bool> manuallySetDates = {};

  bool _isValidName(String? name) {
    if (name == null || name
        .trim()
        .isEmpty) return false;
    final lowerCaseName = name.trim().toLowerCase();
    return !(lowerCaseName.contains('not specified') ||
        lowerCaseName.contains('not provided'));
  }

  String _formatLabel(String key) {
    return key
        .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'), (match) => '${match.group(1)} ${match.group(
        2)}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
    word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  bool _allDatesFilled() {
    final fields = selectedContractType == "Cash" ? cashFields : financeFields;
    for (var field in fields) {
      if (dateFields[field] == null &&
          field != 'Additional Escrow Deposit Due Date') {
        return false;
      }
    }
    return true;
  }

  void _validateFields() {
    firstNameError = newFirstName
        .trim()
        .isEmpty;
    lastNameError = newLastName
        .trim()
        .isEmpty;
    emailError = newEmail
        .trim()
        .isEmpty || !_validateEmail(newEmail);
    buyerNameError = buyerNames.isEmpty || buyerNames[0]
        .trim()
        .isEmpty;
  }

  bool _validateEmail(String email) {
    if (email.isEmpty) return false;
    if (email.contains(',')) return false;

    final parts = email.split('@');
    if (parts.length != 2) return false;
    if (parts[0].length > 20) return false;

    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9-]+(\.[a-zA-Z]{2,})+$');
    return regex.hasMatch(email);
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(top: 10, right: 10),
      ),
    );
  }

  void _onContractTypeChanged(String? value) {
    if (value != null) {
      setState(() {
        selectedContractType = value;
      });
    }
  }

  void _selectDate(BuildContext context, String label) async {
    final currentDate = dateFields[label] ?? DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        dateFields[label] = pickedDate;
        manuallySetDates[label] = true;
      });

      // Recalculate dependents when either base date changes
      if (label == 'Effective Date' || label == 'Closing Date') {
        _calculateRelativeDates();
      }
    }
  }

  int? _extractDaysOffset(String text) {
    if (text.isEmpty) return null;

    final afterEffectiveMatch = RegExp(
      r'(?:\(|Within|On or before)?\s*(\d+)\s+days?\s+after\s+Effective\s+Date',
      caseSensitive: false,
    ).firstMatch(text);
    if (afterEffectiveMatch != null) {
      return int.tryParse(afterEffectiveMatch.group(1)!);
    }

    final beforeClosingMatch = RegExp(
      r'(\d+)\s+days?\s+before\s+Closing\s+Date',
      caseSensitive: false,
    ).firstMatch(text);
    if (beforeClosingMatch != null) {
      return -int.tryParse(beforeClosingMatch.group(1)!)!;
    }

    final simpleNumberMatch = RegExp(r'(\d+)').firstMatch(text);
    if (simpleNumberMatch != null) {
      return int.tryParse(simpleNumberMatch.group(1)!);
    }

    return null;
  }

  void _addSeller() {
    if (sellerNames.length < 5) {
      setState(() {
        sellerNames.add('');
      });
    }
  }

  void _removeSeller() {
    if (sellerNames.length > 1) {
      setState(() {
        sellerNames.removeLast();
      });
    }
  }

  void _addBuyer() {
    if (buyerNames.length < 5) {
      setState(() {
        buyerNames.add('');
      });
    }
  }

  void _removeBuyer() {
    if (buyerNames.length > 1) {
      setState(() {
        buyerNames.removeLast();
      });
    }
  }

  Future<void> _nextStep() async {
    if (!_formKey.currentState!.validate() || !_allDatesFilled()) {
      _showErrorMessage('Please fill all required fields with valid data');
      return;
    }

    _validateFields();
    if (firstNameError || lastNameError || emailError || buyerNameError) {
      return;
    }

    setState(() {
      loading = true;
      progress = 0;
      processingErrors = [];
    });

    try {
      // final lastContractResponse = await apiService.getLastContractNumber();
      // String lastContractStr;
      // if (lastContractResponse['customValues'] is Map) {
      //   lastContractStr =
      //       lastContractResponse['customValues']['contract_contract_type']
      //           ?.toString() ?? "Contract 0000";
      // } else {
      //   lastContractStr = "Contract 0000";
      // }
      // final numericPart = lastContractStr.replaceAll(RegExp(r'[^0-9]'), '');
      // final lastContractNumber = int.tryParse(numericPart) ?? 0;
      //
      // newContractNumber = (lastContractNumber + 1).toString().padLeft(4, '0');
      // final contractTag = 'contract #$newContractNumber';

      final lastContractResponse = await apiService.getLastContractNumber();
      final lastContractStr = lastContractResponse['value'] ?? "Contract 0000";
      final numericPart = lastContractStr.replaceAll(RegExp(r'[^0-9]'), '');
      final lastContractNumber = int.tryParse(numericPart) ?? 0;

      newContractNumber = (lastContractNumber + 1).toString().padLeft(4, '0');
      final contractTag = 'contract #$newContractNumber';

      final allContacts = _prepareContacts(contractTag, newContractNumber!);
      totalApiCalls = allContacts.length;
      completedApiCalls = 0;

      for (final contact in allContacts) {
        try {
          final contactResponse = await apiService.upsertContact(
              contact['data']);
          final contactId = contactResponse['contact']['id'];

          if (contact['isFirstBuyer'] && !oppCreated) {
            await _createOpportunityAndUpdateContact(
              contactId,
              newContractNumber!,
              contact['firstName'],
            );
            oppCreated = true;
          }

          completedApiCalls++;
          setState(() => progress = completedApiCalls / totalApiCalls * 100);
        } catch (e) {
          debugPrint('Stack trace: $e');
          processingErrors.add(
              'Failed to create contact: ${contact['data']['firstName']} - $e');
          completedApiCalls++;
          setState(() => progress = completedApiCalls / totalApiCalls * 100);
        }
      }

      await apiService.updateCustomValue('Contract $newContractNumber');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SubmitPage(
                isOpportunityCreated: oppCreated,
                processingErrors: processingErrors,
              ),
        ),
      );
    } catch (e) {
      setState(() {
        processingErrors.add(e.toString());
        loading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SubmitPage(
                isOpportunityCreated: false,
                processingErrors: processingErrors,
              ),
        ),
      );

      _showErrorMessage('Error processing data: $e');
    } finally {
      if (!oppCreated) {
        setState(() => loading = false);
      }
    }
  }

  List<Map<String, dynamic>> _prepareContacts(String contractTag,
      String newContractNumber) {
    final contacts = <Map<String, dynamic>>[];
    int sellerCounter = 1;
    int buyerCounter = 1;

    for (final seller in sellerNames) {
      final nameParts = seller.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      contacts.add({
        'data': _createContactData(
          firstName,
          lastName,
          contractTag,
          'seller$sellerCounter',
        ),
        'isFirstBuyer': false,
        'firstName': firstName,
      });
      sellerCounter++;
    }

    for (final buyer in buyerNames) {
      final nameParts = buyer.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';
      final isFirstBuyer = buyerCounter == 1;

      contacts.add({
        'data': _createContactData(
          firstName,
          lastName,
          contractTag,
          'buyer$buyerCounter',
        ),
        'isFirstBuyer': isFirstBuyer,
        'firstName': firstName,
      });

      if (isFirstBuyer) {
        firstBuyerName = firstName;
      }
      buyerCounter++;
    }

    if (sellerAgentName.isNotEmpty) {
      final nameParts = sellerAgentName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      contacts.add({
        'data': _createContactData(
          firstName,
          lastName,
          contractTag,
          "seller's agent",
        ),
        'isFirstBuyer': false,
        'firstName': firstName,
      });
    }

    if (buyerAgentController.text.isNotEmpty) {
      final nameParts = buyerAgentController.text.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      contacts.add({
        'data': _createContactData(
          firstName,
          lastName,
          contractTag,
          "buyer's agent",
        ),
        'isFirstBuyer': false,
        'firstName': firstName,
      });
    }

    if (escrowAgentController.text.isNotEmpty) {
      final nameParts = escrowAgentController.text.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      contacts.add({
        'data': _createContactData(
          firstName,
          lastName,
          contractTag,
          "escrow agent",
        ),
        'isFirstBuyer': false,
        'firstName': firstName,
      });
    }

    return contacts;
  }

  Map<String, dynamic> _createContactData(String firstName,
      String lastName,
      String contractTag,
      String typeTag,) {
    final email = _generateEmail(firstName, lastName);

    return {
      'firstName': firstName,
      'lastName': lastName,
      'name': '$firstName $lastName',
      'email': email,
      'tags': [contractTag, typeTag],
      'type': 'customer',
      'locationId': apiService.locationId,
      'tags': [contractTag, typeTag],
      'customFields': [
        {
          'key': 'contract_contract_type',
          'value': contractTag.replaceFirst('#', '')
        }
      ]
    };
  }

  String _generateEmail(String firstName, String lastName) {
    final cleanFirst = firstName.toLowerCase().replaceAll(
        RegExp(r'[^a-z]'), '');
    final cleanLast = lastName.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    return '$cleanFirst${cleanLast.isNotEmpty
        ? '.$cleanLast'
        : ''}@no-email.net';
  }

  Future<void> _createOpportunityAndUpdateContact(String contactId,
      String newContractNumber,
      String firstName,) async {
    opportunityCustomFields = _prepareOpportunityFields(newContractNumber);


    final opportunityData = {
      'pipelineId': "B2abziQpwJBYSr4qzopT",
      'locationId': apiService.locationId,
      'contactId': contactId,
      'name': 'Contract #$newContractNumber - ${propertyAddressController.text
          .isNotEmpty
          ? propertyAddressController.text
          : "Default Name"}',
      'customFields': opportunityCustomFields,
    };

    final opportunityResponse = await apiService.upsertOpportunity(
        opportunityData);
    final opportunityId = opportunityResponse['opportunity']['id'];
    final opportunityName = opportunityData['name'];

    await apiService.updateContactCustomFields(
      contactId,
      [
        {'key': 'oppurtunityid', 'value': opportunityId},
        {'key': 'oppurtunityname', 'value': opportunityName},
      ],
    );
  }

  List<Map<String, dynamic>> _prepareOpportunityFields(
      String newContractNumber) {
    final fields = <Map<String, dynamic>>[];

    for (final entry in dateFields.entries) {
      if (entry.value != null) {
        final snakeCaseKey = entry.key
            .toLowerCase()
            .replaceAll(' ', '_');
        fields.add({
          'key': snakeCaseKey,
          'value': DateFormat('yyyy-MM-dd').format(entry.value!),
        });
      }
    }

    for (int i = 0; i < sellerNames.length; i++) {
      if (sellerNames[i].isNotEmpty) {
        fields.add({
          'key': 'seller_${i + 1}',
          'value': sellerNames[i],
        });
      }
    }

    for (int i = 0; i < buyerNames.length; i++) {
      if (buyerNames[i].isNotEmpty) {
        fields.add({
          'key': 'buyer_${i + 1}',
          'value': buyerNames[i],
        });
      }
    }

    fields.addAll([
      {'key': 'escrow_agent_name', 'value': escrowAgentController.text},
      {'key': 'escrow_agent_email', 'value': escrowAgentEmail ?? ''},
      {'key': 'escrow_agent_phone', 'value': escrowAgentPhone ?? ''},
      {'key': 'property_address', 'value': propertyAddressController.text},
      {'key': 'property_tax_id', 'value': propertyTaxId ?? ''},
      {'key': 'contract_type', 'value': selectedContractType},
      {'key': 'contract_number', 'value': newContractNumber},
      {'key': 'sellers_agent', 'value': sellerAgentName},
      {'key': 'buyers_agent', 'value': buyerAgentController.text},
      {
        'key': 'listing_agent_name',
        'value': widget.contractData['Listing Agent Name'] ?? ''
      },
      {
        'key': 'listing_agent_company_name',
        'value': widget.contractData['Listing Agent Company'] ?? ''
      },
      {
        'key': 'listing_agent_phone',
        'value': widget.contractData['Listing Agent Phone'] ?? ''
      },
      {
        'key': 'listing_agent_email',
        'value': widget.contractData['Listing Agent Email'] ?? ''
      },
      {
        'key': 'selling_agent_name',
        'value': widget.contractData['Selling Agent Name'] ?? ''
      },
      {
        'key': 'selling_agent_company_name',
        'value': widget.contractData['Selling Agent Company'] ?? ''
      },
      {
        'key': 'selling_agent_phone',
        'value': widget.contractData['Selling Agent Phone'] ?? ''
      },
      {
        'key': 'selling_agent_email',
        'value': widget.contractData['Selling Agent Email'] ?? ''
      },
      {
        'key': 'mlolender_name',
        'value': widget.contractData['MLO/Lender Name'] ?? ''
      },
      {
        'key': 'mlolender_company_name',
        'value': widget.contractData['MLO/Lender Company'] ?? ''
      },
      {
        'key': 'mlolender_phone',
        'value': widget.contractData['MLO/Lender Phone'] ?? ''
      },
      {
        'key': 'mlolender_email',
        'value': widget.contractData['MLO/Lender Email'] ?? ''
      },
    ]);

    return fields;
  }

  List<Widget> _getDateWidgets() {
    final fields = selectedContractType == "Cash" ? cashFields : financeFields;
    return fields.map((key) {
      final date = dateFields[key];
      final isRequired = key != 'Additional Escrow Deposit Due Date';

      return Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _selectDate(context, key),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: isRequired ? '$key *' : key,
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today, size: 20),
              labelStyle: isRequired && date == null
                  ? TextStyle(color: Colors.red)
                  : null,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? DateFormat('MM/dd/yyyy').format(date)
                      : 'Select date',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPdfViewer() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _isPdfReady
            ? PdfViewPinch(
          controller: pdfController,
          scrollDirection: Axis.vertical,
        )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildForm() {
    final isFormValid = selectedContractType != 'Select' &&
        _allDatesFilled() &&
        !firstNameError &&
        !lastNameError &&
        !emailError &&
        !buyerNameError;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contract Type
          Card(
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contract Type',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedContractType,
                    items: ['Select', 'Finance', 'Cash', 'None']
                        .map((type) =>
                        DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                        .toList(),
                    onChanged: _onContractTypeChanged,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    isExpanded: true,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Buyer Information Section
          Card(
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Buyer Information',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Spacer(),
                      if (buyerNames.length < 5)
                        TextButton(
                          onPressed: _addBuyer,
                          child: Text('+ Add Buyer',
                              style: TextStyle(color: Colors.indigo)),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ...buyerNames
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Buyer ${index + 1} Name',
                                border: OutlineInputBorder(),
                                errorText: index == 0 && buyerNameError
                                    ? 'Buyer name is required'
                                    : null,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              initialValue: entry.value,
                              onChanged: (value) {
                                setState(() {
                                  buyerNames[index] = value;
                                  if (index == 0) {
                                    buyerNameError = value
                                        .trim()
                                        .isEmpty;
                                  }
                                });
                              },
                            ),
                          ),
                          if (buyerNames.length > 1)
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline,
                                  color: Colors.red),
                              onPressed: _removeBuyer,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Seller Information Section
          Card(
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Seller Information',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Spacer(),
                      if (sellerNames.length < 5)
                        TextButton(
                          onPressed: _addSeller,
                          child: Text('+ Add Seller',
                              style: TextStyle(color: Colors.indigo)),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ...sellerNames
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Seller ${index + 1} Name',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              initialValue: entry.value,
                              onChanged: (value) {
                                setState(() {
                                  sellerNames[index] = value;
                                });
                              },
                            ),
                          ),
                          if (sellerNames.length > 1)
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline,
                                  color: Colors.red),
                              onPressed: _removeSeller,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Primary Buyer Details
          Card(
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Primary Buyer Details',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                      errorText: firstNameError
                          ? 'First name is required'
                          : null,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    initialValue: newFirstName,
                    onChanged: (value) {
                      setState(() {
                        newFirstName = value;
                        firstNameError = value
                            .trim()
                            .isEmpty;
                      });
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                      errorText: lastNameError ? 'Last name is required' : null,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    initialValue: newLastName,
                    onChanged: (value) {
                      setState(() {
                        newLastName = value;
                        lastNameError = value
                            .trim()
                            .isEmpty;
                      });
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      errorText: emailError ? 'Valid email is required' : null,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    initialValue: newEmail,
                    onChanged: (value) {
                      setState(() {
                        newEmail = value;
                        emailError = value
                            .trim()
                            .isEmpty || !_validateEmail(value);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Agent Information
          Card(
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Agent Information',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Seller Agent Name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    initialValue: sellerAgentName,
                    onChanged: (value) {
                      setState(() {
                        sellerAgentName = value;
                      });
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Buyer Agent Name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    controller: buyerAgentController,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Escrow Agent Name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    controller: escrowAgentController,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Property Address',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    controller: propertyAddressController,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Dates Section
          Card(
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contract Dates',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 12),
                  ..._getDateWidgets(),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Progress Indicator
          if (loading)
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                    ),
                    SizedBox(height: 10),
                    Text('Processing... ${progress.toInt()}%'),
                    if (processingErrors.isNotEmpty)
                      Column(
                        children: [
                          SizedBox(height: 10),
                          Text(
                            'Errors: ${processingErrors.length}',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

          SizedBox(height: 20),

          // Submit Button
          Center(
            child: ElevatedButton(
              onPressed: loading || !isFormValid ? null : _nextStep,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('Submit', style: TextStyle(fontSize: 16)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1,
              ),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contract Preview'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: widget.onGoBack,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 768) {
              // Web layout - side by side
              return Column(
                children: [
                  // Add progress bar at the top
                  ContractProgressBar(currentStep: 2),
                  SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PDF Viewer (left side)
                        Expanded(
                          flex: 1,
                          child: _buildPdfViewer(),
                        ),
                        SizedBox(width: 20),
                        // Form (right side)
                        Expanded(
                          flex: 1,
                          child: SingleChildScrollView(
                            child: _buildForm(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // Mobile layout - stacked
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Add progress bar at the top
                    ContractProgressBar(currentStep: 2),
                    SizedBox(height: 20),
                    // PDF Viewer (top)
                    Container(
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.4,
                      child: _buildPdfViewer(),
                    ),
                    SizedBox(height: 20),
                    // Form (bottom)
                    _buildForm(),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}