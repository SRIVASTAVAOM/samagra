import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.downloadUrl != null
                    ? '${state.message}: ${state.attachmentName ?? "File"}'
                    : state.message),
                backgroundColor: AppColors.primaryText,
              ),
            );
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          _filterChip('ALL', 'All (${allItems.length})'),
          const SizedBox(width: 8),
          _filterChip('PENDING', 'Pending ($pendingCount)'),
          const SizedBox(width: 8),
          _filterChip('COMPLETED', 'Completed ($completedCount)'),
        ],
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
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text(
                'Due: ${hw.dueDate}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.secondaryText),
              ),
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
                    context.read<HomeworkBloc>().add(
                          DownloadHomeworkAttachmentEvent(hw.id),
                        );
                  },
                  icon: const Icon(Icons.download_outlined, size: 16, color: AppColors.primaryAccent),
                  label: Text(
                    hw.attachmentName ?? 'Attachment',
                    style: const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
        ],
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
