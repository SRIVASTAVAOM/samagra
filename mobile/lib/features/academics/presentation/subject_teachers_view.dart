import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../models/subject_teacher_item.dart';

class SubjectTeachersView extends StatelessWidget {
  final List<SubjectTeacherItem> teachers;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const SubjectTeachersView({
    super.key,
    required this.teachers,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 36, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 16),
              if (onRetry != null)
                OutlinedButton(
                  onPressed: onRetry,
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

    if (teachers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'No subject teacher allocations recorded for your class.',
            style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: teachers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = teachers[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                name: (item.teacherName != null && item.teacherName!.trim().isNotEmpty)
                    ? item.teacherName!
                    : item.subjectName,
                avatarUrl: item.avatarUrl,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBackground,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            item.subjectCode,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.subjectName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                        if (item.isClassTeacher)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CLASS TEACHER',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.teacherName != null && item.teacherName!.trim().isNotEmpty
                          ? 'Teacher: ${item.teacherName}'
                          : 'Teacher: Not Assigned Yet',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    if (item.qualification != null &&
                        item.qualification!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.qualification!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                    if (item.teacherPhone != null &&
                        item.teacherPhone!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Contact: ${item.teacherPhone}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
