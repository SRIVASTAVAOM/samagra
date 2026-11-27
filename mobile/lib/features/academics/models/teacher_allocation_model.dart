import 'package:equatable/equatable.dart';

class HomeroomInfo extends Equatable {
  final String id;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final int? studentCount;

  const HomeroomInfo({
    required this.id,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    this.studentCount,
  });

  factory HomeroomInfo.fromJson(Map<String, dynamic> json) {
    final rawCount = json['student_count'] ?? json['studentCount'];
    return HomeroomInfo(
      id: json['id'] as String? ?? '',
      classId: json['class_id'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      sectionId: json['section_id'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? '',
      studentCount: rawCount is int ? rawCount : int.tryParse(rawCount?.toString() ?? ''),
    );
  }

  @override
  List<Object?> get props => [id, classId, className, sectionId, sectionName, studentCount];
}

class TeacherAllocationItem extends Equatable {
  final String id;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final int? studentCount;

  const TeacherAllocationItem({
    required this.id,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    this.studentCount,
  });

  factory TeacherAllocationItem.fromJson(Map<String, dynamic> json) {
    final rawCount = json['student_count'] ?? json['studentCount'];
    return TeacherAllocationItem(
      id: json['id'] as String? ?? '',
      classId: json['class_id'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      sectionId: json['section_id'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      studentCount: rawCount is int ? rawCount : int.tryParse(rawCount?.toString() ?? ''),
    );
  }

  @override
  List<Object?> get props => [
        id,
        classId,
        className,
        sectionId,
        sectionName,
        subjectId,
        subjectName,
        subjectCode,
        studentCount,
      ];
}

class TeacherAllocationsResponse extends Equatable {
  final HomeroomInfo? homeroom;
  final List<TeacherAllocationItem> allocations;

  const TeacherAllocationsResponse({
    this.homeroom,
    required this.allocations,
  });

  factory TeacherAllocationsResponse.fromJson(Map<String, dynamic> json) {
    return TeacherAllocationsResponse(
      homeroom: json['homeroom'] != null
          ? HomeroomInfo.fromJson(json['homeroom'] as Map<String, dynamic>)
          : null,
      allocations: (json['allocations'] as List<dynamic>? ?? [])
          .map((e) => TeacherAllocationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [homeroom, allocations];
}
