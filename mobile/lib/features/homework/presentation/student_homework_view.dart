import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/homework_bloc.dart';
import '../models/homework_model.dart';

/// Premium Student Homework & Assignments View
/// Features:
/// - Homework filters with counts
/// - Subject and status badges
/// - Due date and teacher information
/// - Mark completed and attachment actions
/// - Consistent SAMAGRA theme design
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
    return Container(
      color: const Color(0xFFF4F8FF), // Very light blue background
      child: BlocConsumer<HomeworkBloc, HomeworkState>(
        listener: (context, state) {
          if (state is HomeworkOperationSuccess) {
            if (state.downloadUrl != null && state.downloadUrl!.isNotEmpty) {
              _showAttachmentViewer(context, state.downloadUrl!, state.attachmentName);
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
          if (state is HomeworkLoading) {
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

          if (state is StudentHomeworkLoaded) {
            final allItems = state.homeworkList;
            final filtered = _filterHomework(allItems);

            return Column(
              children: [
                // Section Heading
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'My Homework & Assignments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ),

                // Filter Chips
                _buildFilterBar(allItems),

                // Homework List
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
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
              ],
            );
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

          // Action Button
          if (homework.studentStatus != 'COMPLETED')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  context.read<HomeworkBloc>().add(
                        ToggleHomeworkCompletionEvent(
                            homework.id, homework.studentStatus),
                      );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFF16A765),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Mark Completed',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFF16A765),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.visibility_outlined, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'View Submission',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Attachment Section
          if (homework.hasAttachment) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
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
                        color: AppColors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      context.read<HomeworkBloc>().add(
                            DownloadHomeworkAttachmentEvent(homework.id),
                          );
                    },
                    child: Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ],
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

  void _showAttachmentViewer(
      BuildContext context, String downloadUrl, String? attachmentName) {
    // This is a placeholder - actual implementation would handle PDF/document viewing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening: ${attachmentName ?? "attachment"}'),
        backgroundColor: AppColors.primaryAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Extension on HomeworkBloc events
extension HomeworkBlocExt on HomeworkBloc {
  // These events should already exist in HomeworkBloc, but are referenced in this view
  // ToggleCompletionEvent, DownloadAttachmentEvent
}
