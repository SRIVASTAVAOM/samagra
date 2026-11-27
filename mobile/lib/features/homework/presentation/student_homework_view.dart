import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/document_picker_bottom_sheet.dart';
import '../bloc/homework_bloc.dart';
import '../models/homework_model.dart';
import '../repository/homework_repository.dart';

/// Premium Student Homework & Assignments View
/// Features:
/// - Homework filters with counts (All, Pending, Completed)
/// - Subject and status badges
/// - Student submission dialog (notes + camera/gallery/PDF attachment) & completion toggle
/// - In-app image preview + external browser/app launcher for teacher & student attachments
/// - Consistent SAMAGRA theme design
class StudentHomeworkView extends StatefulWidget {
  final bool showAppBar;

  const StudentHomeworkView({super.key, this.showAppBar = false});

  @override
  State<StudentHomeworkView> createState() => _StudentHomeworkViewState();
}

class _StudentHomeworkViewState extends State<StudentHomeworkView> {
  String _selectedFilter = 'ALL'; // 'ALL', 'PENDING', 'COMPLETED'
  List<HomeworkModel> _cachedItems = [];

  @override
  void initState() {
    super.initState();
    final bloc = context.read<HomeworkBloc>();
    if (bloc.state is StudentHomeworkLoaded) {
      _cachedItems = (bloc.state as StudentHomeworkLoaded).homeworkList;
    } else if (bloc.cachedStudentHomework.isNotEmpty) {
      _cachedItems = bloc.cachedStudentHomework;
    }
    bloc.add(const LoadStudentHomeworkEvent());
  }

