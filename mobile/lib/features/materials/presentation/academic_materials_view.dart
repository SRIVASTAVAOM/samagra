import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/materials_bloc.dart';
import '../models/academic_material_model.dart';
import '../../../core/widgets/document_picker_bottom_sheet.dart';

class AcademicMaterialsView extends StatefulWidget {
  final String classId;
  final String subjectId;
  final String? className;
  final String? subjectName;

  const AcademicMaterialsView({
    super.key,
    required this.classId,
    required this.subjectId,
    this.className,
    this.subjectName,
  });

  @override
  State<AcademicMaterialsView> createState() => _AcademicMaterialsViewState();
}

class _AcademicMaterialsViewState extends State<AcademicMaterialsView> {
  @override
  void initState() {
    super.initState();
    if (widget.classId.isNotEmpty && widget.subjectId.isNotEmpty) {
      context.read<MaterialsBloc>().add(
            LoadClassMaterialsEvent(widget.classId, widget.subjectId),
          );
    }
  }

  @override
  void didUpdateWidget(AcademicMaterialsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.classId != widget.classId || oldWidget.subjectId != widget.subjectId) &&
        widget.classId.isNotEmpty &&
        widget.subjectId.isNotEmpty) {
      context.read<MaterialsBloc>().add(
            LoadClassMaterialsEvent(widget.classId, widget.subjectId),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isTeacher = authState is Authenticated && authState.activeRole == 'TEACHER';

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subjectName ?? "Subject"} Study Materials'),
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryText,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryAccent),
            onPressed: () {
              if (widget.classId.isNotEmpty && widget.subjectId.isNotEmpty) {
                context.read<MaterialsBloc>().add(
                      LoadClassMaterialsEvent(widget.classId, widget.subjectId),
                    );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.border, height: 1.0),
        ),
      ),
      backgroundColor: AppColors.scaffoldBackground,
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              key: const Key('upload_material_fab'),
              onPressed: () => _showUploadDialog(context),
              backgroundColor: AppColors.primaryAccent,
              icon: const Icon(Icons.upload_file, color: AppColors.surface),
              label: const Text('Upload Material', style: TextStyle(color: AppColors.surface)),
            )
          : null,
      body: (widget.classId.isEmpty || widget.subjectId.isEmpty)
          ? const Center(
              child: Text(
                'Please select a class and subject to view study materials.',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            )
          : BlocConsumer<MaterialsBloc, MaterialsState>(
        listener: (context, state) {
          if (state is MaterialOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.downloadUrl != null
                    ? 'Download link ready: ${state.fileName ?? "Document"}'
                    : state.message),
                backgroundColor: AppColors.primaryText,
              ),
            );
          } else if (state is MaterialsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is MaterialsLoading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (state is MaterialUploading) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LinearProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                      backgroundColor: AppColors.indigo100,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.statusText,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primaryText),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is MaterialsLoaded) {
            final materials = state.materials;
            if (materials.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open_outlined, size: 48, color: AppColors.tertiaryText),
                    const SizedBox(height: 12),
                    const Text(
                      'No study materials uploaded yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: materials.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildMaterialCard(materials[index]);
              },
            );
          }

          return Center(
            child: ElevatedButton(
              onPressed: () {
                context.read<MaterialsBloc>().add(
                      LoadClassMaterialsEvent(widget.classId, widget.subjectId),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.surface,
              ),
              child: const Text('Load Materials'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaterialCard(AcademicMaterialModel item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.indigo50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.indigo100),
                ),
                child: Icon(
                  item.contentType.contains('pdf') ? Icons.picture_as_pdf : Icons.image,
                  color: AppColors.primaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.fileName,
                      style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  item.formattedSize,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.secondaryText),
                ),
              ),
            ],
          ),
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.description!,
              style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'By ${item.teacherName ?? "Teacher"}',
                style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
              ),
              OutlinedButton.icon(
                key: Key('download_material_${item.id}'),
                onPressed: () {
                  context.read<MaterialsBloc>().add(DownloadMaterialEvent(item.id));
                },
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Download Document'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryAccent,
                  side: const BorderSide(color: AppColors.indigo200),
                  backgroundColor: AppColors.indigo50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _UploadMaterialDialog(
          classId: widget.classId,
          subjectId: widget.subjectId,
          onSubmitted: (event) {
            context.read<MaterialsBloc>().add(event);
            Navigator.pop(dialogContext);
          },
        );
      },
    );
  }
}

