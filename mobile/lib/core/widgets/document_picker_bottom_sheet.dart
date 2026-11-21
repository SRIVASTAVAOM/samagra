import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart' show XTypeGroup, openFile;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../network/dio_client.dart';
import '../theme/app_colors.dart';

Future<void> viewAttachment(BuildContext context, String? value) async {
  final uri = Uri.tryParse(value ?? '');
  try {
    if (uri != null && uri.scheme == 'https' && !uri.path.contains('/v1/uploads/') && await launchUrl(uri)) return;
  } catch (_) { /* Show recovery guidance below. */ }
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File unavailable. Ask the uploader to replace it.')));
}

enum DocumentUploadSource {
  device,
  camera,
}

class PickedDocument {
  final String name;
  final String url;
  final int size;
  final DocumentUploadSource source;

  const PickedDocument({
    required this.name,
    required this.url,
    this.size = 0,
    required this.source,
  });
}

class DocumentPickerBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String categoryPrefix;
  final ImagePicker? imagePicker;
  final Future<XFile?> Function(ImageSource source)? pickImageFn;
  final void Function(PickedDocument doc)? onDocumentPicked;

  const DocumentPickerBottomSheet({
    super.key,
    this.title = 'Attach Supporting Document',
    this.subtitle = 'Select an option to upload your document',
    this.categoryPrefix = 'document',
    this.imagePicker,
    this.pickImageFn,
    this.onDocumentPicked,
  });

  static Future<PickedDocument?> show(
    BuildContext context, {
    String title = 'Attach Supporting Document',
    String subtitle = 'Select an option to upload your document',
    String categoryPrefix = 'document',
    ImagePicker? imagePicker,
    Future<XFile?> Function(ImageSource source)? pickImageFn,
  }) async {
    return showModalBottomSheet<PickedDocument>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => DocumentPickerBottomSheet(
        title: title,
        subtitle: subtitle,
        categoryPrefix: categoryPrefix,
        imagePicker: imagePicker,
        pickImageFn: pickImageFn,
      ),
    );
  }

  Future<void> _handlePick(
    BuildContext context,
    DocumentUploadSource source,
  ) async {
    try {
      final imageSource = source == DocumentUploadSource.camera ? ImageSource.camera : ImageSource.gallery;
      final file = pickImageFn != null ? await pickImageFn!(imageSource)
          : source == DocumentUploadSource.camera ? await (imagePicker ?? ImagePicker()).pickImage(source: imageSource)
          : await openFile(acceptedTypeGroups: [const XTypeGroup(label: 'Images and PDFs', extensions: ['jpg','jpeg','png','pdf'], mimeTypes: ['image/jpeg','image/png','application/pdf'], uniformTypeIdentifiers: ['public.jpeg','public.png','com.adobe.pdf'])]);
      if (!context.mounted || file == null) return;
      final client = context.read<DioClient>();
      if (await file.length() > 10 * 1024 * 1024) throw const FormatException('Choose a file under 10 MB.');
      final bytes = await file.readAsBytes();
      final response = await client.post('/materials/attachments', data: bytes, options: Options(contentType: 'application/octet-stream'));
      final url = response.data['data']['url'] as String;
      if (!context.mounted) return;
      final result = PickedDocument(name: file.name, url: url, source: source, size: bytes.length);

      if (onDocumentPicked != null) {
        onDocumentPicked!(result);
      }
      Navigator.of(context).pop(result);
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error is FormatException ? error.message : 'Upload failed. Select a JPEG, PNG or PDF and retry.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Title & Subtitle
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 18),

            // Option 1: Choose from Device / Gallery
            _buildOptionTile(
              context: context,
              key: const Key('doc_picker_device_option'),
              icon: Icons.photo_library_outlined,
              title: 'Device / Gallery se Chunein (Files & Gallery)',
              description:
                  'Choose PDF, JPEG or PNG from device storage or gallery',
              badgeText: 'Gallery / Device',
              onTap: () => _handlePick(context, DocumentUploadSource.device),
            ),
            const SizedBox(height: 12),

            // Option 2: Take Photo with Camera
            _buildOptionTile(
              context: context,
              key: const Key('doc_picker_camera_option'),
              icon: Icons.camera_alt_rounded,
              title: 'Camera se Photo Kheenche (Take Photo)',
              description:
                  'Click photo of document, notebook page or certificate directly using camera',
              badgeText: 'Camera Photo',
              onTap: () => _handlePick(context, DocumentUploadSource.camera),
            ),
            const SizedBox(height: 16),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required Key key,
    required IconData icon,
    required String title,
    required String description,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                icon,
                size: 22,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.tertiaryText,
            ),
          ],
        ),
      ),
    );
  }
}
