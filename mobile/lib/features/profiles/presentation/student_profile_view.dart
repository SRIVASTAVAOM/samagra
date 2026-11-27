import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/document_picker_bottom_sheet.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../models/student_profile_model.dart';
import '../../auth/presentation/change_password_dialog.dart';
import '../../auth/repositories/auth_repository.dart';

class StudentProfileView extends StatelessWidget {
  const StudentProfileView({super.key});

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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Student Information Card (Premium Design)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3ECF8), width: 1),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 2),
                blurRadius: 8,
                color: Colors.black.withValues(alpha: 0.04),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF24B9F2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    p.firstName.isNotEmpty ? p.firstName[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Adm: ${p.admissionNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (p.rollNumber != null && p.rollNumber!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Roll: ${p.rollNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    if (p.className != null && p.sectionName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${p.className} - ${p.sectionName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Institutional Records (Read-only)
        _buildSectionCard(
          title: 'Institutional Records',
          titleIcon: Icons.school_outlined,
          rows: [
            _buildRow('Date of Birth', _formatDate(p.dateOfBirth)),
            _buildRow('Gender', p.gender),
            _buildRow('Admission Date', _formatDate(p.admissionDate)),
            if (p.fatherName != null && p.fatherName!.isNotEmpty) _buildRow("Father's Name", p.fatherName!),
            if (p.motherName != null && p.motherName!.isNotEmpty) _buildRow("Mother's Name", p.motherName!),
          ],
        ),
        const SizedBox(height: 20),

        // Emergency & Health Details
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3ECF8), width: 1),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 2),
                blurRadius: 8,
                color: Colors.black.withValues(alpha: 0.04),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.health_and_safety_outlined, size: 18, color: Color(0xFF0284C7)),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Emergency & Health',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _showEditDialog(context, p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F8FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE3ECF8)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined, size: 14, color: Color(0xFF0284C7)),
                          SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildRow('Emergency Phone', p.emergencyPhone ?? 'Not Provided'),
              _buildRow('Blood Group', p.bloodGroup ?? 'Not Provided'),
              _buildRow('Medical Notes', p.medicalNotes ?? 'None recorded'),
              _buildRow('Medical / ID Document', (p.documentUrl != null && p.documentUrl!.isNotEmpty) ? 'Document Uploaded' : 'None Attached'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Address Details
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3ECF8), width: 1),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 2),
                blurRadius: 8,
                color: Colors.black.withValues(alpha: 0.04),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Address Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildRow('Street Address', p.schoolAddress ?? 'Not Provided'),
              _buildRow('City', 'Knowledge Park'),
              _buildRow('State', 'Not Specified'),
              _buildRow('Postal Code', 'N/A'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // School Contact Details (Read-only)
        _buildSectionCard(
          title: 'School Contact Details',
          titleIcon: Icons.phone_outlined,
          rows: [
            _buildRow('School Name', p.schoolName ?? 'Apex International School'),
            _buildRow('Phone', p.schoolPhone ?? '+91 9876543210'),
            _buildRow('Email', p.schoolEmail ?? 'info@apexschool.edu'),
          ],
        ),
        const SizedBox(height: 20),

        // Account Security & Change Password
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3ECF8), width: 1),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 2),
                blurRadius: 8,
                color: Colors.black.withValues(alpha: 0.04),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock_outline, size: 18, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Account Security',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Change your password anytime to protect your personal account.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final authRepo = context.read<AuthRepository>();
                    ChangePasswordDialog.show(context, authRepo);
                  },
                  icon: const Icon(Icons.key, size: 16),
                  label: const Text('Change Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return 'Not Available';
      final parts = dateStr.split('T')[0].split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final month = int.tryParse(parts[1]) ?? 1;
        final day = int.tryParse(parts[2]) ?? 1;
        const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        final monthName = (month >= 1 && month <= 12) ? months[month - 1] : 'N/A';
        return '$day $monthName $year';
      }
    } catch (_) {}
    return dateStr;
  }


  Widget _buildSectionCard({
    required String title,
    required List<Widget> rows,
    IconData? titleIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3ECF8), width: 1),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(titleIcon, size: 18, color: const Color(0xFF0284C7)),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
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
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE3ECF8), width: 1),
          ),
          title: const Text(
            'Edit Emergency & Health',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEditTextField(phoneController, 'Emergency Phone', '+91 9876543210'),
                const SizedBox(height: 14),
                _buildEditTextField(bloodGroupController, 'Blood Group', 'e.g. O+, A+, B-'),
                const SizedBox(height: 14),
                _buildEditTextField(notesController, 'Medical Notes / Allergies', 'e.g. Asthmatic, peanut allergy', maxLines: 2),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE3ECF8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Medical / ID Document (Optional)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (docUrl != null && docUrl!.isNotEmpty)
                            InkWell(
                              onTap: () {
                                setDialogState(() {
                                  docUrl = null;
                                  docName = null;
                                });
                              },
                              child: const Text(
                                'Remove',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFE53935),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                          label: const Text('Attach Document',
                              style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE3ECF8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
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
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
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
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                elevation: 0,
              ),
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE3ECF8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE3ECF8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
