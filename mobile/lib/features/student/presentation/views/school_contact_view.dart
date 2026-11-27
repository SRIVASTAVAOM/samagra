import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profiles/bloc/profile_bloc.dart';
import '../../../profiles/bloc/profile_event.dart';
import '../../../profiles/bloc/profile_state.dart';
import '../../../profiles/models/student_profile_model.dart';

class SchoolContactView extends StatefulWidget {
  const SchoolContactView({super.key});

  @override
  State<SchoolContactView> createState() => _SchoolContactViewState();
}

class _SchoolContactViewState extends State<SchoolContactView> {
  StudentProfileModel? _cachedProfile;

  String _pickNonEmpty(List<dynamic> candidates, {String fallback = 'Not Provided'}) {
    for (final c in candidates) {
      if (c != null) {
        final s = c.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'School Contact Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: AppColors.secondaryText),
                tooltip: 'Refresh',
                onPressed: () {
                  context.read<ProfileBloc>().add(LoadStudentProfileEvent());
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is StudentProfileLoaded) {
                setState(() => _cachedProfile = state.profile);
              }
            },
            builder: (context, state) {
              final profile = state is StudentProfileLoaded
                  ? state.profile
                  : _cachedProfile;

              if (profile == null) {
                if (state is ProfileLoading || state is ProfileUpdating) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                if (state is ProfileError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 36,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              context
                                  .read<ProfileBloc>()
                                  .add(LoadStudentProfileEvent());
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Initial / unhandled non-loading state before first fetch
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 36,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'School contact details not loaded yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            context
                                .read<ProfileBloc>()
                                .add(LoadStudentProfileEvent());
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Load Contact Details'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final branding = profile.brandingConfig ?? const <String, dynamic>{};
              final schoolName = _pickNonEmpty(
                [profile.schoolName, branding['name']],
                fallback: 'School Information',
              );
              final phone = _pickNonEmpty(
                [profile.schoolPhone, branding['phone'], branding['contactPhone']],
              );
              final email = _pickNonEmpty(
                [profile.schoolEmail, branding['email'], branding['contactEmail']],
              );
              final address = _pickNonEmpty(
                [profile.schoolAddress, branding['address']],
              );
              final officeHours = _pickNonEmpty(
                [branding['officeHours'], branding['office_hours']],
                fallback: '',
              );
              final affiliation = _pickNonEmpty(
                [branding['affiliation']],
                fallback: '',
              );

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ProfileBloc>().add(LoadStudentProfileEvent());
                  await Future.delayed(const Duration(milliseconds: 250));
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              color: AppColors.scaffoldBackground,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.school,
                              size: 36,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            schoolName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            affiliation.isNotEmpty
                                ? affiliation
                                : 'Official Institutional Contact Details',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildContactTile(
                      icon: Icons.phone_outlined,
                      title: 'School Reception & Helpdesk',
                      value: phone,
                    ),
                    const SizedBox(height: 10),
                    _buildContactTile(
                      icon: Icons.email_outlined,
                      title: 'Official Inquiries Email',
                      value: email,
                    ),
                    const SizedBox(height: 10),
                    _buildContactTile(
                      icon: Icons.location_on_outlined,
                      title: 'Campus Physical Address',
                      value: address,
                    ),
                    if (officeHours.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildContactTile(
                        icon: Icons.access_time_outlined,
                        title: 'Office Working Hours',
                        value: officeHours,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
