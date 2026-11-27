import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/document_picker_bottom_sheet.dart';
import '../../../core/widgets/user_avatar.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../models/student_profile_model.dart';
import '../../auth/presentation/change_password_dialog.dart';
import '../../auth/repositories/auth_repository.dart';

class StudentProfileView extends StatelessWidget {
  const StudentProfileView({super.key});

  String _formatDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Not Provided';
    final datePart = trimmed.split('T').first;
    final parsed = DateTime.tryParse(datePart);
    if (parsed == null) return datePart;
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

  Future<void> _handlePhotoPick(
    BuildContext context,
    StudentProfileModel profile,
  ) async {
    if (!profile.canUploadPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'One-time profile photo upload is already used. Ask your School Admin to allow a photo re-upload.',
          ),
          backgroundColor: AppColors.primaryText,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final doc = await DocumentPickerBottomSheet.show(
      context,
      title: 'Upload Profile Photo',
      subtitle: profile.canReuploadPhoto
          ? 'Admin approved re-upload. Choose a photo from gallery or camera.'
          : 'Students can upload/change their profile photo once.',
      categoryPrefix: 'student_photo',
    );

    if (doc != null && doc.bytes != null && doc.bytes!.isNotEmpty && context.mounted) {
      context.read<ProfileBloc>().add(
            UploadStudentPhotoEvent(
              bytes: doc.bytes!,
              fileName: doc.name,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.primaryText,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileUpdating) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (state is ProfileError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 36, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      context.read<ProfileBloc>().add(LoadStudentProfileEvent());
                    },
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

        if (state is StudentProfileLoaded) {
          return _buildProfileContent(context, state.profile);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProfileContent(BuildContext context, StudentProfileModel p) {
    final extraRows = <Widget>[];
    final extra = p.extraData ?? {};
    const extraLabels = <String, String>{
      'house': 'House',
      'stream': 'Stream',
      'session': 'Academic Session',
      'fee_cat': 'Fee Category',
      'adm_category': 'Admission Category',
      'lang': 'Medium / Language',
      'fat_mobile': "Father's Mobile",
      'mot_mobile': "Mother's Mobile",
      'guard_relation': 'Guardian Relation',
    };
    for (final entry in extraLabels.entries) {
      final raw = extra[entry.key]?.toString().trim() ?? '';
      if (raw.isNotEmpty) {
        extraRows.add(_buildRow(entry.value, raw));
      }
    }

    final schoolRows = <Widget>[
      _buildRow(
        'School Name',
        (p.schoolName != null && p.schoolName!.trim().isNotEmpty)
            ? p.schoolName!.trim()
            : 'Not Provided',
      ),
      if (p.schoolPhone != null && p.schoolPhone!.trim().isNotEmpty)
        _buildRow('Helpline / Phone', p.schoolPhone!.trim()),
      if (p.schoolEmail != null && p.schoolEmail!.trim().isNotEmpty)
        _buildRow('Contact Email', p.schoolEmail!.trim()),
      if (p.schoolAddress != null && p.schoolAddress!.trim().isNotEmpty)
        _buildRow('Campus Address', p.schoolAddress!.trim()),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProfileBloc>().add(LoadStudentProfileEvent());
        await Future.delayed(const Duration(milliseconds: 250));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Identity Card + One-time Photo Upload Control
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _handlePhotoPick(context, p),
                      child: Stack(
                        children: [
                          UserAvatar(
                            name: p.fullName.isNotEmpty ? p.fullName : p.admissionNumber,
                            avatarUrl: p.avatarUrl,
                            radius: 28,
                            fontSize: 20,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: p.canUploadPhoto
                                    ? AppColors.primaryAccent
                                    : AppColors.secondaryText,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.surface, width: 1.5),
                              ),
                              child: Icon(
                                p.canUploadPhoto ? Icons.camera_alt : Icons.lock,
                                size: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.fullName.isNotEmpty ? p.fullName : p.admissionNumber,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Adm: ${p.admissionNumber} • Roll: ${(p.rollNumber != null && p.rollNumber!.trim().isNotEmpty) ? p.rollNumber : "N/A"}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          if (p.className != null && p.className!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              p.sectionName != null && p.sectionName!.trim().isNotEmpty
                                  ? 'Class: ${p.className} - ${p.sectionName}'
                                  : 'Class: ${p.className}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        p.canUploadPhoto ? Icons.add_a_photo_outlined : Icons.verified_user_outlined,
                        size: 16,
                        color: p.canUploadPhoto ? AppColors.primaryAccent : AppColors.secondaryText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.canReuploadPhoto
                              ? 'Admin approved photo re-upload'
                              : (p.canUploadPhoto
                                  ? 'One-time student profile photo upload available'
                                  : 'One-time photo uploaded • Contact Admin to re-allow'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: p.canUploadPhoto ? AppColors.primaryText : AppColors.secondaryText,
                          ),
                        ),
                      ),
                      if (p.canUploadPhoto)
                        TextButton(
                          onPressed: () => _handlePhotoPick(context, p),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            (p.avatarUrl != null && p.avatarUrl!.isNotEmpty)
                                ? 'Change Photo'
                                : 'Upload Photo',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Personal & Admission Records (Dynamic DB records)
          _buildSectionCard(
            title: 'Institutional & Admission Records',
            rows: [
              _buildRow('Date of Birth', _formatDate(p.dateOfBirth)),
              _buildRow('Gender', p.gender.isNotEmpty ? p.gender : 'Not Provided'),
              _buildRow('Admission Date', _formatDate(p.admissionDate)),
              if (p.phone != null && p.phone!.trim().isNotEmpty)
                _buildRow('Primary Phone', p.phone!.trim()),
              if (p.email != null && p.email!.trim().isNotEmpty)
                _buildRow('Email', p.email!.trim()),
              if (p.fatherName != null && p.fatherName!.trim().isNotEmpty)
                _buildRow("Father's Name", p.fatherName!.trim()),
              if (p.motherName != null && p.motherName!.trim().isNotEmpty)
                _buildRow("Mother's Name", p.motherName!.trim()),
              if (p.guardianName != null && p.guardianName!.trim().isNotEmpty)
                _buildRow("Guardian's Name", p.guardianName!.trim()),
              if (p.address != null && p.address!.trim().isNotEmpty)
                _buildRow('Address', p.address!.trim()),
              if (p.caste != null && p.caste!.trim().isNotEmpty)
                _buildRow('Category / Caste', p.caste!.trim()),
              if (p.religion != null && p.religion!.trim().isNotEmpty)
                _buildRow('Religion', p.religion!.trim()),
              if (p.nationality != null && p.nationality!.trim().isNotEmpty)
                _buildRow('Nationality', p.nationality!.trim()),
              if (p.studentAadhar != null && p.studentAadhar!.trim().isNotEmpty)
                _buildRow('Student Aadhar', p.studentAadhar!.trim()),
            ],
          ),
          const SizedBox(height: 16),

          if (extraRows.isNotEmpty) ...[
            _buildSectionCard(
              title: 'Additional Enrollment Details',
              rows: extraRows,
            ),
            const SizedBox(height: 16),
          ],

          // Editable Emergency & Health Information
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Emergency & Health Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Edit', style: TextStyle(fontSize: 13)),
                      onPressed: () => _showEditDialog(context, p),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRow(
                  'Emergency Phone',
                  (p.emergencyPhone != null && p.emergencyPhone!.trim().isNotEmpty)
                      ? p.emergencyPhone!.trim()
                      : 'Not Provided',
                ),
                _buildRow(
                  'Blood Group',
                  (p.bloodGroup != null && p.bloodGroup!.trim().isNotEmpty)
                      ? p.bloodGroup!.trim()
                      : 'Not Provided',
                ),
                _buildRow(
                  'Medical Notes',
                  (p.medicalNotes != null && p.medicalNotes!.trim().isNotEmpty)
                      ? p.medicalNotes!.trim()
                      : 'None recorded',
                ),
                _buildRow(
                  'Medical / ID Document',
                  (p.documentUrl != null && p.documentUrl!.isNotEmpty)
                      ? 'Document Uploaded'
                      : 'None Attached',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // School Contact Details (Real DB records only — no hardcoded strings)
          _buildSectionCard(
            title: 'School Contact & Institutional Details',
            rows: schoolRows,
          ),
          const SizedBox(height: 16),

          // Account Security & Change Password
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Security',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Change your password anytime to protect your personal account.',
                  style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final authRepo = context.read<AuthRepository>();
                      ChangePasswordDialog.show(context, authRepo);
                    },
                    icon: const Icon(Icons.key, size: 16),
                    label: const Text(
                      'Change Password',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> rows}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, StudentProfileModel profile) {
    final phoneController = TextEditingController(text: profile.emergencyPhone ?? '');
    final bloodGroupController = TextEditingController(text: profile.bloodGroup ?? '');
    final notesController = TextEditingController(text: profile.medicalNotes ?? '');
    String? docUrl = profile.documentUrl;
    String? docName = (profile.documentUrl != null && profile.documentUrl!.isNotEmpty)
        ? 'Medical_or_ID_Document.pdf'
        : null;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (stCtx, setDialogState) => AlertDialog(
          title: const Text(
            'Edit Emergency & Health',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Phone Number',
                    hintText: '+91 9876543210',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bloodGroupController,
                  decoration: const InputDecoration(
                    labelText: 'Blood Group',
                    hintText: 'e.g. O+, B-, AB+',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Medical Notes / Allergies',
                    hintText: 'Any known conditions or allergies',
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Medical / ID Document',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          if (docName != null)
                            InkWell(
                              onTap: () {
                                setDialogState(() {
                                  docName = null;
                                  docUrl = null;
                                });
                              },
                              child: const Text(
                                'Remove',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (docName == null) ...[
                        OutlinedButton.icon(
                          onPressed: () async {
                            final doc = await DocumentPickerBottomSheet.show(
                              dialogCtx,
                              title: 'Attach Student Document',
                              subtitle:
                                  'Choose from device storage or take a photo with camera',
                              categoryPrefix: 'student_profile',
                            );
                            if (doc != null) {
                              setDialogState(() {
                                docName = doc.name;
                                docUrl = doc.url;
                              });
                            }
                          },
                          icon: const Icon(Icons.upload_file, size: 14),
                          label: const Text('Attach Document (Optional)',
                              style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Icon(
                              docName!.toLowerCase().endsWith('.pdf')
                                  ? Icons.picture_as_pdf
                                  : Icons.camera_alt_outlined,
                              size: 16,
                              color: docName!.toLowerCase().endsWith('.pdf')
                                  ? const Color(0xFFB91C1C)
                                  : const Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                docName!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newPhone = phoneController.text.trim();
                final newBlood = bloodGroupController.text.trim();
                final newNotes = notesController.text.trim();

                context.read<ProfileBloc>().add(
                      UpdateStudentProfileEvent(
                        emergencyPhone: newPhone.isNotEmpty ? newPhone : null,
                        bloodGroup: newBlood.isNotEmpty ? newBlood : null,
                        medicalNotes: newNotes.isNotEmpty ? newNotes : null,
                        documentUrl: docUrl,
                      ),
                    );
                Navigator.pop(dialogCtx);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
