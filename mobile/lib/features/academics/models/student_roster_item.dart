import 'package:equatable/equatable.dart';

class StudentSubjectTag extends Equatable {
  final String id;
  final String name;
  final String code;

  const StudentSubjectTag({
    required this.id,
    required this.name,
    this.code = '',
  });

  factory StudentSubjectTag.fromJson(Map<String, dynamic> json) {
    return StudentSubjectTag(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, code];
}

class StudentRosterItem extends Equatable {
  final String id;
  final String admissionNumber;
  final String? rollNumber;
  final String firstName;
  final String lastName;
  final String gender;
  final String? emergencyPhone;
  final String? bloodGroup;
  final String? medicalNotes;
  final String? dateOfBirth;
  final String? birthdayFormatted;
  final String? avatarUrl;
  final String? classId;
  final String? sectionId;
  final String? className;
  final String? sectionName;
  final List<StudentSubjectTag> subjects;
  final List<String> subjectIds;

  const StudentRosterItem({
    required this.id,
    this.admissionNumber = '',
    this.rollNumber,
    required this.firstName,
    required this.lastName,
    this.gender = '',
    this.emergencyPhone,
    this.bloodGroup,
    this.medicalNotes,
    this.dateOfBirth,
    this.birthdayFormatted,
    this.avatarUrl,
    this.classId,
    this.sectionId,
    this.className,
    this.sectionName,
    this.subjects = const [],
    this.subjectIds = const [],
  });

  String get fullName => '$firstName $lastName'.trim();

  String? get classSectionLabel {
    final c = className?.trim() ?? '';
    final s = sectionName?.trim() ?? '';
    if (c.isEmpty && s.isEmpty) return null;
    if (c.isNotEmpty && s.isNotEmpty) return '$c • $s';
    return c.isNotEmpty ? c : s;
  }

  String? get formattedBirthday {
    final preformatted = birthdayFormatted?.trim();
    if (preformatted != null && preformatted.isNotEmpty) {
      return preformatted;
    }

    final raw = dateOfBirth?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  }

  factory StudentRosterItem.fromJson(Map<String, dynamic> json) {
    final rawFirst = json['first_name']?.toString().trim() ?? '';
    final rawLast = json['last_name']?.toString().trim() ?? '';
    final rawFull = json['full_name']?.toString().trim() ?? '';

    String firstName = rawFirst;
    String lastName = rawLast;
    if (firstName.isEmpty && lastName.isEmpty && rawFull.isNotEmpty) {
      final parts = rawFull.split(RegExp(r'\s+'));
      firstName = parts.first;
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    final rawSubjects = json['subjects'];
    final parsedSubjects = rawSubjects is List
        ? rawSubjects
            .whereType<Map<String, dynamic>>()
            .map(StudentSubjectTag.fromJson)
            .where((s) => s.id.isNotEmpty || s.name.isNotEmpty)
            .toList()
        : const <StudentSubjectTag>[];

    final rawSubjectIds = json['subject_ids'] ?? json['subjectIds'];
    final parsedSubjectIds = rawSubjectIds is List
        ? rawSubjectIds.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : parsedSubjects.map((s) => s.id).where((e) => e.isNotEmpty).toList();

    return StudentRosterItem(
      id: json['id']?.toString() ?? '',
      admissionNumber: json['admission_number']?.toString() ?? '',
      rollNumber: (json['roll_number'] ?? json['roll_no'])?.toString(),
      firstName: firstName,
      lastName: lastName,
      gender: json['gender']?.toString() ?? '',
      emergencyPhone: json['emergency_phone']?.toString(),
      bloodGroup: json['blood_group']?.toString(),
      medicalNotes: json['medical_notes']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      birthdayFormatted: json['birthday_formatted']?.toString(),
      avatarUrl: (json['avatar_url'] ?? json['photo_url'] ?? json['photoUrl'])?.toString(),
      classId: json['class_id']?.toString(),
      sectionId: json['section_id']?.toString(),
      className: (json['class_name'] ?? json['className'])?.toString(),
      sectionName: (json['section_name'] ?? json['sectionName'])?.toString(),
      subjects: parsedSubjects,
      subjectIds: parsedSubjectIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        admissionNumber,
        rollNumber,
        firstName,
        lastName,
        gender,
        emergencyPhone,
        bloodGroup,
        medicalNotes,
        dateOfBirth,
        birthdayFormatted,
        avatarUrl,
        classId,
        sectionId,
        className,
        sectionName,
        subjects,
        subjectIds,
      ];

}
