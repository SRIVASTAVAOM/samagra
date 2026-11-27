import 'package:equatable/equatable.dart';

class SubjectTeacherItem extends Equatable {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String? subjectType;
  final String? teacherName;
  final String? teacherPhone;
  final String? employeeCode;
  final String? qualification;
  final String? avatarUrl;
  final bool isClassTeacher;

  const SubjectTeacherItem({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    this.subjectType,
    this.teacherName,
    this.teacherPhone,
    this.employeeCode,
    this.qualification,
    this.avatarUrl,
    this.isClassTeacher = false,
  });

  factory SubjectTeacherItem.fromJson(Map<String, dynamic> json) {
    return SubjectTeacherItem(
      subjectId: json['subject_id']?.toString() ?? '',
      subjectName: json['subject_name']?.toString() ?? '',
      subjectCode: json['subject_code']?.toString() ?? '',
      subjectType: json['subject_type']?.toString(),
      teacherName: json['teacher_name']?.toString(),
      teacherPhone: (json['teacher_phone'] ?? json['emergency_phone'])?.toString(),
      employeeCode: json['employee_code']?.toString(),
      qualification: json['qualification']?.toString(),
      avatarUrl: (json['avatar_url'] ?? json['photo_url'] ?? json['photoUrl'])?.toString(),
      isClassTeacher: json['is_class_teacher'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        subjectId,
        subjectName,
        subjectCode,
        subjectType,
        teacherName,
        teacherPhone,
        employeeCode,
        qualification,
        avatarUrl,
        isClassTeacher,
      ];
}

