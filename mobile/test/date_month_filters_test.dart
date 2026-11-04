import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/features/attendance/bloc/attendance_bloc.dart';
import 'package:mobile/features/attendance/bloc/attendance_state.dart';
import 'package:mobile/features/attendance/models/staff_attendance_record_model.dart';
import 'package:mobile/features/attendance/models/student_attendance_record_model.dart';
import 'package:mobile/features/attendance/presentation/student_attendance_history_view.dart';
import 'package:mobile/features/attendance/presentation/teacher_own_attendance_view.dart';
import 'package:mobile/features/attendance/repository/attendance_repository.dart';
import 'package:mobile/features/student/bloc/student_features_bloc.dart';
import 'package:mobile/features/student/models/student_features_model.dart';
import 'package:mobile/features/student/presentation/views/student_notices_view.dart';
import 'package:mobile/features/student/repository/student_features_repository.dart';

class DummyAttendanceRepo implements AttendanceRepository {
  List<StudentAttendanceRecordModel> studentRecords = [];
  List<StaffAttendanceRecordModel> staffRecords = [];

  DummyAttendanceRepo({
    this.studentRecords = const [],
    this.staffRecords = const [],
  });

  @override
  DioClient get dioClient => DioClient(storageService: SecureStorageService());

  @override
  Future<List<StudentAttendanceRecordModel>> getStudentAttendanceHistory() async => studentRecords;
  @override
  Future<List<StudentAttendanceRecordModel>> getClassAttendance(String c, String s, {String? date}) async => [];
  @override
  Future<void> markStudentAttendance({required String classId, required String sectionId, required String attendanceDate, required List<Map<String, dynamic>> records}) async {}
  @override
  Future<List<StaffAttendanceRecordModel>> getStaffAttendanceHistory() async => staffRecords;
  @override
  Future<List<StaffAttendanceRecordModel>> getWingStaffAttendance(String w, {String? date}) async => [];
  @override
  Future<List<StaffAttendanceRecordModel>> getManagementStaffAttendanceOverview({String? date, String? wingId}) async => [];
  @override
  Future<void> markStaffAttendance({required String date, required List<Map<String, dynamic>> records}) async {}
}

class FakeAttendanceBloc extends AttendanceBloc {
  FakeAttendanceBloc(AttendanceState initialState, {AttendanceRepository? repo})
      : super(repository: repo ?? DummyAttendanceRepo()) {
    emit(initialState);
  }
}

class DummyStudentFeaturesRepo implements StudentFeaturesRepository {
  List<NoticeModel> noticesList = [];

  @override
  DioClient get dioClient => throw UnimplementedError();

  @override
  Future<List<NoticeModel>> getNotices() async => noticesList;

  @override
  Future<FeeOverviewModel> getFeesOverview() async => const FeeOverviewModel(totalDues: 0, totalPaid: 0, totalOutstanding: 0, fees: []);
  @override
  Future<List<FeeReceiptModel>> getReceipts() async => [];
  @override
  Future<List<ComplaintModel>> getComplaints() async => [];
  @override
  Future<ComplaintModel> submitComplaint({required String title, required String category, required String description}) async => throw UnimplementedError();
  @override
  Future<List<FeedbackModel>> getFeedback() async => [];
  @override
  Future<FeedbackModel> submitFeedback({
    required String category,
    required int rating,
    required String feedbackText,
  }) async => throw UnimplementedError();
}

