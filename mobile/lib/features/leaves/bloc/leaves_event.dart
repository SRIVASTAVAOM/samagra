abstract class LeavesEvent {
  const LeavesEvent();
}

class LoadStaffMyLeavesEvent extends LeavesEvent {
  const LoadStaffMyLeavesEvent();
}

class ApplyStaffLeaveEvent extends LeavesEvent {
  final String startDate;
  final String endDate;
  final String leaveType;
  final String reason;
  final String? documentUrl;
  final String? attachmentName;

  const ApplyStaffLeaveEvent({
    required this.startDate,
    required this.endDate,
    required this.leaveType,
    required this.reason,
    this.documentUrl,
    this.attachmentName,
  });
}

class LoadCoordinatorWingLeavesEvent extends LeavesEvent {
  const LoadCoordinatorWingLeavesEvent();
}

class RecommendStaffLeaveEvent extends LeavesEvent {
  final String leaveId;
  final String? note;

  const RecommendStaffLeaveEvent({
    required this.leaveId,
    this.note,
  });
}

class LoadManagementLeaveQueueEvent extends LeavesEvent {
  final String? status;
  final String? timeframe;
  final String? startDate;
  final String? endDate;
  final String? search;

  const LoadManagementLeaveQueueEvent({
    this.status,
    this.timeframe,
    this.startDate,
    this.endDate,
    this.search,
  });
}

class DecideStaffLeaveEvent extends LeavesEvent {
  final String leaveId;
  final String decision; // 'APPROVED' | 'REJECTED'
  final String? note;
  final String? rejectionReason;

  const DecideStaffLeaveEvent({
    required this.leaveId,
    required this.decision,
    this.note,
    this.rejectionReason,
  });
}

class LoadStudentMyLeavesEvent extends LeavesEvent {
  const LoadStudentMyLeavesEvent();
}

class ApplyStudentLeaveEvent extends LeavesEvent {
  final String startDate;
  final String endDate;
  final String reason;
  final String? documentUrl;
  final String? attachmentName;

  const ApplyStudentLeaveEvent({
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.documentUrl,
    this.attachmentName,
  });
}

class LoadClassStudentLeavesEvent extends LeavesEvent {
  final String? status;
  final String? timeframe;
  final String? startDate;
  final String? endDate;
  final String? search;

  const LoadClassStudentLeavesEvent({
    this.status,
    this.timeframe,
    this.startDate,
    this.endDate,
    this.search,
  });
}

class UpdateStudentLeaveStatusEvent extends LeavesEvent {
  final String leaveId;
  final String status; // 'APPROVED' | 'REJECTED'
  final String? remarks;

  const UpdateStudentLeaveStatusEvent({
    required this.leaveId,
    required this.status,
    this.remarks,
  });
}

