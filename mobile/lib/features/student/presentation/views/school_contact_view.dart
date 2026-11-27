import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profiles/bloc/profile_bloc.dart';
import '../../../profiles/bloc/profile_event.dart';
import '../../../profiles/bloc/profile_state.dart';

class SchoolContactView extends StatelessWidget {
  const SchoolContactView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            border: Border(bottom: BorderSide(color: Color(0xFFE3ECF8), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'School Contact',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF64748B)),
                tooltip: 'Refresh',
                onPressed: () {
                  context.read<ProfileBloc>().add(LoadStudentProfileEvent());
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoading) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }

              if (state is StudentProfileLoaded) {
                final p = state.profile;
                final schoolName = p.schoolName ?? 'Apex International School';
                final phone = p.schoolPhone ?? '+91 9876543210';
                final email = p.schoolEmail ?? 'info@apexschool.edu';
                final address = p.schoolAddress ?? '123 Education Lane, Knowledge Park';

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school_outlined, size: 40, color: Color(0xFF0284C7)),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        schoolName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Official Institutional Contact',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _buildContactTile(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  value: phone,
                ),
                const SizedBox(height: 12),
                _buildContactTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  value: email,
                ),
                const SizedBox(height: 12),
                _buildContactTile(
                  icon: Icons.location_on_outlined,
                  title: 'Campus Address',
                  value: address,
                ),
                const SizedBox(height: 12),
                _buildContactTile(
                  icon: Icons.access_time_outlined,
                  title: 'Office Hours',
                  value: 'Monday to Friday: 8:00 AM – 3:30 PM\nSaturday: 8:00 AM – 1:00 PM',
                ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
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
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF0284C7)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    height: 1.4,
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