void main() {
  group('Date and Month Filter Widget Tests', () {
    testWidgets('StudentAttendanceHistoryView displays filters and filters by month', (tester) async {
      final records = [
        const StudentAttendanceRecordModel(
          studentId: 's1',
          attendanceDate: '2026-10-15',
          status: 'PRESENT',
        ),
        const StudentAttendanceRecordModel(
          studentId: 's1',
          attendanceDate: '2026-09-10',
          status: 'ABSENT',
        ),
      ];

      final bloc = FakeAttendanceBloc(StudentAttendanceHistoryLoaded(records));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<AttendanceBloc>.value(
              value: bloc,
              child: const StudentAttendanceHistoryView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially shows all 2 logs
      expect(find.text('Pick Date'), findsOneWidget);
      expect(find.text('All Months'), findsOneWidget);
      expect(find.text('2026-10-15'), findsOneWidget);
      expect(find.text('2026-09-10'), findsOneWidget);
      expect(find.text('50.0%'), findsOneWidget);
      expect(find.text('Overall Attendance'), findsOneWidget);

      // Tap on Month Dropdown
      await tester.tap(find.text('All Months'));
      await tester.pumpAndSettle();

      // Select 'Oct 2026' from dropdown
      final monthOption = find.text('Oct 2026').last;
      await tester.tap(monthOption);
      await tester.pumpAndSettle();

      // Now only 2026-10-15 should be shown
      expect(find.text('2026-10-15'), findsOneWidget);
      expect(find.text('2026-09-10'), findsNothing);
      expect(find.text('100.0%'), findsOneWidget);
      expect(find.text('Attendance for Oct 2026'), findsOneWidget);
      expect(find.text('Clear Filter'), findsOneWidget);

      // Tap Clear Filter
      await tester.tap(find.text('Clear Filter'));
      await tester.pumpAndSettle();

      // Both records should be back
      expect(find.text('2026-10-15'), findsOneWidget);
      expect(find.text('2026-09-10'), findsOneWidget);
      expect(find.text('Overall Attendance'), findsOneWidget);
    });

    testWidgets('TeacherOwnAttendanceView displays filters and filters by month', (tester) async {
      final records = [
        const StaffAttendanceRecordModel(
          staffId: 'st1',
          attendanceDate: '2026-10-05',
          status: 'PRESENT',
        ),
        const StaffAttendanceRecordModel(
          staffId: 'st1',
          attendanceDate: '2026-08-20',
          status: 'LEAVE',
        ),
      ];

      final bloc = FakeAttendanceBloc(
        StaffAttendanceHistoryLoaded(records),
        repo: DummyAttendanceRepo(staffRecords: records),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<AttendanceBloc>.value(
              value: bloc,
              child: const TeacherOwnAttendanceView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state
      expect(find.text('Pick Date'), findsOneWidget);
      expect(find.text('All Months'), findsOneWidget);
      expect(find.text('1 / 2 Days Logged'), findsOneWidget);
      expect(find.text('2026-10-05'), findsOneWidget);
      expect(find.text('2026-08-20'), findsOneWidget);

      // Select month Aug 2026
      await tester.tap(find.text('All Months'));
      await tester.pumpAndSettle();

      final augustOption = find.text('Aug 2026').last;
      await tester.tap(augustOption);
      await tester.pumpAndSettle();

      expect(find.text('2026-08-20'), findsOneWidget);
      expect(find.text('2026-10-05'), findsNothing);
      expect(find.text('0 / 1 Days Logged'), findsOneWidget);
      expect(find.text('Attendance for Aug 2026'), findsOneWidget);

      // Clear filter
      expect(find.text('Clear Filter'), findsOneWidget);
      await tester.tap(find.text('Clear Filter'));
      await tester.pumpAndSettle();

      expect(find.text('2026-10-05'), findsOneWidget);
      expect(find.text('2026-08-20'), findsOneWidget);
    });

    testWidgets('StudentNoticesView displays filters and filters by month', (tester) async {
      final repo = DummyStudentFeaturesRepo();
      repo.noticesList = [
        const NoticeModel(
          id: 'n1',
          title: 'Sports Day 2026',
          content: 'Sports day will be celebrated.',
          publishedAt: '2026-10-20',
          targetRole: 'STUDENT',
          priority: 'NORMAL',
        ),
        const NoticeModel(
          id: 'n2',
          title: 'Science Fair',
          content: 'Science fair submission.',
          publishedAt: '2026-09-15',
          targetRole: 'STUDENT',
          priority: 'NORMAL',
        ),
      ];

      final bloc = StudentFeaturesBloc(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<StudentFeaturesBloc>.value(
              value: bloc,
              child: const StudentNoticesView(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Pick Date'), findsOneWidget);
      expect(find.text('All Months'), findsOneWidget);
      expect(find.text('Sports Day 2026'), findsOneWidget);
      expect(find.text('Science Fair'), findsOneWidget);
      expect(find.text('2 notices'), findsOneWidget);

      // Select Month Oct 2026
      await tester.tap(find.text('All Months'));
      await tester.pumpAndSettle();

      final octOption = find.text('Oct 2026').last;
      await tester.tap(octOption);
      await tester.pumpAndSettle();

      expect(find.text('Sports Day 2026'), findsOneWidget);
      expect(find.text('Science Fair'), findsNothing);
      expect(find.text('1 notice'), findsOneWidget);
      expect(find.text('Notices for Oct 2026'), findsOneWidget);

      // Clear filter
      await tester.tap(find.text('Clear Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Sports Day 2026'), findsOneWidget);
      expect(find.text('Science Fair'), findsOneWidget);
      expect(find.text('2 notices'), findsOneWidget);

      bloc.close();
    });
  });
}
