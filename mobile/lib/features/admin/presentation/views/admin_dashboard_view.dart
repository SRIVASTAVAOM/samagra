import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/models/user_model.dart';
import '../../models/admin_dashboard_model.dart';
import '../../repository/admin_repository.dart';

class AdminDashboardView extends StatefulWidget {
  final UserModel user;

  const AdminDashboardView({super.key, required this.user});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final _adminRepo = AdminRepository();
  late Future<AdminDashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _statsFuture = _adminRepo.fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Principal / Admin Portal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.surface,
              ),
            ),
            Text(
              'SAMAGRA School Management',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.surface),
            tooltip: 'Refresh Pulse',
            onPressed: _loadStats,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadStats(),
        child: FutureBuilder<AdminDashboardStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = snapshot.data ??
                const AdminDashboardStats(
                  totalStudents: 0,
                  presentStudents: 0,
                  absentStudents: 0,
                  studentAttendanceRate: 0,
                  totalStaff: 0,
                  presentStaff: 0,
                  onLeaveStaff: 0,
                  staffAttendanceRate: 0,
                  todayCollection: 0,
                  totalTransactionsToday: 0,
                  pendingLeaveRequests: 0,
                );

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Welcome Banner
                _buildHeaderCard(),
                const SizedBox(height: 16),

                // Section 1: Executive Pulse
                const Text(
                  "Today's Executive Pulse",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 12),

                // Attendance Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Student Attendance',
                        mainValue: '${stats.studentAttendanceRate.toStringAsFixed(1)}%',
                        subtitle: '${stats.presentStudents} / ${stats.totalStudents} Present',
                        icon: Icons.school_outlined,
                        color: Colors.blue.shade700,
                        accentColor: Colors.blue.shade50,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Staff On Duty',
                        mainValue: '${stats.staffAttendanceRate.toStringAsFixed(1)}%',
                        subtitle: '${stats.presentStaff} / ${stats.totalStaff} Present',
                        icon: Icons.badge_outlined,
                        color: Colors.teal.shade700,
                        accentColor: Colors.teal.shade50,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Fee Collection Card
                _buildFeePulseCard(stats),
                const SizedBox(height: 20),

                // Section 2: Action Center
                const Text(
                  'Quick Management Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 12),

                _buildActionItem(
                  icon: Icons.campaign_rounded,
                  title: 'Broadcast Urgent Notice',
                  description: 'Send instant notification to all classes or teachers',
                  color: Colors.indigo,
                  onTap: () => _showBroadcastDialog(context),
                ),
                const SizedBox(height: 10),

                _buildActionItem(
                  icon: Icons.pending_actions_rounded,
                  title: 'Staff Leave Approvals',
                  description: '${stats.pendingLeaveRequests} leave requests waiting for review',
                  badgeCount: stats.pendingLeaveRequests,
                  color: Colors.orange.shade800,
                  onTap: () => _openLeaveApprovalsBottomSheet(context),
                ),
                const SizedBox(height: 10),

                _buildActionItem(
                  icon: Icons.language_rounded,
                  title: 'Full School Web Admin HQ',
                  description: 'For bulk uploads & financial ledger, access via PC browser',
                  color: Colors.purple.shade700,
                  onTap: () => _showWebAdminHqModal(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryAccent, Colors.teal.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxStyle.cardShadow,
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            child: const Icon(Icons.admin_panel_settings_rounded, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${widget.user.firstName ?? "Principal"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Real-time overview of school operations today',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String mainValue,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxStyle.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            mainValue,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeePulseCard(AdminDashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxStyle.cardShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.currency_rupee_rounded, color: Colors.green.shade700, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Fee Counter Collection",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${stats.todayCollection.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '${stats.totalTransactionsToday} Receipts',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
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
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount != null && badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText, size: 20),
          ],
        ),
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Broadcast Urgent Notice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Notice Title',
                hintText: 'e.g. School closed tomorrow',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notice Details',
                hintText: 'Enter announcement text...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final ok = await _adminRepo.broadcastNotice(
                title: titleCtrl.text.trim(),
                content: bodyCtrl.text.trim(),
                priority: 'URGENT',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Notice broadcasted successfully!'
                        : 'Notice saved to school circular board.'),
                  ),
                );
                _loadStats();
              }
            },
            child: const Text('Broadcast'),
          ),
        ],
      ),
    );
  }

  void _showWebAdminHqModal(BuildContext context) {
    const webUrl = 'https://samagra-web-admin.vercel.app';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.language_rounded, color: Colors.purple.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full School Web Admin HQ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Desktop browser administration portal',
                        style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Access the complete school management suite on your PC, laptop, or tablet browser:',
              style: TextStyle(fontSize: 13, color: AppColors.primaryText),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Bulk CSV student & teacher onboarding\n• Fee structure management & accounting reports\n• Class-wise timetable grid builder & substitutions\n• Complete Greensheet operational audits',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: SelectableText(
                      webUrl,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: Color(0xFF1D4ED8)),
                    tooltip: 'Copy URL',
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: webUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Web Admin HQ link copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: webUrl));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Web Admin HQ URL copied! Paste in your browser on PC/Mac.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy Portal URL & Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openLeaveApprovalsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return FutureBuilder<List<AdminPendingLeaveItem>>(
              future: _adminRepo.fetchPendingLeaves(),
              builder: (ctx, snapshot) {
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final leaves = snapshot.data ?? [];

                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.pending_actions_rounded,
                                  color: Colors.orange.shade800),
                              const SizedBox(width: 8),
                              const Text(
                                'Pending Leave Approvals',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(bottomSheetCtx),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (leaves.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 48, color: Colors.green),
                                SizedBox(height: 12),
                                Text(
                                   'All Caught Up!',
                                   style: TextStyle(
                                       fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 6),
                                Text(
                                   'No staff or student leave requests waiting for review.',
                                   textAlign: TextAlign.center,
                                   style: TextStyle(
                                       fontSize: 12, color: AppColors.secondaryText),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: leaves.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final leave = leaves[i];
                              final isStaff = leave.applicantType == 'STAFF';
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                leave.applicantName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (leave.detail != null)
                                                Text(
                                                  leave.detail!,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.secondaryText,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isStaff
                                                ? Colors.blue.shade50
                                                : Colors.amber.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: isStaff
                                                  ? Colors.blue.shade200
                                                  : Colors.amber.shade200,
                                            ),
                                          ),
                                          child: Text(
                                            isStaff ? 'STAFF' : 'STUDENT',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isStaff
                                                  ? Colors.blue.shade800
                                                  : Colors.amber.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${leave.leaveType} • ${leave.startDate} to ${leave.endDate}',
                                      style: const TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      leave.reason,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (leave.documentUrl != null &&
                                        leave.documentUrl!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.attach_file,
                                              size: 13, color: Color(0xFF1D4ED8)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Doc: ${leave.documentUrl}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF1D4ED8),
                                                decoration: TextDecoration.underline,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () async {
                                            final ok = isStaff
                                                ? await _adminRepo.decideStaffLeave(
                                                    leaveId: leave.id,
                                                    isApprove: false,
                                                  )
                                                : await _adminRepo.decideStudentLeave(
                                                    leaveId: leave.id,
                                                    isApprove: false,
                                                  );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(ok
                                                      ? 'Leave application rejected'
                                                      : 'Failed to update leave status'),
                                                ),
                                              );
                                              setSheetState(() {});
                                              _loadStats();
                                            }
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFFB91C1C),
                                            side: const BorderSide(
                                                color: Color(0xFFFCA5A5)),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 8),
                                          ),
                                          child: const Text('Reject',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final ok = isStaff
                                                ? await _adminRepo.decideStaffLeave(
                                                    leaveId: leave.id,
                                                    isApprove: true,
                                                  )
                                                : await _adminRepo.decideStudentLeave(
                                                    leaveId: leave.id,
                                                    isApprove: true,
                                                  );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(ok
                                                      ? 'Leave application approved'
                                                      : 'Failed to update leave status'),
                                                ),
                                              );
                                              setSheetState(() {});
                                              _loadStats();
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF15803D),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 8),
                                          ),
                                          child: const Text('Approve',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class BoxStyle {
  static final cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );
}
