import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/student_features_bloc.dart';
import '../../bloc/student_features_event.dart';
import '../../bloc/student_features_state.dart';
import '../../models/student_features_model.dart';

class StudentComplaintsView extends StatefulWidget {
  const StudentComplaintsView({super.key});

  @override
  State<StudentComplaintsView> createState() => _StudentComplaintsViewState();
}

class _StudentComplaintsViewState extends State<StudentComplaintsView> {
  @override
  void initState() {
    super.initState();
    context
        .read<StudentFeaturesBloc>()
        .add(const LoadStudentComplaintsEvent());
  }

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
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_outlined, size: 20, color: Color(0xFF0284C7)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Complaints & Grievances',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Submit concerns directly to administration',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _showNewComplaintModal(context),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF64748B)),
                tooltip: 'Refresh',
                onPressed: () {
                  context
                      .read<StudentFeaturesBloc>()
                      .add(const LoadStudentComplaintsEvent());
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocConsumer<StudentFeaturesBloc, StudentFeaturesState>(
            listener: (context, state) {
              if (state is ComplaintSubmittedSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (state is StudentFeaturesError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is StudentFeaturesLoading) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }

              if (state is StudentComplaintsLoaded) {
                final complaints = state.complaints;
                if (complaints.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppColors.secondaryText),
                        SizedBox(height: 12),
                        Text(
                          'No grievances or complaints submitted',
                          style: TextStyle(color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: complaints.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildComplaintCard(complaints[index]);
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintCard(ComplaintModel c) {
    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    
    switch (c.status.toUpperCase()) {
      case 'RESOLVED':
        statusColor = const Color(0xFF16A765);
        statusBg = const Color(0xFFEAF9F0);
        statusIcon = Icons.check_circle;
        break;
      case 'IN_REVIEW':
        statusColor = const Color(0xFF0284C7);
        statusBg = const Color(0xFFEBF8FF);
        statusIcon = Icons.hourglass_bottom;
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFFEF3C7);
        statusIcon = Icons.flag;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE3ECF8)),
                ),
                child: Text(
                  c.category,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      c.status,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            c.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            c.description,
            style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B)),
          ),
          if (c.resolutionNotes != null && c.resolutionNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF9F0),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF16A765).withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF16A765)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin Resolution: ${c.resolutionNotes}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showNewComplaintModal(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String category = 'ACADEMIC';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Submit New Complaint',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ACADEMIC', child: Text('Academic')),
                      DropdownMenuItem(value: 'FACILITY', child: Text('Facility & Infrastructure')),
                      DropdownMenuItem(value: 'DISCIPLINE', child: Text('Discipline / Behavior')),
                      DropdownMenuItem(value: 'TRANSPORT', child: Text('School Transport')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Title / Subject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'Brief summary of the issue',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Detailed Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Explain the issue clearly...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        if (titleController.text.trim().isEmpty || descController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all required fields')),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        context.read<StudentFeaturesBloc>().add(
                              SubmitStudentComplaintEvent(
                                title: titleController.text.trim(),
                                category: category,
                                description: descController.text.trim(),
                              ),
                            );
                      },
                      child: const Text('Submit Complaint', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
