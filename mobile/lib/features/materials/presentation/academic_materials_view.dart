import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../profiles/bloc/profile_bloc.dart';
import '../../profiles/bloc/profile_state.dart';
import '../bloc/materials_bloc.dart';
import '../models/academic_material_model.dart';
import '../../../core/widgets/document_picker_bottom_sheet.dart';

class AcademicMaterialsView extends StatefulWidget {
  final String classId;
  final String subjectId;
  final String? className;
  final String? subjectName;
  final bool showAppBar;

  const AcademicMaterialsView({
    super.key,
    required this.classId,
    required this.subjectId,
    this.className,
    this.subjectName,
    this.showAppBar = true,
  });

  @override
  State<AcademicMaterialsView> createState() => _AcademicMaterialsViewState();
}

class _AcademicMaterialsViewState extends State<AcademicMaterialsView> {
  List<AcademicMaterialModel> _cachedMaterials = [];

  String _getEffectiveClassId(BuildContext context) {
    try {
      final profileState = context.read<ProfileBloc>().state;
      if (profileState is StudentProfileLoaded &&
          profileState.profile.currentClassId != null &&
          profileState.profile.currentClassId!.isNotEmpty) {
        return profileState.profile.currentClassId!;
      }
    } catch (_) {}
    if (widget.classId.isNotEmpty) return widget.classId;
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      return authState.user.classId ?? '';
    }
    return '';
  }

  void _openMaterial(BuildContext context, AcademicMaterialModel item) {
    final key = item.s3FileKey.trim();
    if (key.startsWith('http://') || key.startsWith('https://')) {
      _showAttachmentViewer(context, key, item.fileName);
      return;
    }
    context.read<MaterialsBloc>().add(DownloadMaterialEvent(item.id));
  }

  @override
  void initState() {
    super.initState();
    final bloc = context.read<MaterialsBloc>();
    if (bloc.state is MaterialsLoaded) {
      _cachedMaterials = (bloc.state as MaterialsLoaded).materials;
    } else if (bloc.cachedMaterials.isNotEmpty) {
      _cachedMaterials = bloc.cachedMaterials;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final effectiveClassId = _getEffectiveClassId(context);
      if (effectiveClassId.isNotEmpty && widget.subjectId.isNotEmpty) {
        context.read<MaterialsBloc>().add(
              LoadClassMaterialsEvent(effectiveClassId, widget.subjectId),
            );
      }
    });
  }

  @override
  void didUpdateWidget(AcademicMaterialsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final effectiveClassId = _getEffectiveClassId(context);
    if ((oldWidget.classId != widget.classId || oldWidget.subjectId != widget.subjectId) &&
        effectiveClassId.isNotEmpty &&
        widget.subjectId.isNotEmpty) {
      context.read<MaterialsBloc>().add(
            LoadClassMaterialsEvent(effectiveClassId, widget.subjectId),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isTeacher = authState is Authenticated && authState.activeRole == 'TEACHER';
    final effectiveClassId = _getEffectiveClassId(context);

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text('${widget.subjectName ?? "Subject"} Study Materials'),
              elevation: 0,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primaryText,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primaryAccent),
                  onPressed: () {
                    if (effectiveClassId.isNotEmpty && widget.subjectId.isNotEmpty) {
                      context.read<MaterialsBloc>().add(
                            LoadClassMaterialsEvent(effectiveClassId, widget.subjectId),
                          );
                    }
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(color: AppColors.border, height: 1.0),
              ),
            )
          : null,
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
      body: effectiveClassId.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school_outlined, size: 52, color: AppColors.secondaryText),
                    SizedBox(height: 16),
                    Text(
                      'No Enrolled Class Found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your student account does not have an active class enrollment. Please contact your school administrator.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
            )
          : widget.subjectId.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_outlined, size: 52, color: AppColors.secondaryText),
                        SizedBox(height: 16),
                        Text(
                          'Select a Subject',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please select a subject from the options above to view study materials and guides.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                )
              : BlocConsumer<MaterialsBloc, MaterialsState>(
        listener: (context, state) {
          if (state is MaterialsLoaded) {
            setState(() {
              _cachedMaterials = state.materials;
            });
          } else if (state is MaterialOperationSuccess) {
            if (state.downloadUrl != null && state.downloadUrl!.isNotEmpty) {
              _showAttachmentViewer(context, state.downloadUrl!, state.fileName);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.primaryText,
                ),
              );
            }
          } else if (state is MaterialsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is MaterialsLoading && _cachedMaterials.isEmpty) {
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
            _cachedMaterials = state.materials;
            return _buildMaterialsListView(context, state.materials);
          }

          // Preserve visible list when MaterialOperationSuccess or transient MaterialsError occurs
          if (_cachedMaterials.isNotEmpty) {
            return _buildMaterialsListView(context, _cachedMaterials);
          }

          if (state is MaterialsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      state.message.contains('own class')
                          ? 'Study materials are only accessible for your enrolled class.'
                          : state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        final effectiveClassId = _getEffectiveClassId(context);
                        if (effectiveClassId.isNotEmpty && widget.subjectId.isNotEmpty) {
                          context.read<MaterialsBloc>().add(
                                LoadClassMaterialsEvent(effectiveClassId, widget.subjectId),
                              );
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: AppColors.surface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: ElevatedButton(
              onPressed: () {
                final effectiveClassId = _getEffectiveClassId(context);
                if (effectiveClassId.isNotEmpty && widget.subjectId.isNotEmpty) {
                  context.read<MaterialsBloc>().add(
                        LoadClassMaterialsEvent(effectiveClassId, widget.subjectId),
                      );
                }
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

  Widget _buildMaterialsListView(
      BuildContext context, List<AcademicMaterialModel> materials) {
    if (materials.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          final effectiveClassId = _getEffectiveClassId(context);
          if (effectiveClassId.isNotEmpty && widget.subjectId.isNotEmpty) {
            context.read<MaterialsBloc>().add(
                  LoadClassMaterialsEvent(effectiveClassId, widget.subjectId),
                );
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.22),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_outlined,
                      size: 56, color: AppColors.tertiaryText),
                  const SizedBox(height: 16),
                  const Text(
                    'No study materials available yet',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Materials uploaded by your teachers or school admin will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final effectiveClassId = _getEffectiveClassId(context);
        if (effectiveClassId.isNotEmpty && widget.subjectId.isNotEmpty) {
          context.read<MaterialsBloc>().add(
                LoadClassMaterialsEvent(effectiveClassId, widget.subjectId),
              );
        }
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: materials.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildMaterialCard(materials[index]);
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openMaterial(context, item),
          child: Padding(
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
                      onPressed: () => _openMaterial(context, item),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open Document'),
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
          ),
        ),
      ),
    );
  }

  Future<void> _launchDocumentUrl(BuildContext context, String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document URL is invalid or empty'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      final uri = Uri.parse(trimmed);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final fallback = await launchUrl(uri);
        if (!fallback) {
          throw Exception('Platform browser could not launch document URL');
        }
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: trimmed));
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not open document viewer ($e). Link copied to clipboard.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showAttachmentViewer(BuildContext context, String url, String? name) {
    final lowerName = (name ?? url).toLowerCase();
    final isPdf = lowerName.endsWith('.pdf');
    final isImage = lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.webp');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name ?? (isPdf ? 'Study Material (PDF)' : 'Study Material'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: isImage
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: InteractiveViewer(
                                panEnabled: true,
                                minScale: 0.5,
                                maxScale: 4.0,
                                child: Image.network(
                                  url,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(24.0),
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                                          const SizedBox(height: 8),
                                          const Text('Unable to load image preview'),
                                          const SizedBox(height: 4),
                                          Text(url, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _launchDocumentUrl(context, url),
                                  icon: const Icon(Icons.open_in_new, size: 16),
                                  label: const Text('Open Full Image'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryAccent,
                                    foregroundColor: AppColors.surface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: url));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Image link copied to clipboard'),
                                        backgroundColor: AppColors.success,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Copy Link'),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPdf ? Icons.picture_as_pdf : Icons.description_outlined,
                                size: 56,
                                color: isPdf ? const Color(0xFFB91C1C) : AppColors.primaryAccent,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                name ?? (isPdf ? 'Study Material (PDF)' : 'Study Material Document'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tap Open Document to view in your browser or external PDF reader.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    key: const Key('open_document_external_button'),
                                    onPressed: () => _launchDocumentUrl(context, url),
                                    icon: const Icon(Icons.open_in_new, size: 16),
                                    label: Text(isPdf ? 'Open PDF' : 'Open Document'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryAccent,
                                      foregroundColor: AppColors.surface,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    key: const Key('copy_document_link_button'),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: url));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Document link copied to clipboard'),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: const Text('Copy Link'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
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
  final _fileNameController = TextEditingController(text: '');
  String _selectedContentType = 'application/pdf';
  String? _pickedDocumentSource;
  List<int>? _pickedFileBytes;

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
                            _pickedFileBytes = doc.bytes;
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
              if (_pickedFileBytes == null || _pickedFileBytes!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please choose a document or photo from your device/camera before uploading.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              widget.onSubmitted(
                UploadMaterialEvent(
                  classId: widget.classId,
                  subjectId: widget.subjectId,
                  title: _titleController.text.trim(),
                  description: _descController.text.trim(),
                  fileName: _fileNameController.text.trim(),
                  fileBytes: _pickedFileBytes!,
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
          child: const Text('Upload Material'),
        ),
      ],
    );
  }
}
