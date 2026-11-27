import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../models/exam_model.dart';

class MarksRosterResult {
  final ExamDatesheetModel datesheet;
  final List<StudentMarkRosterModel> roster;

  const MarksRosterResult({
    required this.datesheet,
    required this.roster,
  });
}

class ExamsRepository {
  final DioClient client;

  ExamsRepository({required this.client});

  String _extractDioErrorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic> && error['message'] != null) {
        return error['message'].toString();
      }
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }
      if (data['message'] != null) {
        return data['message'].toString();
      }
    }
    return fallback;
  }

  /// 1. List Examinations
  Future<List<ExamModel>> getExams({String? wingId, String? academicYearId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (wingId != null) queryParams['wingId'] = wingId;
      if (academicYearId != null) queryParams['academicYearId'] = academicYearId;

      final response = await client.dio.get(
        ApiEndpoints.exams,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data['data'] as List<dynamic>;
      return data.map((e) => ExamModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, 'Failed to load examinations.'));
    }
  }

  /// 2. Get Exam Datesheets
  Future<List<ExamDatesheetModel>> getDatesheets(String examId, {String? classId}) async {
    try {
      final response = await client.dio.get(
        ApiEndpoints.examDatesheets(examId, classId: classId),
      );

      final data = response.data['data'] as List<dynamic>;
      return data.map((e) => ExamDatesheetModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, 'Failed to load exam datesheet.'));
    }
  }

  /// 3. Get Marks Roster for a Datesheet
  Future<MarksRosterResult> getMarksRoster(
    String examId,
    String datesheetId, {
    String? sectionId,
  }) async {
    try {
      final response = await client.dio.get(
        ApiEndpoints.examMarksRoster(examId, datesheetId, sectionId: sectionId),
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final datesheet = ExamDatesheetModel.fromJson(data['datesheet'] as Map<String, dynamic>);
      final rosterList = (data['roster'] as List<dynamic>)
          .map((e) => StudentMarkRosterModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return MarksRosterResult(datesheet: datesheet, roster: rosterList);
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, 'Failed to load marks roster.'));
    }
  }

  /// 4. Save Marks (Teacher / Coordinator)
  Future<void> saveMarks(
    String examId,
    String datesheetId,
    List<Map<String, dynamic>> entries, {
    bool submitForVerification = false,
  }) async {
    try {
      await client.dio.post(
        ApiEndpoints.examSaveMarks(examId, datesheetId),
        data: {
          'submitForVerification': submitForVerification,
          'entries': entries,
        },
      );
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, 'Failed to save marks.'));
    }
  }

  /// 5. Get Datesheet Summary & Analysis
  Future<DatesheetSummaryModel> getDatesheetSummary(String examId, String datesheetId) async {
    try {
      final response = await client.dio.get(
        ApiEndpoints.examDatesheetSummary(examId, datesheetId),
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return DatesheetSummaryModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, 'Failed to load datesheet summary.'));
    }
  }

  /// 6. Coordinator Verify Marks
  Future<int> verifyMarks(String examId, String datesheetId) async {
    try {
      final response = await client.dio.patch(
        ApiEndpoints.examVerifyMarks(examId, datesheetId),
      );
      return response.data['data']?['verifiedCount'] as int? ?? 1;
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, 'Failed to verify marks.'));
    }
  }

  /// 7. Generate Class Report Cards
  Future<List<ReportCardModel>> generateReportCards(
    String examId,
    String classId,
    String sectionId, {
    String? remarks,
  }) async {
    try {
      final response = await client.dio.post(
        ApiEndpoints.examGenerateReportCards(examId, classId, sectionId),
        data: remarks != null ? {'remarks': remarks} : {},
      );

      final data = response.data['data'] as List<dynamic>;
      return data.map((e) => ReportCardModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, 'Failed to generate report cards.'));
    }
  }

  /// 8. Get Class Report Cards
  Future<List<ReportCardModel>> getClassReportCards(
    String examId,
    String classId,
    String sectionId,
  ) async {
    try {
      final response = await client.dio.get(
        ApiEndpoints.examClassReportCards(examId, classId, sectionId),
      );

      final data = response.data['data'] as List<dynamic>;
      return data.map((e) => ReportCardModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, 'Failed to load report cards.'));
    }
  }

  /// 9. Approve Class Report Cards
  Future<int> approveReportCards(String examId, String classId, String sectionId) async {
    try {
      final response = await client.dio.patch(
        ApiEndpoints.examApproveReportCards(examId, classId, sectionId),
      );
      return response.data['data']?['approvedCount'] as int? ?? 1;
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, 'Failed to approve report cards.'));
    }
  }

  /// 10. Student View Result
  Future<StudentExamResultModel> getStudentResult(String examId) async {
    try {
      final response = await client.dio.get(
        ApiEndpoints.examStudentResult(examId),
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return StudentExamResultModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, 'Failed to fetch exam result.'));
    }
  }

  /// 11. Coordinator Publish Exam
  Future<void> publishExam(String examId, bool isPublished) async {
    try {
      await client.dio.patch(
        ApiEndpoints.examPublish(examId),
        data: {'isPublished': isPublished},
      );
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, 'Failed to update publication status.'));
    }
  }
}
