import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../models/staff_leave_model.dart';
import '../models/student_leave_model.dart';

class LeavesRepository {
  final DioClient dioClient;

  LeavesRepository({required this.dioClient});

  /// Submit a staff leave application (for Teacher self-apply)
  Future<StaffLeaveModel> applyStaffLeave({
    required String startDate,
    required String endDate,
    required String leaveType,
    required String reason,
    String? documentUrl,
    String? attachmentName,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.staffLeaves,
        data: {
          'startDate': startDate,
          'start_date': startDate,
          'endDate': endDate,
          'end_date': endDate,
          'leaveType': leaveType,
          'leave_type': leaveType,
          'reason': reason,
          if (documentUrl != null && documentUrl.isNotEmpty) ...{
            'documentUrl': documentUrl,
            'document_url': documentUrl,
          },
          if (attachmentName != null && attachmentName.isNotEmpty) ...{
            'attachmentName': attachmentName,
            'attachment_name': attachmentName,
          },
        },
      );
      return StaffLeaveModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?.toString() ?? 'Failed to apply staff leave';
      throw Exception(message);
    }
  }

  /// Get teacher's own leave applications
  Future<List<StaffLeaveModel>> getStaffMyLeaves() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.staffMyLeaves);
      final data = response.data['data'] as List<dynamic>;
      return data
          .map((item) => StaffLeaveModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message = e.response?.data?['error']?.toString() ??
          'Failed to load staff leave applications';
      throw Exception(message);
    }
  }

  /// Get wing staff leaves for Coordinator review
  Future<List<StaffLeaveModel>> getStaffWingLeaves() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.staffWingLeaves);
      final data = response.data['data'] as List<dynamic>;
      return data
          .map((item) => StaffLeaveModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message = e.response?.data?['error']?.toString() ??
          'Failed to load wing staff leaves';
      throw Exception(message);
    }
  }

  /// Make a coordinator recommendation for staff leave
  Future<void> recommendStaffLeave(String leaveId, {String? note}) async {
    try {
      await dioClient.dio.patch(
        ApiEndpoints.recommendStaffLeave(leaveId),
        data: {
          'recommendation': ?note,
          'note': ?note,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data?['error']?.toString() ??
          'Failed to recommend leave';
      throw Exception(message);
    }
  }

  /// Get management queue of staff leaves with optional filters
  Future<List<StaffLeaveModel>> getManagementLeaveQueue({
    String? status,
    String? timeframe,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty && status.toUpperCase() != 'ALL') {
        queryParams['status'] = status.toUpperCase();
      }
      if (timeframe != null && timeframe.isNotEmpty && timeframe != 'all') {
        queryParams['timeframe'] = timeframe;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      final response = await dioClient.dio.get(
        ApiEndpoints.staffManagementQueue,
        queryParameters: queryParams,
      );
      final data = response.data['data'] as List<dynamic>;
      return data
          .map((item) => StaffLeaveModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message = e.response?.data?['error']?.toString() ??
          'Failed to load management leave queue';
      throw Exception(message);
    }
  }

  /// Approve or reject staff leave (Management only)
  Future<void> decideStaffLeave(
    String leaveId, {
    required String decision, // 'APPROVED' | 'REJECTED'
    String? note,
    String? rejectionReason,
  }) async {
    try {
      await dioClient.dio.patch(
        ApiEndpoints.decideStaffLeave(leaveId),
        data: {
          'decision': decision,
          'comment': ?(note ?? rejectionReason),
          'note': ?note,
          'rejection_reason': ?rejectionReason,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data?['error']?.toString() ??
          'Failed to decide leave application';
      throw Exception(message);
    }
  }

  /// Submit a student leave application
  Future<StudentLeaveModel> applyStudentLeave({
    required String startDate,
    required String endDate,
    required String reason,
    String? documentUrl,
    String? attachmentName,
  }) async {
    try {
      final payload = <String, dynamic>{
        'startDate': startDate,
        'start_date': startDate,
        'endDate': endDate,
        'end_date': endDate,
        'reason': reason,
      };
      if (documentUrl != null && documentUrl.isNotEmpty) {
        payload['documentUrl'] = documentUrl;
        payload['document_url'] = documentUrl;
      }
      if (attachmentName != null && attachmentName.isNotEmpty) {
        payload['attachmentName'] = attachmentName;
        payload['attachment_name'] = attachmentName;
      }
      final response = await dioClient.dio.post(
        ApiEndpoints.studentLeaves,
        data: payload,
      );
      return StudentLeaveModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data?['error']?.toString() ??
          'Failed to submit student leave';
      throw Exception(message);
    }
  }

  /// Get student's own leave applications
  Future<List<StudentLeaveModel>> getStudentMyLeaves() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.studentMyLeaves);
      final data = response.data['data'] as List<dynamic>;
      return data
          .map((item) => StudentLeaveModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message = e.response?.data?['error']?.toString() ??
          'Failed to load student leave history';
      throw Exception(message);
    }
  }

  /// Direct upload of leave attachment (image or PDF up to 5MB)
  Future<Map<String, dynamic>> uploadAttachment(List<int> bytes, String fileName) async {
    try {
      final lower = fileName.toLowerCase();
      final mimeType = lower.endsWith('.pdf')
          ? 'application/pdf'
          : (lower.endsWith('.png')
              ? 'image/png'
              : (lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg'));
      final response = await dioClient.dio.post(
        '${ApiEndpoints.leaveAttachmentUpload}?fileName=${Uri.encodeComponent(fileName)}',
        data: Uint8List.fromList(bytes),
        options: Options(
          headers: {
            'Content-Type': mimeType,
          },
        ),
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?.toString() ?? 'Failed to upload leave attachment';
      throw Exception(message);
    }
  }

  /// Get student leave applications for class teacher's homeroom or pending approvals
  Future<List<StudentLeaveModel>> getClassStudentLeaves({
    String? status,
    String? timeframe,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty && status.toUpperCase() != 'ALL') {
        queryParams['status'] = status.toUpperCase();
      }
      if (timeframe != null && timeframe.isNotEmpty && timeframe != 'all') {
        queryParams['timeframe'] = timeframe;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final endpoint = (status != null && status.toUpperCase() != 'PENDING' && status.toUpperCase() != 'ALL')
          ? ApiEndpoints.studentClassLeaves
          : ApiEndpoints.studentPendingApprovals;

      try {
        final response = await dioClient.dio.get(
          endpoint,
          queryParameters: queryParams,
        );
        final data = response.data['data'] as List<dynamic>;
        return data
            .map((item) => StudentLeaveModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } on DioException catch (_) {
        final fallbackResponse = await dioClient.dio.get(
          ApiEndpoints.studentClassLeaves,
          queryParameters: queryParams,
        );
        final fallbackData = fallbackResponse.data['data'] as List<dynamic>;
        return fallbackData
            .map((item) => StudentLeaveModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } on DioException catch (e) {
      final message = e.response?.data?['error']?.toString() ??
          'Failed to load class student leave requests';
      throw Exception(message);
    }
  }

  /// Approve or reject student leave application (Class Teacher only)
  Future<void> updateStudentLeaveStatus(
    String leaveId, {
    required String status,
    String? remarks,
  }) async {
    try {
      await dioClient.patch(
        ApiEndpoints.updateStudentLeaveStatus(leaveId),
        data: {
          'status': status,
          'remarks': remarks,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data?['error']?.toString() ??
          'Failed to update student leave status';
      throw Exception(message);
    }
  }
}

