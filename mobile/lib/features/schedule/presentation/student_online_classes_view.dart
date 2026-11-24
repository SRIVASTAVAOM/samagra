import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/schedule_bloc.dart';
import '../models/online_class_model.dart';

class StudentOnlineClassesView extends StatefulWidget {
  const StudentOnlineClassesView({super.key});

  @override
  State<StudentOnlineClassesView> createState() => _StudentOnlineClassesViewState();
}

class _StudentOnlineClassesViewState extends State<StudentOnlineClassesView> {
  @override
  void initState() {
    super.initState();
    context.read<ScheduleBloc>().add(const LoadOnlineClassesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: BlocBuilder<ScheduleBloc, ScheduleState>(
        builder: (context, state) {
          if (state is ScheduleLoadingState) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (state is ScheduleErrorState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => context
                          .read<ScheduleBloc>()
                          .add(const LoadOnlineClassesEvent()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final sessions = state is ScheduleLoadedState
              ? state.onlineClasses
              : <OnlineClassModel>[];

          if (sessions.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ScheduleBloc>().add(const LoadOnlineClassesEvent());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.video_camera_front_outlined, size: 48, color: AppColors.tertiaryText),
                        SizedBox(height: 12),
                        Text(
                          'No online classes currently scheduled',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'When your teachers schedule live classes, they will appear here',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.tertiaryText,
                          ),
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
              context.read<ScheduleBloc>().add(const LoadOnlineClassesEvent());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _buildStudentSessionCard(context, session);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentSessionCard(BuildContext context, OnlineClassModel session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & Time
            Row(
              children: [
                const Icon(Icons.event, size: 14, color: AppColors.secondaryText),
                const SizedBox(width: 4),
                Text(
                  session.scheduledDate,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const Text(' • ', style: TextStyle(color: AppColors.secondaryText)),
                const Icon(Icons.access_time, size: 14, color: AppColors.secondaryText),
                const SizedBox(width: 4),
                Text(
                  '${session.startTime} (${session.durationMinutes}m)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              session.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 6),

            // Subject badge & Teacher name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    session.subjectName ?? 'Subject',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.secondaryText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          session.teacherName ?? 'Teacher',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Join Class Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _joinMeeting(context, session),
                icon: const Icon(Icons.videocam, size: 16),
                label: const Text('Join Live Class'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _joinMeeting(BuildContext context, OnlineClassModel session) {
    final url = session.meetingUrl.trim();
    if (url.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Meeting Link Pending', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Text(
            'The meeting link has not been provided yet by ${session.teacherName ?? "the teacher"}. Please check back closer to class time (${session.startTime}).',
            style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: url));
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.video_call, color: AppColors.info),
              SizedBox(width: 8),
              Text('Join Online Class', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${session.subjectName ?? "Class"}: ${session.title}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryText),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Meeting link copied to clipboard!',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Paste into your browser or meeting app (Google Meet, Zoom, MS Teams) to join:',
                style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        url,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: AppColors.primaryAccent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Copy Link',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: url));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Meeting link copied to clipboard'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primaryText,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Meeting link copied to clipboard'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.primaryText,
                  ),
                );
              },
              child: const Text('Copy Again'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.surface,
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }
}