  @override
  Widget build(BuildContext context) {
    final body = Material(
      color: const Color(0xFFF4F8FF), // Very light blue background
      child: BlocConsumer<HomeworkBloc, HomeworkState>(
        listener: (context, state) {
          if (state is StudentHomeworkLoaded) {
            setState(() {
              _cachedItems = state.homeworkList;
            });
          } else if (state is HomeworkOperationSuccess) {
            if (state.downloadUrl != null && state.downloadUrl!.isNotEmpty) {
              _showAttachmentViewer(
                  context, state.downloadUrl!, state.attachmentName);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.primaryAccent,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          } else if (state is HomeworkError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is StudentHomeworkLoaded) {
            _cachedItems = state.homeworkList;
            return _buildHomeworkContent(state.homeworkList);
          }

          if (state is HomeworkLoading) {
            if (_cachedItems.isNotEmpty) {
              return _buildHomeworkContent(_cachedItems);
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading homework...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Preserve visible list during HomeworkOperationSuccess or transient HomeworkError
          if (_cachedItems.isNotEmpty) {
            return _buildHomeworkContent(_cachedItems);
          }

          if (state is HomeworkError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to Load Homework',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context
                          .read<HomeworkBloc>()
                          .add(const LoadStudentHomeworkEvent()),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: ElevatedButton(
              onPressed: () => context
                  .read<HomeworkBloc>()
                  .add(const LoadStudentHomeworkEvent()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Load Homework'),
            ),
          );
        },
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Homework & Assignments'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primaryText,
          elevation: 0,
        ),
        body: body,
      );
    }

    return body;
  }

  Widget _buildHomeworkContent(List<HomeworkModel> allItems) {
    final filtered = _filterHomework(allItems);

    return Column(
      children: [
        // Section Heading
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Homework & Assignments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                color: AppColors.secondaryText,
                tooltip: 'Refresh Homework',
                onPressed: () => context
                    .read<HomeworkBloc>()
                    .add(const LoadStudentHomeworkEvent()),
              ),
            ],
          ),
        ),

        // Filter Chips
        _buildFilterBar(allItems),

        // Homework List with Pull-to-Refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context
                  .read<HomeworkBloc>()
                  .add(const LoadStudentHomeworkEvent());
            },
            child: filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [_buildEmptyState()],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildHomeworkCard(filtered[index]),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  List<HomeworkModel> _filterHomework(List<HomeworkModel> allItems) {
    return allItems.where((hw) {
      if (_selectedFilter == 'PENDING') return hw.studentStatus != 'COMPLETED';
      if (_selectedFilter == 'COMPLETED') return hw.studentStatus == 'COMPLETED';
      return true;
    }).toList();
  }

  Widget _buildFilterBar(List<HomeworkModel> allItems) {
    final pendingCount = allItems.where((h) => h.studentStatus != 'COMPLETED').length;
    final completedCount = allItems.where((h) => h.studentStatus == 'COMPLETED').length;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip('ALL', 'All (${allItems.length})'),
            const SizedBox(width: 10),
            _buildFilterChip('PENDING', 'Pending ($pendingCount)'),
            const SizedBox(width: 10),
            _buildFilterChip('COMPLETED', 'Completed ($completedCount)'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryAccent
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryAccent
                : const Color(0xFFE3ECF8),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.primaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48,
              color: AppColors.secondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              'No Homework',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No assignments found for this filter',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkCard(HomeworkModel homework) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3ECF8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Subject Badge & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSubjectBadge(homework.subjectName),
              _buildStatusBadge(homework.studentStatus),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            homework.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            homework.description,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Due Date & Teacher Info Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCFBF00)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDueDate(homework.dueDate),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (homework.teacherName != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      homework.teacherName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons
          if (homework.studentStatus != 'COMPLETED')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openSubmitHomeworkDialog(context, homework),
                    icon: const Icon(Icons.upload_file_outlined, size: 17),
                    label: const Text(
                      'Submit Work',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<HomeworkBloc>().add(
                          ToggleHomeworkCompletionEvent(
                              homework.id, homework.studentStatus),
                        );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 17),
                  label: const Text(
                    'Mark Done',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF16A765),
                    side: const BorderSide(
                      color: Color(0xFF16A765),
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                  ),
                ),
              ],
            )
          else ...[
            if (homework.hasSubmission) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (homework.submissionText != null &&
                        homework.submissionText!.trim().isNotEmpty)
                      Text(
                        homework.submissionText!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryText,
                        ),
                      ),
                    if (homework.hasSubmissionAttachment) ...[
                      if (homework.submissionText != null &&
                          homework.submissionText!.trim().isNotEmpty)
                        const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _openAttachment(
                          homework,
                          isSubmission: true,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.insert_drive_file_outlined,
                                size: 15, color: Color(0xFF15803D)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                homework.submissionAttachmentName ??
                                    'Submitted attachment',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF15803D),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showStudentSubmissionDialog(homework),
                    icon: const Icon(Icons.visibility_outlined, size: 17),
                    label: const Text(
                      'View Submission',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16A765),
                      side: const BorderSide(
                        color: Color(0xFF16A765),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    context.read<HomeworkBloc>().add(
                          ToggleHomeworkCompletionEvent(
                              homework.id, homework.studentStatus),
                        );
                  },
                  child: const Text(
                    'Reopen',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Teacher Attachment Section (whole row tappable)
          if (homework.hasAttachment) ...[
            const SizedBox(height: 14),
            Material(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => _openAttachment(homework, isSubmission: false),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE3ECF8)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attachment,
                        size: 18,
                        color: AppColors.primaryAccent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          homework.attachmentName ?? 'Assignment attachment',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryAccent,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 18,
                        color: AppColors.primaryAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectBadge(String? subjectName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Text(
        subjectName ?? 'Subject',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0284C7),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    if (status == 'COMPLETED') {
      bgColor = const Color(0xFFEAF9F0);
      textColor = const Color(0xFF16A765);
      borderColor = const Color(0xFFA7F3D0);
    } else {
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFF59E0B);
      borderColor = const Color(0xFFFDE68A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _formatDueDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final dueDate = DateTime(date.year, date.month, date.day);

      if (dueDate.isBefore(today)) {
        return 'OVERDUE';
      } else if (dueDate == today) {
        return 'DUE TODAY';
      } else if (dueDate == tomorrow) {
        return 'DUE TOMORROW';
      } else {
        return 'Due ${date.day} ${_getMonthName(date.month)}';
      }
    } catch (_) {
      return dateStr;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  void _openAttachment(HomeworkModel homework, {required bool isSubmission}) {
    final directUrl = isSubmission
        ? homework.submissionAttachmentKey
        : homework.s3AttachmentKey;
    final name = isSubmission
        ? homework.submissionAttachmentName
        : homework.attachmentName;

    if (directUrl != null &&
        (directUrl.startsWith('http://') || directUrl.startsWith('https://'))) {
      _showAttachmentViewer(context, directUrl, name);
      return;
    }

    context.read<HomeworkBloc>().add(
          DownloadHomeworkAttachmentEvent(
            homework.id,
            isSubmission: isSubmission,
          ),
        );
  }

  Future<void> _launchExternalAttachment(
      BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attachment link copied to clipboard.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showAttachmentViewer(
      BuildContext context, String downloadUrl, String? attachmentName) {
    final lower = (attachmentName ?? downloadUrl).toLowerCase();
    final isPdf = lower.contains('.pdf');

    if (isPdf) {
      _launchExternalAttachment(context, downloadUrl);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        attachmentName ?? 'Attachment Preview',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, size: 19),
                      tooltip: 'Open externally',
                      onPressed: () =>
                          _launchExternalAttachment(context, downloadUrl),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      downloadUrl,
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
                              const Icon(Icons.broken_image_outlined,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text('Unable to preview image in-app'),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _launchExternalAttachment(
                                    context, downloadUrl),
                                icon: const Icon(Icons.open_in_browser, size: 16),
                                label: const Text('Open in Browser'),
                              ),
                            ],
                          ),
                        );
                      },
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

  void _showStudentSubmissionDialog(HomeworkModel homework) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          homework.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status: COMPLETED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16A765),
              ),
            ),
            if (homework.submittedAt != null &&
                homework.submittedAt!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Submitted: ${homework.submittedAt!.split('T')[0]}',
                style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
              ),
            ],
            const SizedBox(height: 12),
            if (homework.submissionText != null &&
                homework.submissionText!.trim().isNotEmpty) ...[
              const Text(
                'Your Note / Answer:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                homework.submissionText!.trim(),
                style: TextStyle(fontSize: 13, color: AppColors.primaryText),
              ),
              const SizedBox(height: 12),
            ] else if (!homework.hasSubmissionAttachment)
              Text(
                'Marked as completed without notes or attachment.',
                style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
            if (homework.hasSubmissionAttachment)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openAttachment(homework, isSubmission: true);
                },
                icon: const Icon(Icons.attachment, size: 16),
                label: Text(
                  homework.submissionAttachmentName ?? 'Open Attached Work',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openSubmitHomeworkDialog(context, homework);
            },
            child: const Text('Update Submission'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openSubmitHomeworkDialog(BuildContext context, HomeworkModel homework) {
    final notesCtrl =
        TextEditingController(text: homework.submissionText ?? '');
    String? attachedKey = homework.submissionAttachmentKey;
    String? attachedName = homework.submissionAttachmentName;
    final homeworkBloc = context.read<HomeworkBloc>();
    HomeworkRepository? homeworkRepo;
    try {
      homeworkRepo = context.read<HomeworkRepository>();
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Submit: ${homework.title}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Answer / Submission Notes',
                      hintText:
                          'Write your answer, summary, or note for your teacher...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (attachedName == null)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final doc = await DocumentPickerBottomSheet.show(
                          sheetCtx,
                          title: 'Attach Completed Work',
                          subtitle:
                              'Upload photo of notebook/worksheet or PDF (Max 5 MB)',
                          categoryPrefix: 'hw_submission',
                          onUpload: homeworkRepo == null
                              ? null
                              : (bytes, fileName) async {
                                  final res = await homeworkRepo!
                                      .uploadAttachment(bytes, fileName);
                                  return res['fileKey'] as String? ??
                                      res['attachmentUrl'] as String;
                                },
                        );
                        if (doc != null && sheetCtx.mounted) {
                          setSheetState(() {
                            attachedName = doc.name;
                            attachedKey = doc.url;
                          });
                        }
                      },
                      icon: const Icon(Icons.add_photo_alternate_outlined,
                          size: 18),
                      label: const Text('+ Attach Photo / PDF (Optional)'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 18, color: Color(0xFF16A765)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              attachedName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setSheetState(() {
                                attachedName = null;
                                attachedKey = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      final note = notesCtrl.text.trim();
                      if (note.isEmpty &&
                          (attachedKey == null || attachedKey!.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please enter submission notes or attach a photo/PDF.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(sheetCtx);
                      homeworkBloc.add(
                        SubmitHomeworkEvent(
                          homeworkId: homework.id,
                          submissionText: note.isEmpty ? null : note,
                          submissionAttachmentKey: attachedKey,
                          submissionAttachmentName: attachedName,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Submit & Mark Completed',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
