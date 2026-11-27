import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../academics/bloc/academics_bloc.dart';
import '../../../academics/bloc/academics_event.dart';
import '../../../academics/bloc/academics_state.dart';
import '../../../academics/models/classmate_birthday_model.dart';

class StudentBirthdaysView extends StatefulWidget {
  final String title;
  final String emptyMessage;
  final bool autoLoad;

  const StudentBirthdaysView({
    super.key,
    this.title = "Today's Birthdays",
    this.emptyMessage = 'No classmates have a birthday today',
    this.autoLoad = true,
  });

  @override
  State<StudentBirthdaysView> createState() => _StudentBirthdaysViewState();
}

class _StudentBirthdaysViewState extends State<StudentBirthdaysView> {
  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      context.read<AcademicsBloc>().add(LoadClassmatesBirthdaysEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: AppColors.secondaryText),
                tooltip: 'Refresh',
                onPressed: () {
                  context.read<AcademicsBloc>().add(LoadClassmatesBirthdaysEvent());
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<AcademicsBloc, AcademicsState>(
            builder: (context, state) {
              if (state is AcademicsLoading) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }

              if (state is AcademicsError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 36, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            context
                                .read<AcademicsBloc>()
                                .add(LoadClassmatesBirthdaysEvent());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is ClassmatesBirthdaysLoaded) {
                final birthdays = state.birthdays;
                if (birthdays.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cake_outlined, size: 48, color: AppColors.secondaryText),
                          const SizedBox(height: 12),
                          Text(
                            widget.emptyMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: birthdays.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildBirthdayCard(birthdays[index]);
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBirthdayCard(ClassmateBirthdayModel b) {
    final displayName = b.fullName.isNotEmpty ? b.fullName : 'Student';
    final rollLabel = (b.rollNumber != null && b.rollNumber!.trim().isNotEmpty)
        ? b.rollNumber!
        : '-';
    final birthdayLabel =
        b.birthdayFormatted.trim().isNotEmpty ? b.birthdayFormatted.trim() : 'Today';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          UserAvatar(
            name: displayName,
            avatarUrl: b.avatarUrl,
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Roll No: $rollLabel',
                  style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cake_outlined, size: 13, color: AppColors.primaryAccent),
                const SizedBox(width: 4),
                Text(
                  birthdayLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
