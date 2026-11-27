import 'package:equatable/equatable.dart';

class ClassmateBirthdayModel extends Equatable {
  final String id;
  final String admissionNumber;
  final String? rollNumber;
  final String firstName;
  final String lastName;
  final int birthMonth;
  final int birthDay;
  final String birthdayFormatted;
  final String? avatarUrl;
  final bool isToday;

  const ClassmateBirthdayModel({
    required this.id,
    this.admissionNumber = '',
    this.rollNumber,
    required this.firstName,
    required this.lastName,
    required this.birthMonth,
    required this.birthDay,
    required this.birthdayFormatted,
    this.avatarUrl,
    this.isToday = true,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ClassmateBirthdayModel.fromJson(Map<String, dynamic> json) {
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

    return ClassmateBirthdayModel(
      id: json['id']?.toString() ?? '',
      admissionNumber: json['admission_number']?.toString() ?? '',
      rollNumber: (json['roll_number'] ?? json['roll_no'])?.toString(),
      firstName: firstName,
      lastName: lastName,
      birthMonth: (json['birth_month'] as num?)?.toInt() ?? 1,
      birthDay: (json['birth_day'] as num?)?.toInt() ?? 1,
      birthdayFormatted: json['birthday_formatted']?.toString() ?? '',
      avatarUrl: (json['avatar_url'] ?? json['photo_url'] ?? json['photoUrl'])?.toString(),
      isToday: json['is_today'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        admissionNumber,
        rollNumber,
        firstName,
        lastName,
        birthMonth,
        birthDay,
        birthdayFormatted,
        avatarUrl,
        isToday,
      ];
}
