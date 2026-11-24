class AdminDashboardStats {
  final int totalStudents;
  final int presentStudents;
  final int absentStudents;
  final double studentAttendanceRate;

  final int totalStaff;
  final int presentStaff;
  final int onLeaveStaff;
  final double staffAttendanceRate;

  final double todayCollection;
  final int totalTransactionsToday;

  final int pendingLeaveRequests;

  const AdminDashboardStats({
    required this.totalStudents,
    required this.presentStudents,
    required this.absentStudents,
    required this.studentAttendanceRate,
    required this.totalStaff,
    required this.presentStaff,
    required this.onLeaveStaff,
    required this.staffAttendanceRate,
    required this.todayCollection,
    required this.totalTransactionsToday,
    required this.pendingLeaveRequests,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    // 1. Direct summary fields from backend AdminController.getDashboardSummary
    final todayStatus = json['today_status'] as Map<String, dynamic>?;
    final dailyCollection = json['daily_collection'] as Map<String, dynamic>?;
    final kpis = json['kpis'] as Map<String, dynamic>?;
    final pendingLeavesList = json['pending_leaves'] as List<dynamic>?;

    // 2. Legacy/alternate shapes for backward compatibility
    final students = json['students'] as Map<String, dynamic>? ?? {};
    final staff = json['staff'] as Map<String, dynamic>? ?? {};
    final fees = json['fees'] as Map<String, dynamic>? ?? {};
    final leaves = json['leaves'] as Map<String, dynamic>? ?? {};

    // Parse Students
    final totalStudents = (todayStatus?['total_students'] as num?)?.toInt() ??
        (students['total'] as num?)?.toInt() ??
        0;
    final presentStudents = (todayStatus?['present_students'] as num?)?.toInt() ??
        (students['present'] as num?)?.toInt() ??
        0;
    final absentStudents = (todayStatus?['absent_students'] as num?)?.toInt() ??
        (kpis?['total_absent_students'] as num?)?.toInt() ??
        (students['absent'] as num?)?.toInt() ??
        (totalStudents > presentStudents ? totalStudents - presentStudents : 0);
    final studentAttendanceRate = (students['rate'] as num?)?.toDouble() ??
        (totalStudents > 0 ? (presentStudents / totalStudents) * 100.0 : 0.0);

    // Parse Staff
    final totalStaff = (todayStatus?['total_teachers'] as num?)?.toInt() ??
        (kpis?['total_faculty'] as num?)?.toInt() ??
        (staff['total'] as num?)?.toInt() ??
        0;
    final presentStaff = (todayStatus?['present_teachers'] as num?)?.toInt() ??
        (staff['present'] as num?)?.toInt() ??
        0;
    final onLeaveStaff = (todayStatus?['absent_teachers'] as num?)?.toInt() ??
        (kpis?['total_absent_staff'] as num?)?.toInt() ??
        (staff['onLeave'] as num?)?.toInt() ??
        (totalStaff > presentStaff ? totalStaff - presentStaff : 0);
    final staffAttendanceRate = (staff['rate'] as num?)?.toDouble() ??
        (totalStaff > 0 ? (presentStaff / totalStaff) * 100.0 : 0.0);

    // Parse Fees
    final todayCollection = (dailyCollection?['total_received'] as num?)?.toDouble() ??
        (todayStatus?['today_fee_collection'] as num?)?.toDouble() ??
        (fees['todayCollection'] as num?)?.toDouble() ??
        0.0;
    final totalTransactionsToday = (dailyCollection?['received_count'] as num?)?.toInt() ??
        (fees['transactionsToday'] as num?)?.toInt() ??
        0;

    // Parse Pending Leaves
    final pendingLeaveRequests = (kpis?['pending_leaves_count'] as num?)?.toInt() ??
        pendingLeavesList?.length ??
        (leaves['pending'] as num?)?.toInt() ??
        0;

    return AdminDashboardStats(
      totalStudents: totalStudents,
      presentStudents: presentStudents,
      absentStudents: absentStudents,
      studentAttendanceRate: studentAttendanceRate,
      totalStaff: totalStaff,
      presentStaff: presentStaff,
      onLeaveStaff: onLeaveStaff,
      staffAttendanceRate: staffAttendanceRate,
      todayCollection: todayCollection,
      totalTransactionsToday: totalTransactionsToday,
      pendingLeaveRequests: pendingLeaveRequests,
    );
  }
}

class AdminPendingLeaveItem {
  final String id;
  final String applicantId;
  final String applicantName;
  final String applicantType; // 'STAFF' or 'STUDENT'
  final String? detail;
  final String leaveType;
  final String startDate;
  final String endDate;
  final String reason;
  final String status;
  final String? documentUrl;

  const AdminPendingLeaveItem({
    required this.id,
    required this.applicantId,
    required this.applicantName,
    required this.applicantType,
    this.detail,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.documentUrl,
  });

  factory AdminPendingLeaveItem.fromJson(Map<String, dynamic> json) {
    return AdminPendingLeaveItem(
      id: json['id']?.toString() ?? '',
      applicantId: json['applicant_id']?.toString() ??
          json['staff_id']?.toString() ??
          json['student_id']?.toString() ??
          '',
      applicantName: json['applicant_name']?.toString() ?? 'Applicant',
      applicantType: (json['applicant_type']?.toString() ?? 'STAFF').toUpperCase(),
      detail: json['detail']?.toString(),
      leaveType: json['leave_type']?.toString() ?? 'LEAVE',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      documentUrl: json['document_url']?.toString(),
    );
  }
}

class AdminNoticeItem {
  final String id;
  final String title;
  final String content;
  final String? targetRole;
  final String priority;
  final String? publishedAt;
  final String? className;
  final String? sectionName;

  const AdminNoticeItem({
    required this.id,
    required this.title,
    required this.content,
    this.targetRole,
    required this.priority,
    this.publishedAt,
    this.className,
    this.sectionName,
  });

  factory AdminNoticeItem.fromJson(Map<String, dynamic> json) {
    return AdminNoticeItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      targetRole: json['target_role']?.toString(),
      priority: json['priority']?.toString() ?? 'NORMAL',
      publishedAt: json['published_at']?.toString() ?? json['created_at']?.toString(),
      className: json['class_name']?.toString(),
      sectionName: json['section_name']?.toString(),
    );
  }
}
