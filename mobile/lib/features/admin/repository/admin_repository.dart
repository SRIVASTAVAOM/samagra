import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/admin_dashboard_model.dart';

class AdminRepository {
  final DioClient dioClient;

  AdminRepository({DioClient? dioClient})
      : dioClient = dioClient ??
            DioClient(storageService: SecureStorageService());

  Future<AdminDashboardStats> fetchDashboardStats() async {
    try {
      final res = await dioClient.dio.get('/admin/dashboard/summary');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data['data'] as Map<String, dynamic>? ?? res.data;
        return AdminDashboardStats.fromJson(data);
      }
    } catch (_) {
      // Safe fallback when disconnected or offline
    }

    return const AdminDashboardStats(
      totalStudents: 0,
      presentStudents: 0,
      absentStudents: 0,
      studentAttendanceRate: 0.0,
      totalStaff: 0,
      presentStaff: 0,
      onLeaveStaff: 0,
      staffAttendanceRate: 0.0,
      todayCollection: 0.0,
      totalTransactionsToday: 0,
      pendingLeaveRequests: 0,
    );
  }

  Future<bool> broadcastNotice({
    required String title,
    required String content,
    String priority = 'URGENT',
  }) async {
    try {
      final res = await dioClient.dio.post('/notices', data: {
        'title': title,
        'content': content,
        'priority': priority,
        'target_role': 'ALL',
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<List<AdminNoticeItem>> fetchNotices() async {
    try {
      final res = await dioClient.dio.get('/notices');
      if (res.statusCode == 200 && res.data != null) {
        final list = (res.data['data'] as List<dynamic>?) ?? [];
        return list
            .map((e) => AdminNoticeItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<AdminPendingLeaveItem>> fetchPendingLeaves() async {
    try {
      final res = await dioClient.dio.get('/admin/dashboard/summary');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data['data'] as Map<String, dynamic>? ?? res.data;
        final list = (data['pending_leaves'] as List<dynamic>?) ?? [];
        return list
            .map((e) =>
                AdminPendingLeaveItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> decideStaffLeave({
    required String leaveId,
    required bool isApprove,
    String? remarks,
  }) async {
    try {
      final res = await dioClient.dio.patch(
        '/leaves/staff/$leaveId/decide',
        data: {
          'decision': isApprove ? 'APPROVED' : 'REJECTED',
          if (remarks != null && remarks.isNotEmpty) 'comment': remarks,
        },
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> decideStudentLeave({
    required String leaveId,
    required bool isApprove,
    String? remarks,
  }) async {
    try {
      final res = await dioClient.dio.patch(
        '/leaves/student/$leaveId/status',
        data: {
          'status': isApprove ? 'APPROVED' : 'REJECTED',
          if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        },
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
