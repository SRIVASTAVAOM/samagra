import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../bloc/exams_bloc.dart';
import '../models/exam_model.dart';

class TeacherMarksEntryView extends StatefulWidget {
  final String examId;
  final String datesheetId;
  final String? sectionId;

  const TeacherMarksEntryView({
    super.key,
    required this.examId,
    required this.datesheetId,
    this.sectionId,
  });

  @override
  State<TeacherMarksEntryView> createState() => _TeacherMarksEntryViewState();
}

class _TeacherMarksEntryViewState extends State<TeacherMarksEntryView> {
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};
  final Map<String, bool> _absentStatus = {};

  @override
  void initState() {
    super.initState();
    context.read<ExamsBloc>().add(
          LoadMarksRosterEvent(widget.examId, widget.datesheetId, sectionId: widget.sectionId),
        );
  }

  @override
  void dispose() {
    for (final c in _marksControllers.values) {
      c.dispose();
    }
    for (final c in _remarksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initStudentFields(List<StudentMarkRosterModel> roster) {
    for (final s in roster) {
      if (!_marksControllers.containsKey(s.studentId)) {
        _marksControllers[s.studentId] = TextEditingController(
          text: s.marksObtained != null ? s.marksObtained!.toStringAsFixed(1) : '',
        );
      }
      if (!_remarksControllers.containsKey(s.studentId)) {
        _remarksControllers[s.studentId] = TextEditingController(text: s.remarks ?? '');
      }
      if (!_absentStatus.containsKey(s.studentId)) {
        _absentStatus[s.studentId] = s.isAbsent;
      }
    }
  }

  void _submitMarks(ExamDatesheetModel datesheet, List<StudentMarkRosterModel> roster, bool submitForVerification) {
    if (datesheet.isLocked || datesheet.isPublished || roster.any((s) => s.status == 'VERIFIED')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marks are locked after verification or publication.')),
      );
      return;
    }
    final entries = <Map<String, dynamic>>[];

    for (final s in roster) {
      final isAbsent = _absentStatus[s.studentId] ?? false;
      final marksText = _marksControllers[s.studentId]?.text.trim() ?? '';
      final remarksText = _remarksControllers[s.studentId]?.text.trim();

      double? marks;
      if (!isAbsent) {
        if (marksText.isNotEmpty) {
          final parsed = double.tryParse(marksText);
          if (parsed == null || parsed < 0 || parsed > datesheet.maxMarks) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Invalid marks for ${s.fullName}. Must be between 0 and ${datesheet.maxMarks.toStringAsFixed(0)}.',
                ),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }
          marks = parsed;
        }
      }

      entries.add({
        'student_id': s.studentId,
        'marks_obtained': marks,
        'is_absent': isAbsent,
        'remarks': remarksText?.isNotEmpty == true ? remarksText : null,
      });
    }

    context.read<ExamsBloc>().add(
          SaveMarksEvent(
            widget.examId,
            widget.datesheetId,
            entries,
            submitForVerification: submitForVerification,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marks Entry'),
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryText,
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
          if (state is ExamsLoading && _marksControllers.isEmpty) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (state is MarksRosterLoaded) {
            final datesheet = state.datesheet;
            final roster = state.roster;
            _initStudentFields(roster);
            final isLocked = datesheet.isLocked ||
                datesheet.isPublished ||
                roster.any((s) => s.status == 'VERIFIED');

            return Column(
              children: [
                _buildHeader(datesheet, roster),
                if (isLocked) _buildLockedBanner(),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: roster.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final student = roster[index];
                      return _buildStudentMarkTile(student, datesheet, isLocked);
                    },
                  ),
                ),
                _buildBottomBar(datesheet, roster, isLocked),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader(ExamDatesheetModel datesheet, List<StudentMarkRosterModel> roster) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                datesheet.subjectName ?? 'Subject',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.indigo50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.indigo100),
                ),
                child: Text(
                  'Max: ${datesheet.maxMarks.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.primaryAccent, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${datesheet.className ?? "Class"} • Date: ${datesheet.examDate} • ${roster.length} Students',
            style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        children: const [
          Icon(Icons.lock_outline, size: 18, color: AppColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Locked (Verified/Published): Marks cannot be edited after coordinator verification or result publication.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentMarkTile(
    StudentMarkRosterModel student,
    ExamDatesheetModel datesheet,
    bool isLocked,
  ) {
    final isAbsent = _absentStatus[student.studentId] ?? false;
    final marksCtrl = _marksControllers[student.studentId];
    final remarksCtrl = _remarksControllers[student.studentId];

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.indigo50,
                child: Text(
                  student.rollNumber,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryAccent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryText),
                    ),
                    Text(
                      'Adm: ${student.admissionNumber}',
                      style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: isAbsent,
                    activeColor: AppColors.primaryAccent,
                    onChanged: isLocked
                        ? null
                        : (val) {
                            setState(() {
                              _absentStatus[student.studentId] = val ?? false;
                              if (val == true) {
                                marksCtrl?.clear();
                              }
                            });
                          },
                  ),
                  Text('Absent', style: TextStyle(fontSize: 12, color: isLocked ? AppColors.tertiaryText : AppColors.secondaryText)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: marksCtrl,
                  enabled: !isLocked && !isAbsent,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Marks (out of ${datesheet.maxMarks.toStringAsFixed(0)})',
                    labelStyle: const TextStyle(fontSize: 12),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: isAbsent || isLocked,
                    fillColor: (isAbsent || isLocked) ? AppColors.scaffoldBackground : AppColors.surface,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: remarksCtrl,
                  enabled: !isLocked,
                  decoration: InputDecoration(
                    labelText: 'Remarks (optional)',
                    labelStyle: const TextStyle(fontSize: 12),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ExamDatesheetModel datesheet, List<StudentMarkRosterModel> roster, bool isLocked) {
    if (isLocked) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Marks Verification Completed',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondaryText),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _submitMarks(datesheet, roster, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryAccent,
                  side: const BorderSide(color: AppColors.indigo200),
                  backgroundColor: AppColors.indigo50,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save Draft'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _submitMarks(datesheet, roster, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Submit & Verify'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
