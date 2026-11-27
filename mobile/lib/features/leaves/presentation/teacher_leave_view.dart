import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/document_picker_bottom_sheet.dart';
import '../bloc/leaves_bloc.dart';
import '../bloc/leaves_event.dart';
import '../bloc/leaves_state.dart';
import '../models/staff_leave_model.dart';
import '../models/student_leave_model.dart';
import '../repository/leaves_repository.dart';

class TeacherLeaveView extends StatefulWidget {
  final int initialTab;

  const TeacherLeaveView({super.key, this.initialTab = 0});

  @override
  State<TeacherLeaveView> createState() => _TeacherLeaveViewState();
}

class _TeacherLeaveViewState extends State<TeacherLeaveView> {
  late int _currentTab; // 0: My Leaves, 1: Student Leave Requests
  String _studentLeaveStatus = 'PENDING'; // 'PENDING' | 'APPROVED' | 'REJECTED' | 'ALL'
  String _studentLeaveTimeframe = 'all'; // 'all' | 'this_week' | 'this_month'
  final TextEditingController _studentSearchController = TextEditingController();
  List<StaffLeaveModel>? _cachedMyLeaves;
  List<StudentLeaveModel>? _cachedStudentLeaves;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    if (_currentTab == 1) {
      _applyStudentLeaveFilters();
    } else {
      context.read<LeavesBloc>().add(const LoadStaffMyLeavesEvent());
    }
  }

  void _applyStudentLeaveFilters() {
    context.read<LeavesBloc>().add(
          LoadClassStudentLeavesEvent(
            status: _studentLeaveStatus == 'ALL' ? null : _studentLeaveStatus,
            timeframe: _studentLeaveTimeframe == 'all' ? null : _studentLeaveTimeframe,
            search: _studentSearchController.text.trim().isEmpty
                ? null
                : _studentSearchController.text.trim(),
          ),
        );
  }

  @override
  void dispose() {
    _studentSearchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryText : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryText : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.surface : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  void _showAttachmentViewer(BuildContext context, String url, String? name) {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No document URL available for this leave request.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

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
                        name ?? (isPdf ? 'Leave Document (PDF)' : 'Leave Document'),
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
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: isImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: InteractiveViewer(
                              panEnabled: true,
                              minScale: 0.5,
                              maxScale: 3.0,
                              child: Image.network(
                                url,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.broken_image, size: 48, color: AppColors.error),
                                        SizedBox(height: 8),
                                        Text('Failed to load image preview', style: TextStyle(color: AppColors.secondaryText)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
                                size: 56,
                                color: isPdf ? AppColors.error : AppColors.primaryAccent,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                name ?? 'Attached Document',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: SelectableText(
                                  url,
                                  style: const TextStyle(fontSize: 12, color: AppColors.primaryAccent),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final uri = Uri.parse(url);
                                        final launched = await launchUrl(uri,
                                            mode: LaunchMode.externalApplication);
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
                                              content: Text('Invalid document URL.'),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.open_in_new, size: 16),
                                    label: const Text('Open Document'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: url));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Document URL copied to clipboard'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: const Text('Copy Link'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _openApplyDialog() {
    final formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController();
    String leaveType = 'CASUAL';
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
                'Apply Staff Leave',
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
                      DropdownButtonFormField<String>(
                        initialValue: leaveType,
                        decoration: const InputDecoration(
                          labelText: 'Leave Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'CASUAL', child: Text('Casual Leave (CL)')),
                          DropdownMenuItem(
                              value: 'SICK', child: Text('Medical / Sick Leave')),
                          DropdownMenuItem(
                              value: 'EARNED', child: Text('Earned Leave (EL)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => leaveType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
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
                                    final parsedEnd = DateTime.tryParse(endDate);
                                    if (parsedEnd != null && parsedEnd.isBefore(picked)) {
                                      endDate = startDate;
                                    }
                                  });
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                alignment: Alignment.centerLeft,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'From Date',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatShortLeaveDate(startDate),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                ],
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
                                    horizontal: 10, vertical: 10),
                                alignment: Alignment.centerLeft,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'To Date',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatShortLeaveDate(endDate),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Builder(
                        builder: (_) {
                          final days = calculateLeaveDayCount(startDate, endDate);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                days == null
                                    ? 'To Date must be on or after From Date'
                                    : '$days ${days == 1 ? 'day' : 'days'} selected',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: days == null
                                      ? AppColors.error
                                      : AppColors.secondaryText,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      TextFormField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Reason for leave',
                          hintText: 'Briefly explain why leave is needed...',
                          helperText: 'Minimum 5 characters',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          final trimmed = val?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Please enter a reason';
                          }
                          if (trimmed.length < 5) {
                            return 'Please enter at least 5 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      if (selectedDocumentName == null)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final leavesRepo = this.context.read<LeavesRepository>();
                              final doc = await DocumentPickerBottomSheet.show(
                                dialogCtx,
                                title: 'Attach Leave Document',
                                subtitle:
                                    'Choose from device storage or take a photo with camera',
                                categoryPrefix: 'staff_leave_doc',
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
                            icon: const Icon(Icons.add_a_photo_outlined, size: 15),
                            label: const Text(
                              '+ Attach Photo / PDF (Optional)',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryText,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                selectedDocumentName!
                                        .toLowerCase()
                                        .endsWith('.pdf')
                                    ? Icons.picture_as_pdf
                                    : Icons.image_outlined,
                                size: 16,
                                color: selectedDocumentName!
                                        .toLowerCase()
                                        .endsWith('.pdf')
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFF1D4ED8),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  selectedDocumentName!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    selectedDocumentName = null;
                                    selectedDocumentUrl = null;
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.close,
                                      size: 16, color: AppColors.error),
                                ),
                              ),
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
                    if (calculateLeaveDayCount(startDate, endDate) == null) return;
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(dialogCtx);
                      this.context.read<LeavesBloc>().add(
                            ApplyStaffLeaveEvent(
                              startDate: startDate,
                              endDate: endDate,
                              leaveType: leaveType,
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
        if (state is StaffMyLeavesLoaded) {
          setState(() => _cachedMyLeaves = state.leaves);
        } else if (state is ClassStudentLeavesLoaded) {
          setState(() => _cachedStudentLeaves = state.leaves);
        } else if (state is LeaveActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF15803D),
            ),
          );
        } else if (state is LeavesError) {
          final isClassTeacherNoticeOnTab0 = _currentTab == 0 &&
              (state.message.contains('not assigned as a Class Teacher') ||
                  state.message.contains('NOT_CLASS_TEACHER'));
          if (!isClassTeacherNoticeOnTab0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      child: Column(
        children: [
          // Segmented Navigation Tabs
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_currentTab != 0) {
                        setState(() => _currentTab = 0);
                        context
                            .read<LeavesBloc>()
                            .add(const LoadStaffMyLeavesEvent());
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _currentTab == 0
                            ? AppColors.primaryText
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _currentTab == 0
                              ? AppColors.primaryText
                              : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'My Leaves',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _currentTab == 0
                              ? AppColors.surface
                              : AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_currentTab != 1) {
                        setState(() => _currentTab = 1);
                        context
                            .read<LeavesBloc>()
                            .add(const LoadClassStudentLeavesEvent());
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _currentTab == 1
                            ? AppColors.primaryText
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _currentTab == 1
                              ? AppColors.primaryText
                              : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Student Leave Requests',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _currentTab == 1
                              ? AppColors.surface
                              : AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contextual Header
          if (_currentTab == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Leave Applications',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Reviewed & approved by School Admin.',
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
                          horizontal: 14, vertical: 9),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student Leave Requests',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Homeroom Class Teacher review queue',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: _applyStudentLeaveFilters,
                        tooltip: 'Refresh queue',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Search bar
                  SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _studentSearchController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Search by student name or admission...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _studentSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _studentSearchController.clear();
                                  _applyStudentLeaveFilters();
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      onSubmitted: (_) => _applyStudentLeaveFilters(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Pending',
                          isSelected: _studentLeaveStatus == 'PENDING',
                          onTap: () {
                            setState(() => _studentLeaveStatus = 'PENDING');
                            _applyStudentLeaveFilters();
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Approved',
                          isSelected: _studentLeaveStatus == 'APPROVED',
                          onTap: () {
                            setState(() => _studentLeaveStatus = 'APPROVED');
                            _applyStudentLeaveFilters();
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Rejected',
                          isSelected: _studentLeaveStatus == 'REJECTED',
                          onTap: () {
                            setState(() => _studentLeaveStatus = 'REJECTED');
                            _applyStudentLeaveFilters();
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'All Status',
                          isSelected: _studentLeaveStatus == 'ALL',
                          onTap: () {
                            setState(() => _studentLeaveStatus = 'ALL');
                            _applyStudentLeaveFilters();
                          },
                        ),
                        const SizedBox(width: 12),
                        Container(height: 16, width: 1, color: AppColors.border),
                        const SizedBox(width: 12),
                        _buildFilterChip(
                          label: 'All Time',
                          isSelected: _studentLeaveTimeframe == 'all',
                          onTap: () {
                            setState(() => _studentLeaveTimeframe = 'all');
                            _applyStudentLeaveFilters();
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'This Week',
                          isSelected: _studentLeaveTimeframe == 'this_week',
                          onTap: () {
                            setState(() => _studentLeaveTimeframe = 'this_week');
                            _applyStudentLeaveFilters();
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'This Month',
                          isSelected: _studentLeaveTimeframe == 'this_month',
                          onTap: () {
                            setState(() => _studentLeaveTimeframe = 'this_month');
                            _applyStudentLeaveFilters();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Leave List Body
          Expanded(
            child: BlocBuilder<LeavesBloc, LeavesState>(
              builder: (context, state) {
                if (state is LeavesLoading) {
                  if (_currentTab == 0 && _cachedMyLeaves == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (_currentTab == 1 && _cachedStudentLeaves == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                }

                if (state is LeavesError) {
                  final isNotClassTeacher = state.message
                          .contains('not assigned as a Class Teacher') ||
                      state.message.contains('NOT_CLASS_TEACHER');

                  if (_currentTab == 1 ||
                      (!isNotClassTeacher && _cachedMyLeaves == null)) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isNotClassTeacher
                                  ? Icons.lock_outline
                                  : Icons.error_outline,
                              size: 36,
                              color: isNotClassTeacher
                                  ? AppColors.secondaryText
                                  : AppColors.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isNotClassTeacher
                                  ? 'Student leave approvals are only available for designated Class Teachers with an active homeroom assignment.'
                                  : state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.secondaryText),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                if (_currentTab == 0) {
                                  context
                                      .read<LeavesBloc>()
                                      .add(const LoadStaffMyLeavesEvent());
                                } else {
                                  _applyStudentLeaveFilters();
                                }
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
                }

                if (_currentTab == 0) {
                  final leaves = state is StaffMyLeavesLoaded
                      ? state.leaves
                      : _cachedMyLeaves;
                  if (leaves == null) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  if (leaves.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<LeavesBloc>()
                            .add(const LoadStaffMyLeavesEvent());
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(48.0),
                            child: Center(
                              child: Text(
                                'No leave records yet.',
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
                          .add(const LoadStaffMyLeavesEvent());
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

                final studentLeaves = state is ClassStudentLeavesLoaded
                    ? state.leaves
                    : _cachedStudentLeaves;
                if (studentLeaves == null) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                if (studentLeaves.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => _applyStudentLeaveFilters(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(48.0),
                          child: Center(
                            child: Text(
                              'No student leave applications submitted for your class.',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.secondaryText),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _applyStudentLeaveFilters(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: studentLeaves.length,
                    itemBuilder: (context, index) {
                      return _buildStudentLeaveCard(studentLeaves[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openReviewDialog(StudentLeaveModel leave, {required bool isApprove}) {
    final remarksController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          isApprove ? 'Approve Student Leave' : 'Reject Student Leave',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color:
                isApprove ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${leave.studentName ?? 'Student'} (${formatLeaveDateRange(leave.startDate, leave.endDate)})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reason: ${leave.reason}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
            if ((leave.documentUrl != null && leave.documentUrl!.isNotEmpty) ||
                (leave.attachmentName != null && leave.attachmentName!.isNotEmpty)) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _showAttachmentViewer(
                  context,
                  leave.documentUrl ?? '',
                  leave.attachmentName,
                ),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, size: 13, color: Color(0xFF1D4ED8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          leave.attachmentName != null && leave.attachmentName!.isNotEmpty
                              ? 'Doc: ${leave.attachmentName}'
                              : 'Supporting Document Attached',
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
            const SizedBox(height: 12),
            TextField(
              controller: remarksController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: isApprove
                    ? 'Remarks (Optional)'
                    : 'Remarks / Reason (Optional)',
                hintText: isApprove
                    ? 'e.g. Approved, take care'
                    : 'e.g. Prior intimation required',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<LeavesBloc>().add(
                    UpdateStudentLeaveStatusEvent(
                      leaveId: leave.id,
                      status: isApprove ? 'APPROVED' : 'REJECTED',
                      remarks: remarksController.text.trim().isEmpty
                          ? null
                          : remarksController.text.trim(),
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove
                  ? const Color(0xFF15803D)
                  : const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            child: Text(isApprove ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentLeaveCard(StudentLeaveModel leave) {
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
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.studentName ?? 'Student',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Roll: ${leave.rollNumber ?? '—'}  |  Adm: ${leave.admissionNumber ?? '—'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
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
          const Divider(height: 16, color: AppColors.border),
          Row(
            children: [
              const Icon(Icons.date_range_outlined,
                  size: 14, color: AppColors.secondaryText),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  formatLeaveDateRange(leave.startDate, leave.endDate),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            leave.reason,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: AppColors.primaryText,
            ),
          ),
          if ((leave.documentUrl != null && leave.documentUrl!.isNotEmpty) ||
              (leave.attachmentName != null && leave.attachmentName!.isNotEmpty)) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _showAttachmentViewer(
                context,
                leave.documentUrl ?? '',
                leave.attachmentName,
              ),
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
                    const Icon(Icons.attach_file, size: 12, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        leave.attachmentName != null && leave.attachmentName!.isNotEmpty
                            ? 'Doc: ${leave.attachmentName}'
                            : 'Supporting Document Attached',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D4ED8),
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new, size: 11, color: Color(0xFF1D4ED8)),
                  ],
                ),
              ),
            ),
          ],
          if ((leave.remarks != null && leave.remarks!.trim().isNotEmpty) ||
              (leave.rejectionReason != null &&
                  leave.rejectionReason!.trim().isNotEmpty)) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Remarks: ${(leave.remarks?.trim().isNotEmpty == true ? leave.remarks : leave.rejectionReason)!.trim()}',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: leave.status == 'REJECTED'
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFF15803D),
                ),
              ),
            ),
          ],
          if (leave.status == 'PENDING') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () =>
                      _openReviewDialog(leave, isApprove: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                  child:
                      const Text('Reject', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      _openReviewDialog(leave, isApprove: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                  child:
                      const Text('Approve', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaveCard(StaffLeaveModel leave) {
    Color badgeColor;
    Color badgeBg;
    Color badgeBorder;

    switch (leave.status) {
      case 'APPROVED':
        badgeColor = const Color(0xFF15803D);
        badgeBg = const Color(0xFFF0FDF4);
        badgeBorder = const Color(0xFF86EFAC);
        break;
      case 'RECOMMENDED':
        badgeColor = const Color(0xFF1D4ED8);
        badgeBg = const Color(0xFFEFF6FF);
        badgeBorder = const Color(0xFF93C5FD);
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${leave.leaveType} LEAVE • ${formatLeaveDateRange(leave.startDate, leave.endDate)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: AppColors.primaryText,
            ),
          ),
          if ((leave.documentUrl != null && leave.documentUrl!.trim().isNotEmpty) ||
              (leave.attachmentName != null && leave.attachmentName!.trim().isNotEmpty)) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _showAttachmentViewer(
                context,
                leave.documentUrl ?? '',
                leave.attachmentName,
              ),
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
                    const Icon(Icons.attach_file, size: 12, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        leave.attachmentName != null && leave.attachmentName!.trim().isNotEmpty
                            ? 'Doc: ${leave.attachmentName!.trim()}'
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
                    const Icon(Icons.open_in_new, size: 11, color: Color(0xFF1D4ED8)),
                  ],
                ),
              ),
            ),
          ],
          if (leave.recommendationNote != null &&
              leave.recommendationNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.thumb_up_alt_outlined,
                      size: 14, color: Color(0xFF1D4ED8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      leave.recommendedByName != null && leave.recommendedByName!.trim().isNotEmpty
                          ? 'Coordinator Note: "${leave.recommendationNote!.trim()}" (${leave.recommendedByName!.trim()})'
                          : 'Coordinator Note: "${leave.recommendationNote!.trim()}"',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if ((leave.decisionNote != null && leave.decisionNote!.trim().isNotEmpty) ||
              (leave.rejectionReason != null && leave.rejectionReason!.trim().isNotEmpty)) ...[
            const SizedBox(height: 6),
            Text(
              'Remarks: ${(leave.decisionNote?.trim().isNotEmpty == true ? leave.decisionNote : leave.rejectionReason)!.trim()}',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: leave.status == 'REJECTED'
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFF15803D),
              ),
            ),
          ],
          if (leave.decidedByName != null &&
              leave.decidedByName!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Reviewed by ${leave.decidedByName!.trim()}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
