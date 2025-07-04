import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as file_picker;

import '../api/api_service.dart';
import '../service/user_session_service.dart';
import '../widgets/custom_navbar.dart';
import '../widgets/navbar_page.dart';

class UploadContractTimelinePdfPage extends StatefulWidget {
  const UploadContractTimelinePdfPage({super.key});

  @override
  State<UploadContractTimelinePdfPage> createState() => _UploadContractTimelinePdfPageState();
}

class _UploadContractTimelinePdfPageState extends State<UploadContractTimelinePdfPage> {
  Uint8List? _headerImageBytes;
  Uint8List? _footerImageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage(bool isHeader) async {
    try {
      if (kIsWeb) {
        final result = await file_picker.FilePicker.platform.pickFiles(
          type: file_picker.FileType.image,
          withData: true,
        );
        if (result != null && result.files.single.bytes != null) {
          setState(() {
            if (isHeader) {
              _headerImageBytes = result.files.single.bytes!;
            } else {
              _footerImageBytes = result.files.single.bytes!;
            }
          });
        }
      } else {
        final picked = await _picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          setState(() {
            if (isHeader) {
              _headerImageBytes = bytes;
            } else {
              _footerImageBytes = bytes;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showMessage('Error selecting image: ${e.toString()}', isError: true);
    }
  }

  Future<int?> _getUserId() async {
    final userId = UserSessionService().userId;
    if (userId != null && userId > 0) {
      return userId;
    } else {
      await UserSessionService().initialize();
      return UserSessionService().userId;
    }
  }

  Future<void> _uploadImages() async {
    final userId = await _getUserId();

    if (userId == null) {
      _showMessage('User ID not found. Please login again.', isError: true);
      return;
    }

    if (_headerImageBytes == null && _footerImageBytes == null) {
      _showMessage('Please select at least one image.', isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final String? headerBase64 = _headerImageBytes != null ? base64Encode(_headerImageBytes!) : null;
      final String? footerBase64 = _footerImageBytes != null ? base64Encode(_footerImageBytes!) : null;

      final body = {
        "userId": userId,
        "headerImage": headerBase64,
        "footerImage": footerBase64,
      };

      final success = await ApiService().uploadContractImages(body);

      _showMessage(success ? 'Images uploaded!' : 'Upload failed', isError: !success);
    } catch (e) {
      _showMessage('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildImageButton({
    required String label,
    required Uint8List? imageBytes,
    required VoidCallback onTap,
    required IconData icon,
    required VoidCallback onDelete,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(icon, size: 48, color: Colors.blue),
                const SizedBox(height: 6),
                Text(label),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (imageBytes != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  imageBytes,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: InkWell(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavbarPage(),
      drawer: const CustomNavbar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  "Upload Header & Footer Images",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildImageButton(
                      label: 'Select Header',
                      imageBytes: _headerImageBytes,
                      onTap: () => _pickImage(true),
                      icon: Icons.upload_file,
                      onDelete: () => setState(() => _headerImageBytes = null),
                    ),
                    _buildImageButton(
                      label: 'Select Footer',
                      imageBytes: _footerImageBytes,
                      onTap: () => _pickImage(false),
                      icon: Icons.upload_file,
                      onDelete: () => setState(() => _footerImageBytes = null),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    onPressed: _isUploading ? null : _uploadImages,
                    label: _isUploading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black12,
                      ),
                    )
                        : const Text("Upload Images"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
