import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/leaves_bloc.dart';
import '../bloc/leaves_event.dart';
import '../bloc/leaves_state.dart';
import '../models/staff_leave_model.dart';
import '../models/student_leave_model.dart';

class ManagementLeaveApprovalView extends StatefulWidget {
  const ManagementLeaveApprovalView({super.key});

  @override
  State<ManagementLeaveApprovalView> createState() =>
      _ManagementLeaveApprovalViewState();
}

class _ManagementLeaveApprovalViewState
    extends State<ManagementLeaveApprovalView> {
  String _statusFilter = 'ALL'; // 'ALL' | 'PENDING' | 'RECOMMENDED' | 'APPROVED' | 'REJECTED'
  String _timeframeFilter = 'all'; // 'all' | 'this_week' | 'this_month'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<LeavesBloc>().add(
          LoadManagementLeaveQueueEvent(
            status: _statusFilter == 'ALL' ? null : _statusFilter,
            timeframe: _timeframeFilter == 'all' ? null : _timeframeFilter,
            search: _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
          ),
        );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryText : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryText : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.surface : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  void _showAttachmentViewer(BuildContext context, String url, String? name) {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No document URL available for this leave request.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final lowerName = (name ?? url).toLowerCase();
    final isPdf = lowerName.endsWith('.pdf');
    final isImage = lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.webp');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name ?? (isPdf ? 'Leave Document (PDF)' : 'Leave Document'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: isImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: InteractiveViewer(
                              panEnabled: true,
                              minScale: 0.5,
                              maxScale: 3.0,
                              child: Image.network(
                                url,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stack) => const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('Failed to load image preview'),
                                ),
                              ),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
                                size: 48,
                                color: isPdf ? AppColors.error : AppColors.primaryAccent,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                name ?? 'Attached Document',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final uri = Uri.tryParse(url);
                                      if (uri != null) {
                                        await launchUrl(uri,
                                            mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    icon: const Icon(Icons.open_in_new, size: 16),
                                    label: const Text('Open Document'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: url));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Document URL copied'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: const Text('Copy Link'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDecisionDialog(StaffLeaveModel leave, bool isApprove) {
    final noteController = TextEditingController();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            isApprove
                ? 'Approve Leave: ${leave.staffName ?? 'Teacher'}'
                : 'Reject Leave: ${leave.staffName ?? 'Teacher'}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${leave.leaveType} Leave (${formatLeaveDateRange(leave.startDate, leave.endDate)})',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reason: "${leave.reason}"',
                  style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.primaryText),
                ),
                if (leave.recommendationNote != null &&
                    leave.recommendationNote!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Coordinator Recommendation: "${leave.recommendationNote!.trim()}"',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                if (isApprove)
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Decision Note (Optional)',
                      hintText: 'e.g., Sanctioned as per school policy',
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  TextFormField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Rejection Reason (Required)',
                      hintText: 'State reason for rejection',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Rejection reason is required';
                      }
                      return null;
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.secondaryText)),
            ),
            ElevatedButton(
              onPressed: () {
                if (!isApprove && !formKey.currentState!.validate()) {
                  return;
                }
                Navigator.pop(dialogCtx);
                context.read<LeavesBloc>().add(
                      DecideStaffLeaveEvent(
                        leaveId: leave.id,
                        decision: isApprove ? 'APPROVED' : 'REJECTED',
                        note: noteController.text.trim().isNotEmpty
                            ? noteController.text.trim()
                            : null,
                        rejectionReason: reasonController.text.trim().isNotEmpty
                            ? reasonController.text.trim()
                            : null,
                      ),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isApprove
                    ? const Color(0xFF15803D)
                    : const Color(0xFFB91C1C),
                foregroundColor: AppColors.surface,
                elevation: 0,
              ),
              child: Text(isApprove ? 'Confirm Approval' : 'Confirm Rejection'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeavesBloc, LeavesState>(
      listener: (context, state) {
        if (state is LeaveActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF15803D),
            ),
          );
        } else if (state is LeavesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Executive Leave Approval Queue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Review & sanction teacher leave applications.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: _applyFilters,
                      tooltip: 'Refresh queue',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Search teacher name, code, or reason...',
                      hintStyle: const TextStyle(
                          fontSize: 12, color: AppColors.secondaryText),
                      prefixIcon: const Icon(Icons.search, size: 17),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onSubmitted: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All',
                        isSelected: _statusFilter == 'ALL',
                        onTap: () {
                          setState(() => _statusFilter = 'ALL');
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Pending',
                        isSelected: _statusFilter == 'PENDING',
                        onTap: () {
                          setState(() => _statusFilter = 'PENDING');
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Recommended',
                        isSelected: _statusFilter == 'RECOMMENDED',
                        onTap: () {
                          setState(() => _statusFilter = 'RECOMMENDED');
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Approved',
                        isSelected: _statusFilter == 'APPROVED',
                        onTap: () {
                          setState(() => _statusFilter = 'APPROVED');
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Rejected',
                        isSelected: _statusFilter == 'REJECTED',
                        onTap: () {
                          setState(() => _statusFilter = 'REJECTED');
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 10),
                      Container(height: 16, width: 1, color: AppColors.border),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                        label: 'All Time',
                        isSelected: _timeframeFilter == 'all',
                        onTap: () {
                          setState(() => _timeframeFilter = 'all');
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'This Week',
                        isSelected: _timeframeFilter == 'this_week',
                        onTap: () {
                          setState(() => _timeframeFilter = 'this_week');
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'This Month',
                        isSelected: _timeframeFilter == 'this_month',
                        onTap: () {
                          setState(() => _timeframeFilter = 'this_month');
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<LeavesBloc, LeavesState>(
              builder: (context, state) {
                if (state is LeavesLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                if (state is LeavesError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 36, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryText),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _applyFilters,
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

                if (state is ManagementLeaveQueueLoaded) {
                  final leaves = state.leaves;

                  if (leaves.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async => _applyFilters(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(48.0),
                            child: Center(
                              child: Text(
                                'No teacher leave applications match these filters.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.secondaryText),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _applyFilters(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: leaves.length,
                      itemBuilder: (context, index) {
                        return _buildApprovalCard(leaves[index]);
                      },
                    ),
                  );
                }

                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(StaffLeaveModel leave) {
    Color badgeColor;
    Color badgeBg;
    Color badgeBorder;

    switch (leave.status) {
      case 'APPROVED':
        badgeColor = const Color(0xFF15803D);
        badgeBg = const Color(0xFFF0FDF4);
        badgeBorder = const Color(0xFF86EFAC);
        break;
      case 'RECOMMENDED':
        badgeColor = const Color(0xFF1D4ED8);
        badgeBg = const Color(0xFFEFF6FF);
        badgeBorder = const Color(0xFF93C5FD);
        break;
      case 'REJECTED':
        badgeColor = const Color(0xFFB91C1C);
        badgeBg = const Color(0xFFFEF2F2);
        badgeBorder = const Color(0xFFFCA5A5);
        break;
      case 'PENDING':
      default:
        badgeColor = const Color(0xFFB45309);
        badgeBg = const Color(0xFFFFFBEB);
        badgeBorder = const Color(0xFFFDE68A);
        break;
    }

    final isActionable =
        leave.status == 'PENDING' || leave.status == 'RECOMMENDED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.staffName ?? 'Teacher',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    if (leave.employeeCode != null &&
                        leave.employeeCode!.trim().isNotEmpty)
                      Text(
                        'Code: ${leave.employeeCode!.trim()}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  leave.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.date_range_outlined,
                  size: 14, color: AppColors.secondaryText),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${leave.leaveType} Leave • ${formatLeaveDateRange(leave.startDate, leave.endDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            leave.reason,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: AppColors.primaryText,
            ),
          ),
          if ((leave.documentUrl != null && leave.documentUrl!.trim().isNotEmpty) ||
              (leave.attachmentName != null && leave.attachmentName!.trim().isNotEmpty)) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _showAttachmentViewer(
                context,
                leave.documentUrl ?? '',
                leave.attachmentName,
              ),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attach_file, size: 12, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        leave.attachmentName != null && leave.attachmentName!.trim().isNotEmpty
                            ? 'Doc: ${leave.attachmentName!.trim()}'
                            : 'View Attached Document',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D4ED8),
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new, size: 11, color: Color(0xFF1D4ED8)),
                  ],
                ),
              ),
            ),
          ],
          if (leave.recommendationNote != null &&
              leave.recommendationNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF93C5FD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.thumb_up_alt_outlined,
                      size: 14, color: Color(0xFF1D4ED8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      leave.recommendedByName != null &&
                              leave.recommendedByName!.trim().isNotEmpty
                          ? 'Coordinator Recommendation: "${leave.recommendationNote!.trim()}" (${leave.recommendedByName!.trim()})'
                          : 'Coordinator Recommendation: "${leave.recommendationNote!.trim()}"',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1E40AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if ((leave.decisionNote != null && leave.decisionNote!.trim().isNotEmpty) ||
              (leave.rejectionReason != null &&
                  leave.rejectionReason!.trim().isNotEmpty)) ...[
            const SizedBox(height: 6),
            Text(
              'Remarks: ${(leave.decisionNote?.trim().isNotEmpty == true ? leave.decisionNote : leave.rejectionReason)!.trim()}',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: leave.status == 'REJECTED'
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFF15803D),
              ),
            ),
          ],
          if (leave.decidedByName != null &&
              leave.decidedByName!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Reviewed by ${leave.decidedByName!.trim()}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.secondaryText,
              ),
            ),
          ],
          if (isActionable) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _openDecisionDialog(leave, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFB91C1C)),
                    foregroundColor: const Color(0xFFB91C1C),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _openDecisionDialog(leave, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: AppColors.surface,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
