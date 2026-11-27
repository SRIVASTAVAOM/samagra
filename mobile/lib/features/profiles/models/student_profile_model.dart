import 'package:equatable/equatable.dart';

class StudentProfileModel extends Equatable {
  final String id;
  final String admissionNumber;
  final String? rollNumber;
  final String firstName;
  final String lastName;
  final String gender;
  final String dateOfBirth;
  final String admissionDate;
  final String? currentClassId;
  final String? currentSectionId;
  final String? fatherName;
  final String? motherName;
  final String? guardianName;
  final String? emergencyPhone;
  final String? phone;
  final String? email;
  final String? bloodGroup;
  final String? medicalNotes;
  final String? documentUrl;
  final String? avatarUrl;
  final bool photoSelfEditUsed;
  final bool canReuploadPhoto;
  final String? photoUpdatedAt;
  final String? address;
  final String? caste;
  final String? religion;
  final String? nationality;
  final String? studentAadhar;
  final String? aadharFather;
  final String? aadharMother;
  final String? fatherPan;
  final String? panMother;
  final Map<String, dynamic>? extraData;
  final String? className;
  final String? sectionName;
  final String? schoolName;
  final String? schoolPhone;
  final String? schoolEmail;
  final String? schoolAddress;
  final Map<String, dynamic>? menuConfig;
  final Map<String, dynamic>? brandingConfig;

  const StudentProfileModel({
    required this.id,
    required this.admissionNumber,
    this.rollNumber,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.dateOfBirth,
    required this.admissionDate,
    this.currentClassId,
    this.currentSectionId,
    this.fatherName,
    this.motherName,
    this.guardianName,
    this.emergencyPhone,
    this.phone,
    this.email,
    this.bloodGroup,
    this.medicalNotes,
    this.documentUrl,
    this.avatarUrl,
    this.photoSelfEditUsed = false,
    this.canReuploadPhoto = false,
    this.photoUpdatedAt,
    this.address,
    this.caste,
    this.religion,
    this.nationality,
    this.studentAadhar,
    this.aadharFather,
    this.aadharMother,
    this.fatherPan,
    this.panMother,
    this.extraData,
    this.className,
    this.sectionName,
    this.schoolName,
    this.schoolPhone,
    this.schoolEmail,
    this.schoolAddress,
    this.menuConfig,
    this.brandingConfig,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get canUploadPhoto => !photoSelfEditUsed || canReuploadPhoto;

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    final extra = json['extra_data'] is Map<String, dynamic>
        ? json['extra_data'] as Map<String, dynamic>
        : null;

    var first = (json['first_name'] as String? ?? '').trim();
    var last = (json['last_name'] as String? ?? '').trim();
    if (first.isEmpty && json['full_name'] is String) {
      final parts = (json['full_name'] as String).trim().split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        first = parts.first;
        last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    }

    final photoSelfEditUsed = json['photo_self_edit_used'] == true ||
        json['photoSelfEditUsed'] == true;
    final canReuploadPhoto =
        json['can_reupload_photo'] == true || json['canReuploadPhoto'] == true;

    return StudentProfileModel(
      id: json['id'] as String? ?? '',
      admissionNumber: json['admission_number'] as String? ?? '',
      rollNumber: json['roll_number'] as String?,
      firstName: first,
      lastName: last,
      gender: json['gender'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] as String? ?? '',
      admissionDate: json['admission_date'] as String? ?? '',
      currentClassId: (json['current_class_id'] ?? json['class_id']) as String?,
      currentSectionId:
          (json['current_section_id'] ?? json['section_id']) as String?,
      fatherName: json['father_name'] as String?,
      motherName: json['mother_name'] as String?,
      guardianName:
          (json['guardian_name'] ?? extra?['guard_name']) as String?,
      emergencyPhone: json['emergency_phone'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      bloodGroup: json['blood_group'] as String?,
      medicalNotes: json['medical_notes'] as String?,
      documentUrl:
          json['document_url'] as String? ?? json['documentUrl'] as String?,
      avatarUrl:
          (json['avatar_url'] ?? json['photo_url'] ?? json['photoUrl'])
              as String?,
      photoSelfEditUsed: photoSelfEditUsed,
      canReuploadPhoto: canReuploadPhoto,
      photoUpdatedAt: json['photo_updated_at']?.toString(),
      address: json['address'] as String?,
      caste: json['caste'] as String?,
      religion: json['religion'] as String?,
      nationality: json['nationality'] as String?,
      studentAadhar: json['student_aadhar'] as String?,
      aadharFather: json['aadhar_father'] as String?,
      aadharMother: json['aadhar_mother'] as String?,
      fatherPan: json['father_pan'] as String?,
      panMother: json['pan_mother'] as String?,
      extraData: extra,
      className: json['class_name'] as String?,
      sectionName: json['section_name'] as String?,
      schoolName: json['school_name'] as String?,
      schoolPhone: json['school_phone'] as String?,
      schoolEmail: json['school_email'] as String?,
      schoolAddress: json['school_address'] as String?,
      menuConfig: json['menu_config'] as Map<String, dynamic>?,
      brandingConfig: json['branding_config'] as Map<String, dynamic>?,
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
        dateOfBirth,
        admissionDate,
        currentClassId,
        currentSectionId,
        fatherName,
        motherName,
        guardianName,
        emergencyPhone,
        phone,
        email,
        bloodGroup,
        medicalNotes,
        documentUrl,
        avatarUrl,
        photoSelfEditUsed,
        canReuploadPhoto,
        photoUpdatedAt,
        address,
        caste,
        religion,
        nationality,
        studentAadhar,
        aadharFather,
        aadharMother,
        fatherPan,
        panMother,
        extraData,
        className,
        sectionName,
        schoolName,
        schoolPhone,
        schoolEmail,
        schoolAddress,
        menuConfig,
        brandingConfig,
      ];
}
