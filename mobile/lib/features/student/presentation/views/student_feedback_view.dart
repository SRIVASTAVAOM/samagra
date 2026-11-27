import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/student_features_bloc.dart';
import '../../bloc/student_features_event.dart';
import '../../bloc/student_features_state.dart';
import '../../models/student_features_model.dart';

class StudentFeedbackView extends StatefulWidget {
  const StudentFeedbackView({super.key});

  @override
  State<StudentFeedbackView> createState() => _StudentFeedbackViewState();
}

class _StudentFeedbackViewState extends State<StudentFeedbackView> {
  List<FeedbackModel>? _cachedFeedback;
  String? _lastError;
  bool _isModalOpen = false;

  @override
  void initState() {
    super.initState();
    context.read<StudentFeaturesBloc>().add(const LoadStudentFeedbackEvent());
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
                child: const Icon(
                  Icons.rate_review_outlined,
                  size: 20,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'School Feedback',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Share your experience and suggestions',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.rate_review_outlined, size: 16),
                label: const Text('Give Feedback', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _showFeedbackModal(context),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF64748B)),
                tooltip: 'Refresh',
                onPressed: () {
                  context
                      .read<StudentFeaturesBloc>()
                      .add(const LoadStudentFeedbackEvent());
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocConsumer<StudentFeaturesBloc, StudentFeaturesState>(
            listener: (context, state) {
              if (state is StudentFeedbackLoaded) {
                setState(() {
                  _cachedFeedback = state.feedbackList;
                  _lastError = null;
                });
              } else if (state is FeedbackSubmittedSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (state is StudentFeaturesError) {
                final hadCache = _cachedFeedback != null;
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
              final feedbackList = state is StudentFeedbackLoaded
                  ? state.feedbackList
                  : _cachedFeedback;

              if (feedbackList == null) {
                if (state is StudentFeaturesLoading || state is StudentFeaturesInitial) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }

                if (_lastError != null || state is StudentFeaturesError) {
                  final errMsg = _lastError ??
                      (state is StudentFeaturesError
                          ? state.message
                          : 'Failed to load feedback');
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
                                  .add(const LoadStudentFeedbackEvent());
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

              final list = feedbackList ?? const <FeedbackModel>[];

              return Column(
                children: [
                  if (state is StudentFeaturesLoading)
                    const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<StudentFeaturesBloc>()
                            .add(const LoadStudentFeedbackEvent());
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
                                        Icons.thumb_up_alt_outlined,
                                        size: 48,
                                        color: AppColors.secondaryText,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'No feedback submitted yet',
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
                                return _buildFeedbackCard(list[index]);
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

  Widget _buildFeedbackCard(FeedbackModel fb) {
    final submittedDate = _formatDate(fb.createdAt);

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
                  fb.category,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      i < fb.rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: const Color(0xFFFCD34D),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            fb.feedbackText,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (submittedDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 12, color: AppColors.secondaryText),
                const SizedBox(width: 4),
                Text(
                  'Submitted on $submittedDate',
                  style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showFeedbackModal(BuildContext context) {
    final textController = TextEditingController();
    final featuresBloc = context.read<StudentFeaturesBloc>();
    String category = 'CURRICULUM';
    int rating = 5;
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
                if (state is FeedbackSubmittedSuccess) {
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
                          'Share Your Feedback',
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
                        DropdownMenuItem(value: 'CURRICULUM', child: Text('Curriculum & Syllabus')),
                        DropdownMenuItem(value: 'TEACHING', child: Text('Teaching & Academics')),
                        DropdownMenuItem(value: 'FACILITIES', child: Text('Facilities & Campus')),
                        DropdownMenuItem(value: 'ACTIVITIES', child: Text('Sports & Extracurricular')),
                        DropdownMenuItem(value: 'GENERAL', child: Text('General School Experience')),
                      ],
                      onChanged: isSubmitting
                          ? null
                          : (val) {
                              if (val != null) setModalState(() => category = val);
                            },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rating',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          icon: Icon(
                            starValue <= rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 28,
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  setModalState(() => rating = starValue);
                                },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your Comments',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: textController,
                      maxLines: 4,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        hintText: 'Share constructive feedback or suggestions...',
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
                                final comment = textController.text.trim();
                                if (comment.isEmpty) {
                                  setModalState(() {
                                    modalError = 'Please enter your feedback comments.';
                                  });
                                  return;
                                }
                                setModalState(() {
                                  modalError = null;
                                  isSubmitting = true;
                                });
                                featuresBloc.add(
                                  SubmitStudentFeedbackEvent(
                                    category: category,
                                    rating: rating,
                                    feedbackText: comment,
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
                                'Submit Feedback',
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
