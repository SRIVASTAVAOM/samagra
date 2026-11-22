import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/homework_bloc.dart';
import '../models/homework_model.dart';

class StudentHomeworkView extends StatefulWidget {
  const StudentHomeworkView({super.key});

  @override
  State<StudentHomeworkView> createState() => _StudentHomeworkViewState();
}

class _StudentHomeworkViewState extends State<StudentHomeworkView> {
  String _selectedFilter = 'ALL'; // 'ALL', 'PENDING', 'COMPLETED'

  @override
  void initState() {
    super.initState();
    context.read<HomeworkBloc>().add(const LoadStudentHomeworkEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Homework & Assignments'),
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryText,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.border, height: 1.0),
        ),
      ),
      backgroundColor: AppColors.scaffoldBackground,
      body: BlocConsumer<HomeworkBloc, HomeworkState>(
        listener: (context, state) {
          if (state is HomeworkOperationSuccess) {
            if (state.downloadUrl != null && state.downloadUrl!.isNotEmpty) {
              _showAttachmentViewer(context, state.downloadUrl!, state.attachmentName);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.primaryText,
                ),
              );
            }
          } else if (state is HomeworkError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is HomeworkLoading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (state is StudentHomeworkLoaded) {
            final allItems = state.homeworkList;
            final filtered = allItems.where((hw) {
              if (_selectedFilter == 'PENDING') return hw.studentStatus != 'COMPLETED';
              if (_selectedFilter == 'COMPLETED') return hw.studentStatus == 'COMPLETED';
              if (_selectedFilter == 'URGENT') {
                return hw.studentStatus != 'COMPLETED' && (hw.isDueToday || hw.isOverdue || hw.isDueTomorrow);
              }
              return true;
            }).toList();

            return Column(
              children: [
                _buildFilterChips(allItems),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildHomeworkCard(filtered[index]);
                          },
                        ),
                ),
              ],
            );
          }

          return Center(
            child: ElevatedButton(
              onPressed: () => context.read<HomeworkBloc>().add(const LoadStudentHomeworkEvent()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.surface,
              ),
              child: const Text('Load Homework'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(List<HomeworkModel> allItems) {
    final pendingCount = allItems.where((h) => h.studentStatus != 'COMPLETED').length;
    final completedCount = allItems.where((h) => h.studentStatus == 'COMPLETED').length;
    final urgentCount = allItems.where((h) => h.studentStatus != 'COMPLETED' && (h.isDueToday || h.isOverdue || h.isDueTomorrow)).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('ALL', 'All (${allItems.length})'),
            const SizedBox(width: 8),
            _filterChip('PENDING', 'Pending ($pendingCount)'),
            const SizedBox(width: 8),
            _filterChip('URGENT', 'Due Soon / Overdue ($urgentCount)'),
            const SizedBox(width: 8),
            _filterChip('COMPLETED', 'Completed ($completedCount)'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterKey),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAccent : AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primaryAccent : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.surface : AppColors.primaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeworkCard(HomeworkModel hw) {
    final isDone = hw.studentStatus == 'COMPLETED';

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.indigo50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.indigo100),
                ),
                child: Text(
                  hw.subjectName ?? 'Subject',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryAccent),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDone ? AppColors.successLight : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDone ? AppColors.successBorder : AppColors.warningBorder),
                ),
                child: Text(
                  isDone ? 'Completed' : 'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDone ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hw.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText),
          ),
          const SizedBox(height: 6),
          Text(
            hw.description,
            style: const TextStyle(fontSize: 14, color: AppColors.secondaryText, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (hw.isOverdue) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 13, color: Color(0xFFB91C1C)),
                      const SizedBox(width: 4),
                      Text(
                        'OVERDUE: ${hw.dueDate}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                      ),
                    ],
                  ),
                ),
              ] else if (hw.isDueToday) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_filled, size: 13, color: Color(0xFFB45309)),
                      SizedBox(width: 4),
                      Text(
                        'DUE TODAY',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
              ] else if (hw.isDueTomorrow) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDE047)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 13, color: Color(0xFF854D0E)),
                      SizedBox(width: 4),
                      Text(
                        'DUE TOMORROW',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF854D0E)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.secondaryText),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${hw.dueDate}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ],
              if (hw.teacherName != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.person_outline, size: 14, color: AppColors.secondaryText),
                const SizedBox(width: 4),
                Text(
                  hw.teacherName!,
                  style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                key: Key('toggle_completion_${hw.id}'),
                onPressed: () {
                  context.read<HomeworkBloc>().add(
                        ToggleHomeworkCompletionEvent(hw.id, hw.studentStatus),
                      );
                },
                icon: Icon(
                  isDone ? Icons.undo_outlined : Icons.check_circle_outline,
                  size: 16,
                  color: isDone ? AppColors.primaryText : AppColors.success,
                ),
                label: Text(
                  isDone ? 'Mark as Pending' : 'Mark Completed',
                  style: TextStyle(
                    color: isDone ? AppColors.primaryText : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (hw.hasAttachment) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  key: Key('download_attachment_${hw.id}'),
                  onPressed: () {
                    final key = hw.s3AttachmentKey;
                    if (key != null && key.startsWith('http')) {
                      _showAttachmentViewer(context, key, hw.attachmentName);
                    } else {
                      context.read<HomeworkBloc>().add(
                            DownloadHomeworkAttachmentEvent(hw.id),
                          );
                    }
                  },
                  icon: const Icon(Icons.download_outlined, size: 16, color: AppColors.primaryAccent),
                  label: Text(
                    hw.attachmentName ?? 'View Attachment',
                    style: const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
          if (hw.hasAttachment) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                final key = hw.s3AttachmentKey;
                if (key != null && key.startsWith('http')) {
                  _showAttachmentViewer(context, key, hw.attachmentName);
                } else {
                  context.read<HomeworkBloc>().add(
                        DownloadHomeworkAttachmentEvent(hw.id),
                      );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      (hw.attachmentName ?? '').toLowerCase().endsWith('.pdf')
                          ? Icons.picture_as_pdf
                          : Icons.image_outlined,
                      size: 20,
                      color: (hw.attachmentName ?? '').toLowerCase().endsWith('.pdf')
                          ? const Color(0xFFB91C1C)
                          : AppColors.primaryAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hw.attachmentName ?? 'Attached Homework Photo / Document',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.open_in_new, size: 14, color: AppColors.primaryAccent),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAttachmentViewer(BuildContext context, String url, String? name) {
    final isPdf = (name ?? url).toLowerCase().endsWith('.pdf');

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
                        name ?? (isPdf ? 'PDF Document' : 'Homework Photo'),
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
                  padding: const EdgeInsets.all(12),
                  child: isPdf
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.picture_as_pdf, size: 48, color: Color(0xFFB91C1C)),
                              const SizedBox(height: 12),
                              Text(
                                name ?? 'Homework PDF',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  try {
                                    Clipboard.setData(ClipboardData(text: url));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Document link copied to clipboard: $url'),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Unable to open document: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.open_in_browser, size: 16),
                                label: const Text('Open / Copy PDF Link'),
                              ),
                            ],
                          ),
                        )
                      : InteractiveViewer(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppColors.tertiaryText),
          const SizedBox(height: 12),
          const Text(
            'No homework assignments found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}
