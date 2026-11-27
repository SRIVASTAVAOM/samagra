import 'package:equatable/equatable.dart';

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
  });

  String get fullName => '$firstName $lastName'.trim();

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
      ];

}
