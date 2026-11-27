import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../models/student_roster_item.dart';

class StudentRosterView extends StatefulWidget {
  final List<StudentRosterItem> students;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Future<void> Function()? onRefresh;
  final String title;
  final bool canEdit;
  final bool isStudentClassmatesMode;
  final bool showClassSectionBadge;
  final bool showSubjectTags;
  final String? emptyMessage;
  final Function(StudentRosterItem)? onEditStudent;

  const StudentRosterView({
    super.key,
    required this.students,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onRefresh,
    this.title = 'Class Roster',
    this.canEdit = false,
    this.isStudentClassmatesMode = false,
    this.showClassSectionBadge = false,
    this.showSubjectTags = false,
    this.emptyMessage,
    this.onEditStudent,
  });

  @override
  State<StudentRosterView> createState() => _StudentRosterViewState();
}

class _StudentRosterViewState extends State<StudentRosterView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (widget.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 36, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                widget.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 16),
              if (widget.onRetry != null)
                OutlinedButton(
                  onPressed: widget.onRetry,
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

    final filtered = widget.students.where((s) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      if (widget.isStudentClassmatesMode) {
        return s.fullName.toLowerCase().contains(q) ||
            (s.rollNumber != null && s.rollNumber!.toLowerCase().contains(q));
      }
      return s.fullName.toLowerCase().contains(q) ||
          s.admissionNumber.toLowerCase().contains(q) ||
          (s.rollNumber != null && s.rollNumber!.toLowerCase().contains(q));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: widget.isStudentClassmatesMode
                  ? 'Search by classmate name or roll no...'
                  : 'Search by student name or roll no...',
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.secondaryText),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: AppColors.secondaryText),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            widget.isStudentClassmatesMode
                ? '${filtered.length} ${filtered.length == 1 ? 'classmate' : 'classmates'}'
                : '${filtered.length} students enrolled',
            style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _wrapWithRefresh(
            filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            _searchQuery.trim().isNotEmpty
                                ? 'No students found matching "${_searchQuery.trim()}".'
                                : (widget.emptyMessage ?? 'No students found matching your criteria.'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _buildStudentCard(filtered[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _wrapWithRefresh(Widget child) {
    if (widget.onRefresh == null) return child;
    return RefreshIndicator(onRefresh: widget.onRefresh!, child: child);
  }

  Widget _buildStudentCard(StudentRosterItem student) {
    final classSecLabel = widget.showClassSectionBadge ? student.classSectionLabel : null;
    final subjectTags = widget.showSubjectTags ? student.subjects : const <StudentSubjectTag>[];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          UserAvatar(
            name: student.fullName.isNotEmpty
                ? student.fullName
                : (widget.isStudentClassmatesMode ? 'Classmate' : 'Student'),
            avatarUrl: student.avatarUrl,
            radius: 18,
            fontSize: 13,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        student.fullName.isNotEmpty
                            ? student.fullName
                            : (widget.isStudentClassmatesMode ? 'Classmate' : 'Student'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                    if (widget.isStudentClassmatesMode)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          (student.rollNumber != null && student.rollNumber!.trim().isNotEmpty)
                              ? 'Roll No: ${student.rollNumber}'
                              : 'Roll No: -',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      )
                    else if (student.rollNumber != null && student.rollNumber!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Roll ${student.rollNumber}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                  ],
                ),
                if (widget.isStudentClassmatesMode) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.cake_outlined,
                        size: 14,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Birthday: ${student.formattedBirthday ?? 'Not available'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      ?classSecLabel,
                      if (student.admissionNumber.isNotEmpty) 'Adm: ${student.admissionNumber}',
                      if (student.gender.isNotEmpty) student.gender,
                    ].join(' • '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  if (subjectTags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: subjectTags.map((sub) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.indigo50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.indigo100),
                          ),
                          child: Text(
                            sub.code.isNotEmpty ? '${sub.name} (${sub.code})' : sub.name,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if ((student.bloodGroup != null && student.bloodGroup!.trim().isNotEmpty) ||
                      (student.emergencyPhone != null && student.emergencyPhone!.trim().isNotEmpty) ||
                      (student.medicalNotes != null && student.medicalNotes!.trim().isNotEmpty)) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (student.bloodGroup != null && student.bloodGroup!.trim().isNotEmpty)
                          Text(
                            'Blood: ${student.bloodGroup}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        if (student.emergencyPhone != null && student.emergencyPhone!.trim().isNotEmpty)
                          Text(
                            'Emergency: ${student.emergencyPhone}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        if (student.medicalNotes != null && student.medicalNotes!.trim().isNotEmpty)
                          Text(
                            'Medical: ${student.medicalNotes}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFFD97706),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (!widget.isStudentClassmatesMode && widget.canEdit && widget.onEditStudent != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryText),
              tooltip: 'Update Student Details',
              onPressed: () => widget.onEditStudent!(student),
            ),
        ],
      ),
    );
  }
}
