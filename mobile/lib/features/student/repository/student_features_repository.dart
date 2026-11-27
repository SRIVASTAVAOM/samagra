import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/student_features_model.dart';

class StudentFeaturesRepository {
  final DioClient dioClient;
  final SecureStorageService? storageService;

  StudentFeaturesRepository({
    required this.dioClient,
    this.storageService,
  });

  Future<String> _dismissedStorageKey() async {
    final userId = await storageService?.read('active_user_id');
    return (userId != null && userId.isNotEmpty)
        ? 'dismissed_notice_ids_$userId'
        : 'dismissed_notice_ids';
  }

  Future<Set<String>> getLocalDismissedNoticeIds() async {
    if (storageService == null) return <String>{};
    try {
      final key = await _dismissedStorageKey();
      final raw = await storageService!.read(key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toSet();
        }
      }
    } catch (_) {}
    return <String>{};
  }

  Future<void> _saveLocalDismissedNoticeIds(Set<String> ids) async {
    if (storageService == null) return;
    try {
      final key = await _dismissedStorageKey();
      await storageService!.write(key, jsonEncode(ids.toList()));
    } catch (_) {}
  }

  // 1. Notices
  Future<List<NoticeModel>> getNotices() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.studentNotices);
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      final notices = list
          .map((e) => NoticeModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final dismissed = await getLocalDismissedNoticeIds();
      if (dismissed.isEmpty) return notices;
      return notices.where((n) => !dismissed.contains(n.id)).toList();
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?.toString() ?? 'Failed to load notices';
      throw Exception(message);
    }
  }

  Future<List<NoticeModel>> getTeacherNotices() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.teacherNotices);
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      final notices = list
          .map((e) => NoticeModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final dismissed = await getLocalDismissedNoticeIds();
      if (dismissed.isEmpty) return notices;
      return notices.where((n) => !dismissed.contains(n.id)).toList();
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?.toString() ?? 'Failed to load teacher notices';
      throw Exception(message);
    }
  }

  Future<void> dismissNotice(String noticeId) async {
    final dismissed = await getLocalDismissedNoticeIds();
    dismissed.add(noticeId);
    await _saveLocalDismissedNoticeIds(dismissed);
    try {
      await dioClient.dio.post(ApiEndpoints.dismissStudentNotice(noticeId));
    } catch (_) {}
  }

  Future<void> clearAllNotices(List<String> noticeIds) async {
    final dismissed = await getLocalDismissedNoticeIds();
    dismissed.addAll(noticeIds);
    await _saveLocalDismissedNoticeIds(dismissed);
    try {
      await dioClient.dio.post(
        ApiEndpoints.dismissAllStudentNotices,
        data: {'noticeIds': noticeIds},
      );
    } catch (_) {}
  }

  Future<void> restoreDismissedNotices({List<String>? noticeIds}) async {
    if (noticeIds != null && noticeIds.isNotEmpty) {
      final dismissed = await getLocalDismissedNoticeIds();
      dismissed.removeAll(noticeIds);
      await _saveLocalDismissedNoticeIds(dismissed);
    } else {
      await _saveLocalDismissedNoticeIds(<String>{});
    }
    try {
      await dioClient.dio.post(
        ApiEndpoints.restoreStudentNotices,
        data: noticeIds != null && noticeIds.isNotEmpty
            ? {'noticeIds': noticeIds}
            : <String, dynamic>{},
      );
    } catch (_) {}
  }

  // 2. Fees
  Future<FeeOverviewModel> getFeesOverview() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.studentFees);
      return FeeOverviewModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data?['error']?.toString() ??
          'Failed to load fee information';
      throw Exception(message);
    }
  }

  // 3. Receipts
  Future<List<FeeReceiptModel>> getReceipts() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.studentReceipts);
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list
          .map((e) => FeeReceiptModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?.toString() ?? 'Failed to load receipts';
      throw Exception(message);
    }
  }

  // 4. Complaints
  Future<List<ComplaintModel>> getComplaints() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.studentComplaints);
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list
          .map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?.toString() ?? 'Failed to load complaints';
      throw Exception(message);
    }
  }

  Future<ComplaintModel> submitComplaint({
    required String title,
    required String category,
    required String description,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.studentComplaints,
        data: {
          'title': title,
          'category': category,
          'description': description,
        },
      );
      return ComplaintModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data?['error']?.toString() ??
          'Failed to submit complaint';
      throw Exception(message);
    }
  }

  // 5. Feedback
  Future<List<FeedbackModel>> getFeedback() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.studentFeedback);
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list
          .map((e) => FeedbackModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?.toString() ?? 'Failed to load feedback';
      throw Exception(message);
    }
  }

  Future<FeedbackModel> submitFeedback({
    required String category,
    required int rating,
    required String feedbackText,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.studentFeedback,
        data: {
          'category': category,
          'rating': rating,
          'feedback_text': feedbackText,
        },
      );
      return FeedbackModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?.toString() ?? 'Failed to submit feedback';
      throw Exception(message);
    }
  }
}
