import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/document_picker_bottom_sheet.dart';
import '../bloc/leaves_bloc.dart';
import '../bloc/leaves_event.dart';
import '../bloc/leaves_state.dart';
import '../models/student_leave_model.dart';
import '../repository/leaves_repository.dart';

class StudentLeaveView extends StatefulWidget {
  const StudentLeaveView({super.key});

  @override
  State<StudentLeaveView> createState() => _StudentLeaveViewState();
}

class _StudentLeaveViewState extends State<StudentLeaveView> {
  @override
  void initState() {
    super.initState();
    context.read<LeavesBloc>().add(const LoadStudentMyLeavesEvent());
  }

  void _openAttachment(BuildContext context, String? rawUrl, String? fileName) async {
    final url = (rawUrl ?? '').trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No document URL available for this leave application.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final lower = (fileName ?? url).toLowerCase();
    final isImage = lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');

    if (isImage) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          fileName ?? 'Attached Photo',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        loadingBuilder: (c, child, progress) {
                          if (progress == null) return child;
                          return const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                        errorBuilder: (c, error, stackTrace) => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('Failed to load image preview',
                                style: TextStyle(color: AppColors.secondaryText)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    // For PDFs and other documents: Launch externally
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open document externally.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid document URL or application not found.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _openApplyDialog() {
    final formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController();
    String startDate = DateTime.now().toIso8601String().split('T')[0];
    String endDate = DateTime.now().toIso8601String().split('T')[0];
    String? selectedDocumentName;
    String? selectedDocumentUrl;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.border),
              ),
              title: const Text(
                'Apply Student Leave',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date selectors
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.tryParse(startDate) ??
                                      DateTime.now(),
                                  firstDate: DateTime.now().subtract(
                                      const Duration(days: 30)),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 90)),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    startDate = picked
                                        .toIso8601String()
                                        .split('T')[0];
                                  });
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                              ),
                              child: Text(
                                'From: $startDate',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryText),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.tryParse(endDate) ??
                                      DateTime.now(),
                                  firstDate: DateTime.now().subtract(
                                      const Duration(days: 30)),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 90)),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    endDate = picked
                                        .toIso8601String()
                                        .split('T')[0];
                                  });
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                              ),
                              child: Text(
                                'To: $endDate',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryText),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Reason for leave',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a reason';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Optional Document Attachment
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.attach_file,
                                        size: 15,
                                        color: AppColors.secondaryText),
                                    SizedBox(width: 4),
                                    Text(
                                      'Supporting Document (Optional)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                                if (selectedDocumentName != null)
                                  InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedDocumentName = null;
                                        selectedDocumentUrl = null;
                                      });
                                    },
                                    child: const Text(
                                      'Remove',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (selectedDocumentName == null) ...[
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final leavesRepo = dialogCtx.read<LeavesRepository>();
                                  final doc =
                                      await DocumentPickerBottomSheet.show(
                                    dialogCtx,
                                    title: 'Attach Leave Document',
                                    subtitle:
                                        'Choose from device storage or take a photo with camera',
                                    categoryPrefix: 'leave_doc',
                                    onUpload: (bytes, fileName) async {
                                      final uploadRes = await leavesRepo.uploadAttachment(bytes, fileName);
                                      return (uploadRes['attachmentUrl'] as String?) ??
                                          (uploadRes['fileKey'] as String?) ??
                                          '';
                                    },
                                  );
                                  if (doc != null) {
                                    setDialogState(() {
                                      selectedDocumentName = doc.name;
                                      selectedDocumentUrl = doc.url;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.upload_file, size: 15),
                                label: const Text('Attach Document (Optional)',
                                    style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.border),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                ),
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Icon(
                                    selectedDocumentName!
                                            .toLowerCase()
                                            .endsWith('.pdf')
                                        ? Icons.picture_as_pdf
                                        : Icons.camera_alt_outlined,
                                    size: 16,
                                    color: selectedDocumentName!
                                            .toLowerCase()
                                            .endsWith('.pdf')
                                        ? const Color(0xFFB91C1C)
                                        : const Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      selectedDocumentName!,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primaryText),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.secondaryText)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(dialogCtx);
                      this.context.read<LeavesBloc>().add(
                            ApplyStudentLeaveEvent(
                              startDate: startDate,
                              endDate: endDate,
                              reason: reasonController.text.trim(),
                              documentUrl: selectedDocumentUrl,
                              attachmentName: selectedDocumentName,
                            ),
                          );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryText,
                    foregroundColor: AppColors.surface,
                    elevation: 0,
                  ),
                  child: const Text('Submit Application'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeavesBloc, LeavesState>(
      listener: (context, state) {
        if (state is LeaveActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF15803D),
            ),
          );
        } else if (state is LeavesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Column(
        children: [
          // Banner with disclaimer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Student Leave Applications',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Reviewed & approved by your Class Teacher or School Admin.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openApplyDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Apply'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryText,
                    foregroundColor: AppColors.surface,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // Leave List
          Expanded(
            child: BlocBuilder<LeavesBloc, LeavesState>(
              builder: (context, state) {
                if (state is LeavesLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                if (state is LeavesError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 36, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryText),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              context
                                  .read<LeavesBloc>()
                                  .add(const LoadStudentMyLeavesEvent());
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is StudentMyLeavesLoaded) {
                  final leaves = state.leaves;

                  if (leaves.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<LeavesBloc>()
                            .add(const LoadStudentMyLeavesEvent());
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(48.0),
                            child: Center(
                              child: Text(
                                'No leave applications submitted yet.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.secondaryText),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<LeavesBloc>()
                          .add(const LoadStudentMyLeavesEvent());
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: leaves.length,
                      itemBuilder: (context, index) {
                        return _buildLeaveCard(leaves[index]);
                      },
                    ),
                  );
                }

                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(StudentLeaveModel leave) {
    Color badgeColor;
    Color badgeBg;
    Color badgeBorder;

    switch (leave.status) {
      case 'APPROVED':
        badgeColor = const Color(0xFF15803D);
        badgeBg = const Color(0xFFF0FDF4);
        badgeBorder = const Color(0xFF86EFAC);
        break;
      case 'REJECTED':
        badgeColor = const Color(0xFFB91C1C);
        badgeBg = const Color(0xFFFEF2F2);
        badgeBorder = const Color(0xFFFCA5A5);
        break;
      case 'PENDING':
      default:
        badgeColor = const Color(0xFFB45309);
        badgeBg = const Color(0xFFFFFBEB);
        badgeBorder = const Color(0xFFFDE68A);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${leave.startDate} to ${leave.endDate}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  leave.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            leave.reason,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primaryText,
            ),
          ),
          if ((leave.remarks != null && leave.remarks!.isNotEmpty) ||
              (leave.rejectionReason != null &&
                  leave.rejectionReason!.isNotEmpty)) ...[
            const SizedBox(height: 6),
            Text(
              'Remarks: ${leave.remarks ?? leave.rejectionReason}',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: leave.status == 'REJECTED'
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFF15803D),
              ),
            ),
          ],
          if ((leave.documentUrl != null && leave.documentUrl!.isNotEmpty) ||
              (leave.attachmentName != null && leave.attachmentName!.isNotEmpty)) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _openAttachment(context, leave.documentUrl, leave.attachmentName),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attach_file, size: 14, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        leave.attachmentName != null && leave.attachmentName!.isNotEmpty
                            ? 'Doc: ${leave.attachmentName}'
                            : 'View Attached Document',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D4ED8),
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new, size: 12, color: Color(0xFF1D4ED8)),
                  ],
                ),
              ),
            ),
          ],
          if (leave.reviewedByName != null &&
              leave.reviewedByName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Reviewed by: ${leave.reviewedByName}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );

  }
}
