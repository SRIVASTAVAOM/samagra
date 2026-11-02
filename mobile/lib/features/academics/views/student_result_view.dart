import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/exams_bloc.dart';
import '../models/exam_model.dart';

class StudentResultView extends StatefulWidget {
  final String examId;
  final String examName;

  const StudentResultView({
    super.key,
    required this.examId,
    required this.examName,
  });

  @override
  State<StudentResultView> createState() => _StudentResultViewState();
}

class _StudentResultViewState extends State<StudentResultView> {
  @override
  void initState() {
    super.initState();
    context.read<ExamsBloc>().add(LoadStudentResultEvent(widget.examId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.examName} Result'),
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryText,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryAccent),
            onPressed: () {
              context.read<ExamsBloc>().add(LoadStudentResultEvent(widget.examId));
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
          if (state is ExamsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is ExamsLoading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (state is StudentResultLoaded) {
            final res = state.result;
            return _buildResultContent(context, res);
          }

          if (state is ExamsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 48, color: AppColors.tertiaryText),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildResultContent(BuildContext context, StudentExamResultModel result) {
    final card = result.reportCard;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall Aggregate Summary Card
        Container(
          padding: const EdgeInsets.all(20),
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.studentName ?? 'Student Result',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryText),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Roll No: ${card.rollNumber ?? "-"} • ${card.className ?? ""} ${card.sectionName ?? ""}',
                          style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.successBorder),
                    ),
                    child: const Text(
                      'APPROVED',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.borderLight, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric('Total Marks', '${card.totalMarksObtained.toStringAsFixed(1)} / ${card.totalMaxMarks.toStringAsFixed(0)}'),
                  _buildMetric('Percentage', '${card.percentage.toStringAsFixed(1)}%'),
                ],
              ),
              if (card.classTeacherRemarks != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.indigo50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.indigo100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Teacher Remarks:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.classTeacherRemarks!,
                        style: const TextStyle(fontSize: 13, color: AppColors.secondaryText, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section Title
        const Text(
          'Subject-wise Breakdown',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText),
        ),
        const SizedBox(height: 10),

        // Subject marks list
        ...result.subjectMarks.map((s) => _buildSubjectTile(s)),
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText),
        ),
      ],
    );
  }

  Widget _buildSubjectTile(SubjectMarkItemModel sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.subjectName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.primaryText),
                ),
                const SizedBox(height: 2),
                Text(
                  'Code: ${sub.subjectCode} • Max: ${sub.maxMarks.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                ),
                if (sub.remarks != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    sub.remarks!,
                    style: const TextStyle(fontSize: 12, color: AppColors.secondaryText, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          if (sub.isAbsent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.errorBorder),
              ),
              child: const Text(
                'ABSENT',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error),
              ),
            )
          else if (sub.marksObtained != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${sub.marksObtained!.toStringAsFixed(1)} / ${sub.maxMarks.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                ),
                Text(
                  sub.marksObtained! >= sub.passingMarks ? 'Pass' : 'Needs Improvement',
                  style: TextStyle(
                    fontSize: 11,
                    color: sub.marksObtained! >= sub.passingMarks ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            const Text(
              'Pending',
              style: TextStyle(fontSize: 13, color: AppColors.tertiaryText, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }
}
