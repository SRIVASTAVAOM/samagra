import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/exams_bloc.dart';
import '../models/exam_model.dart';

class CoordinatorMarksReviewView extends StatefulWidget {
  final String examId;
  final String datesheetId;

  const CoordinatorMarksReviewView({
    super.key,
    required this.examId,
    required this.datesheetId,
  });

  @override
  State<CoordinatorMarksReviewView> createState() => _CoordinatorMarksReviewViewState();
}

class _CoordinatorMarksReviewViewState extends State<CoordinatorMarksReviewView> {
  @override
  void initState() {
    super.initState();
    context.read<ExamsBloc>().add(
          LoadDatesheetSummaryEvent(widget.examId, widget.datesheetId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marks Verification & Review'),
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryText,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryAccent),
            onPressed: () {
              context.read<ExamsBloc>().add(
                    LoadDatesheetSummaryEvent(widget.examId, widget.datesheetId),
                  );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.border, height: 1.0),
        ),
      ),
      backgroundColor: AppColors.scaffoldBackground,
      body: BlocConsumer<ExamsBloc, ExamsState>(
        listener: (context, state) {
          if (state is ExamOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.primaryText),
            );
          } else if (state is ExamsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is ExamsLoading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (state is DatesheetSummaryLoaded) {
            final summary = state.summary;
            return _buildContent(context, summary);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, DatesheetSummaryModel summary) {
    final isVerified = summary.status == 'VERIFIED';
    final hasMissing = summary.missingCount > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        summary.subjectName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryText),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isVerified ? AppColors.successLight : AppColors.warningLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isVerified ? AppColors.successBorder : AppColors.warningBorder),
                      ),
                      child: Text(
                        summary.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isVerified ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.borderLight, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCol('Max Marks', summary.maxMarks.toStringAsFixed(0)),
                    _buildStatCol('Total Students', '${summary.totalStudents}'),
                    _buildStatCol('Entered', '${summary.enteredCount}'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCol('Absent', '${summary.absentCount}', color: AppColors.warning),
                    _buildStatCol('Missing', '${summary.missingCount}', color: hasMissing ? AppColors.error : AppColors.success),
                    _buildStatCol('Average', summary.averageMarks != null ? '${summary.averageMarks!.toStringAsFixed(1)}%' : '-'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Analysis Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Analytics',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryText),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticTile(
                        'Highest Marks',
                        summary.highestMarks != null ? '${summary.highestMarks!.toStringAsFixed(1)}' : '-',
                        Icons.trending_up,
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticTile(
                        'Lowest Marks',
                        summary.lowestMarks != null ? '${summary.lowestMarks!.toStringAsFixed(1)}' : '-',
                        Icons.trending_down,
                        AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Verify Button Action
          if (!isVerified)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasMissing
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot verify marks while some students have missing entries.'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      }
                    : () {
                        context.read<ExamsBloc>().add(
                              VerifyMarksEvent(widget.examId, widget.datesheetId),
                            );
                      },
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: const Text('Verify Marks & Lock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasMissing ? AppColors.slate400 : AppColors.primaryAccent,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.successBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Marks Verified and Locked by Coordinator',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value, {Color color = AppColors.primaryText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildAnalyticTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
            ],
          ),
        ],
      ),
    );
  }
}