class _UploadMaterialDialog extends StatefulWidget {
  final String classId;
  final String subjectId;
  final void Function(UploadMaterialEvent) onSubmitted;

  const _UploadMaterialDialog({
    required this.classId,
    required this.subjectId,
    required this.onSubmitted,
  });

  @override
  State<_UploadMaterialDialog> createState() => _UploadMaterialDialogState();
}

class _UploadMaterialDialogState extends State<_UploadMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _fileNameController = TextEditingController(text: 'Chapter_Summary_Guide.pdf');
  String _selectedContentType = 'application/pdf';
  String? _pickedDocumentSource;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Upload Study Material', style: TextStyle(color: AppColors.primaryText)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('material_title_field'),
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('material_desc_field'),
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
                ),
              ),
              const SizedBox(height: 12),
              // Camera / Gallery / Device Picker Container
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.attach_file, size: 15, color: AppColors.secondaryText),
                            SizedBox(width: 4),
                            Text(
                              'Choose / Capture Document',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryText),
                            ),
                          ],
                        ),
                        if (_pickedDocumentSource != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.successBorder),
                            ),
                            child: Text(
                              _pickedDocumentSource!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('material_pick_file_btn'),
                      onPressed: () async {
                        final doc = await DocumentPickerBottomSheet.show(
                          context,
                          title: 'Upload Syllabus / Study Material',
                          subtitle:
                              'Choose from device storage or take a photo with camera',
                          categoryPrefix: 'study_material',
                        );
                        if (doc != null) {
                          setState(() {
                            _fileNameController.text = doc.name;
                            _pickedDocumentSource = doc.source == DocumentUploadSource.camera
                                ? 'From Camera'
                                : 'From Gallery/Device';
                            if (doc.name.toLowerCase().endsWith('.pdf')) {
                              _selectedContentType = 'application/pdf';
                            } else if (doc.name.toLowerCase().endsWith('.png')) {
                              _selectedContentType = 'image/png';
                            } else {
                              _selectedContentType = 'image/jpeg';
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.add_a_photo_outlined, size: 14),
                      label: const Text(
                        'Device / Camera se File Chunein',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryAccent,
                        side: const BorderSide(color: AppColors.indigo200),
                        backgroundColor: AppColors.indigo50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('material_filename_field'),
                controller: _fileNameController,
                decoration: const InputDecoration(
                  labelText: 'File Name *',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'File name is required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedContentType,
                decoration: const InputDecoration(
                  labelText: 'MIME Type',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
                ),
                items: const [
                  DropdownMenuItem(value: 'application/pdf', child: Text('PDF Document (.pdf)')),
                  DropdownMenuItem(value: 'image/jpeg', child: Text('JPEG Image (.jpg)')),
                  DropdownMenuItem(value: 'image/png', child: Text('PNG Image (.png)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedContentType = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.secondaryText),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('confirm_upload_btn'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final sampleBytes = List<int>.filled(1024 * 100, 65);
              widget.onSubmitted(
                UploadMaterialEvent(
                  classId: widget.classId,
                  subjectId: widget.subjectId,
                  title: _titleController.text.trim(),
                  description: _descController.text.trim(),
                  fileName: _fileNameController.text.trim(),
                  fileBytes: sampleBytes,
                  contentType: _selectedContentType,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAccent,
            foregroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Upload to S3'),
        ),
      ],
    );
  }
}
