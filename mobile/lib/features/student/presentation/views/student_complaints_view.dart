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
  List<ComplaintModel>? _cachedComplaints;
  String? _lastError;
  bool _isModalOpen = false;

  @override
  void initState() {
    super.initState();
    context
        .read<StudentFeaturesBloc>()
        .add(const LoadStudentComplaintsEvent());
  }

  String _formatDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final parsed = DateTime.tryParse(trimmed)?.toLocal();
    if (parsed == null) return trimmed.split('T').first;
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
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complaints & Grievances',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Submit concerns directly to administration',
                      style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryText,
                  foregroundColor: AppColors.surface,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _showNewComplaintModal(context),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: AppColors.secondaryText),
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
              if (state is StudentComplaintsLoaded) {
                setState(() {
                  _cachedComplaints = state.complaints;
                  _lastError = null;
                });
              } else if (state is ComplaintSubmittedSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (state is StudentFeaturesError) {
                final hadCache = _cachedComplaints != null;
                setState(() {
                  _lastError = state.message;
                });
                if (!_isModalOpen && hadCache) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            builder: (context, state) {
              final complaints = state is StudentComplaintsLoaded
                  ? state.complaints
                  : _cachedComplaints;

              if (complaints == null) {
                if (state is StudentFeaturesLoading || state is StudentFeaturesInitial) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }

                if (_lastError != null || state is StudentFeaturesError) {
                  final errMsg = _lastError ??
                      (state is StudentFeaturesError
                          ? state.message
                          : 'Failed to load complaints');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 36, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(
                            errMsg,
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
                                  .read<StudentFeaturesBloc>()
                                  .add(const LoadStudentComplaintsEvent());
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
              }

              final list = complaints ?? const <ComplaintModel>[];

              return Column(
                children: [
                  if (state is StudentFeaturesLoading)
                    const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<StudentFeaturesBloc>()
                            .add(const LoadStudentComplaintsEvent());
                        await Future.delayed(const Duration(milliseconds: 250));
                      },
                      child: list.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 120),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.assignment_turned_in_outlined,
                                        size: 48,
                                        color: AppColors.secondaryText,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'No grievances or complaints submitted',
                                        style: TextStyle(color: AppColors.secondaryText),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: list.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildComplaintCard(list[index]);
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintCard(ComplaintModel c) {
    Color statusColor;
    switch (c.status.toUpperCase()) {
      case 'RESOLVED':
        statusColor = AppColors.success;
        break;
      case 'IN_REVIEW':
        statusColor = AppColors.info;
        break;
      default:
        statusColor = AppColors.warning;
    }

    final filedDate = _formatDate(c.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  c.category,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  c.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            c.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            c.description,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.secondaryText,
            ),
          ),
          if (filedDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 12, color: AppColors.secondaryText),
                const SizedBox(width: 4),
                Text(
                  'Filed on $filedDate',
                  style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                ),
              ],
            ),
          ],
          if (c.resolutionNotes != null && c.resolutionNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin Resolution: ${c.resolutionNotes}',
                      style: const TextStyle(fontSize: 11, color: AppColors.primaryText),
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
    final featuresBloc = context.read<StudentFeaturesBloc>();
    String category = 'ACADEMIC';
    bool isSubmitting = false;
    String? modalError;

    setState(() => _isModalOpen = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return BlocListener<StudentFeaturesBloc, StudentFeaturesState>(
              bloc: featuresBloc,
              listener: (_, state) {
                if (!isSubmitting) return;
                if (state is ComplaintSubmittedSuccess) {
                  isSubmitting = false;
                  if (Navigator.of(ctx).canPop()) {
                    Navigator.of(ctx).pop();
                  }
                } else if (state is StudentFeaturesError) {
                  setModalState(() {
                    isSubmitting = false;
                    modalError = state.message;
                  });
                }
              },
              child: SingleChildScrollView(
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    if (modalError != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          modalError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Category',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ACADEMIC', child: Text('Academic')),
                        DropdownMenuItem(
                            value: 'FACILITY', child: Text('Facility & Infrastructure')),
                        DropdownMenuItem(
                            value: 'DISCIPLINE', child: Text('Discipline / Behavior')),
                        DropdownMenuItem(
                            value: 'TRANSPORT', child: Text('School Transport')),
                        DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                      ],
                      onChanged: isSubmitting
                          ? null
                          : (val) {
                              if (val != null) setModalState(() => category = val);
                            },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Title / Subject',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: titleController,
                      maxLength: 255,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        hintText: 'Brief summary of the issue',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Detailed Description',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: descController,
                      maxLines: 4,
                      enabled: !isSubmitting,
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
                        onPressed: isSubmitting
                            ? null
                            : () {
                                final title = titleController.text.trim();
                                final desc = descController.text.trim();
                                if (title.isEmpty || desc.isEmpty) {
                                  setModalState(() {
                                    modalError =
                                        'Please enter both a title and a detailed description.';
                                  });
                                  return;
                                }
                                setModalState(() {
                                  modalError = null;
                                  isSubmitting = true;
                                });
                                featuresBloc.add(
                                  SubmitStudentComplaintEvent(
                                    title: title,
                                    category: category,
                                    description: desc,
                                  ),
                                );
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Complaint',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() => _isModalOpen = false);
      } else {
        _isModalOpen = false;
      }
    });
  }
}
