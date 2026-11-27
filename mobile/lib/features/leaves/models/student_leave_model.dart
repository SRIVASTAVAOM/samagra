class StudentLeaveModel {
  final String id;
  final String studentId;
  final String? studentName;
  final String? admissionNumber;
  final String? rollNumber;
  final String? className;
  final String? sectionName;
  final String startDate;
  final String endDate;
  final String reason;
  final String status; // 'PENDING' | 'APPROVED' | 'REJECTED'
  final String? documentUrl;
  final String? attachmentName;
  final String? rejectionReason;
  final String? remarks;
  final String? reviewedByName;
  final String? reviewedAt;
  final String? createdAt;

  const StudentLeaveModel({
    required this.id,
    required this.studentId,
    this.studentName,
    this.admissionNumber,
    this.rollNumber,
    this.className,
    this.sectionName,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.documentUrl,
    this.attachmentName,
    this.rejectionReason,
    this.remarks,
    this.reviewedByName,
    this.reviewedAt,
    this.createdAt,
  });

  factory StudentLeaveModel.fromJson(Map<String, dynamic> json) {
    return StudentLeaveModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String?,
      admissionNumber: json['admission_number'] as String?,
      rollNumber: json['roll_number'] as String?,
      className: json['class_name'] as String?,
      sectionName: json['section_name'] as String?,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      reason: json['reason'] as String,
      status: (json['status'] as String).toUpperCase(),
      documentUrl: json['document_url'] as String? ?? json['documentUrl'] as String?,
      attachmentName: json['attachment_name'] as String? ?? json['attachmentName'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      remarks: json['remarks'] as String?,
      reviewedByName: json['reviewed_by_name'] as String?,
      reviewedAt: json['reviewed_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

DateTime? _parseLeaveCalendarDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.contains('T') || trimmed.contains(' ')) {
    final parsedFull = DateTime.tryParse(trimmed);
    if (parsedFull != null) {
      return (parsedFull.isUtc &&
              (parsedFull.hour != 0 || parsedFull.minute != 0))
          ? parsedFull.toLocal()
          : parsedFull;
    }
  }
  return DateTime.tryParse(trimmed.split(RegExp(r'[T ]')).first);
}

String _formatParsedLeaveDate(DateTime parsed) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final day = parsed.day.toString().padLeft(2, '0');
  return '$day ${months[parsed.month - 1]} ${parsed.year}';
}

/// Formats an ISO timestamp or YYYY-MM-DD date string into `dd MMM yyyy`.
/// Safely falls back to the trimmed date portion or empty string if unparseable.
String formatShortLeaveDate(String raw) {
  final parsed = _parseLeaveCalendarDate(raw);
  if (parsed == null) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? '' : trimmed.split(RegExp(r'[T ]')).first;
  }
  return _formatParsedLeaveDate(parsed);
}

/// Formats a start and end date range into a compact readable string.
String formatLeaveDateRange(String startRaw, String endRaw) {
  final start = formatShortLeaveDate(startRaw);
  final end = formatShortLeaveDate(endRaw);
  if (start.isEmpty && end.isEmpty) return 'Date unavailable';
  if (start.isEmpty) return end;
  if (end.isEmpty || start == end) return start;
  return '$start – $end';
}

/// Returns inclusive day count between [startRaw] and [endRaw], or null if invalid/reversed.
int? calculateLeaveDayCount(String startRaw, String endRaw) {
  final s = _parseLeaveCalendarDate(startRaw);
  final e = _parseLeaveCalendarDate(endRaw);
  if (s == null || e == null) return null;
  final sDate = DateTime(s.year, s.month, s.day);
  final eDate = DateTime(e.year, e.month, e.day);
  final diff = eDate.difference(sDate).inDays;
  if (diff < 0) return null;
  return diff + 1;
}

